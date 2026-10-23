import Foundation
import Testing
@testable import RecalledCore

private struct PrivacyFixture: Sendable {
    let text: String
    let originals: [String]
    let types: [String]
}

private let privacyFixtures: [PrivacyFixture] = [
    .init(
        text: "The American Red Cross was established in Washington, D.C., by Clara Barton.",
        originals: ["American Red Cross", "Clara Barton"], types: ["O", "P"]
    ),
    .init(
        text: "Barack Obama met Angela Merkel. Barack Obama spoke again.",
        originals: ["Barack Obama", "Angela Merkel"], types: ["P"]
    ),
    .init(text: "Please email alex@example.com.", originals: ["alex@example.com"], types: ["E"]),
    .init(
        text: "Send to team+planning@example.org, then team+planning@example.org again.",
        originals: ["team+planning@example.org"], types: ["E"]
    ),
    .init(
        text: "Reply to first@example.com or second@example.net.",
        originals: ["first@example.com", "second@example.net"], types: ["E"]
    ),
    .init(text: "Call +1 (415) 555-0123.", originals: ["+1 (415) 555-0123"], types: ["T"]),
    .init(text: "Call +61 2 9374 4000.", originals: ["+61 2 9374 4000"], types: ["T"]),
    .init(
        text: "Deliver to 1 Infinite Loop, Cupertino, CA 95014.",
        originals: ["1 Infinite Loop"], types: ["A"]
    ),
    .init(
        text: "Meet at 350 Fifth Avenue, New York, NY 10118.",
        originals: ["350 Fifth Avenue"], types: ["A"]
    ),
    .init(
        text: "📬 Send the résumé to zoe@example.com.\n☎️ Call +1 (212) 555-0199.",
        originals: ["zoe@example.com", "+1 (212) 555-0199"], types: ["E", "T"]
    )
]

// These exercise real Apple recognition, not a mocked detector. CI on macOS is
// required: model/locale changes must not silently weaken the privacy fixtures.
@Test private func tenFixturesRemoveOriginalsAndRoundTrip() throws {
    #expect(privacyFixtures.count == 10)
    for fixture in privacyFixtures {
        let result = try Pseudonymiser.pseudonymise(fixture.text)
        #expect(!result.map.isEmpty)
        #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == fixture.text)
        for original in fixture.originals {
            #expect(!result.text.contains(original), "Original remains: \(original)")
            #expect(result.map.values.contains(where: { $0.contains(original) }))
        }
        for original in result.map.values {
            #expect(!result.text.contains(original))
        }
        for type in fixture.types {
            #expect(result.map.keys.contains(where: { $0.hasPrefix("[" + type) }))
        }
    }
}

@Test func repeatedNameUsesOnePlaceholder() throws {
    let text = "Barack Obama met Angela Merkel. Barack Obama spoke again."
    let result = try Pseudonymiser.pseudonymise(text)
    #expect(result.map["[P1]"] == "Barack Obama")
    #expect(result.map["[P2]"] == "Angela Merkel")
    #expect(result.text == "[P1] met [P2]. [P1] spoke again.")
    #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == text)
}

@Test func detectedEmailsNumberInAppearanceOrderAndResetBetweenCalls() throws {
    let result = try Pseudonymiser.pseudonymise("z@example.com, a@example.com, z@example.com")
    #expect(result.text == "[E1], [E2], [E1]")
    #expect(result.map == ["[E1]": "z@example.com", "[E2]": "a@example.com"])
    let next = try Pseudonymiser.pseudonymise("a@example.com")
    #expect(next.text == "[E1]")
    #expect(next.map == ["[E1]": "a@example.com"])
}

@Test func emptyAndNonPersonalTextAreUnchanged() throws {
    for text in ["", "send the report tomorrow", "📚\n\t", "https://example.com"] {
        let result = try Pseudonymiser.pseudonymise(text)
        #expect(result.text == text)
        #expect(result.map.isEmpty)
        #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == text)
    }
}

@Test func existingPlaceholdersAreRejectedWithoutAnAmbiguousMap() {
    for token in ["[P1]", "[O2]", "[E3]", "[T4]", "[A10]"] {
        #expect(throws: Pseudonymiser.Failure.reservedPlaceholderInInput) {
            try Pseudonymiser.pseudonymise("Keep \(token) and email alex@example.com")
        }
    }
}

@Test func rehydrationUsesWholeTokensAndDoesNotCascade() {
    let map = ["[P1]": "[O1]", "[O1]": "Original organisation", "[P10]": "Tenth person"]
    #expect(Pseudonymiser.rehydrate("[P1] [P10] [O1] [P1] [P2]", map: map) ==
            "[O1] Tenth person Original organisation [O1] [P2]")
    #expect(Pseudonymiser.rehydrate("[P1]", map: [:]) == "[P1]")
    #expect(Pseudonymiser.rehydrate("", map: map).isEmpty)
    #expect(Pseudonymiser.rehydrate("[P0] [P01] [X1] P1", map: map) == "[P0] [P01] [X1] P1")
}

private func entity(_ original: String, in text: String, kind: Pseudonymiser.Kind) -> Pseudonymiser.Entity {
    Pseudonymiser.Entity(range: (text as NSString).range(of: original), kind: kind)
}

@Test func numberingIsPerTypeAndUsesAppearanceNotDetectionOrder() throws {
    let text = "Zoe; Zen Co; z@example.com; +1 415 555 0123; 12 Main St; Amy; Apex Co; a@example.com; +1 212 555 0199; 8 Oak St; Zoe; Zen Co; z@example.com; +1 415 555 0123; 12 Main St"
    let originals: [(String, Pseudonymiser.Kind)] = [
        ("Zoe", .person), ("Zen Co", .organisation), ("z@example.com", .email),
        ("+1 415 555 0123", .telephone), ("12 Main St", .address),
        ("Amy", .person), ("Apex Co", .organisation), ("a@example.com", .email),
        ("+1 212 555 0199", .telephone), ("8 Oak St", .address)
    ]
    let entities = originals.reversed().map { entity($0.0, in: text, kind: $0.1) }
    let result = try Pseudonymiser.redact(text, entities: entities)
    #expect(result.text == "[P1]; [O1]; [E1]; [T1]; [A1]; [P2]; [O2]; [E2]; [T2]; [A2]; [P1]; [O1]; [E1]; [T1]; [A1]")
    #expect(result.map.count == 10)
    for (index, original) in originals.enumerated() {
        #expect(result.map["[\(original.1.rawValue)\(index / 5 + 1)]"] == original.0)
    }
    #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == text)
}

@Test func longerNamesAndDetectorSpansWinOverOverlappingNames() throws {
    let text = "Ann Lee emailed ann@example.com from 12 Ann Street. Ann Lee called Ann."
    let entities = [
        entity("Ann", in: text, kind: .person),
        entity("Ann Lee", in: text, kind: .person),
        entity("ann@example.com", in: text, kind: .email),
        entity("ann", in: text, kind: .person),
        entity("12 Ann Street", in: text, kind: .address)
    ]
    let result = try Pseudonymiser.redact(text, entities: entities)
    #expect(result.text == "[P1] emailed [E1] from [A1]. [P1] called [P2].")
    #expect(result.map == [
        "[P1]": "Ann Lee", "[P2]": "Ann", "[E1]": "ann@example.com", "[A1]": "12 Ann Street"
    ])
    #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == text)
}

@Test func repeatsRespectWordBoundariesAndUnicodeRanges() throws {
    let text = "👩🏽‍💻 Zoe met Zoey. Zoé is different.\nZoe, send café notes to Élodie. Élodie agreed."
    let result = try Pseudonymiser.redact(text, entities: [
        entity("Zoe", in: text, kind: .person), entity("Élodie", in: text, kind: .person)
    ])
    #expect(result.text == "👩🏽‍💻 [P1] met Zoey. Zoé is different.\n[P1], send café notes to [P2]. [P2] agreed.")
    #expect(Pseudonymiser.rehydrate(result.text, map: result.map) == text)
}

@Test func concurrentCallsKeepIndependentMaps() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        for index in 0..<8 {
            group.addTask {
                let original = "person\(index)@example.com"
                let result = try Pseudonymiser.pseudonymise(original)
                #expect(result.text == "[E1]")
                #expect(result.map == ["[E1]": original])
            }
        }
        try await group.waitForAll()
    }
}
