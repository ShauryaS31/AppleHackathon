import Foundation
import RecalledCore
import SwiftUI

struct CalendarApprovalView: View {
    let store: AppStore
    @State var preview: CalendarPreview
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var notice: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Event to save") {
                    LabeledContent("Title", value: preview.draft.title)
                    if preview.draft.isAllDay {
                        LabeledContent("Date", value: formatted(preview.draft.start, allDay: true))
                        Text("All-day event").font(.callout)
                    } else {
                        LabeledContent("Start", value: formatted(preview.draft.start))
                        LabeledContent("End", value: formatted(preview.draft.end))
                    }
                    LabeledContent("Time zone", value: preview.draft.timezone)
                    if let location = preview.draft.location, !location.isEmpty {
                        LabeledContent("Location", value: location)
                    }
                    Text(preview.commitment.calendarEventId == nil
                        ? "Create an event in your default calendar."
                        : "Update the linked event in its current calendar.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                Section("Overlapping calendar events") {
                    if preview.overlaps.isEmpty { Text("No overlaps found.") }
                    ForEach(preview.overlaps.indices, id: \.self) { index in
                        let event = preview.overlaps[index]
                        VStack(alignment: .leading, spacing: 4) {
                            Label(event.title, systemImage: "exclamationmark.triangle")
                            Text("\(formatted(event.start, allDay: event.isAllDay)) – \(formatted(event.end, allDay: event.isAllDay))")
                                .font(.caption)
                        }
                    }
                }
                if let notice { Text(notice).foregroundStyle(.orange) }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                Section {
                    if store.pendingCalendarReceipt != nil {
                        Button("Retry saving receipt") { retryReceipt() }
                            .disabled(isSaving)
                    } else {
                        Button(approvalLabel) { Task { await approve() } }
                            .disabled(isSaving || store.isWritingCalendar)
                    }
                    if isSaving { ProgressView("Saving…") }
                }
            }
            .navigationTitle("Review calendar event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
        }
        .frame(minWidth: 320, minHeight: 440)
        .interactiveDismissDisabled(isSaving)
    }

    private var approvalLabel: String {
        if !preview.overlaps.isEmpty { return "Approve despite overlaps" }
        return preview.commitment.calendarEventId == nil ? "Approve and add to Calendar" : "Approve calendar update"
    }

    private func formatted(_ date: Date, allDay: Bool = false) -> String {
        let zone = TimeZone(identifier: preview.draft.timezone) ?? .current
        return date.formatted(Date.FormatStyle(date: .abbreviated,
            time: allDay ? .omitted : .shortened, timeZone: zone))
    }

    @MainActor private func approve() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            if let refreshed = try await store.approveCalendar(preview) {
                preview = refreshed
                notice = "Calendar overlaps changed. Review them and approve again to save."
            } else { dismiss() }
        } catch { errorMessage = error.localizedDescription }
    }

    private func retryReceipt() {
        do {
            try store.savePendingCalendarReceipt()
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
