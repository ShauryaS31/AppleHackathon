import Foundation

public enum ConflictDetector {
    public struct Conflict: Sendable, Equatable {
        public let commitment: Commitment
        public let event: CalendarEvent
    }

    /// Half-open intervals: an event ending at another's start does not overlap.
    public static func conflicts(
        commitments: [Commitment], calendarEvents: [CalendarEvent]
    ) -> [Conflict] {
        commitments.flatMap { commitment -> [Conflict] in
            guard commitment.kind != .deadline,
                  ![Commitment.Status.cancelled, .completed, .superseded].contains(commitment.status),
                  let start = commitment.dueStart, let end = commitment.dueEnd, end > start else {
                return []
            }
            return calendarEvents.compactMap { event in
                guard event.id != commitment.calendarEventId, event.end > event.start,
                      start < event.end, event.start < end else { return nil }
                return Conflict(commitment: commitment, event: event)
            }
        }
    }
}
