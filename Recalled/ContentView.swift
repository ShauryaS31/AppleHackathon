import FoundationModels
import RecalledCore
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability = SystemLanguageModel.default.availability

    private var availabilityDescription: String {
        switch availability {
        case .available:
            "On-device language model is available."
        case .unavailable:
            "On-device language model is unavailable."
        @unknown default:
            "On-device language model availability is unknown."
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(RecalledPlaceholder.appName)
                    .font(.largeTitle)
                Text(availabilityDescription)
                    .multilineTextAlignment(.center)
                Text("Your commitments will appear here.")
                    .foregroundStyle(.secondary)
                NavigationLink("What left my phone") {
                    LedgerView(entries: [])
                }
            }
            .padding(32)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                availability = SystemLanguageModel.default.availability
            }
        }
    }
}
