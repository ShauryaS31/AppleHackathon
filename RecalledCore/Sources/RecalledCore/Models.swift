import Foundation

/// The body is transient input; persistence must retain only evidence and metadata.
public struct SourceMessage: Codable, Sendable, Equatable {
    public enum Source: String, Codable, Sendable, Equatable, CaseIterable {
        case share, gmail, seed
    }

    public var id: String
    public var source: Source
    public var sender: String
    public var sentAt: Date
    public var subject: String
    public var body: String
    public var threadKey: String?
    public var labels: [String]
    public var headers: [String: String]

    public init(
        id: String, source: Source, sender: String, sentAt: Date,
        subject: String, body: String, threadKey: String? = nil,
        labels: [String] = [], headers: [String: String] = [:]
    ) {
        self.id = id
        self.source = source
        self.sender = sender
        self.sentAt = sentAt
        self.subject = subject
        self.body = body
        self.threadKey = threadKey
        self.labels = labels
        self.headers = headers
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        source = try container.decode(Source.self, forKey: .source)
        sender = try container.decode(String.self, forKey: .sender)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        subject = try container.decode(String.self, forKey: .subject)
        body = try container.decode(String.self, forKey: .body)
        threadKey = try container.decodeIfPresent(String.self, forKey: .threadKey)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        headers = try container.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
    }
}

public struct Commitment: Codable, Sendable, Equatable {
    public enum Kind: String, Codable, Sendable, Equatable, CaseIterable {
        case event, deadline, commitment
    }

    public enum Status: String, Codable, Sendable, Equatable, CaseIterable {
        case candidate, tentative, confirmed, completed, cancelled, superseded, needsReview
    }

    public var id: UUID
    public var title: String
    public var kind: Kind
    public var status: Status
    public var actor: String
    public var dueText: String
    public var dueStart: Date?
    public var dueEnd: Date?
    public var timezone: String?
    public var version: Int
    public var calendarEventId: String?

    public init(
        id: UUID = UUID(), title: String, kind: Kind, status: Status = .candidate,
        actor: String, dueText: String, dueStart: Date? = nil, dueEnd: Date? = nil,
        timezone: String? = nil, version: Int = 1, calendarEventId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.status = status
        self.actor = actor
        self.dueText = dueText
        self.dueStart = dueStart
        self.dueEnd = dueEnd
        self.timezone = timezone
        self.version = version
        self.calendarEventId = calendarEventId
    }
}

public struct Evidence: Codable, Sendable, Equatable {
    public var commitmentId: UUID
    public var sourceMessageId: String
    public var excerpt: String
    public var source: SourceMessage.Source
    public var capturedAt: Date

    public init(
        commitmentId: UUID, sourceMessageId: String, excerpt: String,
        source: SourceMessage.Source, capturedAt: Date
    ) {
        self.commitmentId = commitmentId
        self.sourceMessageId = sourceMessageId
        self.excerpt = excerpt
        self.source = source
        self.capturedAt = capturedAt
    }
}

public struct ReviewItem: Codable, Sendable, Equatable {
    public let commitmentId: UUID?
    public let sourceMessageId: String?
    public var reason: String

    /// Returns nil when neither link is supplied. Links are immutable so a valid
    /// review cannot later lose both; decoding enforces the same requirement.
    public init?(commitmentId: UUID? = nil, sourceMessageId: String? = nil, reason: String) {
        guard commitmentId != nil || sourceMessageId != nil else { return nil }
        self.commitmentId = commitmentId
        self.sourceMessageId = sourceMessageId
        self.reason = reason
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let commitmentId = try container.decodeIfPresent(UUID.self, forKey: .commitmentId)
        let sourceMessageId = try container.decodeIfPresent(String.self, forKey: .sourceMessageId)
        let reason = try container.decode(String.self, forKey: .reason)
        guard let item = ReviewItem(
            commitmentId: commitmentId, sourceMessageId: sourceMessageId, reason: reason
        ) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "ReviewItem requires a commitmentId or sourceMessageId."
            ))
        }
        self = item
    }
}

public struct LedgerEntry: Codable, Sendable, Equatable {
    public var timestamp: Date
    public var destinationModelId: String
    public var regions: [String]
    public var byteCount: Int
    public var redactedPayloadPreview: String

    public init(
        timestamp: Date, destinationModelId: String, regions: [String],
        byteCount: Int, redactedPayloadPreview: String
    ) {
        self.timestamp = timestamp
        self.destinationModelId = destinationModelId
        self.regions = regions
        self.byteCount = byteCount
        self.redactedPayloadPreview = redactedPayloadPreview
    }
}

public struct ActionReceipt: Codable, Sendable, Equatable {
    public enum Action: String, Codable, Sendable, Equatable, CaseIterable {
        case createEvent, updateEvent, createReminder
    }

    public var commitmentId: UUID
    public var action: Action
    public var providerId: String
    public var result: String

    public init(commitmentId: UUID, action: Action, providerId: String, result: String) {
        self.commitmentId = commitmentId
        self.action = action
        self.providerId = providerId
        self.result = result
    }
}

/// A short reference (for example, "t3") supplied alongside an existing item.
public struct ItemRef: Codable, Sendable, Equatable {
    public var ref: String
    public var commitmentId: UUID
    public var title: String
    public var kind: Commitment.Kind
    public var status: Commitment.Status

    public init(
        ref: String, commitmentId: UUID, title: String,
        kind: Commitment.Kind, status: Commitment.Status
    ) {
        self.ref = ref
        self.commitmentId = commitmentId
        self.title = title
        self.kind = kind
        self.status = status
    }
}
