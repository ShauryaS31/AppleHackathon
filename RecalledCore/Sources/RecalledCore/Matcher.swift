import Foundation

public enum Matcher {
    public enum Result: Sendable, Equatable {
        case match(UUID)
        case review([UUID])
        case new
    }

    public static func match(
        _ item: ExtractionDTO, existing: [Commitment], refs: [ItemRef] = []
    ) -> Result {
        if !item.updatesRef.isEmpty {
            let referencedIDs = Set(refs.filter { $0.ref == item.updatesRef }.map(\.commitmentId))
            let validIDs = Set(existing.map(\.id)).intersection(referencedIDs)
            if validIDs.count == 1, let id = validIDs.first { return .match(id) }
            if validIDs.count > 1 { return .review(validIDs.sorted { $0.uuidString < $1.uuidString }) }
        }
        let title = tokens(item.title)
        var strong: [UUID] = []
        var possible: [UUID] = []
        for commitment in existing {
            let other = tokens(commitment.title)
            let union = title.union(other).count
            let similarity = union == 0 ? 0 : Double(title.intersection(other).count) / Double(union)
            if similarity >= 0.6 { strong.append(commitment.id) }
            if similarity >= 0.4 { possible.append(commitment.id) }
        }
        let uniqueStrong = Set(strong)
        if uniqueStrong.count == 1, let id = uniqueStrong.first { return .match(id) }
        if !possible.isEmpty {
            return .review(Set(possible).sorted { $0.uuidString < $1.uuidString })
        }
        return .new
    }

    private static func tokens(_ title: String) -> Set<String> {
        let stripped = title.lowercased().components(separatedBy: .punctuationCharacters).joined()
        return Set(stripped.split(whereSeparator: { $0.isWhitespace }).map(String.init))
    }
}
