/// Synthetic extraction benchmark input and human-authored expectations.
/// All fixtures use Australia/Sydney for date resolution. sentAt preserves its
/// ISO 8601 offset as a string so decoding needs no custom date strategy.
public struct BenchmarkFixture: Codable, Sendable, Equatable {
    public enum Style: String, Codable, Sendable, Equatable {
        case email, chat
    }

    public enum Origin: String, Codable, Sendable, Equatable {
        case ported, new
    }

    /// Fixture refs have no persistence UUID; the benchmark runner assigns those.
    public struct OpenItem: Codable, Sendable, Equatable {
        public let ref: String
        public let title: String
        public let kind: Commitment.Kind
        public let status: Commitment.Status
        public let dueText: String
    }

    public struct Expected: Codable, Sendable, Equatable {
        public let relevance: ExtractionResult.Relevance
        public let items: [Item]

        public struct Item: Codable, Sendable, Equatable {
            public let kind: Commitment.Kind
            public let change: ExtractionResult.Change
            public let tentative: Bool
            /// Verbatim date words supplied to DateResolver, not a computed date.
            public let dueText: String
            /// Human-labelled local date/time, never model output. For Review cases
            /// these remain reference labels and must not be used as resolved dates.
            public let dueDate: String?
            public let dueTime: String?
            public let evidence: String
            public let updatesRef: String
            /// Ambiguous resolution or uncertain relevance requires human Review.
            public let requiresReview: Bool
        }
    }

    public let id: String
    public let name: String
    public let style: Style
    public let origin: Origin
    public let sender: String
    public let sentAt: String
    public let subject: String
    public let body: String
    public let openItems: [OpenItem]
    public let expected: Expected
}
