import Foundation

/// Scripts by message id, so concurrent extraction order does not affect results.
public struct FakeExtractor: CommitmentExtractor, Codable, Sendable, Equatable {
    public var resultsByMessageID: [String: ExtractionResult]
    public var defaultResult: ExtractionResult

    public init(
        resultsByMessageID: [String: ExtractionResult] = [:],
        defaultResult: ExtractionResult = ExtractionResult(relevance: .none, change: .none, items: [])
    ) {
        self.resultsByMessageID = resultsByMessageID
        self.defaultResult = defaultResult
    }

    public func extract(_ msg: SourceMessage, openItems: [ItemRef]) async throws -> ExtractionResult {
        resultsByMessageID[msg.id] ?? defaultResult
    }
}

/// Actor isolation protects mutable event storage across concurrent protocol calls.
public actor InMemoryCalendarStore: CalendarStore {
    private var storedEvents: [CalendarEvent]

    public init(events: [CalendarEvent] = []) {
        self.storedEvents = events
    }

    /// Returns overlaps in insertion order, using half-open [start, end) intervals.
    public func events(in range: DateInterval) async throws -> [CalendarEvent] {
        guard range.duration > 0 else { return [] }
        return storedEvents.filter { event in
            event.start < event.end && event.start < range.end && event.end > range.start
        }
    }

    public func create(_ draft: EventDraft) async throws -> String {
        let id = UUID().uuidString
        storedEvents.append(CalendarEvent(
            id: id, title: draft.title, start: draft.start, end: draft.end,
            timezone: draft.timezone, isAllDay: draft.isAllDay, notes: draft.notes
        ))
        return id
    }
}

public struct FakePlanningModel: PlanningModel, Codable, Sendable, Equatable {
    public var regions: [String]
    public var response: PlanResponse

    public init(
        regions: [String] = [],
        response: PlanResponse = PlanResponse(summary: "", orderedRefs: [])
    ) {
        self.regions = regions
        self.response = response
    }

    public func plan(_ request: PseudonymisedPlanRequest) async throws -> PlanResponse {
        response
    }
}

public struct SilentSpeech: Speech, Codable, Sendable, Equatable {
    public init() {}

    public func speak(_ text: String) async throws {}
}
