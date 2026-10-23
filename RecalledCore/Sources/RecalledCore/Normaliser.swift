import Foundation

public enum Normaliser {
    /// Produces the canonical text used for extraction and evidence matching.
    /// Long HTTP(S) URLs are treated as tracking noise, using a 200-character cutoff.
    public static func normalise(_ text: String) -> String {
        collapseWhitespace(preservingLines(text))
    }

    static func collapseWhitespace(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    // Keep structural lines until QuoteStripper has inspected reply/signature markers.
    static func preservingLines(_ text: String) -> String {
        var result = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        result = result.replacingOccurrences(
            of: #"(?is)<!--.*?-->|<(script|style)\b[^>]*>.*?</\1\s*>"#,
            with: "", options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"(?i)</?(?:br|p|div|li|tr|blockquote|h[1-6])\b[^>]*>"#,
            with: "\n", options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: #"</?[A-Za-z][^>]*>"#, with: "", options: .regularExpression
        )
        // Decode after removing tags, so escaped prose is not mistaken for markup.
        for (entity, replacement) in [
            ("&nbsp;", " "), ("&#160;", " "), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"), ("&amp;", "&")
        ] {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        guard let urls = try? NSRegularExpression(pattern: #"(?i)\bhttps?://[^\s<>"']+"#) else {
            return result
        }
        // Reverse order keeps earlier UTF-16 match ranges valid after each removal.
        for match in urls.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
            if let range = Range(match.range, in: result), result[range].count > 200 {
                result.replaceSubrange(range, with: "")
            }
        }
        return result
    }
}
