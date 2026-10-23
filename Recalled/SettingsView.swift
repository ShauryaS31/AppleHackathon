import SwiftUI

struct SettingsView: View {
    let store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingForget = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Button("Forget all", role: .destructive) { confirmingForget = true }
            } header: {
                Text("Stored data")
            } footer: {
                Text("Delete all commitments, evidence, review items, ledger entries and action receipts from Recalled.")
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Forget all stored data?", isPresented: $confirmingForget, titleVisibility: .visible) {
            Button("Forget all", role: .destructive) {
                do {
                    try store.forgetAll()
                    dismiss()
                } catch { errorMessage = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Couldn't delete stored data", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}
