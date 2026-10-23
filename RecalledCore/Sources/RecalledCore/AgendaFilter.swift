import Foundation

public enum AgendaFilter {
    /// Confirmed items without a start date, ordered by title ignoring case.
    /// Identity breaks title ties so storage fetch order cannot reorder rows.
    public static func noDate(_ commitments: [Commitment]) -> [Commitment] {
        commitments.filter { $0.status == .confirmed && $0.dueStart == nil }
            .sorted { left, right in
                let order = left.title.caseInsensitiveCompare(right.title)
                if order == .orderedSame { return left.id.uuidString < right.id.uuidString }
                return order == .orderedAscending
            }
    }
}
