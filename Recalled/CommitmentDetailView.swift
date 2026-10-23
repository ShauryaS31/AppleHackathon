import Foundation
import RecalledCore
import SwiftData
import SwiftUI

struct CommitmentDetailView: View {
    let store: AppStore
    let commitment: StoredCommitment
    @Environment(\.scenePhase) private var scenePhase
    @State private var conflicts: [ConflictDetector.Conflict] = []
    @State private var calendarError: String?
    @State private var actionError: String?
    @State private var preview: CalendarPreview?
    @State private var isPreparing = false
    @Query private var evidence: [StoredEvidence]
    @Query private var reviews: [StoredReviewItem]
    @Query private var receipts: [StoredActionReceipt]

    init(store: AppStore, commitment: StoredCommitment) {
        self.store = store
        self.commitment = commitment
        let id = commitment.id
        _evidence = Query(filter: #Predicate<StoredEvidence> { $0.commitmentId == id },
                          sort: \StoredEvidence.capturedAt)
        _reviews = Query(filter: #Predicate<StoredReviewItem> { $0.commitmentId == id })
        _receipts = Query(filter: #Predicate<StoredActionReceipt> { $0.commitmentId == id })
    }

    var body: some View {
        List {
            Section("Commitment") {
                LabeledContent("Title", value: commitment.title)
                LabeledContent("Kind", value: commitment.kind.rawValue.capitalized)
                LabeledContent("Status", value: statusDescription)
                LabeledContent("Who", value: commitment.actor)
                LabeledContent("Original date words", value: commitment.dueText)
                if let start = commitment.dueStart {
                    if commitment.kind == .deadline && commitment.dueEnd == nil {
                        LabeledContent("Due date", value: start.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        LabeledContent("Start", value: start.formatted(date: .abbreviated, time: .shortened))
                    }
                } else {
                    LabeledContent("Date", value: "Needs review")
                }
                if let end = commitment.dueEnd {
                    LabeledContent("End", value: end.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Time zone", value: commitment.timezone ?? "Not specified")
                LabeledContent("Version", value: String(commitment.version))
                if let id = commitment.calendarEventId { LabeledContent("Calendar event", value: id) }
            }
            Section("Calendar") {
                if commitment.status == .confirmed {
                    Button(commitment.calendarEventId == nil ? "Add to Calendar" : "Update Calendar event") {
                        Task { await preparePreview() }
                    }
                    .disabled(isPreparing || store.isWritingCalendar || store.pendingCalendarReceipt != nil)
                    if isPreparing { ProgressView("Checking calendar…") }
                } else {
                    Text("Confirm this item in Review before adding it to Calendar.")
                        .foregroundStyle(.secondary)
                }
                if store.pendingCalendarReceipt != nil {
                    Text("An event was saved. Its receipt still needs saving.")
                    Button("Retry saving receipt") {
                        do { try store.savePendingCalendarReceipt(); actionError = nil }
                        catch { actionError = error.localizedDescription }
                    }
                }
                if let actionError { Text(actionError).foregroundStyle(.red) }
                if let calendarError {
                    Text(calendarError).foregroundStyle(.secondary)
                    Button("Retry conflict check") { Task { await refreshConflicts() } }
                }
            }
            if !conflicts.isEmpty {
                Section("Calendar conflicts · next 14 days") {
                    ForEach(conflicts.indices, id: \.self) { index in
                        let event = conflicts[index].event
                        VStack(alignment: .leading, spacing: 4) {
                            Label(event.title, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("\(event.start.formatted(date: .abbreviated, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                        }
                    }
                }
            }
            if !reviews.isEmpty {
                Section("Review") {
                    ForEach(reviews) { review in
                        Label(review.reason, systemImage: "questionmark.circle")
                    }
                }
            }
            Section {
                if evidence.isEmpty { Text("No evidence recorded").foregroundStyle(.secondary) }
                ForEach(evidence) { source in
                    VStack(alignment: .leading, spacing: 12) {
                        Label(source.sender, systemImage: source.sourceIcon).font(.headline)
                        Text(source.subject).font(.subheadline)
                        Text(highlightedExcerpt(source))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        LabeledContent("Source", value: source.source.rawValue.capitalized)
                        LabeledContent("Sent", value: source.sentAt.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Captured", value: source.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Message reference", value: source.sourceMessageId)
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Evidence")
            } footer: {
                Text("The highlighted words are the evidence. Only excerpts and message metadata are retained.")
            }
            if !receipts.isEmpty {
                Section("Actions") {
                    ForEach(receipts) { receipt in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(receiptTitle(receipt.action))
                            Text(receipt.result)
                            Text(receipt.providerId).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .textSelection(.enabled)
        .navigationTitle(commitment.title)
        .sheet(item: $preview) { value in
            CalendarApprovalView(store: store, preview: value)
        }
        .task(id: refreshKey) { await refreshConflicts() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshConflicts() } }
        }
    }

    private struct RefreshKey: Equatable {
        let commitment: Commitment
        let revision: Int
    }

    private var refreshKey: RefreshKey {
        RefreshKey(commitment: commitment.toCore(), revision: store.calendarRevision)
    }

    @MainActor private func refreshConflicts() async {
        let key = refreshKey
        let start = Calendar.current.startOfDay(for: .now)
        guard let end = Calendar.current.date(byAdding: .day, value: 14, to: start) else { return }
        do {
            let events = try await store.calendarStore.events(in: DateInterval(start: start, end: end))
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = ConflictDetector.conflicts(commitments: [key.commitment], calendarEvents: events)
            calendarError = nil
        } catch {
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = []
            calendarError = error.localizedDescription
        }
    }

    @MainActor private func preparePreview() async {
        guard !isPreparing else { return }
        isPreparing = true
        actionError = nil
        defer { isPreparing = false }
        do { preview = try await store.calendarPreview(for: commitment.toCore()) }
        catch { actionError = error.localizedDescription }
    }

    private func receiptTitle(_ action: ActionReceipt.Action) -> String {
        switch action {
        case .createEvent: "Create event"
        case .updateEvent: "Update event"
        case .createReminder: "Create reminder"
        }
    }

    private var statusDescription: String {
        commitment.status == .needsReview ? "Needs review" : commitment.status.rawValue.capitalized
    }

    private func highlightedExcerpt(_ source: StoredEvidence) -> AttributedString {
        var result = AttributedString("… " + source.contextBefore)
        var excerpt = AttributedString(source.excerpt)
        excerpt.backgroundColor = .yellow
        excerpt.foregroundColor = .black
        excerpt.font = .body.bold()
        result.append(excerpt)
        result.append(AttributedString(source.contextAfter + " …"))
        return result
    }
}
