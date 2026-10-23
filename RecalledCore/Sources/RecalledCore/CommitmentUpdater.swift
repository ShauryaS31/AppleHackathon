import Foundation

public enum CommitmentUpdater {
    public enum Result: Sendable, Equatable {
        case applied(Commitment)
        case review
    }

    /// Call only after matching and evidence validation. A review leaves the stored
    /// item intact; the caller owns persistence and any provider/reminder effects.
    public static func reschedule(
        _ commitment: Commitment, using item: ExtractionDTO, sentAt: Date, timeZone: TimeZone
    ) -> Result {
        guard commitment.version < Int.max else { return .review }
        var updated = commitment
        if item.dueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updated.dueStart = nil
            updated.dueEnd = nil
            updated.kind = item.kind
        } else {
            let resolution = DateResolver.resolve(dueText: item.dueText, sentAt: sentAt, timeZone: timeZone)
            switch resolution {
            case .exact(let interval):
                updated.dueStart = interval.start
                updated.dueEnd = interval.end
                updated.kind = item.kind
            case .dateOnly(let day):
                updated.dueStart = day
                updated.dueEnd = nil
                updated.kind = .deadline
            case .ambiguous:
                return .review
            }
        }
        updated.title = item.title
        updated.actor = item.actor
        updated.dueText = item.dueText
        updated.timezone = timeZone.identifier
        updated.status = item.tentative ? .tentative : .confirmed
        updated.version += 1
        return .applied(updated)
    }

    public static func cancel(_ commitment: Commitment) -> Commitment {
        var updated = commitment
        updated.status = .cancelled
        return updated
    }
}
