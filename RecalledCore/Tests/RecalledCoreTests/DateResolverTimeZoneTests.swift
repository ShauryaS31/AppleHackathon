import Foundation
import Testing
import RecalledCore

private let zoneSydney = TimeZone(identifier: "Australia/Sydney")!
private let zonePerth = TimeZone(identifier: "Australia/Perth")!
private let zoneSentAt = zoneInstant("2026-10-10T00:00:00Z")

private func zoneInstant(_ text: String) -> Date {
    ISO8601DateFormatter().date(from: text)!
}

private func zoneResolution(
    _ text: String, sentAt: Date = zoneSentAt, userZone: TimeZone = zoneSydney
) -> DateResolver.Resolution {
    DateResolver.resolve(dueText: text, sentAt: sentAt, timeZone: userZone)
}

@Test func zoneSuffixExamplesAndOptionalSeparators() {
    for (text, start, duration) in [
        ("10:00 AM Australia/Sydney", "2026-10-09T23:00:00Z", 3_600),
        ("14 October 2026 at 10:00 AM Australia/Sydney", "2026-10-13T23:00:00Z", 3_600),
        ("17:00 Sydney time", "2026-10-10T06:00:00Z", 3_600),
        ("Tuesday 20 October at 17:00 Sydney time", "2026-10-20T06:00:00Z", 3_600),
        ("6pm AEDT", "2026-10-10T07:00:00Z", 3_600),
        ("9am UTC", "2026-10-10T09:00:00Z", 3_600),
        ("3pm Perth time", "2026-10-10T07:00:00Z", 3_600),
        ("Friday 16 October, 16:30–17:00 Sydney time", "2026-10-16T05:30:00Z", 1_800),
        ("  ON 14 OCTOBER 2026, AT 10:00 AM, aUsTrAlIa/sYdNeY  ", "2026-10-13T23:00:00Z", 3_600),
        ("at 9am,utc", "2026-10-10T09:00:00Z", 3_600),
        ("today at 9am, at UTC", "2026-10-10T09:00:00Z", 3_600),
        ("14 October 2026 10am eUrOpE/lOnDoN", "2026-10-14T09:00:00Z", 3_600)
    ] {
        #expect(zoneResolution(text) == .exact(DateInterval(
            start: zoneInstant(start), duration: TimeInterval(duration)
        )), "Unexpected resolution for \(text)")
    }
}

@Test func zoneCityNamesKeepCanonicalIdentifiersAndUseSeasonalOffsets() {
    for (city, identifier, octoberUTC, julyUTC) in [
        ("Sydney", "Australia/Sydney", "01:00", "02:00"),
        ("Melbourne", "Australia/Melbourne", "01:00", "02:00"),
        ("Canberra", "Australia/Sydney", "01:00", "02:00"),
        ("Hobart", "Australia/Hobart", "01:00", "02:00"),
        ("Brisbane", "Australia/Brisbane", "02:00", "02:00"),
        ("Adelaide", "Australia/Adelaide", "01:30", "02:30"),
        ("Darwin", "Australia/Darwin", "02:30", "02:30"),
        ("Perth", "Australia/Perth", "04:00", "04:00"),
        ("Auckland", "Pacific/Auckland", "23:00", "00:00"),
        ("London", "Europe/London", "11:00", "11:00"),
        ("Singapore", "Asia/Singapore", "04:00", "04:00")
    ] {
        for (dateText, utc) in [
            ("14 October 2026", "2026-10-\(city == "Auckland" ? "13" : "14")T\(octoberUTC):00Z"),
            ("14 July 2026", "2026-07-14T\(julyUTC):00Z")
        ] {
            let detailed = DateResolver.resolveDetailed(
                dueText: "\(dateText) at 12:00 \(city.uppercased()) TIME",
                sentAt: zoneSentAt, timeZone: zoneSydney)
            #expect(detailed.sourceTimeZone?.identifier == identifier)
            #expect(detailed.resolution == .exact(DateInterval(start: zoneInstant(utc), duration: 3_600)))
        }
    }
}

@Test func zoneAbbreviationsHaveFixedOffsetsInBothSeasons() {
    for (name, minutes) in [("AEDT", 660), ("AEST", 600), ("ACDT", 630), ("ACST", 570),
                            ("AWST", 480), ("NZDT", 780), ("NZST", 720), ("UTC", 0), ("GMT", 0)] {
        for (dateText, noonUTC) in [("14 October 2026", "2026-10-14T12:00:00Z"),
                                    ("14 July 2026", "2026-07-14T12:00:00Z")] {
            let text = "\(dateText) 12pm \(name.lowercased())"
            let detailed = DateResolver.resolveDetailed(dueText: text, sentAt: zoneSentAt, timeZone: zoneSydney)
            let expected = zoneInstant(noonUTC).addingTimeInterval(TimeInterval(-minutes * 60))
            #expect(detailed.resolution == .exact(DateInterval(start: expected, duration: 3_600)))
            #expect(detailed.sourceTimeZone == TimeZone(secondsFromGMT: minutes * 60))
            #expect(detailed.sourceTimeZone?.identifier == TimeZone(secondsFromGMT: minutes * 60)?.identifier)
            #expect(DateResolver.resolve(dueText: text, sentAt: zoneSentAt, timeZone: zoneSydney)
                == detailed.resolution)
        }
    }
}

@Test func zoneInstantsDisplayCorrectlyInTheUserZoneIncludingRangeEndsAndDayRollover() {
    for (text, userZone, expectedStart, expectedEnd) in [
        ("9am UTC", zoneSydney, "2026-10-10 20:00", "2026-10-10 21:00"),
        ("3pm Perth time", zoneSydney, "2026-10-10 18:00", "2026-10-10 19:00"),
        ("6pm AEDT", zonePerth, "2026-10-10 15:00", "2026-10-10 16:00"),
        ("today 23:30 to 23:45 UTC", zoneSydney, "2026-10-11 10:30", "2026-10-11 10:45"),
        ("Friday 16 October, 16:30–17:00 Sydney time", zonePerth, "2026-10-16 13:30", "2026-10-16 14:00")
    ] {
        guard case .exact(let interval) = zoneResolution(text, userZone: userZone) else {
            Issue.record("Expected exact time for \(text)")
            continue
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = userZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        #expect(formatter.string(from: interval.start) == expectedStart)
        #expect(formatter.string(from: interval.end) == expectedEnd)
    }
}

@Test func zoneRelativeDaysAndMissingYearUseTheUsersCalendar() {
    // Friday in Sydney, still Thursday in UTC and Perth.
    let nearMidnight = zoneInstant("2026-10-22T13:30:00Z")
    for (text, utc) in [
        ("9am UTC", "2026-10-23T09:00:00Z"),
        ("Friday 9am UTC", "2026-10-23T09:00:00Z"),
        ("tomorrow 9am UTC", "2026-10-24T09:00:00Z"),
        ("tomorrow 3pm Perth time", "2026-10-24T07:00:00Z"),
        ("next Friday 9am UTC", "2026-10-30T09:00:00Z"),
        ("22 October 9am UTC", "2027-10-22T09:00:00Z")
    ] {
        #expect(zoneResolution(text, sentAt: nearMidnight)
            == .exact(DateInterval(start: zoneInstant(utc), duration: 3_600)))
    }
    // Thursday in Perth even though the source zone is already on Friday.
    #expect(zoneResolution("tomorrow 6pm AEDT", sentAt: nearMidnight, userZone: zonePerth)
        == .exact(DateInterval(start: zoneInstant("2026-10-23T07:00:00Z"), duration: 3_600)))
}

@Test func zoneDateOnlyStaysOnTheUserDayAndDetailedUnzonedResultsHaveNoSource() {
    for suffix in ["Sydney time", "Perth time", "Europe/London", "UTC", "AEDT"] {
        let detailed = DateResolver.resolveDetailed(
            dueText: "14 October 2026 \(suffix)", sentAt: zoneSentAt, timeZone: zoneSydney)
        #expect(detailed.resolution == .dateOnly(zoneInstant("2026-10-13T13:00:00Z")))
        #expect(detailed.sourceTimeZone != nil)
    }
    for text in ["tomorrow", "tomorrow 9am", "sometime soon", "7pm"] {
        let detailed = DateResolver.resolveDetailed(dueText: text, sentAt: zoneSentAt, timeZone: zoneSydney)
        #expect(detailed.sourceTimeZone == nil)
        #expect(detailed.resolution == zoneResolution(text))
    }
}

@Test func zoneUnknownSuffixesAndMalformedTimesRemainAmbiguous() {
    for text in ["6pm EST-ish", "3pm Mars time", "9am PST", "today 9am PST",
                 "tomorrow 6pm EST-ish", "14 October 2026 Mars time", "today 9am Australia/Unknown",
                 "today 9am UTC maybe", "today 9am UTC AEDT", "today 25:00 UTC",
                 "31 November 2026 9am UTC", "Monday 14 October 2026 9am UTC",
                 "today 11pm-1am UTC", "today 9am-9am UTC", "7 UTC", "UTC"] {
        #expect(zoneResolution(text) == .ambiguous, "Unexpected resolution for \(text)")
    }
}

@Test func zoneDSTValidationUsesTheSourceCalendar() {
    for text in ["4 October 2026 02:30 Australia/Sydney", "5 April 2026 02:30 Sydney time",
                 "29 March 2026 01:30 Europe/London", "25 October 2026 01:30 London time"] {
        let detailed = DateResolver.resolveDetailed(dueText: text, sentAt: zoneSentAt, timeZone: zonePerth)
        #expect(detailed.resolution == .ambiguous)
        #expect(detailed.sourceTimeZone != nil)
    }
    // Fixed offsets and Perth do not inherit Sydney's missing or repeated hour.
    for date in ["4 October 2026", "5 April 2026"] {
        for suffix in ["AEDT", "Perth time"] {
            #expect(zoneResolution("\(date) 02:30 \(suffix)") != .ambiguous)
        }
    }
}
