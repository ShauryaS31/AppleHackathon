import Foundation
import RecalledCore
import SwiftData

// App-only persistence types. No SourceMessage or message body is stored.
@Model
final class StoredCommitment {
    @Attribute(.unique) var id: UUID
    var title: String
    var kind: Commitment.Kind
    var status: Commitment.Status
    var actor: String
    var dueText: String
    var dueStart: Date?
    var dueEnd: Date?
    var timezone: String?
    var version: Int
    var calendarEventId: String?

    init(_ value: Commitment) {
        id = value.id
        title = value.title
        kind = value.kind
        status = value.status
        actor = value.actor
        dueText = value.dueText
        dueStart = value.dueStart
        dueEnd = value.dueEnd
        timezone = value.timezone
        version = value.version
        calendarEventId = value.calendarEventId
    }

    func toCore() -> Commitment {
        Commitment(id: id, title: title, kind: kind, status: status, actor: actor,
                   dueText: dueText, dueStart: dueStart, dueEnd: dueEnd,
                   timezone: timezone, version: version, calendarEventId: calendarEventId)
    }
}

@Model
final class StoredEvidence {
    @Attribute(.unique) var id: UUID
    var commitmentId: UUID
    var sourceMessageId: String
    var excerpt: String
    var source: SourceMessage.Source
    var capturedAt: Date
    var sender: String
    var subject: String
    var sentAt: Date
    // Bounded neighboring excerpts provide context without retaining the body.
    var contextBefore: String
    var contextAfter: String

    init(_ value: Evidence, sender: String, subject: String, sentAt: Date,
         contextBefore: String = "", contextAfter: String = "") {
        id = UUID()
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        excerpt = value.excerpt
        source = value.source
        capturedAt = value.capturedAt
        self.sender = sender
        self.subject = subject
        self.sentAt = sentAt
        self.contextBefore = String(contextBefore.suffix(120))
        self.contextAfter = String(contextAfter.prefix(120))
    }

    func toCore() -> Evidence {
        Evidence(commitmentId: commitmentId, sourceMessageId: sourceMessageId,
                 excerpt: excerpt, source: source, capturedAt: capturedAt)
    }
}

@Model
final class StoredReviewItem {
    @Attribute(.unique) var id: UUID
    var commitmentId: UUID?
    var sourceMessageId: String?
    var reason: String

    init(_ value: ReviewItem) {
        id = UUID()
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        reason = value.reason
    }

    func toCore() -> ReviewItem? {
        ReviewItem(commitmentId: commitmentId, sourceMessageId: sourceMessageId, reason: reason)
    }
}

@Model
final class StoredLedgerEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var destinationModelId: String
    var regions: [String]
    var byteCount: Int
    var redactedPayloadPreview: String

    init(_ value: LedgerEntry) {
        id = UUID()
        timestamp = value.timestamp
        destinationModelId = value.destinationModelId
        regions = value.regions
        byteCount = value.byteCount
        redactedPayloadPreview = value.redactedPayloadPreview
    }

    func toCore() -> LedgerEntry {
        LedgerEntry(timestamp: timestamp, destinationModelId: destinationModelId,
                    regions: regions, byteCount: byteCount,
                    redactedPayloadPreview: redactedPayloadPreview)
    }
}

@Model
final class StoredActionReceipt {
    @Attribute(.unique) var id: UUID
    var commitmentId: UUID
    var action: ActionReceipt.Action
    var providerId: String
    var result: String

    init(_ value: ActionReceipt) {
        id = UUID()
        commitmentId = value.commitmentId
        action = value.action
        providerId = value.providerId
        result = value.result
    }

    func toCore() -> ActionReceipt {
        ActionReceipt(commitmentId: commitmentId, action: action,
                      providerId: providerId, result: result)
    }
}
