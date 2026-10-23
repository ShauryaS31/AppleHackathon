import Foundation

public struct CalendarEvent: Codable, Sendable, Equatable {
    public var id: String
    public var title: String
    public var start: Date
    public var end: Date
    public var timezone: String
    public var isAllDay: Bool
    public var notes: String?

    public init(
        id: String, title: String, start: Date, end: Date, timezone: String,
        isAllDay: Bool = false, notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.timezone = timezone
        self.isAllDay = isAllDay
        self.notes = notes
    }
}

/// Dates have already been resolved locally before an event is drafted.
public struct EventDraft: Codable, Sendable, Equatable {
    public var title: String
    public var start: Date
    public var end: Date
    public var timezone: String
    public var isAllDay: Bool
    public var notes: String?

    public init(
        title: String, start: Date, end: Date, timezone: String,
        isAllDay: Bool = false, notes: String? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.timezone = timezone
        self.isAllDay = isAllDay
        self.notes = notes
    }
}

/// Plain Core counterpart of SPEC 7.4's ExtractedItem, without generation macros.
/// Date words and evidence are copied verbatim; this type never resolves dates.
public struct ExtractionDTO: Codable, Sendable, Equatable {
    public var title: String
    public var kind: Commitment.Kind
    public var tentative: Bool
    public var dueText: String
    public var actor: String
    public var evidence: String
    public var updatesRef: String

    public init(
        title: String, kind: Commitment.Kind, tentative: Bool, dueText: String,
        actor: String, evidence: String, updatesRef: String
    ) {
        self.title = title
        self.kind = kind
        self.tentative = tentative
        self.dueText = dueText
        self.actor = actor
        self.evidence = evidence
        self.updatesRef = updatesRef
    }
}

public struct ExtractionResult: Codable, Sendable, Equatable {
    public enum Relevance: String, Codable, Sendable, Equatable, CaseIterable {
        case none, uncertain, relevant
    }

    public enum Change: String, Codable, Sendable, Equatable, CaseIterable {
        case new, updated, rescheduled, cancelled, completed, none
    }

    public var relevance: Relevance
    public var change: Change
    public var items: [ExtractionDTO]

    public init(relevance: Relevance, change: Change, items: [ExtractionDTO]) {
        self.relevance = relevance
        self.change = change
        self.items = items
    }
}

/// Callers must pseudonymise titles and instructions before constructing a request.
public struct PseudonymisedPlanRequest: Codable, Sendable, Equatable {
    public var items: [ItemRef]
    public var instructions: String

    public init(items: [ItemRef], instructions: String) {
        self.items = items
        self.instructions = instructions
    }
}

/// Planning returns advice about refs, without asking the model to compute dates.
public struct PlanResponse: Codable, Sendable, Equatable {
    public var summary: String
    public var orderedRefs: [String]

    public init(summary: String, orderedRefs: [String]) {
        self.summary = summary
        self.orderedRefs = orderedRefs
    }
}
