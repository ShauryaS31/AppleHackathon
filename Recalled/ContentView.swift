import Foundation
import RecalledCore
import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ContentView: View {
    let store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @Query private var reviews: [StoredReviewItem]

    var body: some View {
        TabView {
            TodayView(store: store)
                .tabItem { Label("Today", systemImage: "calendar") }
            ReviewQueueView(store: store)
                .tabItem { Label("Review", systemImage: "questionmark.circle") }
                .badge(reviews.count)
        }
        .task { await store.processInbox() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.processInbox() } }
        }
        .alert("Shared message import", isPresented: Binding(
            get: { store.inboxError != nil }, set: { if !$0 { store.inboxError = nil } }
        )) {
            Button("Retry") { Task { await store.processInbox() } }
            Button("OK", role: .cancel) { store.inboxError = nil }
        } message: { Text(store.inboxError ?? "") }
    }
}

private struct TodayView: View {
    let store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @Query(filter: #Predicate<StoredCommitment> {
        $0.statusRaw != "completed" && $0.statusRaw != "cancelled" && $0.statusRaw != "superseded"
    }, sort: \StoredCommitment.dueStart) private var commitments: [StoredCommitment]
    @Query private var evidence: [StoredEvidence]
    @State private var conflicts: [ConflictDetector.Conflict] = []
    @State private var calendarError: String?
    @State private var operationError: String?
    @State private var pasteNotice: String?
    @State private var showingLedger = false
    @State private var showingSettings = false
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
                Section {
                    Button("Paste message", systemImage: "doc.on.clipboard") {
                        #if os(iOS)
                        let text = UIPasteboard.general.string
                        #elseif os(macOS)
                        let text = NSPasteboard.general.string(forType: .string)
                        #else
                        let text: String? = nil
                        #endif
                        Task { pasteNotice = await store.pasteMessage(text) }
                    }
                    .disabled(store.isImporting)
                    if let pasteNotice {
                        Text(pasteNotice).font(.callout).foregroundStyle(.secondary)
                    }
                }
                if commitments.isEmpty {
                    ContentUnavailableView("Your day, recalled", systemImage: "calendar",
                        description: Text("Choose Reset demo from the menu to load sample commitments."))
                }
                agendaSection("Today", day: today)
                if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) {
                    agendaSection("Tomorrow", day: tomorrow)
                }
                let undated = undatedItems
                if !undated.isEmpty {
                    Section("No date") {
                        ForEach(undated) { item in
                            agendaRow(item)
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
                        Button("What left my phone") { showingLedger = true }
                        Button("Settings") { showingSettings = true }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(isPresented: $showingLedger) { PersistedLedgerView() }
            .navigationDestination(isPresented: $showingSettings) { SettingsView(store: store) }
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
            guard let start = item.dueStart else { return false }
            if let finish = item.dueEnd, finish > start { return start < end && finish > day }
            return start >= day && start < end
        }
    }

    private func agendaSection(_ title: String, day: Date) -> some View {
        Section(title) {
            let items = items(on: day)
            if items.isEmpty { Text("No commitments").foregroundStyle(.secondary) }
            ForEach(items) { item in
                agendaRow(item)
            }
        }
    }

    private var undatedItems: [StoredCommitment] {
        AgendaFilter.noDate(commitments.map { $0.toCore() }).compactMap { item in
            commitments.first { $0.id == item.id }
        }
    }

    private func agendaRow(_ item: StoredCommitment) -> some View {
        let itemConflicts = conflicts.filter { $0.commitment.id == item.id }
        return NavigationLink {
            CommitmentDetailView(store: store, commitment: item)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).font(.headline)
                Text(item.actor).font(.subheadline).foregroundStyle(.secondary)
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
                ForEach(itemConflicts.indices, id: \.self) { index in
                    Text("Overlaps: \(itemConflicts[index].event.title)")
                        .font(.caption).foregroundStyle(.red)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @MainActor
    private func refreshConflicts() async {
        let key = refreshKey
        guard let end = Calendar.current.date(byAdding: .day, value: 14, to: today) else { return }
        do {
            let events = try await store.calendarStore.events(in: DateInterval(start: today, end: end))
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = ConflictDetector.conflicts(commitments: key.commitments, calendarEvents: events)
            calendarError = nil
        } catch {
            guard !Task.isCancelled, key == refreshKey else { return }
            conflicts = []
            calendarError = error.localizedDescription
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
