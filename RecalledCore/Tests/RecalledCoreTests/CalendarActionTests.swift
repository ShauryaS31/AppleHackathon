import Foundation
import RecalledCore
import Testing

private func confirmedEvent() -> Commitment {
    Commitment(title: "Dinner", kind: .event, status: .confirmed, actor: "Alex",
        dueText: "already resolved", dueStart: Date(timeIntervalSince1970: 1_000),
        dueEnd: Date(timeIntervalSince1970: 4_600), timezone: "Australia/Sydney")
}

@Test func calendarDraftPreservesResolvedTimesWithoutParsingText() throws {
    var item = confirmedEvent()
    item.dueText = "ignore these words; the resolved dates are authoritative"
    let draft = try CalendarAction.draft(for: item)
    #expect(draft.title == item.title)
    #expect(draft.start == item.dueStart)
    #expect(draft.end == item.dueEnd)
    #expect(draft.timezone == item.timezone)
    #expect(!draft.isAllDay)
    #expect(draft.location == nil)
    #expect(draft.notes == nil)
}

@Test func calendarDraftRejectsEveryUnconfirmedStatus() {
    for status in Commitment.Status.allCases where status != .confirmed {
        var item = confirmedEvent()
        item.status = status
        #expect(throws: CalendarActionError.notConfirmed) { try CalendarAction.draft(for: item) }
    }
}

@Test func calendarDraftRejectsUnresolvedOrInvalidDatesAndZones() {
    var item = confirmedEvent()
    item.dueStart = nil
    #expect(throws: CalendarActionError.unresolvedDate) { try CalendarAction.draft(for: item) }
    item = confirmedEvent()
    item.dueEnd = nil
    #expect(throws: CalendarActionError.unresolvedDate) { try CalendarAction.draft(for: item) }
    item.dueEnd = item.dueStart
    #expect(throws: CalendarActionError.unresolvedDate) { try CalendarAction.draft(for: item) }
    item.dueEnd = Date(timeIntervalSince1970: 0)
    #expect(throws: CalendarActionError.unresolvedDate) { try CalendarAction.draft(for: item) }
    item = confirmedEvent()
    let invalidZones: [String?] = [nil, "Not/AZone"]
    for zone in invalidZones {
        item.timezone = zone
        #expect(throws: CalendarActionError.invalidTimeZone) { try CalendarAction.draft(for: item) }
    }
}

@Test func dateOnlyDeadlineCreatesOneCalendarDayAcrossDST() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Australia/Sydney"))
    // Sydney's spring-forward day lasts 23 hours, not 86,400 seconds.
    let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 4)))
    let item = Commitment(title: "Submit report", kind: .deadline, status: .confirmed,
        actor: "Me", dueText: "4 October", dueStart: day, timezone: calendar.timeZone.identifier)
    let draft = try CalendarAction.draft(for: item, calendar: calendar)
    #expect(draft.isAllDay)
    #expect(draft.start == day)
    #expect(draft.end == calendar.date(from: DateComponents(year: 2026, month: 10, day: 5)))
    #expect(draft.end.timeIntervalSince(draft.start) == 23 * 3_600)
}

@Test(arguments: [
    ("Australia/Sydney", "America/Los_Angeles"),
    ("America/Los_Angeles", "Australia/Sydney")
])
func dateOnlyDeadlinePreservesSourceDateInDeviceCalendar(sourceZone: String, deviceZone: String) throws {
    var source = Calendar(identifier: .gregorian)
    source.timeZone = try #require(TimeZone(identifier: sourceZone))
    var device = Calendar(identifier: .gregorian)
    device.timeZone = try #require(TimeZone(identifier: deviceZone))
    let sourceDate = try #require(source.date(from: DateComponents(year: 2026, month: 10, day: 4)))
    let item = Commitment(title: "Submit report", kind: .deadline, status: .confirmed,
        actor: "Me", dueText: "4 October", dueStart: sourceDate, timezone: sourceZone)
    let draft = try CalendarAction.draft(for: item, calendar: device)
    #expect(draft.isAllDay)
    #expect(draft.timezone == deviceZone)
    #expect(draft.start == device.date(from: DateComponents(year: 2026, month: 10, day: 4)))
    #expect(draft.end == device.date(from: DateComponents(year: 2026, month: 10, day: 5)))
    let startComponents = device.dateComponents([.year, .month, .day, .hour, .minute], from: draft.start)
    #expect(startComponents.year == 2026)
    #expect(startComponents.month == 10)
    #expect(startComponents.day == 4)
    #expect(startComponents.hour == 0)
    #expect(startComponents.minute == 0)
    // The target date is reconstructed, not the original absolute midnight.
    #expect(draft.start != sourceDate)
}

@Test func dateOnlyDeadlineUsesUsersNonGregorianCalendar() throws {
    var source = Calendar(identifier: .gregorian)
    source.timeZone = try #require(TimeZone(identifier: "Australia/Sydney"))
    var device = Calendar(identifier: .buddhist)
    device.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
    let sourceDate = try #require(source.date(from: DateComponents(year: 2026, month: 10, day: 4)))
    let item = Commitment(title: "Submit report", kind: .deadline, status: .confirmed,
        actor: "Me", dueText: "4 October", dueStart: sourceDate, timezone: source.timeZone.identifier)
    let draft = try CalendarAction.draft(for: item, calendar: device)
    let components = device.dateComponents([.year, .month, .day], from: draft.start)
    #expect(components.year == 2569)
    #expect(components.month == 10)
    #expect(components.day == 4)
    #expect(draft.end == device.date(byAdding: .day, value: 1, to: draft.start))
}

@Test func explicitlyTimedDeadlineKeepsItsResolvedTime() throws {
    var item = confirmedEvent()
    item.kind = .deadline
    let draft = try CalendarAction.draft(for: item)
    #expect(!draft.isAllDay)
    #expect(draft.start == item.dueStart)
    #expect(draft.end == item.dueEnd)
}

@Test func calendarApprovalOverlapsExcludeOwnEventAndBoundaryTouches() throws {
    var item = confirmedEvent()
    item.calendarEventId = "own"
    let draft = try CalendarAction.draft(for: item)
    func event(_ id: String, start: Date, end: Date) -> CalendarEvent {
        CalendarEvent(id: id, title: id, start: start, end: end, timezone: draft.timezone)
    }
    let own = event("own", start: draft.start, end: draft.end)
    let boundary = event("boundary", start: draft.end, end: draft.end.addingTimeInterval(60))
    let overlap = event("other", start: draft.start, end: draft.end)
    #expect(CalendarAction.overlaps(draft: draft, commitment: item, events: [own, boundary, overlap]) == [overlap])
    // Freshly fetched events must change the approval when a new overlap appears.
    #expect(CalendarAction.overlaps(draft: draft, commitment: item, events: [own, boundary]).isEmpty)
}

@Test func calendarApprovalIgnoresAllDayDeadlineBlock() throws {
    var item = confirmedEvent()
    item.kind = .deadline
    item.dueEnd = nil
    let draft = try CalendarAction.draft(for: item)
    let event = CalendarEvent(id: "busy", title: "Appointment",
        start: draft.start.addingTimeInterval(3_600), end: draft.start.addingTimeInterval(7_200),
        timezone: draft.timezone)
    let allDayEvent = CalendarEvent(id: "holiday", title: "Holiday",
        start: draft.start, end: draft.end, timezone: draft.timezone, isAllDay: true)
    #expect(CalendarAction.overlaps(draft: draft, commitment: item, events: [event, allDayEvent]).isEmpty)
}

@Test func reschedulingUpdatesTheLinkedEventWithoutCreatingADuplicate() async throws {
    let store: any CalendarStore = InMemoryCalendarStore()
    var item = confirmedEvent()
    let original = try CalendarAction.draft(for: item)
    let id = try await store.create(original)
    item.calendarEventId = id
    item.dueStart = original.start.addingTimeInterval(86_400)
    item.dueEnd = original.end.addingTimeInterval(86_400)
    item.version += 1
    let moved = try CalendarAction.draft(for: item)
    try await store.update(id, with: moved)
    let oldEvents = try await store.events(in: DateInterval(start: original.start, end: original.end))
    let newEvents = try await store.events(in: DateInterval(start: moved.start, end: moved.end))
    #expect(oldEvents.isEmpty)
    #expect(newEvents.count == 1)
    #expect(newEvents.first?.id == id)
    #expect(CalendarAction.overlaps(draft: moved, commitment: item, events: newEvents).isEmpty)
}
