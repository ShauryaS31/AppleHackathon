import Foundation

public enum Prefilter {
    public enum Decision: Sendable, Equatable {
        case skip, model, review
    }

    /// One tuning point for the English request signals. Matching ignores case and uses word boundaries.
    public static let requestPhrases = [
        "can you", "could you", "would you", "will you", "please",
        "due", "deadline", "remind", "reminder", "rsvp",
        "let's", "let us", "need you to", "need to", "don't forget",
        "do not forget", "remember to", "make sure", "action required", "confirm"
    ]

    public static let maximumCharacters = 10_000

    /// The exact input to pass on to extraction, including any subject date/request signal.
    public static func preparedText(_ message: SourceMessage) -> String {
        // Strip markup once: decoding &lt;reply&gt; must not make literal prose a tag on a second pass.
        Normaliser.collapseWhitespace(
            Normaliser.normalise(message.subject) + "\n" + QuoteStripper.strip(message.body)
        )
    }

    /// Labels take precedence; remaining oversized inputs go to Review without truncation.
    /// Date detection supplies only a signal. Resolving dates remains DateResolver's job.
    public static func decide(_ message: SourceMessage) -> Decision {
        let excludedLabels: Set<String> = [
            "SPAM", "TRASH", "DRAFT", "CATEGORY_PROMOTIONS", "CATEGORY_SOCIAL"
        ]
        if !excludedLabels.isDisjoint(with: message.labels) {
            return .skip
        }

        let text = preparedText(message)
        guard text.count <= maximumCharacters else { return .review }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            // Failure to initialise a detector must not silently discard a commitment.
            return .review
        }
        let hasDate = detector.firstMatch(
            in: text, range: NSRange(text.startIndex..., in: text)
        ) != nil
        let hasUnsubscribe = message.headers.keys.contains {
            $0.caseInsensitiveCompare("List-Unsubscribe") == .orderedSame
        }
        if hasUnsubscribe && !hasDate {
            return .skip
        }
        let hasRequest = requestPhrases.contains { phrase in
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: phrase) + #"\b"#
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
        return hasDate || hasRequest ? .model : .skip
    }
}
