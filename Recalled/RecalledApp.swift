import SwiftUI
import SwiftData

@main
struct RecalledApp: App {
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
                    Button("Try again") {
                        do {
                            store = try AppStore()
                            startupError = nil
                        } catch { startupError = error.localizedDescription }
                    }
                }
            }
        }
    }
}
