import EventKit
import Foundation
import RecalledCore

enum EventKitCalendarError: LocalizedError {
    case denied, restricted, noWritableCalendar, missingEvent, missingIdentifier, invalidDraft

    var errorDescription: String? {
        switch self {
        case .denied:
            #if os(iOS)
            "Calendar full access is off. Enable full access for Recalled in Settings > Privacy & Security > Calendars, then retry."
            #else
            "Calendar full access is off. Enable full access for Recalled in System Settings > Privacy & Security > Calendars, then retry."
            #endif
        case .restricted:
            "Calendar access is restricted on this device. Recalled cannot check conflicts or save events."
        case .noWritableCalendar:
            "No writable default calendar is available. Choose one in Calendar, then retry."
        case .missingEvent:
            "The linked calendar event no longer exists. No replacement event was created."
        case .missingIdentifier:
            "Calendar saved the event but did not return its identifier. Check Calendar before trying again."
        case .invalidDraft:
            "The event needs a valid time range and time zone before it can be saved."
        }
    }
}

/// EventKit objects stay inside this actor; only Sendable Core values cross it.
actor EventKitCalendarStore: CalendarStore {
    private let store = EKEventStore()
    private var accessRequest: Task<Bool, Error>?

    private func requireFullAccess() async throws {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess: return
        case .denied: throw EventKitCalendarError.denied
        case .restricted: throw EventKitCalendarError.restricted
        case .notDetermined, .writeOnly:
            if accessRequest == nil {
                accessRequest = Task {
                    // Use the callback bridge so the non-Sendable store never
                    // crosses an isolation boundary in an imported async method.
                    try await withCheckedThrowingContinuation { continuation in
                        store.requestFullAccessToEvents { granted, error in
                            if let error { continuation.resume(throwing: error) }
                            else { continuation.resume(returning: granted) }
                        }
                    }
                }
            }
            guard let request = accessRequest else { throw EventKitCalendarError.denied }
            defer { accessRequest = nil }
            guard try await request.value,
                  EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
                throw EventKitCalendarError.denied
            }
        @unknown default: throw EventKitCalendarError.denied
        }
    }

    func events(in range: DateInterval) async throws -> [CalendarEvent] {
        try await requireFullAccess()
        guard range.duration > 0 else { return [] }
        let predicate = store.predicateForEvents(withStart: range.start, end: range.end, calendars: nil)
        return store.events(matching: predicate).compactMap { event in
            guard let id = event.eventIdentifier, let start = event.startDate,
                  let end = event.endDate, end > start,
                  start < range.end, end > range.start else { return nil }
            return CalendarEvent(id: id, title: event.title ?? "Untitled event",
                start: start, end: end, timezone: (event.timeZone ?? .current).identifier,
                isAllDay: event.isAllDay, notes: event.notes, location: event.location)
        }
    }

    func create(_ draft: EventDraft) async throws -> String {
        try await requireFullAccess()
        try Task.checkCancellation()
        guard let calendar = store.defaultCalendarForNewEvents, calendar.allowsContentModifications else {
            throw EventKitCalendarError.noWritableCalendar
        }
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        try apply(draft, to: event)
        try store.save(event, span: .thisEvent, commit: true)
        guard let id = event.eventIdentifier else { throw EventKitCalendarError.missingIdentifier }
        return id
    }

    func update(_ id: String, with draft: EventDraft) async throws {
        try await requireFullAccess()
        try Task.checkCancellation()
        guard let event = store.event(withIdentifier: id) else { throw EventKitCalendarError.missingEvent }
        guard let calendar = event.calendar, calendar.allowsContentModifications else {
            throw EventKitCalendarError.noWritableCalendar
        }
        try apply(draft, to: event)
        try store.save(event, span: .thisEvent, commit: true)
    }

    private func apply(_ draft: EventDraft, to event: EKEvent) throws {
        guard draft.end > draft.start, let zone = TimeZone(identifier: draft.timezone) else {
            throw EventKitCalendarError.invalidDraft
        }
        event.title = draft.title
        event.timeZone = zone
        event.isAllDay = draft.isAllDay
        event.startDate = draft.start
        event.endDate = draft.end
        event.location = draft.location
        event.notes = draft.notes
        // No attendees or recipients are inferred from commitment/model text.
    }
}
