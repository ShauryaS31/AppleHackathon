import Foundation

public enum QuoteStripper {
    /// Removes English reply history and common signatures before whitespace is collapsed.
    /// Accepts plain text or HTML and retains line boundaries in the remaining text.
    public static func strip(_ text: String) -> String {
        var kept: [String] = []
        for line in Normaliser.preservingLines(text).components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "--" || trimmed.caseInsensitiveCompare("Sent from my iPhone") == .orderedSame {
                break
            }
            if trimmed.range(of: #"(?i)^On\s+.+\s+wrote:\s*$"#, options: .regularExpression) != nil {
                break
            }
            if trimmed.hasPrefix(">") {
                continue
            }
            kept.append(line)
        }
        return kept.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
