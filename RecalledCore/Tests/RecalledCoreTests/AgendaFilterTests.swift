import Foundation
import Testing
import RecalledCore

@Test func noDateIncludesOnlyConfirmedStatus() {
    let items = Commitment.Status.allCases.map { status in
        Commitment(title: status.rawValue, kind: .commitment, status: status,
                   actor: "Sam", dueText: "")
    }
    #expect(AgendaFilter.noDate(items) == items.filter { $0.status == .confirmed })
}

@Test func noDateExcludesEveryStartDateButDoesNotRequireAnEmptyEndOrDateText() {
    let undated = Commitment(title: "Send proposal", kind: .commitment, status: .confirmed,
                             actor: "Sam", dueText: "No agreed deadline",
                             dueEnd: Date(timeIntervalSince1970: 100))
    let dated = [-86_400.0, 0, 86_400, 864_000].map { timestamp in
        var item = undated
        item.id = UUID()
        item.dueStart = Date(timeIntervalSince1970: timestamp)
        return item
    }
    #expect(AgendaFilter.noDate(dated + [undated]) == [undated])
}

@Test func noDateSortsTitlesIgnoringCase() {
    let items = ["zebra", "Beta", "alpha"].map { title in
        Commitment(title: title, kind: .commitment, status: .confirmed,
                   actor: "Sam", dueText: "")
    }
    #expect(AgendaFilter.noDate(items) == [items[2], items[1], items[0]])
}

@Test func noDateTitleTiesUseIdentityRegardlessOfInputOrder() {
    let first = Commitment(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                           title: "proposal", kind: .commitment, status: .confirmed,
                           actor: "Sam", dueText: "")
    let second = Commitment(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                            title: "PROPOSAL", kind: .commitment, status: .confirmed,
                            actor: "Maya", dueText: "")
    #expect(AgendaFilter.noDate([second, first]) == [first, second])
    #expect(AgendaFilter.noDate([first, second]) == [first, second])
    var identicalTitle = second
    identicalTitle.title = first.title
    #expect(AgendaFilter.noDate([identicalTitle, first]) == [first, identicalTitle])
}

@Test func noDateHandlesEmptyInputAndNoEligibleItems() {
    #expect(AgendaFilter.noDate([]).isEmpty)
    let item = Commitment(title: "Maybe lunch", kind: .event, status: .tentative,
                          actor: "Sam", dueText: "")
    #expect(AgendaFilter.noDate([item]).isEmpty)
}
