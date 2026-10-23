import Foundation
import RecalledCore
import SwiftData
import SwiftUI

struct ContentView: View {
    let store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \StoredCommitment.dueStart) private var commitments: [StoredCommitment]
    @Query private var evidence: [StoredEvidence]
    @Query private var reviews: [StoredReviewItem]
    @State private var conflicts: [ConflictDetector.Conflict] = []
    @State private var calendarError: String?
    @State private var operationError: String?
    @State private var today = Calendar.current.startOfDay(for: .now)

    private struct RefreshKey: Equatable {
        let commitments: [Commitment]
        let revision: Int
        let today: Date
    }

    private var refreshKey: RefreshKey {
        RefreshKey(commitments: commitments.map { $0.toCore() },
                   revision: store.calendarRevision, today: today)
    }

    var body: some View {
        NavigationStack {
            List {
                if commitments.isEmpty {
                    ContentUnavailableView("Your day, recalled", systemImage: "calendar",
                        description: Text("Choose Reset demo from the menu to load sample commitments."))
                }
                agendaSection("Today", day: today)
                if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) {
                    agendaSection("Tomorrow", day: tomorrow)
                }
                if !reviews.isEmpty {
                    Section("Review") {
                        ForEach(reviews) { review in
                            if let commitment = commitments.first(where: { $0.id == review.commitmentId }) {
                                NavigationLink {
                                    CommitmentDetailView(commitment: commitment,
                                        conflicts: conflicts.filter { $0.commitment.id == commitment.id })
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Label(commitment.title, systemImage: "questionmark.circle")
                                        Text(review.reason).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                Label(review.reason, systemImage: "questionmark.circle")
                            }
                        }
                    }
                }
                if let calendarError {
                    Section {
                        Label(calendarError, systemImage: "exclamationmark.triangle")
                        Button("Retry conflict check") { Task { await refreshConflicts() } }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("Reset demo", systemImage: "arrow.counterclockwise") { resetDemo() }
                        NavigationLink("What left my phone") { PersistedLedgerView() }
                        NavigationLink("Settings") { SettingsView(store: store) }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .task(id: refreshKey) { await refreshConflicts() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = Calendar.current.startOfDay(for: .now)
                    Task { await refreshConflicts() }
                }
            }
            .task {
                // Keep day boundaries correct when the app stays foregrounded.
                while !Task.isCancelled {
                    do { try await Task.sleep(for: .seconds(30)) } catch { break }
                    today = Calendar.current.startOfDay(for: .now)
                }
            }
            .alert("Couldn't reset demo", isPresented: Binding(
                get: { operationError != nil }, set: { if !$0 { operationError = nil } }
            )) {
                Button("OK", role: .cancel) { operationError = nil }
            } message: { Text(operationError ?? "") }
        }
    }

    private func items(on day: Date) -> [StoredCommitment] {
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: day) else { return [] }
        return commitments.filter { item in
            guard ![Commitment.Status.completed, .cancelled, .superseded].contains(item.status),
                  let start = item.dueStart else { return false }
            if let finish = item.dueEnd, finish > start { return start < end && finish > day }
            return start >= day && start < end
        }
    }

    private func agendaSection(_ title: String, day: Date) -> some View {
        Section(title) {
            let items = items(on: day)
            if items.isEmpty { Text("No commitments").foregroundStyle(.secondary) }
            ForEach(items) { item in
                let itemConflicts = conflicts.filter { $0.commitment.id == item.id }
                NavigationLink {
                    CommitmentDetailView(commitment: item, conflicts: itemConflicts)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title).font(.headline)
                        if let date = item.dueStart {
                            if item.kind == .deadline && item.dueEnd == nil {
                                Text("Due this day").font(.subheadline)
                            } else {
                                Text(date, style: .time).font(.subheadline)
                            }
                        }
                        if let source = evidence.first(where: { $0.commitmentId == item.id }) {
                            Label(source.sender, systemImage: source.sourceIcon)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 12) {
                            if item.status == .tentative {
                                Label("Tentative", systemImage: "questionmark.circle").foregroundStyle(.orange)
                            }
                            if !itemConflicts.isEmpty {
                                Label("Conflict", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            }
                        }
                        .font(.caption.bold())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @MainActor
    private func refreshConflicts() async {
        let key = refreshKey
        guard let end = Calendar.current.date(byAdding: .day, value: 2, to: today) else { return }
        do {
            let events = try await store.calendarStore.events(in: DateInterval(start: today, end: end))
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = ConflictDetector.conflicts(commitments: key.commitments, calendarEvents: events)
            calendarError = nil
        } catch {
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = []
            calendarError = "Calendar conflicts could not be checked."
        }
    }

    private func resetDemo() {
        do {
            try store.resetDemo()
            today = Calendar.current.startOfDay(for: .now)
        } catch { operationError = error.localizedDescription }
    }
}

extension StoredEvidence {
    var sourceIcon: String {
        switch source {
        case .gmail: "envelope"
        case .share: "square.and.arrow.up"
        case .seed:
            if sender.hasPrefix("Email") { "envelope" }
            else if sender.hasPrefix("WhatsApp") { "message" }
            else { "number" }
        }
    }
}
