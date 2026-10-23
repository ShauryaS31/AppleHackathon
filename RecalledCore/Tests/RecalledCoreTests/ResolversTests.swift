import Foundation
import Testing
import RecalledCore

private let sydney = TimeZone(identifier: "Australia/Sydney")!

private func localDate(
    _ year: Int = 2026, _ month: Int = 10, _ day: Int, _ hour: Int = 0, _ minute: Int = 0
) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = sydney
    return calendar.date(from: DateComponents(
        year: year, month: month, day: day, hour: hour, minute: minute
    ))!
}

// Friday, 23 October 2026 at 10am Sydney. No tests consult the current clock.
private let sentAt = localDate(2026, 10, 23, 10)
private let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

private func resolve(_ text: String, sent: Date = sentAt) -> DateResolver.Resolution {
    DateResolver.resolve(dueText: text, sentAt: sent, timeZone: sydney)
}

private func extracted(
    _ title: String = "Dinner", dueText: String = "Sunday 7pm", ref: String = "",
    kind: Commitment.Kind = .event, tentative: Bool = false
) -> ExtractionDTO {
    ExtractionDTO(
        title: title, kind: kind, tentative: tentative, dueText: dueText,
        actor: "me", evidence: "Dinner moves to Sunday 7pm", updatesRef: ref
    )
}

private func existing(_ title: String = "Dinner", id: UUID = firstID) -> Commitment {
    Commitment(
        id: id, title: title, kind: .event, status: .confirmed, actor: "me", dueText: "Sat 7pm",
        dueStart: localDate(2026, 10, 24, 19), dueEnd: localDate(2026, 10, 24, 20),
        timezone: sydney.identifier, calendarEventId: "own-event"
    )
}

private func event(_ startHour: Int, _ endHour: Int, id: String = "other-event") -> CalendarEvent {
    CalendarEvent(
        id: id, title: "Existing calendar event", start: localDate(2026, 10, 24, startHour),
        end: localDate(2026, 10, 24, endHour), timezone: sydney.identifier
    )
}

@Test func tomorrowAndTodayResolveRelativeToMessageDay() {
    #expect(resolve("tomorrow") == .dateOnly(localDate(2026, 10, 24)))
    #expect(resolve("today") == .dateOnly(localDate(2026, 10, 23)))
    #expect(resolve("tomorrow 9am") == .exact(DateInterval(
        start: localDate(2026, 10, 24, 9), duration: 3_600
    )))
    #expect(resolve("tomorrow", sent: localDate(2026, 12, 31, 23, 55)) == .dateOnly(localDate(2027, 1, 1)))
}

@Test func weekdaysUseNextOccurrenceIncludingToday() {
    let examples = [("Friday", 23), ("Sat", 24), ("Sunday", 25), ("Monday", 26),
                    ("Tue", 27), ("Wednesday", 28), ("Thu", 29), ("next Friday", 30)]
    for (text, day) in examples {
        #expect(resolve(text) == .dateOnly(localDate(2026, 10, day)))
    }
}

@Test func saturdaySevenPMDefaultsToOneHour() {
    #expect(resolve("Sat 7pm") == .exact(DateInterval(
        start: localDate(2026, 10, 24, 19), end: localDate(2026, 10, 24, 20)
    )))
    #expect(resolve("  SAT   at 7 PM  ") == resolve("Sat 7pm"))
}

@Test func australianDayMonthOrderAndMissingYear() {
    #expect(resolve("25/10") == .dateOnly(localDate(2026, 10, 25)))
    #expect(resolve("10/11") == .dateOnly(localDate(2026, 11, 10)))
    #expect(resolve("1/1") == .dateOnly(localDate(2027, 1, 1)))
    #expect(resolve("1/1/2026") == .dateOnly(localDate(2026, 1, 1)))
    #expect(resolve("10/25") == .ambiguous)
}

@Test func ticketExactTimeUsesSydneyAndExplicitYearA2() {
    let expected = DateInterval(start: localDate(2026, 10, 25, 18, 30), duration: 3_600)
    #expect(resolve("25 Oct 2026 6:30pm") == .exact(expected))
    #expect(resolve("25 October 2026 at 18:30") == .exact(expected))
    // Independent UTC expectation prevents the fixture and resolver sharing a zone bug.
    let utc = ISO8601DateFormatter().date(from: "2026-10-25T07:30:00Z")!
    #expect(expected.start == utc)
}

@Test func namedDateWithoutTimeIsDeadlineA5() {
    #expect(resolve("25 Oct 2026") == .dateOnly(localDate(2026, 10, 25)))
    #expect(resolve("25 October") == .dateOnly(localDate(2026, 10, 25)))
    #expect(resolve("1 Jan") == .dateOnly(localDate(2027, 1, 1)))
}

@Test func explicitEndTimeIsPreserved() {
    let expected = DateResolver.Resolution.exact(DateInterval(
        start: localDate(2026, 10, 24, 19), end: localDate(2026, 10, 24, 21, 30)
    ))
    for text in ["Sat 7pm-9:30pm", "Sat 7pm to 9:30pm", "Sat 19:00–21:30"] {
        #expect(resolve(text) == expected)
    }
    #expect(resolve("Sat 7pm-7pm") == .ambiguous)
    #expect(resolve("Sat 11pm-1am") == .ambiguous)
}

@Test func noonMidnightAnd24HourTimes() {
    for (text, hour) in [("12am", 0), ("12pm", 12), ("00:00", 0), ("23:00", 23)] {
        #expect(resolve("Sat \(text)") == .exact(DateInterval(
            start: localDate(2026, 10, 24, hour), duration: 3_600
        )))
    }
}

@Test func invalidOrUnderspecifiedDatesNeedReview() {
    for text in ["", "sometime soon", "7pm", "Sat 7", "Sat 25:00", "Sat 0pm", "Sat 13pm",
                 "Sat 7:60pm", "31/11", "29/2/2026", "31 Apr 2026", "25 Octopus 2026",
                 "tomorrow or Sunday", "25/10 or 26/10", "Sat 7pm maybe", "25/10/26"] {
        #expect(resolve(text) == .ambiguous, "Unexpected resolution for \(text)")
    }
    #expect(resolve("29/2/2028") == .dateOnly(localDate(2028, 2, 29)))
}

@Test func tomorrowUsesLocalCalendarAcrossDaylightSavingChange() {
    let beforeDST = localDate(2026, 10, 3, 23, 30)
    #expect(resolve("tomorrow 9am", sent: beforeDST) == .exact(DateInterval(
        start: localDate(2026, 10, 4, 9), duration: 3_600
    )))
    #expect(resolve("4/10/2026 02:30") == .ambiguous)
    #expect(resolve("5/4/2026 02:30") == .ambiguous)
}

@Test func dateResolverHonoursSuppliedZoneAtLocalDayBoundary() {
    let nearMidnight = localDate(2026, 10, 24, 0, 30)
    #expect(resolve("tomorrow", sent: nearMidnight) == .dateOnly(localDate(2026, 10, 25)))
}

@Test func evidenceMustBeExactSubstringOfNormalisedMessageA11() {
    let message = "<p>Dinner   is\nSaturday at 7pm.</p>"
    #expect(EvidenceValidator.validate(excerpt: "Dinner is Saturday", message: message))
    #expect(!EvidenceValidator.validate(excerpt: "Dinner is Sunday", message: message))
    #expect(!EvidenceValidator.validate(excerpt: "dinner is Saturday", message: message))
    #expect(!EvidenceValidator.validate(excerpt: "Dinner   is Saturday", message: message))
    #expect(!EvidenceValidator.validate(excerpt: "Dinner is Saturday!", message: message))
}

@Test func evidenceRequiresEightCharactersAndDoesNotNormaliseExcerpt() {
    #expect(EvidenceValidator.validate(excerpt: "12345678", message: "abc 12345678 def"))
    #expect(!EvidenceValidator.validate(excerpt: "1234567", message: "1234567"))
    #expect(!EvidenceValidator.validate(excerpt: "", message: "Anything"))
    #expect(!EvidenceValidator.validate(excerpt: "<b>Dinner</b>", message: "<b>Dinner</b>"))
    #expect(!EvidenceValidator.validate(excerpt: "🙂🙂🙂🙂", message: "🙂🙂🙂🙂"))
}

@Test func validUpdatesReferenceWinsOverTitle() {
    let dinner = existing()
    let lunch = existing("Lunch", id: secondID)
    let ref = ItemRef(ref: "t3", commitmentId: dinner.id, title: dinner.title, kind: .event, status: .confirmed)
    #expect(Matcher.match(extracted("Lunch", ref: "t3"), existing: [dinner, lunch], refs: [ref]) == .match(dinner.id))
}

@Test func unknownAndStaleReferencesFallBackToTitleSimilarity() {
    let stale = ItemRef(ref: "t3", commitmentId: secondID, title: "Dinner", kind: .event, status: .confirmed)
    #expect(Matcher.match(extracted(ref: "unknown"), existing: [existing()], refs: [stale]) == .match(firstID))
    #expect(Matcher.match(extracted(ref: "t3"), existing: [existing()], refs: [stale]) == .match(firstID))
}

@Test func duplicatedReferenceTargetsNeedReview() {
    let refs = [firstID, secondID].map {
        ItemRef(ref: "t3", commitmentId: $0, title: "Dinner", kind: .event, status: .confirmed)
    }
    #expect(Matcher.match(extracted(ref: "t3"), existing: [existing(), existing(id: secondID)], refs: refs)
        == .review([firstID, secondID]))
}

@Test func matcherLowercasesStripsPunctuationAndUsesSets() {
    #expect(Matcher.match(extracted("DINNER, with Alex! Alex"), existing: [existing("Dinner with Alex")]) == .match(firstID))
    #expect(Matcher.match(extracted("Alex's dinner"), existing: [existing("Alexs dinner")]) == .match(firstID))
    #expect(Matcher.match(extracted("!!!"), existing: [existing("???")]) == .new)
}

@Test func jaccardThresholdsIncludePointSixAndPointFour() {
    let fiveTokens = existing("one two three four five")
    #expect(Matcher.match(extracted("one two three"), existing: [fiveTokens]) == .match(firstID))
    #expect(Matcher.match(extracted("one two"), existing: [fiveTokens]) == .review([firstID]))
    #expect(Matcher.match(extracted("one"), existing: [fiveTokens]) == .new)
    #expect(Matcher.match(extracted("one two"), existing: [existing("one two three four")]) == .review([firstID]))
    #expect(Matcher.match(extracted(), existing: []) == .new)
}

@Test func twoStrongMatchesRequireReviewRegardlessOfOrdering() {
    let a = existing("Dinner with Alex")
    let b = existing("Dinner with Alex tomorrow", id: secondID)
    #expect(Matcher.match(extracted("Dinner with Alex"), existing: [a, b]) == .review([firstID, secondID]))
    #expect(Matcher.match(extracted("Dinner with Alex"), existing: [b, a]) == .review([firstID, secondID]))
}

@Test func oneStrongMatchWinsOverWeakerSimilarity() {
    #expect(Matcher.match(extracted("one two three"), existing: [
        existing("one two three"), existing("one two three four five six", id: secondID)
    ]) == .match(firstID))
}

@Test func conflictContainsBothItemsA6() throws {
    let dinner = existing()
    let overlap = event(18, 20)
    let conflicts = ConflictDetector.conflicts(commitments: [dinner], calendarEvents: [overlap])
    #expect(conflicts.count == 1)
    let conflict = try #require(conflicts.first)
    #expect(conflict.commitment == dinner)
    #expect(conflict.event == overlap)
}

@Test func conflictsIncludeContainmentAndIdenticalIntervalsButNotTouchingEndpoints() {
    let events = [event(19, 20, id: "identical"), event(18, 21, id: "contains"),
                  event(18, 19, id: "ends-at-start"), event(20, 21, id: "starts-at-end")]
    #expect(ConflictDetector.conflicts(commitments: [existing()], calendarEvents: events).map(\.event.id)
        == ["identical", "contains"])
    var longer = existing()
    longer.dueStart = localDate(2026, 10, 24, 18)
    longer.dueEnd = localDate(2026, 10, 24, 21)
    #expect(ConflictDetector.conflicts(commitments: [longer], calendarEvents: [event(19, 20)]).count == 1)
}

@Test func deadlinesNeverConflictEvenWithTimedFieldsA5() {
    var deadline = existing()
    deadline.kind = .deadline
    #expect(ConflictDetector.conflicts(commitments: [deadline], calendarEvents: [event(18, 21)]).isEmpty)
    deadline.dueEnd = nil
    #expect(ConflictDetector.conflicts(commitments: [deadline], calendarEvents: [event(18, 21)]).isEmpty)
}

@Test func inactiveUnresolvedAndInvalidCommitmentsDoNotConflict() {
    for status in [Commitment.Status.cancelled, .completed, .superseded] {
        var item = existing()
        item.status = status
        #expect(ConflictDetector.conflicts(commitments: [item], calendarEvents: [event(18, 21)]).isEmpty)
    }
    var item = existing()
    item.dueEnd = nil
    #expect(ConflictDetector.conflicts(commitments: [item], calendarEvents: [event(18, 21)]).isEmpty)
    item.dueEnd = item.dueStart
    #expect(ConflictDetector.conflicts(commitments: [item], calendarEvents: [event(18, 21)]).isEmpty)
    item.dueStart = nil
    #expect(ConflictDetector.conflicts(commitments: [item], calendarEvents: [event(18, 21)]).isEmpty)
}

@Test func ownCalendarEventAndInvalidCalendarIntervalsAreExcluded() {
    let events = [event(19, 20, id: "own-event"), event(19, 19), event(20, 18)]
    #expect(ConflictDetector.conflicts(commitments: [existing()], calendarEvents: events).isEmpty)
    #expect(ConflictDetector.conflicts(commitments: [], calendarEvents: [event(18, 21)]).isEmpty)
}

@Test func allDayCalendarEventCanConflictWithTimedCommitment() {
    let allDay = CalendarEvent(
        id: "all-day", title: "Away", start: localDate(2026, 10, 24), end: localDate(2026, 10, 25),
        timezone: sydney.identifier, isAllDay: true
    )
    var item = existing()
    item.kind = .commitment
    #expect(ConflictDetector.conflicts(commitments: [item], calendarEvents: [allDay]).count == 1)
}

@Test func rescheduleKeepsIdentityAndBumpsVersionA3() {
    let dinner = existing()
    let result = CommitmentUpdater.reschedule(dinner, using: extracted(), sentAt: sentAt, timeZone: sydney)
    guard case .applied(let updated) = result else {
        Issue.record("Expected a resolved reschedule")
        return
    }
    #expect(updated.id == dinner.id)
    #expect(updated.version == 2)
    #expect(updated.calendarEventId == dinner.calendarEventId)
    #expect(updated.dueStart == localDate(2026, 10, 25, 19))
    #expect(updated.dueEnd == localDate(2026, 10, 25, 20))
    #expect(updated.dueText == "Sunday 7pm")
    #expect(updated.timezone == sydney.identifier)
    #expect(updated.status == .confirmed)
    #expect(dinner.version == 1)
}

@Test func dateOnlyRescheduleClearsOldEndAndPreservesTentativeLanguage() {
    let result = CommitmentUpdater.reschedule(
        existing(), using: extracted("Report", dueText: "25/10", kind: .deadline, tentative: true),
        sentAt: sentAt, timeZone: sydney
    )
    guard case .applied(let updated) = result else {
        Issue.record("Expected a date-only reschedule")
        return
    }
    #expect(updated.title == "Report")
    #expect(updated.actor == "me")
    #expect(updated.kind == .deadline)
    #expect(updated.dueStart == localDate(2026, 10, 25))
    #expect(updated.dueEnd == nil)
    #expect(updated.status == .tentative)
    #expect(updated.version == 2)
}

@Test func ambiguousRescheduleAndVersionOverflowRequireReview() {
    let dinner = existing()
    #expect(CommitmentUpdater.reschedule(
        dinner, using: extracted(dueText: "sometime"), sentAt: sentAt, timeZone: sydney
    ) == .review)
    #expect(dinner.dueStart == localDate(2026, 10, 24, 19))
    var overflow = dinner
    overflow.version = Int.max
    #expect(CommitmentUpdater.reschedule(
        overflow, using: extracted(), sentAt: sentAt, timeZone: sydney
    ) == .review)
}

@Test func cancellationSetsStatusAndPreservesIdentityA4() {
    let dinner = existing()
    let cancelled = CommitmentUpdater.cancel(dinner)
    var expected = dinner
    expected.status = .cancelled
    #expect(cancelled == expected)
    #expect(CommitmentUpdater.cancel(cancelled) == cancelled)
    #expect(ConflictDetector.conflicts(commitments: [cancelled], calendarEvents: [event(18, 21)]).isEmpty)
}
