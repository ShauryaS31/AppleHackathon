import Foundation

public enum DateResolver {
    private static let weekdayPattern = #"(?:sun(?:day)?|mon(?:day)?|tue(?:sday)?|wed(?:nesday)?|thu(?:rsday)?|fri(?:day)?|sat(?:urday)?)"#
    private static let namedDatePattern = #"\d{1,2} [a-z]+(?: \d{4})?"#

    public enum Resolution: Sendable, Equatable {
        case exact(DateInterval)
        /// Midnight at the start of the deadline day in the supplied time zone.
        case dateOnly(Date)
        case ambiguous
    }

    /// Bare weekdays include today; `next` weekdays are strictly after today.
    /// A missing year means the next occurrence of that day on or after sentAt's
    /// local day. Unsupported prose, incomplete times and invalid dates need review.
    public static func resolve(dueText: String, sentAt: Date, timeZone: TimeZone) -> Resolution {
        resolveDetailed(dueText: dueText, sentAt: sentAt, timeZone: timeZone).resolution
    }

    /// Day words use the user's calendar; a trailing source zone applies only to
    /// the clock. Zoned times without a day use sentAt's local day. Date-only
    /// results remain midnight in the user's zone. Recognised zones are returned
    /// even when the remaining date or time is ambiguous.
    public static func resolveDetailed(
        dueText: String, sentAt: Date, timeZone: TimeZone
    ) -> (resolution: Resolution, sourceTimeZone: TimeZone?) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_AU_POSIX")
        var text = Normaliser.collapseWhitespace(dueText).lowercased()
            .replacingOccurrences(of: #"^(?:(?:by|on|this|due|before) )+"#,
                                  with: "", options: .regularExpression)
        var sourceTimeZone: TimeZone?
        if let suffix = captures(
            #"^(.+?)(?:, ?| )(?:at )?((?:[a-z0-9_+-]+/)+[a-z0-9_+-]+|[a-z]+ time|[a-z]+)$"#,
            in: text
        ), let zone = sourceZone(suffix[1]) {
            text = suffix[0]
            sourceTimeZone = zone
        }
        return (resolveText(text, sentAt: sentAt, calendar: calendar, sourceTimeZone: sourceTimeZone),
                sourceTimeZone)
    }

    private static func sourceZone(_ text: String) -> TimeZone? {
        let offsets = ["aedt": 660, "aest": 600, "acdt": 630, "acst": 570,
                       "awst": 480, "nzdt": 780, "nzst": 720, "utc": 0, "gmt": 0]
        if let minutes = offsets[text] { return TimeZone(secondsFromGMT: minutes * 60) }
        let cities = [
            "sydney time": "Australia/Sydney", "melbourne time": "Australia/Melbourne",
            "canberra time": "Australia/Sydney", "hobart time": "Australia/Hobart",
            "brisbane time": "Australia/Brisbane", "adelaide time": "Australia/Adelaide",
            "darwin time": "Australia/Darwin", "perth time": "Australia/Perth",
            "auckland time": "Pacific/Auckland", "london time": "Europe/London",
            "singapore time": "Asia/Singapore"
        ]
        if let identifier = cities[text] { return TimeZone(identifier: identifier) }
        // Foundation's identifier lookup is case sensitive. Restrict other names
        // to IANA paths so ambiguous abbreviations such as PST stay unsupported.
        guard text.contains("/"), let identifier = TimeZone.knownTimeZoneIdentifiers.first(where: {
            $0.lowercased() == text
        }) else { return nil }
        return TimeZone(identifier: identifier)
    }

    private static func resolveText(
        _ text: String, sentAt: Date, calendar: Calendar, sourceTimeZone: TimeZone?
    ) -> Resolution {
        // Put the longer forms first so a weekday attached to an explicit date
        // is validated against that date, rather than treated as a bare weekday.
        let dayPattern = "(" + [
            "(?:" + weekdayPattern + " )?" + namedDatePattern,
            "next week " + weekdayPattern, weekdayPattern + " next week",
            "today|tomorrow|tonight|end of (?:the )?month|eom",
            "(?:next )?" + weekdayPattern, #"\d{1,2}/\d{1,2}(?:/\d{4})?"#
        ].joined(separator: "|") + ")"
        let parts: [String]
        if let dated = captures(#"^"# + dayPattern + #"(?:(?:, ?| )(?:at )?(.+))?$"#, in: text) {
            parts = dated
        } else if sourceTimeZone != nil {
            // Preserve the existing ambiguous result for unzoned bare times.
            parts = ["today", text.replacingOccurrences(of: #"^at "#, with: "", options: .regularExpression)]
        } else {
            return .ambiguous
        }
        guard let day = resolveDay(parts[0], sentAt: sentAt, calendar: calendar) else {
            return .ambiguous
        }
        guard !parts[1].isEmpty else { return .dateOnly(day) }

        var clockCalendar = calendar
        clockCalendar.timeZone = sourceTimeZone ?? calendar.timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        guard let year = components.year, let month = components.month, let dayNumber = components.day,
              let clockDay = checkedDate(year: year, month: month, day: dayNumber, calendar: clockCalendar) else {
            return .ambiguous
        }
        let times = parts[1].components(separatedBy: " to ")
            .flatMap { $0.components(separatedBy: CharacterSet(charactersIn: "-–")) }
        guard (1...2).contains(times.count),
              let start = resolveTime(times[0], on: clockDay, calendar: clockCalendar,
                                      defaultPM: parts[0] == "tonight") else {
            return .ambiguous
        }
        if times.count == 1 {
            return .exact(DateInterval(start: start, duration: 3_600))
        }
        // An end earlier than the start could mean overnight or a typo: review it.
        guard let end = resolveTime(times[1], on: clockDay, calendar: clockCalendar,
                                    defaultPM: parts[0] == "tonight"), end > start else {
            return .ambiguous
        }
        return .exact(DateInterval(start: start, end: end))
    }

    private static func resolveDay(_ text: String, sentAt: Date, calendar: Calendar) -> Date? {
        let today = calendar.startOfDay(for: sentAt)
        if text == "today" || text == "tonight" { return today }
        if text == "tomorrow" { return calendar.date(byAdding: .day, value: 1, to: today) }
        if ["end of month", "end of the month", "eom"].contains(text) {
            guard let month = calendar.dateInterval(of: .month, for: today) else { return nil }
            return calendar.date(byAdding: .day, value: -1, to: month.end)
        }
        if let parts = captures("^(" + weekdayPattern + ") (" + namedDatePattern + ")$", in: text) {
            guard let day = resolveDay(parts[1], sentAt: sentAt, calendar: calendar),
                  calendar.component(.weekday, from: day) == weekdayNumber(parts[0]) else { return nil }
            return day
        }
        if let parts = captures(
            "^(?:next week (" + weekdayPattern + ")|(" + weekdayPattern + ") next week)$", in: text
        ), let weekday = weekdayNumber(parts[0].isEmpty ? parts[1] : parts[0]) {
            // Monday is offset zero, regardless of Calendar's default firstWeekday.
            let daysSinceMonday = (calendar.component(.weekday, from: today) + 5) % 7
            let offset = 7 - daysSinceMonday + (weekday + 5) % 7
            return calendar.date(byAdding: .day, value: offset, to: today)
        }
        let next = text.hasPrefix("next ")
        let weekdayText = next ? String(text.dropFirst(5)) : text
        if let weekday = weekdayNumber(weekdayText) {
            var offset = (weekday - calendar.component(.weekday, from: today) + 7) % 7
            if next && offset == 0 { offset = 7 }
            return calendar.date(byAdding: .day, value: offset, to: today)
        }

        let year = calendar.component(.year, from: today)
        if let parts = captures(#"^(\d{1,2})/(\d{1,2})(?:/(\d{4}))?$"#, in: text),
           let day = Int(parts[0]), let month = Int(parts[1]) {
            return resolveAbsoluteDay(
                day: day, month: month, year: Int(parts[2]) ?? year,
                inferYear: parts[2].isEmpty, today: today, calendar: calendar
            )
        }
        let months = ["january", "february", "march", "april", "may", "june",
                      "july", "august", "september", "october", "november", "december"]
        guard let parts = captures(#"^(\d{1,2}) ([a-z]+)(?: (\d{4}))?$"#, in: text),
              let day = Int(parts[0]),
              let monthIndex = months.firstIndex(where: {
                  parts[1] == $0 || parts[1] == String($0.prefix(3))
              }) else { return nil }
        let resolvedYear = Int(parts[2]) ?? year

        // NSDataDetector has no public reference-date parameter. Feed it only an
        // absolute date with an explicit year and GMT, never relative text. Calendar
        // validates its components and constructs the day in the caller's zone.
        let absoluteText = "\(day) \(months[monthIndex]) \(resolvedYear) at 12:00 GMT"
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let detected = detector.firstMatch(
                  in: absoluteText, range: NSRange(absoluteText.startIndex..., in: absoluteText)
              )?.date,
              let utc = TimeZone(secondsFromGMT: 0) else { return nil }
        var detectorCalendar = Calendar(identifier: .gregorian)
        detectorCalendar.timeZone = utc
        let components = detectorCalendar.dateComponents([.year, .month, .day], from: detected)
        guard components.year == resolvedYear, components.month == monthIndex + 1,
              components.day == day else { return nil }
        return resolveAbsoluteDay(
            day: day, month: monthIndex + 1, year: resolvedYear,
            inferYear: parts[2].isEmpty, today: today, calendar: calendar
        )
    }

    private static func weekdayNumber(_ text: String) -> Int? {
        guard captures("^(" + weekdayPattern + ")$", in: text) != nil,
              let index = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
                .firstIndex(of: String(text.prefix(3))) else { return nil }
        return index + 1
    }

    private static func resolveAbsoluteDay(
        day: Int, month: Int, year: Int, inferYear: Bool, today: Date, calendar: Calendar
    ) -> Date? {
        guard let date = checkedDate(year: year, month: month, day: day, calendar: calendar) else {
            return nil
        }
        if inferYear && date < today {
            return checkedDate(year: year + 1, month: month, day: day, calendar: calendar)
        }
        return date
    }

    private static func checkedDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        guard year > 0, (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        let actual = calendar.dateComponents([.year, .month, .day], from: date)
        guard actual.year == year, actual.month == month, actual.day == day else { return nil }
        return calendar.startOfDay(for: date)
    }

    private static func resolveTime(
        _ text: String, on day: Date, calendar: Calendar, defaultPM: Bool = false
    ) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let time = ["noon", "midday"].contains(trimmed) ? "12pm" : trimmed
        guard let parts = captures(
            #"^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$"#,
            in: time
        ), var hour = Int(parts[0]) else { return nil }
        let minute = Int(parts[1]) ?? 0
        guard (0...59).contains(minute) else { return nil }
        if parts[2].isEmpty && defaultPM && (1...12).contains(hour) {
            hour = hour % 12 + 12
        } else if parts[2].isEmpty {
            // Bare '7' does not specify morning or evening; 24-hour HH:mm does.
            guard !parts[1].isEmpty, (0...23).contains(hour) else { return nil }
        } else {
            guard (1...12).contains(hour) else { return nil }
            hour = hour % 12 + (parts[2] == "pm" ? 12 : 0)
        }
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        components.second = 0
        // Reject both missing spring-forward times and repeated fall-back times.
        let before = day.addingTimeInterval(-1)
        guard let first = calendar.nextDate(
            after: before, matching: components, matchingPolicy: .strict, repeatedTimePolicy: .first
        ), let last = calendar.nextDate(
            after: before, matching: components, matchingPolicy: .strict, repeatedTimePolicy: .last
        ), first == last, calendar.isDate(first, inSameDayAs: day) else { return nil }
        return first
    }

    private static func captures(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        return (1..<match.numberOfRanges).map {
            guard let range = Range(match.range(at: $0), in: text) else { return "" }
            return String(text[range])
        }
    }
}
