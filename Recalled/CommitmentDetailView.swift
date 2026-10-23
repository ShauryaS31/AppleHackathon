import Foundation
import RecalledCore
import SwiftData
import SwiftUI

struct CommitmentDetailView: View {
    let commitment: StoredCommitment
    let conflicts: [ConflictDetector.Conflict]
    @Query private var evidence: [StoredEvidence]
    @Query private var reviews: [StoredReviewItem]
    @Query private var receipts: [StoredActionReceipt]

    init(commitment: StoredCommitment, conflicts: [ConflictDetector.Conflict]) {
        self.commitment = commitment
        self.conflicts = conflicts
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
            if !conflicts.isEmpty {
                Section("Calendar conflicts") {
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
                            Text(receipt.action == .createEvent ? "Create event" : "Create reminder")
                            Text(receipt.result)
                            Text(receipt.providerId).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .textSelection(.enabled)
        .navigationTitle(commitment.title)
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
