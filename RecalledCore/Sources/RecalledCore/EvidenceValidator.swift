import Foundation

public enum EvidenceValidator {
    /// Normalise only the message: altering the excerpt could conceal invented evidence.
    public static func validate(excerpt: String, message: String) -> Bool {
        excerpt.count >= 8 && Normaliser.normalise(message).range(of: excerpt, options: .literal) != nil
    }
}
