import Foundation
import RecalledCore
import SwiftUI

struct LedgerView: View {
    let entries: [LedgerEntry]

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Nothing has left your phone", systemImage: "lock.shield",
                    description: Text("Requests sent for planning will appear here.")
                )
            } else {
                List {
                    // Entries have no ID; indices also preserve duplicate audit rows.
                    ForEach(entries.indices, id: \.self) { index in
                        let entry = entries[index]
                        VStack(alignment: .leading, spacing: 12) {
                            Text(entry.timestamp, format: .dateTime
                                .year().month().day().hour().minute().second().timeZone())
                                .font(.headline)
                            LabeledContent("Model") {
                                Text(verbatim: entry.destinationModelId)
                            }
                            LabeledContent("Regions") {
                                Text(verbatim: entry.regions.isEmpty ? "Not recorded" : entry.regions.joined(separator: ", "))
                            }
                            LabeledContent("Bytes", value: String(entry.byteCount))
                            Text("Exact redacted payload")
                                .font(.subheadline.bold())
                            // Despite the model's historical "Preview" name, this
                            // must contain the complete transmitted payload.
                            Text(verbatim: entry.redactedPayloadPreview)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .textSelection(.enabled)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("What left my phone")
    }
}

#Preview("Recorded request (sample)") {
    let payload = """
    {"items":[{"ref":"t1","title":"Send résumé to [P1] at [O1]"}],"instructions":"Plan my week"}
    """
    NavigationStack {
        LedgerView(entries: [LedgerEntry(
            timestamp: Date(timeIntervalSince1970: 1_792_800_000),
            destinationModelId: "sample-model", regions: ["AU"],
            byteCount: payload.utf8.count, redactedPayloadPreview: payload
        )])
    }
}

#Preview("No requests") {
    NavigationStack { LedgerView(entries: []) }
}
