import Foundation
import RecalledCore
import SwiftData

/// User-entered dates, never model-computed dates. A nil end preserves date-only deadlines.
struct ReviewSchedule {
    let start: Date
    let end: Date?
    let timezone: String
}

enum ReviewAction {
    case confirm
    case edit(ReviewSchedule)
    case dismiss
    case merge(existingID: UUID)
    case create(title: String, kind: Commitment.Kind, schedule: ReviewSchedule)
}

private enum ReviewActionError: LocalizedError {
    case stale, missingDate, invalidSchedule, invalidTitle, invalidTarget, versionLimit

    var errorDescription: String? {
        switch self {
        case .stale: "This review has changed. Close it and try again."
        case .missingDate: "Choose a date and time before confirming."
        case .invalidSchedule: "The end must be later than the start."
        case .invalidTitle: "Enter a title for the item."
        case .invalidTarget: "Choose a different open item."
        case .versionLimit: "This item cannot be updated because its version limit was reached."
        }
    }
}

extension AppStore {
    /// Resolve the queue row and its commitment in one save. Roll back all changes on failure.
    func resolveReview(id: UUID, action: ReviewAction) throws {
        let context = container.mainContext
        do {
            let reviews = try context.fetch(FetchDescriptor<StoredReviewItem>())
            guard let review = reviews.first(where: { $0.id == id }) else {
                throw ReviewActionError.stale
            }
            let commitments = try context.fetch(FetchDescriptor<StoredCommitment>())
            let candidate = commitments.first { $0.id == review.commitmentId }
            switch action {
            case .confirm:
                guard let candidate, candidate.isOpenForReview else { throw ReviewActionError.stale }
                guard let start = candidate.dueStart else { throw ReviewActionError.missingDate }
                try validate(ReviewSchedule(start: start, end: candidate.dueEnd,
                    timezone: candidate.timezone ?? TimeZone.current.identifier))
                try bumpVersion(candidate)
                candidate.status = .confirmed
            case .edit(let schedule):
                guard let candidate, candidate.isOpenForReview else { throw ReviewActionError.stale }
                try validate(schedule)
                try bumpVersion(candidate)
                apply(schedule, to: candidate)
                candidate.status = .confirmed
            case .dismiss:
                if let candidate, candidate.isOpenForReview {
                    try bumpVersion(candidate)
                    candidate.status = .cancelled
                }
            case .merge(let existingID):
                guard let candidate, candidate.isOpenForReview,
                      let existing = commitments.first(where: { $0.id == existingID }),
                      existing.id != candidate.id, existing.isOpenForReview else {
                    throw ReviewActionError.invalidTarget
                }
                try bumpVersion(existing)
                try bumpVersion(candidate)
                existing.dueText = candidate.dueText
                existing.dueStart = candidate.dueStart
                existing.dueEnd = candidate.dueEnd
                existing.timezone = candidate.timezone
                // Keep the existing identity, title, kind, status and provider ID.
                // Reparent evidence without losing older evidence or bounded context.
                for evidence in try context.fetch(FetchDescriptor<StoredEvidence>())
                where evidence.commitmentId == candidate.id {
                    evidence.commitmentId = existing.id
                }
                candidate.status = .superseded
            case .create(let title, let kind, let schedule):
                guard candidate == nil, review.commitmentId == nil else { throw ReviewActionError.stale }
                let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty else { throw ReviewActionError.invalidTitle }
                try validate(schedule)
                let item = StoredCommitment(Commitment(title: title, kind: kind, status: .confirmed,
                    actor: review.sender, dueText: ""))
                apply(schedule, to: item)
                context.insert(item)
                // Reuse actual stored evidence; never invent a source or treat a review
                // reason as a quote from the message.
                if let messageID = review.sourceMessageId {
                    for evidence in try context.fetch(FetchDescriptor<StoredEvidence>())
                    where evidence.sourceMessageId == messageID {
                        let copy = StoredEvidence(evidence.toCore(), sender: evidence.sender,
                            subject: evidence.subject, sentAt: evidence.sentAt)
                        copy.update(from: evidence)
                        copy.commitmentId = item.id
                        context.insert(copy)
                    }
                }
            }

            // Multiple reasons may refer to the same candidate; resolve them together.
            for row in reviews where row.id == review.id ||
                (candidate != nil && row.commitmentId == candidate?.id) {
                context.delete(row)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func bumpVersion(_ item: StoredCommitment) throws {
        guard item.version < Int.max else { throw ReviewActionError.versionLimit }
        item.version += 1
    }

    private func validate(_ schedule: ReviewSchedule) throws {
        if let end = schedule.end, end <= schedule.start { throw ReviewActionError.invalidSchedule }
    }

    private func apply(_ schedule: ReviewSchedule, to item: StoredCommitment) {
        item.dueStart = schedule.start
        item.dueEnd = schedule.end
        item.timezone = schedule.timezone
        item.dueText = schedule.start.formatted(date: .abbreviated, time: .shortened)
    }
}

extension StoredCommitment {
    var isOpenForReview: Bool {
        status != .completed && status != .cancelled && status != .superseded
    }
}
