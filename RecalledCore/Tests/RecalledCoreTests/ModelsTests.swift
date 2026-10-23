import Foundation
import Testing
import RecalledCore

/// The constraint also checks each value's Sendable conformance at compile time.
private func expectRoundTrip<T: Codable & Sendable & Equatable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    #expect(decoded == value)
}

private let timestamp = Date(timeIntervalSince1970: 1_792_800_000)

@Test func sourceMessagePreservesMetadataAndRoundTrips() throws {
    let message = SourceMessage(
        id: "gmail-1", source: .gmail, sender: "Alex", sentAt: timestamp,
        subject: "Lunch", body: "Lunch tomorrow?", threadKey: "thread-1",
        labels: ["INBOX", "IMPORTANT"], headers: ["List-Id": "team.example"]
    )
    #expect(message.id == "gmail-1")
    #expect(message.source == .gmail)
    #expect(message.sender == "Alex")
    #expect(message.sentAt == timestamp)
    #expect(message.subject == "Lunch")
    #expect(message.body == "Lunch tomorrow?")
    #expect(message.threadKey == "thread-1")
    #expect(message.labels == ["INBOX", "IMPORTANT"])
    #expect(message.headers == ["List-Id": "team.example"])
    try expectRoundTrip(message)
}

@Test func sourceMessageDefaultsSupportShareAndSeed() throws {
    for source in [SourceMessage.Source.share, .seed] {
        let message = SourceMessage(
            id: "local", source: source, sender: "Me", sentAt: timestamp,
            subject: "", body: "Send the report"
        )
        #expect(message.threadKey == nil)
        #expect(message.labels.isEmpty)
        #expect(message.headers.isEmpty)
        try expectRoundTrip(message)
    }
}

@Test func commitmentPreservesResolvedFieldsAndRoundTrips() throws {
    let id = UUID()
    let end = timestamp.addingTimeInterval(3_600)
    let commitment = Commitment(
        id: id, title: "Lunch", kind: .event, status: .confirmed,
        actor: "Alex", dueText: "tomorrow at noon", dueStart: timestamp,
        dueEnd: end, timezone: "Australia/Sydney", version: 3, calendarEventId: "event-1"
    )
    #expect(commitment.id == id)
    #expect(commitment.title == "Lunch")
    #expect(commitment.kind == .event)
    #expect(commitment.status == .confirmed)
    #expect(commitment.actor == "Alex")
    #expect(commitment.dueText == "tomorrow at noon")
    #expect(commitment.dueStart == timestamp)
    #expect(commitment.dueEnd == end)
    #expect(commitment.timezone == "Australia/Sydney")
    #expect(commitment.version == 3)
    #expect(commitment.calendarEventId == "event-1")
    try expectRoundTrip(commitment)
}

@Test func commitmentDefaultsKeepUnresolvedDatesAndUniqueIdentity() throws {
    let first = Commitment(title: "Report", kind: .deadline, actor: "me", dueText: "Friday")
    let second = Commitment(title: "Report", kind: .deadline, actor: "me", dueText: "Friday")
    #expect(first.id != second.id)
    #expect(first.status == .candidate)
    #expect(first.version == 1)
    #expect(first.dueStart == nil)
    #expect(first.dueEnd == nil)
    #expect(first.timezone == nil)
    #expect(first.calendarEventId == nil)
    try expectRoundTrip(first)
}

@Test func enumRawValuesMatchSpecificationAndRoundTrip() throws {
    #expect(Commitment.Kind.allCases.map(\.rawValue) == ["event", "deadline", "commitment"])
    #expect(Commitment.Status.allCases.map(\.rawValue) == [
        "candidate", "tentative", "confirmed", "completed", "cancelled", "superseded", "needsReview"
    ])
    #expect(SourceMessage.Source.allCases.map(\.rawValue) == ["share", "gmail", "seed"])
    #expect(ActionReceipt.Action.allCases.map(\.rawValue) == ["createEvent", "createReminder"])
    #expect(ExtractionResult.Relevance.allCases.map(\.rawValue) == ["none", "uncertain", "relevant"])
    #expect(ExtractionResult.Change.allCases.map(\.rawValue) == [
        "new", "updated", "rescheduled", "cancelled", "completed", "none"
    ])
    for value in Commitment.Kind.allCases { try expectRoundTrip(value) }
    for value in Commitment.Status.allCases { try expectRoundTrip(value) }
    for value in SourceMessage.Source.allCases { try expectRoundTrip(value) }
    for value in ActionReceipt.Action.allCases { try expectRoundTrip(value) }
    for value in ExtractionResult.Relevance.allCases { try expectRoundTrip(value) }
    for value in ExtractionResult.Change.allCases { try expectRoundTrip(value) }
    let encoded = try JSONEncoder().encode(Commitment.Status.needsReview)
    #expect(String(decoding: encoded, as: UTF8.self) == "\"needsReview\"")
}

@Test func evidenceAndReviewItemRetainLinksAndRoundTrip() throws {
    let id = UUID()
    let evidence = Evidence(
        commitmentId: id, sourceMessageId: "source-1", excerpt: "Let's meet Friday.",
        source: .share, capturedAt: timestamp
    )
    #expect(evidence.commitmentId == id)
    #expect(evidence.sourceMessageId == "source-1")
    #expect(evidence.excerpt == "Let's meet Friday.")
    #expect(evidence.source == .share)
    #expect(evidence.capturedAt == timestamp)
    try expectRoundTrip(evidence)

    let review = ReviewItem(commitmentId: id, reason: "Ambiguous time")
    #expect(review.commitmentId == id)
    #expect(review.reason == "Ambiguous time")
    try expectRoundTrip(review)
}

@Test func ledgerAndReceiptPreserveAuditFieldsAndRoundTrip() throws {
    let ledger = LedgerEntry(
        timestamp: timestamp, destinationModelId: "test-model", regions: ["AU", "US"],
        byteCount: 42, redactedPayloadPreview: "Person A: task t3"
    )
    #expect(ledger.timestamp == timestamp)
    #expect(ledger.destinationModelId == "test-model")
    #expect(ledger.regions == ["AU", "US"])
    #expect(ledger.byteCount == 42)
    #expect(ledger.redactedPayloadPreview == "Person A: task t3")
    try expectRoundTrip(ledger)

    let id = UUID()
    let receipt = ActionReceipt(
        commitmentId: id, action: .createReminder, providerId: "reminder-1", result: "created"
    )
    #expect(receipt.commitmentId == id)
    #expect(receipt.action == .createReminder)
    #expect(receipt.providerId == "reminder-1")
    #expect(receipt.result == "created")
    try expectRoundTrip(receipt)
}

@Test func planningTypesAndItemRefRoundTrip() throws {
    let id = UUID()
    let item = ItemRef(ref: "t3", commitmentId: id, title: "Task A", kind: .commitment, status: .tentative)
    #expect(item.ref == "t3")
    #expect(item.commitmentId == id)
    #expect(item.title == "Task A")
    #expect(item.kind == .commitment)
    #expect(item.status == .tentative)
    try expectRoundTrip(item)

    let request = PseudonymisedPlanRequest(items: [item], instructions: "Prioritise Task A")
    #expect(request.items == [item])
    #expect(request.instructions == "Prioritise Task A")
    try expectRoundTrip(request)

    let response = PlanResponse(summary: "Start with t3", orderedRefs: ["t3"])
    #expect(response.summary == "Start with t3")
    #expect(response.orderedRefs == ["t3"])
    try expectRoundTrip(response)
    try expectRoundTrip(PseudonymisedPlanRequest(items: [], instructions: ""))
    try expectRoundTrip(PlanResponse(summary: "", orderedRefs: []))
}

@Test func extractionDTOAndResultMirrorWireContract() throws {
    let item = ExtractionDTO(
        title: "Lunch", kind: .event, tentative: true, dueText: "tomorrow",
        actor: "Alex", evidence: "Maybe lunch tomorrow?", updatesRef: "t3"
    )
    let result = ExtractionResult(relevance: .uncertain, change: .rescheduled, items: [item])
    let json = """
    {
      "relevance": "uncertain", "change": "rescheduled",
      "items": [{"title": "Lunch", "kind": "event", "tentative": true,
                 "dueText": "tomorrow", "actor": "Alex",
                 "evidence": "Maybe lunch tomorrow?", "updatesRef": "t3"}]
    }
    """
    let decoded = try JSONDecoder().decode(ExtractionResult.self, from: Data(json.utf8))
    #expect(decoded == result)
    try expectRoundTrip(item)
    try expectRoundTrip(result)
    try expectRoundTrip(ExtractionResult(relevance: .none, change: .none, items: []))
    try expectRoundTrip(ExtractionDTO(
        title: "Call", kind: .commitment, tentative: false, dueText: "",
        actor: "me", evidence: "I will call you.", updatesRef: ""
    ))
}

@Test func calendarModelsPreserveFieldsAndRoundTrip() throws {
    let end = timestamp.addingTimeInterval(86_400)
    let draft = EventDraft(
        title: "Conference", start: timestamp, end: end, timezone: "Australia/Sydney",
        isAllDay: true, notes: "Bring notes"
    )
    #expect(draft.title == "Conference")
    #expect(draft.start == timestamp)
    #expect(draft.end == end)
    #expect(draft.timezone == "Australia/Sydney")
    #expect(draft.isAllDay)
    #expect(draft.notes == "Bring notes")
    try expectRoundTrip(draft)

    let event = CalendarEvent(
        id: "event-1", title: "Conference", start: timestamp, end: end,
        timezone: "Australia/Sydney", isAllDay: true, notes: "Bring notes"
    )
    #expect(event.id == "event-1")
    #expect(event.title == draft.title)
    #expect(event.start == draft.start)
    #expect(event.end == draft.end)
    #expect(event.timezone == draft.timezone)
    #expect(event.isAllDay == draft.isAllDay)
    #expect(event.notes == draft.notes)
    try expectRoundTrip(event)
}

@Test func calendarModelDefaultsRoundTrip() throws {
    let end = timestamp.addingTimeInterval(60)
    let draft = EventDraft(title: "Call", start: timestamp, end: end, timezone: "UTC")
    let event = CalendarEvent(id: "1", title: "Call", start: timestamp, end: end, timezone: "UTC")
    #expect(!draft.isAllDay)
    #expect(draft.notes == nil)
    #expect(!event.isAllDay)
    #expect(event.notes == nil)
    try expectRoundTrip(draft)
    try expectRoundTrip(event)
}
