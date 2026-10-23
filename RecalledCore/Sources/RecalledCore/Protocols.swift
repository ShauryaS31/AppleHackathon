import Foundation

public protocol CommitmentExtractor: Sendable {
    func extract(_ msg: SourceMessage, openItems: [ItemRef]) async throws -> ExtractionResult
}

public protocol CalendarStore: Sendable {
    func events(in range: DateInterval) async throws -> [CalendarEvent]
    func create(_ draft: EventDraft) async throws -> String
    func update(_ id: String, with draft: EventDraft) async throws
}

public protocol PlanningModel: Sendable {
    var regions: [String] { get }
    func plan(_ request: PseudonymisedPlanRequest) async throws -> PlanResponse
}

public protocol Speech: Sendable {
    func speak(_ text: String) async throws
}
