import SwiftUI
import SwiftData

@main
struct RecalledApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: AppStore?
    @State private var startupError: String?

    init() {
        do {
            _store = State(initialValue: try AppStore())
        } catch {
            _startupError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let store {
                ContentView(store: store)
                    .modelContainer(store.container)
            } else {
                ContentUnavailableView {
                    Label("Couldn't open stored data", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(startupError ?? "Please try again.")
                } actions: {
                    Button("Try again") { retryOpeningStore() }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { retryOpeningStore() }
        }
    }

    private func retryOpeningStore() {
        guard store == nil else { return }
        do {
            store = try AppStore()
            startupError = nil
        } catch { startupError = error.localizedDescription }
    }
}
