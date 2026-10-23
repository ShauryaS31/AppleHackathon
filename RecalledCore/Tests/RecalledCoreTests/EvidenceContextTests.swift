import Testing
import RecalledCore

@Test func shortMessagesRetainNoNeighboringContext() {
    let excerpt = "Coffee at 11?"
    for body in [excerpt, "Hey " + excerpt + " See you!", String(repeating: " ", count: 79) + excerpt] {
        let result = EvidenceContext.retained(body: body, excerpt: excerpt)
        #expect(result.before.isEmpty)
        #expect(result.after.isEmpty)
    }
}

@Test func contextThresholdIncludesExactlyEightyAdditionalCharacters() {
    let side = String(repeating: "word ", count: 8)
    let result = EvidenceContext.retained(body: side + "Meet" + side, excerpt: "Meet")
    #expect(result.before == side)
    #expect(result.after == side)
}

@Test func contextDropsPartialWordsAtBothOuterEdges() {
    let before = "discard supercalifragilistic " + String(repeating: "x ", count: 15)
    let after = String(repeating: " y", count: 15) + " supercalifragilistic discard"
    let result = EvidenceContext.retained(body: before + "Meet" + after, excerpt: "Meet")
    #expect(result.before == " " + String(repeating: "x ", count: 15))
    #expect(result.after == String(repeating: " y", count: 15) + " ")
    #expect(result.before.count <= 40)
    #expect(result.after.count <= 40)
}

@Test func contextHandlesMissingEmptyAndEdgeExcerpts() {
    let padding = String(repeating: "word ", count: 20)
    for excerpt in ["", "absent"] {
        let result = EvidenceContext.retained(body: padding, excerpt: excerpt)
        #expect(result.before.isEmpty && result.after.isEmpty)
    }
    let start = EvidenceContext.retained(body: "Meet" + padding, excerpt: "Meet")
    let end = EvidenceContext.retained(body: padding + "Meet", excerpt: "Meet")
    #expect(start.before.isEmpty && start.after.count == 40)
    #expect(end.before.count == 40 && end.after.isEmpty)
}

@Test func boundedReviewExcerptHandlesUnicodeWhitespaceAndLongWords() {
    #expect(EvidenceContext.boundedExcerpt("") == "")
    #expect(EvidenceContext.boundedExcerpt("Short message") == "Short message")
    #expect(EvidenceContext.boundedExcerpt(String(repeating: "x", count: 41)).isEmpty)
    let forty = String(repeating: "é", count: 40)
    #expect(EvidenceContext.boundedExcerpt(forty + " next") == forty)
    let unicode = String(repeating: "👩🏽‍💻\n", count: 21)
    #expect(EvidenceContext.boundedExcerpt(unicode) == String(repeating: "👩🏽‍💻\n", count: 20))
}
