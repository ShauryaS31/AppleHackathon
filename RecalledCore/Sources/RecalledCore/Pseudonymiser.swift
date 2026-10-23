import Foundation
import NaturalLanguage

/// Detects personal information locally. Detection is heuristic, not a guarantee
/// that arbitrary text is anonymous. Keep the returned map on device.
public enum Pseudonymiser {
    public enum Failure: Error, Equatable, Sendable {
        /// Already-tokenised input is ambiguous; callers must use the original text.
        case reservedPlaceholderInInput
    }

    /// Numbers each type by first appearance, starting afresh for each call.
    /// Exact repeated values reuse a token. The map is placeholder -> original.
    public static func pseudonymise(_ text: String) throws -> (text: String, map: [String: String]) {
        let tokens = try NSRegularExpression(pattern: placeholderPattern)
        let fullRange = NSRange(text.startIndex..., in: text)
        guard tokens.firstMatch(in: text, range: fullRange) == nil else {
            throw Failure.reservedPlaceholderInInput
        }

        let detector = try NSDataDetector(types:
            NSTextCheckingResult.CheckingType.link.rawValue |
            NSTextCheckingResult.CheckingType.phoneNumber.rawValue |
            NSTextCheckingResult.CheckingType.address.rawValue
        )
        var entities: [Entity] = []
        for match in detector.matches(in: text, range: fullRange) {
            let kind: Kind
            switch match.resultType {
            case .link where match.url?.scheme?.lowercased() == "mailto": kind = .email
            case .phoneNumber: kind = .telephone
            case .address: kind = .address
            default: continue
            }
            entities.append(Entity(range: match.range, kind: kind))
        }

        // Both Apple recognisers are local to this call, never shared across tasks.
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType,
            options: [.omitPunctuation, .omitWhitespace, .joinNames]
        ) { tag, range in
            guard let tag else { return true }
            let kind: Kind
            switch tag {
            case .personalName: kind = .person
            case .organizationName: kind = .organisation
            default: return true
            }
            let candidate = Entity(range: NSRange(range, in: text), kind: kind)
            // A name inside an email or street address must not split that value.
            if !entities.contains(where: { NSIntersectionRange($0.range, candidate.range).length > 0 }) {
                entities.append(candidate)
            }
            return true
        }
        return try redact(text, entities: entities)
    }

    /// Substitutes whole tokens in one pass. Unknown tokens remain unchanged and
    /// restored originals are never interpreted as further placeholders.
    public static func rehydrate(_ text: String, map: [String: String]) -> String {
        guard let regex = try? NSRegularExpression(pattern: placeholderPattern) else { return text }
        var result = text
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let range = Range(match.range, in: text),
                  let original = map[String(text[range])],
                  let outputRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(outputRange, with: original)
        }
        return result
    }

    private static let placeholderPattern = #"\[[POETA][1-9][0-9]*\]"#

    enum Kind: String {
        case person = "P", organisation = "O", email = "E", telephone = "T", address = "A"

        var priority: Int {
            switch self {
            case .email, .telephone, .address: 0
            case .person, .organisation: 1
            }
        }
    }

    struct Entity {
        let range: NSRange
        let kind: Kind
    }

    // Kept separate from Apple detection so ordering/overlap rules are testable
    // independently of the OS's named-entity model.
    static func redact(_ text: String, entities: [Entity]) throws -> (text: String, map: [String: String]) {
        var candidates = entities
        var expanded: Set<String> = []
        for entity in entities {
            guard let range = Range(entity.range, in: text), !range.isEmpty else { continue }
            let original = String(text[range])
            guard expanded.insert(entity.kind.rawValue + original).inserted else { continue }
            // Redact repeats even where the tagger misses the same name in a
            // different context. Do not match inside a longer word.
            let pattern = #"(?<![\p{L}\p{M}\p{N}_])"# +
                NSRegularExpression.escapedPattern(for: original) + #"(?![\p{L}\p{M}\p{N}_])"#
            let regex = try NSRegularExpression(pattern: pattern)
            candidates += regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                .map { Entity(range: $0.range, kind: entity.kind) }
        }

        // Prefer detector spans, then longer spans; resolve all overlaps before
        // assigning numbers in textual order. No replacement shifts a later range.
        candidates.sort {
            if $0.kind.priority != $1.kind.priority { return $0.kind.priority < $1.kind.priority }
            if $0.range.length != $1.range.length { return $0.range.length > $1.range.length }
            if $0.range.location != $1.range.location { return $0.range.location < $1.range.location }
            return $0.kind.rawValue < $1.kind.rawValue
        }
        var selected: [Entity] = []
        for candidate in candidates {
            guard candidate.range.length > 0, Range(candidate.range, in: text) != nil,
                  !selected.contains(where: { NSIntersectionRange($0.range, candidate.range).length > 0 }) else {
                continue
            }
            selected.append(candidate)
        }
        selected.sort { $0.range.location < $1.range.location }

        var counts: [Kind: Int] = [:]
        var tokens: [Kind: [String: String]] = [:]
        var map: [String: String] = [:]
        var output = ""
        var cursor = text.startIndex
        for entity in selected {
            guard let range = Range(entity.range, in: text) else { continue }
            let original = String(text[range])
            let token: String
            if let existing = tokens[entity.kind]?[original] {
                token = existing
            } else {
                counts[entity.kind, default: 0] += 1
                token = "[\(entity.kind.rawValue)\(counts[entity.kind, default: 0])]"
                tokens[entity.kind, default: [:]][original] = token
                map[token] = original
            }
            output += text[cursor..<range.lowerBound]
            output += token
            cursor = range.upperBound
        }
        output += text[cursor...]
        return (output, map)
    }
}
