import Foundation
import RecalledCore
import SwiftData

struct CalendarPreview: Identifiable {
    let id = UUID()
    let commitment: Commitment
    let draft: EventDraft
    var overlaps: [CalendarEvent]
}

enum CalendarApprovalError: LocalizedError {
    case stale, busy, pendingReceipt, receiptFailed(String)

    var errorDescription: String? {
        switch self {
        case .stale: "This commitment changed. Close the preview and review the current item before approving."
        case .busy: "A calendar action is already in progress. Please wait."
        case .pendingReceipt: "An event was saved but its receipt still needs saving. Retry saving the receipt before another calendar action."
        case .receiptFailed(let id):
            "Calendar saved event \(id), but Recalled could not save its receipt. Retry saving the receipt; this will not create another event. Keep the app open until it succeeds."
        }
    }
}

extension AppStore {
    func calendarPreview(for commitment: Commitment) async throws -> CalendarPreview {
        let draft = try CalendarAction.draft(for: commitment)
        let events = try await calendarStore.events(in: DateInterval(start: draft.start, end: draft.end))
        try Task.checkCancellation()
        try validateCalendarSnapshot(commitment)
        return CalendarPreview(commitment: commitment, draft: draft,
            overlaps: CalendarAction.overlaps(draft: draft, commitment: commitment, events: events))
    }

    /// Returns a new preview if overlaps changed or the linked event was deleted.
    /// Neither case writes an event; the returned preview needs fresh approval.
    /// A nil result means the approved event and its local receipt were saved.
    func approveCalendar(_ preview: CalendarPreview) async throws -> CalendarPreview? {
        guard !isWritingCalendar else { throw CalendarApprovalError.busy }
        guard pendingCalendarReceipt == nil else { throw CalendarApprovalError.pendingReceipt }
        isWritingCalendar = true
        defer { isWritingCalendar = false }
        try validateCalendarSnapshot(preview.commitment)
        // Always fetch the proposed interval afresh, even outside the agenda's 14-day window.
        let events = try await calendarStore.events(in:
            DateInterval(start: preview.draft.start, end: preview.draft.end))
        try Task.checkCancellation()
        try validateCalendarSnapshot(preview.commitment)
        let overlaps = CalendarAction.overlaps(draft: preview.draft,
            commitment: preview.commitment, events: events)
        guard overlaps == preview.overlaps else {
            return CalendarPreview(commitment: preview.commitment, draft: preview.draft, overlaps: overlaps)
        }

        let providerID: String
        let action: ActionReceipt.Action
        if let existingID = preview.commitment.calendarEventId {
            do {
                try await calendarStore.update(existingID, with: preview.draft)
            } catch EventKitCalendarError.missingEvent {
                return try unlinkMissingCalendarEvent(preview, events: events)
            } catch CalendarActionError.eventNotFound {
                return try unlinkMissingCalendarEvent(preview, events: events)
            }
            providerID = existingID
            action = .updateEvent
        } else {
            providerID = try await calendarStore.create(preview.draft)
            action = .createEvent
        }
        // Keep the successful external write in memory until the local transaction
        // succeeds. A retry saves only this receipt, never another external event.
        pendingCalendarReceipt = ActionReceipt(commitmentId: preview.commitment.id,
            action: action, providerId: providerID,
            result: "\(action == .updateEvent ? "Updated" : "Created") in Calendar after approval: \(preview.draft.title).")
        noteCalendarChanged()
        try savePendingCalendarReceipt()
        return nil
    }

    private func unlinkMissingCalendarEvent(_ preview: CalendarPreview,
                                            events: [CalendarEvent]) throws -> CalendarPreview {
        // The commitment may have changed while the provider update was suspended.
        try validateCalendarSnapshot(preview.commitment)
        let context = container.mainContext
        let id = preview.commitment.id
        guard let row = try context.fetch(FetchDescriptor<StoredCommitment>(
            predicate: #Predicate { $0.id == id })).first else {
            throw CalendarApprovalError.stale
        }
        do {
            row.calendarEventId = nil
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        let unlinked = row.toCore()
        noteCalendarChanged()
        // No external write or receipt here. Approval of this preview takes the
        // normal create path and records a new createEvent receipt on success.
        return CalendarPreview(commitment: unlinked, draft: preview.draft,
            overlaps: CalendarAction.overlaps(draft: preview.draft, commitment: unlinked, events: events))
    }

    func savePendingCalendarReceipt() throws {
        guard let receipt = pendingCalendarReceipt else { return }
        let context = container.mainContext
        do {
            let id = receipt.commitmentId
            guard let row = try context.fetch(FetchDescriptor<StoredCommitment>(
                predicate: #Predicate { $0.id == id })).first else {
                throw CalendarApprovalError.stale
            }
            row.calendarEventId = receipt.providerId
            context.insert(StoredActionReceipt(receipt))
            try context.save()
            pendingCalendarReceipt = nil
        } catch {
            context.rollback()
            throw CalendarApprovalError.receiptFailed(receipt.providerId)
        }
    }

    private func validateCalendarSnapshot(_ snapshot: Commitment) throws {
        let id = snapshot.id
        let row = try container.mainContext.fetch(FetchDescriptor<StoredCommitment>(
            predicate: #Predicate { $0.id == id })).first
        guard row?.toCore() == snapshot, snapshot.status == .confirmed else {
            throw CalendarApprovalError.stale
        }
    }
}

extension CalendarActionError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConfirmed: "Confirm this item in Review before adding it to Calendar."
        case .unresolvedDate: "Choose a valid date and time in Review before adding this item to Calendar."
        case .invalidTimeZone: "Choose a valid time zone in Review before adding this item to Calendar."
        case .eventNotFound: "The linked calendar event could not be found. No new event was created."
        }
    }
}
