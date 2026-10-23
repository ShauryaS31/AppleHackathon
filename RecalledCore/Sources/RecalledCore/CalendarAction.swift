import Foundation

public enum CalendarActionError: Error, Sendable, Equatable {
    case notConfirmed, unresolvedDate, invalidTimeZone, eventNotFound
}

/// Uses only dates already resolved by DateResolver or explicitly chosen in Review.
public enum CalendarAction {
    public static func draft(for commitment: Commitment, calendar: Calendar = .current) throws -> EventDraft {
        guard commitment.status == .confirmed else { throw CalendarActionError.notConfirmed }
        guard let start = commitment.dueStart else { throw CalendarActionError.unresolvedDate }
        guard let identifier = commitment.timezone,
              let zone = TimeZone(identifier: identifier) else {
            throw CalendarActionError.invalidTimeZone
        }
        if commitment.kind == .deadline && commitment.dueEnd == nil {
            // Keep the deadline's source-zone date, expressed in the user's calendar.
            // Rebuild it locally so EventKit can save a floating all-day date.
            var sourceCalendar = calendar
            sourceCalendar.timeZone = zone
            let components = sourceCalendar.dateComponents([.era, .year, .month, .day], from: start)
            guard let localDate = calendar.date(from: components) else {
                throw CalendarActionError.unresolvedDate
            }
            let day = calendar.startOfDay(for: localDate)
            guard let end = calendar.date(byAdding: .day, value: 1, to: day) else {
                throw CalendarActionError.unresolvedDate
            }
            return EventDraft(title: commitment.title, start: day, end: end,
                              timezone: calendar.timeZone.identifier, isAllDay: true)
        }
        guard let end = commitment.dueEnd, end > start else {
            throw CalendarActionError.unresolvedDate
        }
        return EventDraft(title: commitment.title, start: start, end: end, timezone: identifier)
    }

    /// All-day deadlines do not reserve a timed block and never conflict.
    /// The linked provider event is excluded when approving a reschedule.
    public static func overlaps(draft: EventDraft, commitment: Commitment,
                                events: [CalendarEvent]) -> [CalendarEvent] {
        guard !draft.isAllDay else { return [] }
        var proposed = commitment
        proposed.kind = .event
        proposed.dueStart = draft.start
        proposed.dueEnd = draft.end
        return ConflictDetector.conflicts(commitments: [proposed], calendarEvents: events)
            .map(\.event)
            .sorted { lhs, rhs in
                if lhs.start != rhs.start { return lhs.start < rhs.start }
                return lhs.id < rhs.id
            }
    }
}
