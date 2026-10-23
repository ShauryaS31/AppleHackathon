import Foundation
import RecalledCore

struct PendingModelExtractor: CommitmentExtractor {
    private struct NotWired: LocalizedError {
        var errorDescription: String? { "on-device extractor not wired yet" }
    }

    func extract(_ msg: SourceMessage, openItems: [ItemRef]) async throws -> ExtractionResult {
        throw NotWired()
    }
}
