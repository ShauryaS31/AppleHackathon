import Foundation
import RecalledCore
import SwiftData

// App-only persistence types. No SourceMessage or message body is stored.
@Model
final class StoredCommitment {
    @Attribute(.unique) var id: UUID
    var title: String
    var kindRaw: String
    var statusRaw: String
    var kind: Commitment.Kind {
        get { Commitment.Kind(rawValue: kindRaw) ?? .commitment }
        set { kindRaw = newValue.rawValue }
    }
    var status: Commitment.Status {
        get { Commitment.Status(rawValue: statusRaw) ?? .needsReview }
        set { statusRaw = newValue.rawValue }
    }
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
        kindRaw = value.kind.rawValue
        statusRaw = value.status.rawValue
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
    private(set) var contextBefore: String
    private(set) var contextAfter: String

    init(_ value: Evidence, id: UUID = UUID(), sender: String, subject: String, sentAt: Date,
         body: String = "") {
        self.id = id
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        excerpt = value.excerpt
        source = value.source
        capturedAt = value.capturedAt
        self.sender = sender
        self.subject = subject
        self.sentAt = sentAt
        let context = EvidenceContext.retained(body: body, excerpt: value.excerpt)
        contextBefore = context.before
        contextAfter = context.after
    }

    func update(from value: StoredEvidence) {
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        excerpt = value.excerpt
        source = value.source
        capturedAt = value.capturedAt
        sender = value.sender
        subject = value.subject
        sentAt = value.sentAt
        contextBefore = value.contextBefore
        contextAfter = value.contextAfter
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
    var sender: String = ""
    private(set) var excerpt: String = ""
    var createdAt: Date = Date.now

    init(_ value: ReviewItem, id: UUID = UUID(), sender: String = "",
         excerpt: String = "", createdAt: Date = .now) {
        self.id = id
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        reason = value.reason
        self.sender = sender
        self.excerpt = EvidenceContext.boundedExcerpt(excerpt)
        self.createdAt = createdAt
    }

    func update(from value: StoredReviewItem) {
        commitmentId = value.commitmentId
        sourceMessageId = value.sourceMessageId
        reason = value.reason
        sender = value.sender
        excerpt = EvidenceContext.boundedExcerpt(value.excerpt)
        createdAt = value.createdAt
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
    var actionRaw: String
    var action: ActionReceipt.Action {
        get { ActionReceipt.Action(rawValue: actionRaw) ?? .createEvent }
        set { actionRaw = newValue.rawValue }
    }
    var providerId: String
    var result: String

    init(_ value: ActionReceipt) {
        id = UUID()
        commitmentId = value.commitmentId
        actionRaw = value.action.rawValue
        providerId = value.providerId
        result = value.result
    }

    func toCore() -> ActionReceipt {
        ActionReceipt(commitmentId: commitmentId, action: action,
                      providerId: providerId, result: result)
    }
}
