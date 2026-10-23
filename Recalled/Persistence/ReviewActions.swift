import Foundation
import RecalledCore
import SwiftData

extension AppStore {
    /// Apply the Core decision in one save. Roll back all changes on failure.
    func resolveReview(id: UUID, action: ReviewAction) throws {
        let context = container.mainContext
        do {
            let reviews = try context.fetch(FetchDescriptor<StoredReviewItem>())
            let commitments = try context.fetch(FetchDescriptor<StoredCommitment>())
            let resolution = try ReviewResolver.resolve(id: id, action: action,
                reviews: reviews.map {
                    ReviewResolver.Row(id: $0.id, commitmentID: $0.commitmentId,
                        sourceMessageID: $0.sourceMessageId, sender: $0.sender)
                }, commitments: commitments.map { $0.toCore() })

            for value in resolution.updates {
                guard let row = commitments.first(where: { $0.id == value.id }) else {
                    throw ReviewActionError.stale
                }
                row.status = value.status
                row.version = value.version
                row.dueText = value.dueText
                row.dueStart = value.dueStart
                row.dueEnd = value.dueEnd
                row.timezone = value.timezone
            }
            if let value = resolution.created { context.insert(StoredCommitment(value)) }

            switch resolution.evidenceChange {
            case .none:
                break
            case .reparent(let candidateID, let existingID):
                for evidence in try context.fetch(FetchDescriptor<StoredEvidence>())
                where evidence.commitmentId == candidateID {
                    evidence.commitmentId = existingID
                }
            case .copySource(let messageID, let newID):
                // Copy actual stored evidence and bounded context, never a review reason.
                for evidence in try context.fetch(FetchDescriptor<StoredEvidence>())
                where evidence.sourceMessageId == messageID {
                    let copy = StoredEvidence(evidence.toCore(), sender: evidence.sender,
                        subject: evidence.subject, sentAt: evidence.sentAt)
                    copy.update(from: evidence)
                    copy.commitmentId = newID
                    context.insert(copy)
                }
            }
            for row in reviews where resolution.removedReviewIDs.contains(row.id) {
                context.delete(row)
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

extension StoredCommitment {
    var isOpenForReview: Bool { toCore().isOpenForReview }
}
