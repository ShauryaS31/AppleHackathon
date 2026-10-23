import Foundation

/// User-selected dates and display text; no model or ambient clock is consulted.
public struct ReviewSchedule: Sendable, Equatable {
    public let start: Date
    public let end: Date?
    public let timezone: String
    public let dueText: String

    public init(start: Date, end: Date?, timezone: String, dueText: String) {
        self.start = start
        self.end = end
        self.timezone = timezone
        self.dueText = dueText
    }
}

public enum ReviewAction: Sendable, Equatable {
    case confirm
    case edit(ReviewSchedule)
    case dismiss
    case merge(existingID: UUID)
    case create(id: UUID, title: String, kind: Commitment.Kind, schedule: ReviewSchedule?)
}

public enum ReviewActionError: LocalizedError, Equatable {
    case stale, invalidSchedule, invalidTitle, invalidTarget, versionLimit

    public var errorDescription: String? {
        switch self {
        case .stale: "This review has changed. Close it and try again."
        case .invalidSchedule: "The end must be later than the start."
        case .invalidTitle: "Enter a title for the item."
        case .invalidTarget: "Choose a different open item."
        case .versionLimit: "This item cannot be updated because its version limit was reached."
        }
    }
}

public enum ReviewResolver {
    /// Persistence identity and source metadata needed to resolve one queue row.
    public struct Row: Sendable, Equatable {
        public let id: UUID
        public let commitmentID: UUID?
        public let sourceMessageID: String?
        public let sender: String

        public init(id: UUID, commitmentID: UUID?, sourceMessageID: String?, sender: String) {
            self.id = id
            self.commitmentID = commitmentID
            self.sourceMessageID = sourceMessageID
            self.sender = sender
        }
    }

    public enum EvidenceChange: Sendable, Equatable {
        case none
        case reparent(from: UUID, to: UUID)
        case copySource(messageID: String, to: UUID)
    }

    public struct Resolution: Sendable, Equatable {
        public let updates: [Commitment]
        public let created: Commitment?
        public let removedReviewIDs: Set<UUID>
        public let evidenceChange: EvidenceChange
    }

    /// Produces an atomic change plan from a fresh snapshot. The caller applies it
    /// in one transaction, retaining evidence metadata and bounded context.
    public static func resolve(
        id: UUID, action: ReviewAction, reviews: [Row], commitments: [Commitment]
    ) throws -> Resolution {
        guard let review = reviews.first(where: { $0.id == id }) else {
            throw ReviewActionError.stale
        }
        let candidate = commitments.first { $0.id == review.commitmentID }
        var updates: [Commitment] = []
        var created: Commitment?
        var evidenceChange: EvidenceChange = .none

        switch action {
        case .confirm:
            var item = try openCandidate(candidate)
            if let start = item.dueStart { try validate(start: start, end: item.dueEnd) }
            try bumpVersion(&item)
            item.status = .confirmed
            updates = [item]
        case .edit(let schedule):
            var item = try openCandidate(candidate)
            try validate(start: schedule.start, end: schedule.end)
            try bumpVersion(&item)
            apply(schedule, to: &item)
            item.status = .confirmed
            updates = [item]
        case .dismiss:
            // Even an orphaned or closed candidate's review can be dismissed.
            if var item = candidate, item.isOpenForReview {
                try bumpVersion(&item)
                item.status = .cancelled
                updates = [item]
            }
        case .merge(let existingID):
            var item = try openCandidate(candidate)
            guard var existing = commitments.first(where: { $0.id == existingID }),
                  existing.id != item.id, existing.isOpenForReview else {
                throw ReviewActionError.invalidTarget
            }
            try bumpVersion(&existing)
            try bumpVersion(&item)
            existing.dueText = item.dueText
            existing.dueStart = item.dueStart
            existing.dueEnd = item.dueEnd
            existing.timezone = item.timezone
            item.status = .superseded
            updates = [item, existing]
            evidenceChange = .reparent(from: item.id, to: existing.id)
        case .create(let newID, let title, let kind, let schedule):
            guard review.commitmentID == nil, !commitments.contains(where: { $0.id == newID }) else {
                throw ReviewActionError.stale
            }
            let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { throw ReviewActionError.invalidTitle }
            var item = Commitment(id: newID, title: title, kind: kind, status: .confirmed,
                actor: review.sender, dueText: "")
            if let schedule {
                try validate(start: schedule.start, end: schedule.end)
                apply(schedule, to: &item)
            }
            created = item
            if let messageID = review.sourceMessageID {
                evidenceChange = .copySource(messageID: messageID, to: newID)
            }
        }

        // Resolve all reasons for this candidate, but preserve unrelated rows,
        // including other message-level reviews and the merge target's reviews.
        let removed = reviews.filter {
            $0.id == review.id || (candidate != nil && $0.commitmentID == candidate?.id)
        }
        return Resolution(updates: updates, created: created,
            removedReviewIDs: Set(removed.map(\.id)), evidenceChange: evidenceChange)
    }

    private static func openCandidate(_ item: Commitment?) throws -> Commitment {
        guard let item, item.isOpenForReview else { throw ReviewActionError.stale }
        return item
    }

    private static func bumpVersion(_ item: inout Commitment) throws {
        guard item.version < Int.max else { throw ReviewActionError.versionLimit }
        item.version += 1
    }

    private static func validate(start: Date, end: Date?) throws {
        if let end, end <= start { throw ReviewActionError.invalidSchedule }
    }

    private static func apply(_ schedule: ReviewSchedule, to item: inout Commitment) {
        item.dueStart = schedule.start
        item.dueEnd = schedule.end
        item.timezone = schedule.timezone
        item.dueText = schedule.dueText
    }
}

extension Commitment {
    public var isOpenForReview: Bool {
        status != .completed && status != .cancelled && status != .superseded
    }
}
