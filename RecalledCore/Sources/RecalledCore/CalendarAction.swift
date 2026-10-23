import Foundation

public enum CalendarActionError: Error, Sendable, Equatable {
    case notConfirmed, unresolvedDate, invalidTimeZone, eventNotFound
}

/// Uses only dates already resolved by DateResolver or explicitly chosen in Review.
public enum CalendarAction {
    public static func draft(for commitment: Commitment) throws -> EventDraft {
        guard commitment.status == .confirmed else { throw CalendarActionError.notConfirmed }
        guard let start = commitment.dueStart else { throw CalendarActionError.unresolvedDate }
        guard let identifier = commitment.timezone,
              let zone = TimeZone(identifier: identifier) else {
            throw CalendarActionError.invalidTimeZone
        }
        if commitment.kind == .deadline && commitment.dueEnd == nil {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = zone
            let day = calendar.startOfDay(for: start)
            guard let end = calendar.date(byAdding: .day, value: 1, to: day) else {
                throw CalendarActionError.unresolvedDate
            }
            return EventDraft(title: commitment.title, start: day, end: end,
                              timezone: identifier, isAllDay: true)
        }
        guard let end = commitment.dueEnd, end > start else {
            throw CalendarActionError.unresolvedDate
        }
        return EventDraft(title: commitment.title, start: start, end: end, timezone: identifier)
    }

    /// Check the exact proposed block, including explicitly approved all-day events.
    /// The linked provider event is excluded when approving a reschedule.
    public static func overlaps(draft: EventDraft, commitment: Commitment,
                                events: [CalendarEvent]) -> [CalendarEvent] {
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
