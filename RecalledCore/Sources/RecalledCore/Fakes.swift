import Foundation

public enum FakeServiceError: Error, Codable, Sendable, Equatable {
    case scripted(String)
}

/// Scripts by message id, so concurrent extraction order does not affect results.
public struct FakeExtractor: CommitmentExtractor, Codable, Sendable, Equatable {
    public var resultsByMessageID: [String: ExtractionResult]
    public var defaultResult: ExtractionResult
    /// A scripted error takes precedence over a result for the same message id.
    public var errorsByMessageID: [String: FakeServiceError]

    public init(
        resultsByMessageID: [String: ExtractionResult] = [:],
        defaultResult: ExtractionResult = ExtractionResult(relevance: .irrelevant, change: .noChange, items: []),
        errorsByMessageID: [String: FakeServiceError] = [:]
    ) {
        self.resultsByMessageID = resultsByMessageID
        self.defaultResult = defaultResult
        self.errorsByMessageID = errorsByMessageID
    }

    public func extract(_ msg: SourceMessage, openItems: [ItemRef]) async throws -> ExtractionResult {
        if let error = errorsByMessageID[msg.id] { throw error }
        return resultsByMessageID[msg.id] ?? defaultResult
    }
}

/// Actor isolation protects mutable event storage across concurrent protocol calls.
public actor InMemoryCalendarStore: CalendarStore {
    private var storedEvents: [CalendarEvent]
    private var nextID = 1

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
        // Each store starts at fake-1 and skips any ids already present in seed data.
        while storedEvents.contains(where: { $0.id == "fake-\(nextID)" }) {
            nextID += 1
        }
        let id = "fake-\(nextID)"
        nextID += 1
        storedEvents.append(CalendarEvent(
            id: id, title: draft.title, start: draft.start, end: draft.end,
            timezone: draft.timezone, isAllDay: draft.isAllDay, notes: draft.notes,
            location: draft.location
        ))
        return id
    }

    public func update(_ id: String, with draft: EventDraft) async throws {
        guard let index = storedEvents.firstIndex(where: { $0.id == id }) else {
            throw CalendarActionError.eventNotFound
        }
        storedEvents[index] = CalendarEvent(
            id: id, title: draft.title, start: draft.start, end: draft.end,
            timezone: draft.timezone, isAllDay: draft.isAllDay, notes: draft.notes,
            location: draft.location
        )
    }
}

public struct FakePlanningModel: PlanningModel, Codable, Sendable, Equatable {
    public var regions: [String]
    public var response: PlanResponse
    public var error: FakeServiceError?

    public init(
        regions: [String] = [],
        response: PlanResponse = PlanResponse(summary: "", orderedRefs: []),
        error: FakeServiceError? = nil
    ) {
        self.regions = regions
        self.response = response
        self.error = error
    }

    public func plan(_ request: PseudonymisedPlanRequest) async throws -> PlanResponse {
        if let error { throw error }
        return response
    }
}

public struct SilentSpeech: Speech, Codable, Sendable, Equatable {
    public init() {}

    public func speak(_ text: String) async throws {}
}
