import Foundation
import Testing
import RecalledCore

private let candidateID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
private let existingID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
private let reviewID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
private let otherReviewID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
private let siblingReviewID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
private let messageReviewID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
private let newID = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
private let start = Date(timeIntervalSince1970: 1_792_800_000)
private let schedule = ReviewSchedule(start: start, end: start.addingTimeInterval(3_600),
    timezone: "Australia/Sydney", dueText: "Selected date")

private func item(id: UUID = candidateID, status: Commitment.Status = .needsReview,
                  dated: Bool = true) -> Commitment {
    Commitment(id: id, title: "Send revised proposal", kind: .commitment, status: status,
        actor: "Alex", dueText: dated ? "Friday" : "",
        dueStart: dated ? start : nil, dueEnd: dated ? start.addingTimeInterval(1_800) : nil,
        timezone: dated ? "Australia/Sydney" : nil, version: 3, calendarEventId: "provider-id")
}

private func row(_ id: UUID = reviewID, candidate: UUID? = candidateID) -> ReviewResolver.Row {
    ReviewResolver.Row(id: id, commitmentID: candidate, sourceMessageID: "message-1", sender: "Alex")
}

private let reviews = [row(), row(siblingReviewID), row(otherReviewID, candidate: existingID),
                       row(messageReviewID, candidate: nil)]

private func resolve(_ action: ReviewAction, candidate: Commitment = item()) throws -> ReviewResolver.Resolution {
    try ReviewResolver.resolve(id: reviewID, action: action, reviews: reviews,
        commitments: [candidate, item(id: existingID, status: .confirmed)])
}

@Test func reviewConfirmWithAndWithoutDatePreservesFields() throws {
    for dated in [true, false] {
        let original = item(dated: dated)
        let result = try resolve(.confirm, candidate: original)
        var expected = original
        expected.status = .confirmed
        expected.version += 1
        #expect(result.updates == [expected])
        #expect(result.created == nil)
        #expect(result.evidenceChange == .none)
        #expect(result.removedReviewIDs == [reviewID, siblingReviewID])
        #expect(original.status == .needsReview)
        #expect(original.version == 3)
    }
}

@Test func reviewConfirmValidatesOnlyAnExistingSchedule() throws {
    var candidate = item()
    candidate.dueEnd = start
    #expect(throws: ReviewActionError.invalidSchedule) { try resolve(.confirm, candidate: candidate) }
    candidate.dueEnd = start.addingTimeInterval(-1)
    #expect(throws: ReviewActionError.invalidSchedule) { try resolve(.confirm, candidate: candidate) }
    candidate.dueEnd = nil
    #expect(try resolve(.confirm, candidate: candidate).updates.first?.status == .confirmed)
    candidate.dueStart = nil
    #expect(try resolve(.confirm, candidate: candidate).updates.first?.dueStart == nil)
}

@Test func reviewEditReplacesScheduleAndConfirms() throws {
    for end in [schedule.end, nil] {
        let selected = ReviewSchedule(start: start, end: end, timezone: "UTC", dueText: "User date")
        let original = item()
        let result = try resolve(.edit(selected), candidate: original)
        var expected = original
        expected.dueStart = selected.start
        expected.dueEnd = selected.end
        expected.timezone = selected.timezone
        expected.dueText = selected.dueText
        expected.status = .confirmed
        expected.version += 1
        #expect(result.updates == [expected])
        #expect(result.removedReviewIDs == [reviewID, siblingReviewID])
        #expect(result.evidenceChange == .none)
        #expect(result.created == nil)
    }
}

@Test func reviewDismissCancelsOpenCandidateAndRemovesItsReasons() throws {
    let original = item()
    let result = try resolve(.dismiss, candidate: original)
    var expected = original
    expected.status = .cancelled
    expected.version += 1
    #expect(result.updates == [expected])
    #expect(result.removedReviewIDs == [reviewID, siblingReviewID])
    #expect(result.evidenceChange == .none)
    #expect(result.created == nil)
}

@Test func reviewDismissMessageOrOrphanRemovesOnlySelectedRow() throws {
    for selectedID in [reviewID, messageReviewID] {
        let result = try ReviewResolver.resolve(id: selectedID, action: .dismiss,
            reviews: reviews, commitments: [])
        #expect(result.updates.isEmpty)
        #expect(result.created == nil)
        #expect(result.evidenceChange == .none)
        #expect(result.removedReviewIDs == [selectedID])
    }
}

@Test func reviewDismissClosedCandidateDoesNotChangeIt() throws {
    for status in [Commitment.Status.completed, .cancelled, .superseded] {
        let result = try resolve(.dismiss, candidate: item(status: status))
        #expect(result.updates.isEmpty)
        #expect(result.removedReviewIDs == [reviewID, siblingReviewID])
    }
}

@Test func reviewMergeKeepsExistingIdentityAndBumpsBothVersions() throws {
    for dated in [true, false] {
        let candidate = item(dated: dated)
        var existing = item(id: existingID, status: .tentative)
        existing.title = "Original title"
        existing.kind = .event
        existing.actor = "Sam"
        existing.calendarEventId = "existing-provider"
        existing.version = 7
        let result = try ReviewResolver.resolve(id: reviewID, action: .merge(existingID: existingID),
            reviews: reviews, commitments: [candidate, existing])
        var expectedExisting = existing
        expectedExisting.dueText = candidate.dueText
        expectedExisting.dueStart = candidate.dueStart
        expectedExisting.dueEnd = candidate.dueEnd
        expectedExisting.timezone = candidate.timezone
        expectedExisting.version = 8
        var expectedCandidate = candidate
        expectedCandidate.status = .superseded
        expectedCandidate.version = 4
        #expect(result.updates == [expectedCandidate, expectedExisting])
        #expect(result.evidenceChange == .reparent(from: candidateID, to: existingID))
        #expect(result.removedReviewIDs == [reviewID, siblingReviewID])
        #expect(result.created == nil)
        #expect(candidate.status == .needsReview)
        #expect(existing.version == 7)
    }
}

@Test func reviewCreateWithAndWithoutDateRemovesOnlySelectedMessageReview() throws {
    let messageRows = [row(reviewID, candidate: nil), row(otherReviewID, candidate: nil), row(siblingReviewID)]
    for selected in [schedule, nil] {
        let action = ReviewAction.create(id: newID, title: "  Revised proposal\n", kind: .deadline, schedule: selected)
        let result = try ReviewResolver.resolve(id: reviewID, action: action,
            reviews: messageRows, commitments: [item()])
        let expected = Commitment(id: newID, title: "Revised proposal", kind: .deadline,
            status: .confirmed, actor: "Alex", dueText: selected?.dueText ?? "",
            dueStart: selected?.start, dueEnd: selected?.end, timezone: selected?.timezone)
        #expect(result.created == expected)
        #expect(result.updates.isEmpty)
        #expect(result.removedReviewIDs == [reviewID])
        #expect(result.evidenceChange == .copySource(messageID: "message-1", to: newID))
        // All randomness and display formatting are supplied by the caller.
        #expect(try ReviewResolver.resolve(id: reviewID, action: action,
            reviews: messageRows, commitments: [item()]) == result)
    }
}

@Test func reviewRejectsMissingReviewAndStaleCandidates() {
    #expect(throws: ReviewActionError.stale) {
        try ReviewResolver.resolve(id: reviewID, action: .dismiss, reviews: [], commitments: [item()])
    }
    for action in [ReviewAction.confirm, .edit(schedule), .merge(existingID: existingID)] {
        #expect(throws: ReviewActionError.stale) {
            try ReviewResolver.resolve(id: reviewID, action: action, reviews: reviews, commitments: [])
        }
        for status in [Commitment.Status.completed, .cancelled, .superseded] {
            #expect(throws: ReviewActionError.stale) { try resolve(action, candidate: item(status: status)) }
        }
    }
}

@Test func reviewCreateWithoutSourceMetadataDoesNotInventEvidence() throws {
    let source = ReviewResolver.Row(id: reviewID, commitmentID: nil, sourceMessageID: nil, sender: "")
    let result = try ReviewResolver.resolve(id: reviewID,
        action: .create(id: newID, title: "Proposal", kind: .commitment, schedule: nil),
        reviews: [source], commitments: [])
    #expect(result.evidenceChange == .none)
    #expect(result.created?.actor == "")
    #expect(result.created?.dueStart == nil)
    #expect(result.removedReviewIDs == [reviewID])
}

@Test func reviewMergeRejectsMissingSelfAndClosedTargets() {
    for target in [candidateID, newID] {
        #expect(throws: ReviewActionError.invalidTarget) { try resolve(.merge(existingID: target)) }
    }
    for status in [Commitment.Status.completed, .cancelled, .superseded] {
        #expect(throws: ReviewActionError.invalidTarget) {
            try ReviewResolver.resolve(id: reviewID, action: .merge(existingID: existingID),
                reviews: reviews, commitments: [item(), item(id: existingID, status: status)])
        }
    }
}

@Test func reviewCreateRejectsLinkedReviewIDCollisionAndBlankTitle() {
    let action = ReviewAction.create(id: newID, title: "Proposal", kind: .commitment, schedule: nil)
    for commitments in [[], [item()]] {
        #expect(throws: ReviewActionError.stale) {
            try ReviewResolver.resolve(id: reviewID, action: action, reviews: reviews, commitments: commitments)
        }
    }
    #expect(throws: ReviewActionError.stale) {
        try ReviewResolver.resolve(id: messageReviewID, action: action,
            reviews: reviews, commitments: [item(id: newID)])
    }
    #expect(throws: ReviewActionError.invalidTitle) {
        try ReviewResolver.resolve(id: messageReviewID,
            action: .create(id: newID, title: " \n\t", kind: .commitment, schedule: nil),
            reviews: reviews, commitments: [])
    }
}

@Test func reviewEditAndCreateRejectInvalidSchedule() {
    let invalid = ReviewSchedule(start: start, end: start, timezone: "UTC", dueText: "Invalid")
    #expect(throws: ReviewActionError.invalidSchedule) { try resolve(.edit(invalid)) }
    #expect(throws: ReviewActionError.invalidSchedule) {
        try ReviewResolver.resolve(id: messageReviewID,
            action: .create(id: newID, title: "Proposal", kind: .commitment, schedule: invalid),
            reviews: reviews, commitments: [])
    }
}

@Test func reviewVersionOverflowRejectsWholeResolution() {
    var candidate = item()
    candidate.version = Int.max
    for action in [ReviewAction.confirm, .edit(schedule), .dismiss, .merge(existingID: existingID)] {
        #expect(throws: ReviewActionError.versionLimit) { try resolve(action, candidate: candidate) }
    }
    var existing = item(id: existingID)
    existing.version = Int.max
    #expect(throws: ReviewActionError.versionLimit) {
        try ReviewResolver.resolve(id: reviewID, action: .merge(existingID: existingID),
            reviews: reviews, commitments: [item(), existing])
    }
    #expect(candidate.status == .needsReview)
    #expect(existing.version == Int.max)
}

@Test func reviewOpenStatusMatchesAvailableActions() {
    for status in Commitment.Status.allCases {
        #expect(item(status: status).isOpenForReview ==
            ![Commitment.Status.completed, .cancelled, .superseded].contains(status))
    }
}

@Test func reviewErrorsHaveUserFacingDescriptions() {
    let errors: [ReviewActionError] = [.stale, .invalidSchedule, .invalidTitle, .invalidTarget, .versionLimit]
    for error in errors { #expect(error.errorDescription?.isEmpty == false) }
}
