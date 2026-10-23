import Foundation

/// Privacy limits for persisted message fragments. Bodies are transient input only.
public enum EvidenceContext {
    /// Keeps at most 40 characters on either side, dropping partial outer words.
    /// Short messages, missing excerpts and empty excerpts retain no context.
    public static func retained(body: String, excerpt: String) -> (before: String, after: String) {
        guard !excerpt.isEmpty, body.count >= excerpt.count + 80,
              let range = body.range(of: excerpt) else { return ("", "") }
        let before = String(body[..<range.lowerBound])
        let after = String(body[range.upperBound...])
        // Reverse both strings to apply the same word-boundary rule at either edge.
        return (String(boundedExcerpt(String(before.reversed())).reversed()), boundedExcerpt(after))
    }

    /// A review preview is also limited to 40 characters, ending on a word boundary.
    /// A single oversized word yields no preview rather than a partial word.
    public static func boundedExcerpt(_ text: String) -> String {
        guard text.count > 40 else { return text }
        let end = text.index(text.startIndex, offsetBy: 40)
        let prefix = text[..<end]
        if text[end].isWhitespace || prefix.last?.isWhitespace == true {
            return String(prefix)
        }
        guard let boundary = prefix.lastIndex(where: { $0.isWhitespace }) else { return "" }
        return String(prefix[...boundary])
    }
}
