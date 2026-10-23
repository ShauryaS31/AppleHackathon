import Foundation
import RecalledCore
import SwiftData
import SwiftUI

struct ReviewQueueView: View {
    let store: AppStore
    @Query(sort: \StoredReviewItem.createdAt) private var reviews: [StoredReviewItem]
    @Query private var commitments: [StoredCommitment]
    @Query private var evidence: [StoredEvidence]
    @State private var selectedReview: Selection?

    private struct Selection: Identifiable { let id: UUID }

    var body: some View {
        NavigationStack {
            List {
                if reviews.isEmpty {
                    ContentUnavailableView("All reviewed", systemImage: "checkmark.circle",
                        description: Text("Items needing your decision will appear here."))
                }
                ForEach(reviews) { review in
                    Button { selectedReview = Selection(id: review.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            let candidate = commitments.first { $0.id == review.commitmentId }
                            Text(candidate?.title ?? "Message needs review").font(.headline)
                            Label(review.reason, systemImage: "questionmark.circle")
                                .font(.subheadline)
                            ReviewSourceView(review: review, evidence: sources(for: review))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Open review actions")
                }
            }
            .navigationTitle("Review")
            .sheet(item: $selectedReview) { review in
                ReviewResolutionView(store: store, reviewID: review.id)
            }
        }
    }

    private func sources(for review: StoredReviewItem) -> [StoredEvidence] {
        evidence.filter {
            if let id = review.commitmentId { return $0.commitmentId == id }
            return $0.sourceMessageId == review.sourceMessageId
        }
    }
}

private struct ReviewSourceView: View {
    let review: StoredReviewItem
    let evidence: [StoredEvidence]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let source = evidence.first {
                Text(source.sender.isEmpty ? "Unknown sender" : source.sender)
                Text(source.sentAt, format: .dateTime).font(.caption).foregroundStyle(.secondary)
                Text(source.excerpt.isEmpty ? review.reason : source.excerpt)
            } else {
                Text(review.sender.isEmpty ? "Unknown sender" : review.sender)
                LabeledContent("Received for review",
                    value: review.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
                Text(review.excerpt.isEmpty ? review.reason : review.excerpt)
            }
        }
        .font(.subheadline)
    }
}

private struct ReviewResolutionView: View {
    let store: AppStore
    let reviewID: UUID
    @Environment(\.dismiss) private var dismiss
    @Query private var reviews: [StoredReviewItem]
    @Query(sort: \StoredCommitment.dueStart) private var commitments: [StoredCommitment]
    @Query(sort: \StoredEvidence.capturedAt) private var evidence: [StoredEvidence]
    @State private var mode: Mode = .actions
    @State private var title = ""
    @State private var kind: Commitment.Kind = .commitment
    @State private var start = Date.now
    @State private var end = Date.now
    @State private var includesEnd = false
    @State private var dateOnly = false
    @State private var errorMessage: String?

    private enum Mode { case actions, edit, create, merge }

    private var review: StoredReviewItem? { reviews.first { $0.id == reviewID } }
    private var candidate: StoredCommitment? {
        guard let id = review?.commitmentId else { return nil }
        return commitments.first { $0.id == id }
    }
    private var openTargets: [StoredCommitment] {
        commitments.filter { $0.isOpenForReview && $0.id != candidate?.id }
    }
    private var schedule: ReviewSchedule {
        ReviewSchedule(start: dateOnly ? Calendar.current.startOfDay(for: start) : start,
            end: dateOnly || !includesEnd ? nil : end, timezone: TimeZone.current.identifier)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let review {
                    Section("Needs your decision") {
                        if let candidate { Text(candidate.title).font(.headline) }
                        Text(review.reason)
                        ReviewSourceView(review: review, evidence: evidence.filter {
                            if let id = review.commitmentId { return $0.commitmentId == id }
                            return $0.sourceMessageId == review.sourceMessageId
                        })
                        if let candidate {
                            NavigationLink("View evidence and details") {
                                CommitmentDetailView(commitment: candidate, conflicts: [])
                            }
                        }
                    }
                    switch mode {
                    case .actions:
                        actionSection(review: review)
                    case .edit, .create:
                        editorSection
                    case .merge:
                        mergeSection
                    }
                } else {
                    Text("This review has already been resolved.")
                }
            }
            .navigationTitle(mode == .create ? "Create item" : "Review item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Couldn't resolve review", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
        .frame(minWidth: 320, minHeight: 400)
    }

    @ViewBuilder
    private func actionSection(review: StoredReviewItem) -> some View {
        Section("Actions") {
            if let candidate {
                if let date = candidate.dueStart {
                    LabeledContent("Current date", value: date.formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text("Choose a date and time before confirming.").foregroundStyle(.secondary)
                }
                Button("Confirm") { resolve(.confirm) }
                    .disabled(candidate.dueStart == nil)
                Button("Edit date/time") {
                    kind = candidate.kind
                    start = candidate.dueStart ?? .now
                    end = candidate.dueEnd ?? start
                    includesEnd = candidate.dueEnd != nil
                    dateOnly = candidate.kind == .deadline && candidate.dueEnd == nil
                    mode = .edit
                }
                Button("Mark as same as existing item") { mode = .merge }
            } else if review.commitmentId == nil {
                Button("Create item") {
                    title = ""
                    kind = .commitment
                    start = .now
                    end = start
                    includesEnd = false
                    dateOnly = false
                    mode = .create
                }
            }
            Button("Dismiss", role: .destructive) { resolve(.dismiss) }
        }
    }

    private var editorSection: some View {
        Section {
            if mode == .create {
                TextField("Title", text: $title)
                Picker("Kind", selection: $kind) {
                    ForEach(Commitment.Kind.allCases, id: \.self) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }
                .onChange(of: kind) { _, value in
                    dateOnly = value == .deadline
                    if dateOnly { includesEnd = false }
                }
            }
            if kind == .deadline {
                Toggle("Date only", isOn: $dateOnly)
                    .onChange(of: dateOnly) { _, value in
                        // Today uses a deadline with no end as a date-only item.
                        includesEnd = !value
                    }
            }
            DatePicker(dateOnly ? "Due date" : "Start", selection: $start,
                displayedComponents: dateOnly ? [.date] : [.date, .hourAndMinute])
            if !dateOnly {
                Toggle("Include end time", isOn: $includesEnd)
                    .disabled(kind == .deadline)
                if includesEnd {
                    DatePicker("End", selection: $end, in: start...,
                        displayedComponents: [.date, .hourAndMinute])
                }
            }
            Text("Time zone: \(TimeZone.current.identifier)").font(.caption)
            Button(mode == .create ? "Create item" : "Save and confirm") {
                if mode == .create { resolve(.create(title: title, kind: kind, schedule: schedule)) }
                else { resolve(.edit(schedule)) }
            }
            .disabled((mode == .create && title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                || (!dateOnly && includesEnd && end <= start))
            Button("Back", role: .cancel) { mode = .actions }
        } header: {
            Text(mode == .create ? "New item" : "Choose date and time")
        }
    }

    private var mergeSection: some View {
        Section {
            Text("Choose the item to keep. Its date and time will be replaced by this candidate's, and the candidate's evidence will be added.")
                .font(.subheadline)
            if openTargets.isEmpty { Text("No other open items.").foregroundStyle(.secondary) }
            ForEach(openTargets) { item in
                Button { resolve(.merge(existingID: item.id)) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.actor).font(.subheadline)
                        if let date = item.dueStart {
                            Text(date, format: .dateTime).font(.caption)
                        } else { Text("No date selected").font(.caption) }
                    }
                }
            }
            Button("Back", role: .cancel) { mode = .actions }
        } header: { Text("Mark as same as existing item") }
    }

    private func resolve(_ action: ReviewAction) {
        do {
            try store.resolveReview(id: reviewID, action: action)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
