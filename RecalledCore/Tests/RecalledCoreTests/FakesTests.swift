import Foundation
import Testing
import RecalledCore

private func message(id: String) -> SourceMessage {
    SourceMessage(
        id: id, source: .seed, sender: "Alex", sentAt: Date(timeIntervalSince1970: 0),
        subject: "Lunch", body: "Lunch tomorrow?"
    )
}

@Test func fakeExtractorReturnsScriptsAndConfigurableFallbackThroughProtocol() async throws {
    let item = ExtractionDTO(
        title: "Lunch", kind: .event, tentative: true, dueText: "tomorrow",
        actor: "Alex", evidence: "Lunch tomorrow?", updatesRef: "t3"
    )
    let scripted = ExtractionResult(relevance: .relevant, change: .updated, items: [item])
    let fallback = ExtractionResult(relevance: .uncertain, change: .noChange, items: [])
    let fake = FakeExtractor(resultsByMessageID: ["scripted": scripted], defaultResult: fallback)
    let extractor: any CommitmentExtractor = fake
    let openItems = [ItemRef(
        ref: "t3", commitmentId: UUID(), title: "Lunch", kind: .event, status: .tentative
    )]
    let result = try await extractor.extract(message(id: "scripted"), openItems: openItems)
    let missing = try await extractor.extract(message(id: "missing"), openItems: [])
    let repeated = try await extractor.extract(message(id: "scripted"), openItems: [])
    #expect(result == scripted)
    #expect(missing == fallback)
    #expect(repeated == scripted)
    let decoded = try JSONDecoder().decode(FakeExtractor.self, from: JSONEncoder().encode(fake))
    #expect(decoded == fake)
}

@Test func defaultFakeExtractorReturnsNoRelevantItems() async throws {
    let result = try await FakeExtractor().extract(message(id: "unknown"), openItems: [])
    #expect(result == ExtractionResult(relevance: .irrelevant, change: .noChange, items: []))
}

@Test func inMemoryCalendarStoreCreatesDistinctEventsAndPreservesDrafts() async throws {
    let store: any CalendarStore = InMemoryCalendarStore()
    let start = Date(timeIntervalSince1970: 1_000)
    let end = start.addingTimeInterval(86_400)
    let range = DateInterval(start: start, end: end)
    let initial = try await store.events(in: range)
    #expect(initial.isEmpty)

    let draft = EventDraft(
        title: "Conference", start: start, end: end, timezone: "Australia/Sydney",
        isAllDay: true, notes: "Approved by user"
    )
    let firstID = try await store.create(draft)
    let secondID = try await store.create(draft)
    #expect(firstID == "fake-1")
    #expect(secondID == "fake-2")
    let events = try await store.events(in: range)
    #expect(events == [firstID, secondID].map { id in
        CalendarEvent(
            id: id, title: draft.title, start: draft.start, end: draft.end,
            timezone: draft.timezone, isAllDay: draft.isAllDay, notes: draft.notes
        )
    })
    let otherStore = InMemoryCalendarStore()
    let otherEvents = try await otherStore.events(in: range)
    #expect(otherEvents.isEmpty)
    let otherID = try await otherStore.create(draft)
    #expect(otherID == "fake-1")
}

@Test func inMemoryCalendarStoreSkipsSeededProviderIDs() async throws {
    let start = Date(timeIntervalSince1970: 0)
    let end = start.addingTimeInterval(60)
    let seed = ["fake-1", "fake-3"].map {
        CalendarEvent(id: $0, title: "Seed", start: start, end: end, timezone: "UTC")
    }
    let store = InMemoryCalendarStore(events: seed)
    let draft = EventDraft(title: "New", start: start, end: end, timezone: "UTC")
    let firstID = try await store.create(draft)
    let secondID = try await store.create(draft)
    #expect(firstID == "fake-2")
    #expect(secondID == "fake-4")
    let events = try await store.events(in: DateInterval(start: start, end: end))
    #expect(events.map(\.id) == ["fake-1", "fake-3", "fake-2", "fake-4"])
}

@Test func fakeExtractorThrowsScriptedErrorThroughProtocol() async throws {
    let error = FakeServiceError.scripted("Extraction failed")
    let result = ExtractionResult(relevance: .relevant, change: .new, items: [])
    let fake = FakeExtractor(resultsByMessageID: ["failed": result], errorsByMessageID: ["failed": error])
    let decoded = try JSONDecoder().decode(FakeExtractor.self, from: JSONEncoder().encode(fake))
    #expect(decoded == fake)
    let extractor: any CommitmentExtractor = decoded
    await #expect(throws: error) {
        try await extractor.extract(message(id: "failed"), openItems: [])
    }
    let fallback = try await extractor.extract(message(id: "other"), openItems: [])
    #expect(fallback == fake.defaultResult)
}

@Test func fakePlanningModelThrowsScriptedErrorThroughProtocol() async throws {
    let error = FakeServiceError.scripted("Planning failed")
    let fake = FakePlanningModel(regions: ["AU"], error: error)
    let decoded = try JSONDecoder().decode(FakePlanningModel.self, from: JSONEncoder().encode(fake))
    #expect(decoded == fake)
    let model: any PlanningModel = decoded
    #expect(model.regions == ["AU"])
    await #expect(throws: error) {
        try await model.plan(PseudonymisedPlanRequest(items: [], instructions: "Prioritise"))
    }
}

@Test func inMemoryCalendarStoreFiltersOverlapsAndBoundaryTouches() async throws {
    func event(_ id: String, _ start: TimeInterval, _ end: TimeInterval) -> CalendarEvent {
        CalendarEvent(
            id: id, title: id, start: Date(timeIntervalSince1970: start),
            end: Date(timeIntervalSince1970: end), timezone: "UTC"
        )
    }
    let seed = [
        event("before", 0, 5), event("endsAtStart", 5, 10),
        event("overlapsStart", 5, 15), event("inside", 12, 18),
        event("covers", 0, 30), event("exact", 10, 20),
        event("overlapsEnd", 15, 25), event("startsAtEnd", 20, 25),
        event("after", 25, 30), event("empty", 15, 15), event("reversed", 18, 12)
    ]
    let store = InMemoryCalendarStore(events: seed)
    let range = DateInterval(start: Date(timeIntervalSince1970: 10), end: Date(timeIntervalSince1970: 20))
    let events = try await store.events(in: range)
    #expect(events.map(\.id) == ["overlapsStart", "inside", "covers", "exact", "overlapsEnd"])
    let repeated = try await store.events(in: range)
    #expect(repeated == events)
    let empty = try await store.events(in: DateInterval(start: range.start, duration: 0))
    #expect(empty.isEmpty)
}

@Test func fakePlanningModelExposesConfiguredRegionsAndResponseThroughProtocol() async throws {
    let response = PlanResponse(summary: "Start with t3", orderedRefs: ["t3", "t1"])
    let fake = FakePlanningModel(regions: ["AU", "US"], response: response)
    let model: any PlanningModel = fake
    #expect(model.regions == ["AU", "US"])
    let result = try await model.plan(PseudonymisedPlanRequest(items: [], instructions: "Prioritise"))
    #expect(result == response)
    let decoded = try JSONDecoder().decode(FakePlanningModel.self, from: JSONEncoder().encode(fake))
    #expect(decoded == fake)

    let defaultModel = FakePlanningModel()
    #expect(defaultModel.regions.isEmpty)
    let defaultResponse = try await defaultModel.plan(PseudonymisedPlanRequest(items: [], instructions: ""))
    #expect(defaultResponse == PlanResponse(summary: "", orderedRefs: []))
}

@Test func silentSpeechAcceptsEmptyAndNonemptyTextThroughProtocol() async throws {
    let fake = SilentSpeech()
    let speech: any Speech = fake
    try await speech.speak("")
    try await speech.speak("Your plan is ready.")
    let decoded = try JSONDecoder().decode(SilentSpeech.self, from: JSONEncoder().encode(fake))
    #expect(decoded == fake)
}
