import Foundation

/// Pure ingestion: no persistence, provider actions, network clients or model tools.
public enum InboxPipeline {
    /// Keeps each review paired with its own bounded source evidence, including
    /// failures that have no commitment to attach an Evidence record to.
    public struct Review: Sendable, Equatable {
        public let item: ReviewItem
        public let excerpt: String
    }

    public struct Result: Sendable, Equatable {
        public internal(set) var skipped = false
        public internal(set) var newCommitments: [Commitment] = []
        public internal(set) var updatedCommitments: [Commitment] = []
        public internal(set) var evidence: [Evidence] = []
        public internal(set) var reviews: [Review] = []
        public var reviewItems: [ReviewItem] { reviews.map(\.item) }

        fileprivate mutating func review(_ message: SourceMessage, reason: String,
                                         commitmentId: UUID? = nil, excerpt: String? = nil) {
            if let review = ReviewItem(commitmentId: commitmentId,
                                       sourceMessageId: message.id, reason: reason) {
                reviews.append(Review(item: review, excerpt: EvidenceContext.boundedExcerpt(
                    excerpt ?? Prefilter.preparedText(message))))
            }
        }
    }

    public static func process(
        _ message: SourceMessage, extractor: any CommitmentExtractor,
        existing: [Commitment], refs: [ItemRef], timeZone: TimeZone
    ) async -> Result {
        var result = Result()
        switch Prefilter.decide(message) {
        case .skip:
            result.skipped = true
            return result
        case .review:
            result.review(message, reason: "Message needs review before extraction (oversized or prefilter unavailable).")
            return result
        case .model:
            break
        }

        let text = Prefilter.preparedText(message)
        var prepared = message
        prepared.subject = ""
        prepared.body = text
        let extraction: ExtractionResult
        do {
            extraction = try await extractor.extract(prepared, openItems: refs)
        } catch {
            result.review(message, reason: "Extraction failed: \(error.localizedDescription)")
            return result
        }
        guard extraction.relevance != .irrelevant else { return result }
        if extraction.items.isEmpty && extraction.relevance == .uncertain {
            result.review(message, reason: "tentative")
        }

        var current = existing
        for var item in extraction.items {
            guard EvidenceValidator.validate(excerpt: item.evidence, message: text),
                  text.range(of: item.evidence, options: .literal) != nil else {
                result.review(message, reason: "Evidence is not an exact source excerpt of at least 8 characters.")
                continue
            }
            item.tentative = item.tentative || extraction.relevance == .uncertain
            var start: Date?
            var end: Date?
            var kind = item.kind
            if !item.dueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                switch DateResolver.resolve(dueText: item.dueText, sentAt: message.sentAt, timeZone: timeZone) {
                case .exact(let interval):
                    start = interval.start
                    end = interval.end
                case .dateOnly(let day):
                    start = day
                    kind = .deadline
                case .ambiguous:
                    result.review(message, reason: "Date is ambiguous: \(item.dueText)", excerpt: item.evidence)
                    continue
                }
            }

            let match = Matcher.match(item, existing: current, refs: refs)
            if case .review = match {
                result.review(message, reason: "More than one possible match, or matching is uncertain.",
                              excerpt: item.evidence)
                continue
            }
            var value: Commitment
            var isNew = extraction.change == .new
            switch extraction.change {
            case .new:
                if case .match(let id) = match {
                    result.review(message, reason: "possible duplicate", commitmentId: id, excerpt: item.evidence)
                    continue
                }
                value = Commitment(title: item.title, kind: kind,
                    status: item.tentative ? .tentative : .confirmed, actor: item.actor,
                    dueText: item.dueText, dueStart: start, dueEnd: end, timezone: timeZone.identifier)
            case .updated, .rescheduled, .cancelled, .completed:
                guard case .match(let id) = match,
                      let old = current.first(where: { $0.id == id }) else {
                    result.review(message, reason: "Could not find the commitment to change.", excerpt: item.evidence)
                    continue
                }
                if item.tentative && (extraction.change == .cancelled || extraction.change == .completed) {
                    result.review(message, reason: "tentative", commitmentId: old.id, excerpt: item.evidence)
                    continue
                }
                switch extraction.change {
                case .updated, .rescheduled:
                    guard case .applied(let updated) = CommitmentUpdater.reschedule(
                        old, using: item, sentAt: message.sentAt, timeZone: timeZone
                    ) else {
                        result.review(message, reason: "Could not safely update the commitment.",
                                      commitmentId: old.id, excerpt: item.evidence)
                        continue
                    }
                    value = updated
                case .cancelled:
                    value = CommitmentUpdater.cancel(old)
                default:
                    value = old
                    value.status = .completed
                }
            case .noChange:
                if case .match(let id) = match {
                    if item.tentative {
                        result.review(message, reason: "tentative", commitmentId: id, excerpt: item.evidence)
                    }
                    continue
                }
                guard item.tentative else {
                    result.review(message, reason: "unclear change", excerpt: item.evidence)
                    continue
                }
                isNew = true
                value = Commitment(title: item.title, kind: kind, status: .tentative,
                    actor: item.actor, dueText: item.dueText, dueStart: start,
                    dueEnd: end, timezone: timeZone.identifier)
            }
            if item.tentative { value.status = .tentative }
            if isNew {
                result.newCommitments.append(value)
                current.append(value)
            } else {
                result.updatedCommitments.removeAll { $0.id == value.id }
                result.updatedCommitments.append(value)
                if let index = current.firstIndex(where: { $0.id == value.id }) { current[index] = value }
            }
            result.evidence.append(Evidence(commitmentId: value.id, sourceMessageId: message.id,
                excerpt: item.evidence, source: message.source, capturedAt: message.sentAt))
            if item.tentative {
                result.review(message, reason: "tentative", commitmentId: value.id, excerpt: item.evidence)
            }
        }
        return result
    }
}
