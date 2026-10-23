import Foundation
import RecalledCore
import Testing

@Test func calendarUpdatePreservesIDAndReplacesEveryDraftField() async throws {
    let store: any CalendarStore = InMemoryCalendarStore()
    let start = Date(timeIntervalSince1970: 1_000)
    let original = EventDraft(title: "Dinner", start: start, end: start.addingTimeInterval(60), timezone: "UTC")
    let id = try await store.create(original)
    let replacement = EventDraft(title: "Moved dinner", start: start.addingTimeInterval(100),
        end: start.addingTimeInterval(200), timezone: "Australia/Sydney",
        isAllDay: true, notes: "Approved move", location: "Town Hall")
    try await store.update(id, with: replacement)
    let events = try await store.events(in: DateInterval(start: start, duration: 300))
    #expect(events == [CalendarEvent(id: id, title: replacement.title,
        start: replacement.start, end: replacement.end, timezone: replacement.timezone,
        isAllDay: true, notes: replacement.notes, location: replacement.location)])
    try await store.update(id, with: original)
    let restored = try await store.events(in: DateInterval(start: start, duration: 300))
    #expect(restored.count == 1)
    #expect(restored.first?.location == nil)
    #expect(restored.first?.notes == nil)
    #expect(restored.first?.isAllDay == false)
}

@Test func calendarUpdateUnknownIDThrowsWithoutCreatingAnEvent() async throws {
    let store: any CalendarStore = InMemoryCalendarStore()
    let start = Date(timeIntervalSince1970: 1_000)
    let draft = EventDraft(title: "Dinner", start: start, end: start.addingTimeInterval(60), timezone: "UTC")
    await #expect(throws: CalendarActionError.eventNotFound) {
        try await store.update("missing", with: draft)
    }
    let events = try await store.events(in: DateInterval(start: start, duration: 60))
    #expect(events.isEmpty)
}

@Test func calendarLocationsDecodeMissingAndNullKeysAndRoundTrip() throws {
    for locationField in ["", ",\"location\":null", ",\"location\":\"Town Hall\""] {
        let json = """
        {"id":"event-1","title":"Dinner","start":0,"end":3600,
        "timezone":"UTC","isAllDay":false\(locationField)}
        """
        let data = Data(json.utf8)
        let event = try JSONDecoder().decode(CalendarEvent.self, from: data)
        let draft = try JSONDecoder().decode(EventDraft.self, from: data)
        let expected: String? = locationField.contains("Town Hall") ? "Town Hall" : nil
        #expect(event.location == expected)
        #expect(draft.location == expected)
        #expect(try JSONDecoder().decode(CalendarEvent.self, from: JSONEncoder().encode(event)) == event)
        #expect(try JSONDecoder().decode(EventDraft.self, from: JSONEncoder().encode(draft)) == draft)
    }
    let start = Date(timeIntervalSince1970: 1_000)
    #expect(EventDraft(title: "Dinner", start: start, end: start, timezone: "UTC").location == nil)
    #expect(CalendarEvent(id: "1", title: "Dinner", start: start, end: start, timezone: "UTC").location == nil)
}
