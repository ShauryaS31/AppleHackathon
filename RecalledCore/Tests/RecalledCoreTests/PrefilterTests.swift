import Foundation
import Testing
import RecalledCore

private func message(
    _ body: String, subject: String = "", source: SourceMessage.Source = .gmail,
    labels: [String] = [], headers: [String: String] = [:]
) -> SourceMessage {
    SourceMessage(
        id: "prefilter-fixture", source: source, sender: "Alex <alex@example.com>",
        sentAt: Date(timeIntervalSince1970: 1_792_800_000), subject: subject,
        body: body, labels: labels, headers: headers
    )
}

@Test func normaliserCollapsesWhitespaceIncludingUnicode() {
    #expect(Normaliser.normalise(" \tPlease\r\n send\u{00A0}\u{2003}the   report. \n") == "Please send the report.")
}

@Test func normaliserRemovesHTMLAndPreservesWordBoundaries() {
    let html = "<div>Please <strong>confirm</strong></div><p>your booking.<br>Thanks!</p>"
    #expect(Normaliser.normalise(html) == "Please confirm your booking. Thanks!")
}

@Test func normaliserRemovesHTMLScriptsStylesAndComments() {
    let html = "<style>p { color: red }</style><script>please();</script><!-- deadline --><p>Hello!</p>"
    #expect(Normaliser.normalise(html) == "Hello!")
}

@Test func normaliserDecodesCommonHTMLEntities() {
    #expect(Normaliser.normalise("Alex&nbsp;&amp; Sam: &quot;RSVP&quot;&#39;s &lt;reply&gt;") == "Alex & Sam: \"RSVP\"'s <reply>")
}

@Test func normaliserRemovesLongTrackingURLsButRetainsShortLinks() {
    let tracking = "https://tracking.example/click?token=" + String(repeating: "a", count: 210)
    let body = "🎟️ Tickets \(tracking) details https://venue.example/tickets"
    #expect(Normaliser.normalise(body) == "🎟️ Tickets details https://venue.example/tickets")
}

@Test func normaliserURLCutoffIsStrictlyGreaterThan200Characters() {
    let prefix = "https://example.com/?id="
    let boundary = prefix + String(repeating: "a", count: 200 - prefix.count)
    #expect(Normaliser.normalise(boundary) == boundary)
    #expect(Normaliser.normalise(boundary + "a").isEmpty)
}

@Test func normaliserRemovesMultipleLongURLsUsingValidUnicodeRanges() {
    let url = "https://tracking.example/?id=" + String(repeating: "b", count: 220)
    #expect(Normaliser.normalise("👋 \(url) RSVP \(url) thanks") == "👋 RSVP thanks")
}

@Test func normaliserPreservesComparisonProse() {
    #expect(Normaliser.normalise("Please check 3 < 5 and 8 > 4") == "Please check 3 < 5 and 8 > 4")
}

@Test func quoteStripperRemovesQuotedLinesButKeepsInlineReplies() {
    let body = "> Can you send the report?\nAlready sent.\n  >> Please resend.\nI will check."
    #expect(QuoteStripper.strip(body) == "Already sent.\nI will check.")
}

@Test func quoteStripperRemovesEnglishReplyBlock() {
    let body = "Please use the updated venue.\n\nOn Fri, 23 Oct 2026, Alex <alex@example.com> wrote:\nOld venue\nMore history"
    #expect(QuoteStripper.strip(body) == "Please use the updated venue.")
}

@Test func quoteStripperRecognisesReplyMarkerCaseInsensitively() {
    #expect(QuoteStripper.strip("Thanks!\r\n ON Friday, Alex WROTE: \r\nPlease RSVP") == "Thanks!")
}

@Test func quoteStripperRetainsOrdinaryOnSentences() {
    let body = "On arrival, please check in.\nThe words On and wrote: appear in prose."
    #expect(QuoteStripper.strip(body) == body)
}

@Test func quoteStripperRemovesStandardSignature() {
    #expect(QuoteStripper.strip("Please confirm receipt.\n-- \nAlex Smith\nTeam lead") == "Please confirm receipt.")
}

@Test func quoteStripperRemovesIPhoneSignatureAndFollowingText() {
    #expect(QuoteStripper.strip("See you there!\n\nSent from my iPhone\nAlex") == "See you there!")
}

@Test func quoteStripperPreservesInlineSignatureWordsAndDashes() {
    let body = "Please add -- to the command.\nThe footer says Sent from my iPhone in this example."
    #expect(QuoteStripper.strip(body) == body)
}

@Test func quoteStripperUsesHTMLLineBreaksAndEncodedQuoteMarkers() {
    let html = "<p>All done.</p><div>&gt; Please RSVP</div><div>On Friday, Alex wrote:</div><p>Old request</p>"
    #expect(Normaliser.normalise(QuoteStripper.strip(html)) == "All done.")
}

@Test func emptyInputsAreEmptyAndSkipped() {
    #expect(Normaliser.normalise(" \n\t").isEmpty)
    #expect(QuoteStripper.strip("").isEmpty)
    #expect(Prefilter.preparedText(message("")).isEmpty)
    #expect(Prefilter.decide(message("")) == .skip)
}

@Test func prefilterSkipsEachExcludedGmailLabelEvenWithDateAndRequest() {
    for label in ["SPAM", "TRASH", "DRAFT", "CATEGORY_PROMOTIONS", "CATEGORY_SOCIAL"] {
        #expect(Prefilter.decide(message(
            "Please attend on October 24, 2026 at 7:00 PM.", labels: ["INBOX", label]
        )) == .skip)
    }
}

@Test func prefilterRetainsAllowedLabels() {
    #expect(Prefilter.decide(message("Please send the brief.", labels: ["INBOX", "IMPORTANT"])) == .model)
}

@Test func prefilterSkipsNewsletterWithUnsubscribeAndNoDateEvenWithRequest() {
    let newsletter = message(
        "<h1>The Weekly Edit</h1><p>Please explore our latest stories and exclusive offers.</p>",
        subject: "Our favourite reads", headers: ["List-Unsubscribe": "<mailto:leave@example.com>"]
    )
    #expect(Prefilter.decide(newsletter) == .skip)
}

@Test func prefilterMatchesUnsubscribeHeaderCaseInsensitivelyAndByPresence() {
    for name in ["list-unsubscribe", "LIST-UNSUBSCRIBE", "LiSt-UnSuBsCrIbE"] {
        #expect(Prefilter.decide(message("Please read our news.", headers: [name: ""])) == .skip)
    }
}

@Test func prefilterDoesNotConfuseOtherHeadersWithUnsubscribe() {
    #expect(Prefilter.decide(message(
        "Please read our news.", headers: ["X-List-Unsubscribe": "yes", "List-Unsubscribe-Post": "yes"]
    )) == .model)
}

@Test func prefilterRetainsDatedTicketEmailDespiteUnsubscribeHeader() {
    let ticket = message(
        "<p>Your concert tickets are attached.</p><p>October 24, 2026 at 7:00 PM</p><p>Door B, seat A12.</p>",
        subject: "Booking confirmation", headers: ["list-unsubscribe": "<https://tickets.example/unsubscribe>"]
    )
    #expect(Prefilter.decide(ticket) == .model)
}

@Test func prefilterRetainsWhatsAppStyleSharedText() {
    #expect(Prefilter.decide(message(
        "Alex: hey 👋\nCAN\t YOU bring the charger?\nSam: sure 👍", source: .share
    )) == .model)
}

@Test func prefilterRetainsDateWithoutRequestPhrase() {
    #expect(Prefilter.decide(message("Dinner: October 24, 2026 at 7:00 PM.")) == .model)
}

@Test func prefilterRetainsRelativeDateSignal() {
    #expect(Prefilter.decide(message("Lunch tomorrow at noon?")) == .model)
}

@Test func prefilterSkipsChatterWithoutDateOrRequest() {
    #expect(Prefilter.decide(message("Thanks for the photos! Great seeing everyone.")) == .skip)
}

@Test func prefilterUsesEveryPublicRequestPhrase() {
    #expect(Prefilter.requestPhrases.count == 20)
    #expect(Set(Prefilter.requestPhrases).count == Prefilter.requestPhrases.count)
    for phrase in Prefilter.requestPhrases {
        #expect(Prefilter.decide(message("Alex says: \(phrase.uppercased()) the report.")) == .model)
    }
}

@Test func prefilterDoesNotMatchRequestWordsInsideOtherWords() {
    #expect(Prefilter.decide(message("The duet was pleasing and the unconfirmed rumours faded.")) == .skip)
}

@Test func prefilterUsesSubjectForRequestAndDateSignals() {
    #expect(Prefilter.decide(message("The attached document is ready.", subject: "Action required")) == .model)
    #expect(Prefilter.decide(message(
        "Your seat is reserved.", subject: "October 24, 2026 at 7:00 PM", headers: ["List-Unsubscribe": ""]
    )) == .model)
}

@Test func prefilterIgnoresSignalsOnlyInQuotedHistoryAndSignature() {
    let bodies = [
        "Thanks!\n> Please attend on October 24, 2026 at 7:00 PM.",
        "Thanks!\nOn Friday, Alex wrote:\nPlease attend on October 24, 2026 at 7:00 PM.",
        "Thanks!\n-- \nPlease RSVP on October 24, 2026 at 7:00 PM.",
        "Thanks!\nSent from my iPhone\nPlease RSVP"
    ]
    for body in bodies {
        #expect(Prefilter.decide(message(body)) == .skip)
    }
}

@Test func prefilterShrinksLongThreadBeforeCheckingBudget() {
    let history = String(repeating: "Previous discussion and venue options.\n", count: 400)
    let thread = message("Please confirm the venue.\nOn Friday, Alex wrote:\n" + history)
    #expect(thread.body.count > Prefilter.maximumCharacters)
    #expect(Prefilter.preparedText(thread) == "Please confirm the venue.")
    #expect(Prefilter.decide(thread) == .model)
}

@Test func prefilterReviewsLongUnquotedMessageWithoutTruncation() {
    let body = "Please review: " + String(repeating: "Detailed project discussion. ", count: 400)
    let input = message(body)
    #expect(Prefilter.decide(input) == .review)
    #expect(Prefilter.preparedText(input) == body.trimmingCharacters(in: .whitespaces))
}

@Test func prefilterBudgetBoundaryIncludesSubject() {
    let body = "Please " + String(repeating: "a", count: 9_993)
    #expect(body.count == 10_000)
    #expect(Prefilter.decide(message(body)) == .model)
    #expect(Prefilter.decide(message(body + "a")) == .review)
    #expect(Prefilter.decide(message(body, subject: "Brief")) == .review)
}

@Test func prefilterUsesCharacterCountRatherThanUTF8ByteCountForBudget() {
    let body = "Please " + String(repeating: "🎟️", count: 9_993)
    #expect(body.count == 10_000)
    #expect(body.utf8.count > 10_000)
    #expect(Prefilter.decide(message(body)) == .model)
}

@Test func prefilterReviewsOversizedTextBeforeContentRulesButLabelsStillSkip() {
    let body = String(repeating: "a", count: 10_001)
    #expect(Prefilter.decide(message(body)) == .review)
    #expect(Prefilter.decide(message(body, headers: ["List-Unsubscribe": ""])) == .review)
    #expect(Prefilter.decide(message(body, labels: ["SPAM"])) == .skip)
}

@Test func prefilterMeasuresNormalisedInputAndRetainsSourceMessage() {
    let input = message("<p>Please</p>" + String(repeating: " \n", count: 6_000) + "confirm.\n-- \nAlex", subject: "Booking")
    let original = input
    #expect(Prefilter.preparedText(input) == "Booking Please confirm.")
    #expect(Prefilter.decide(input) == .model)
    #expect(input == original)
}

@Test func prefilterPreservesEscapedProseAfterStrippingHTMLOnce() {
    let input = message("<p>Please use &lt;reply&gt; &amp; confirm.</p>")
    #expect(Prefilter.preparedText(input) == "Please use <reply> & confirm.")
    #expect(Prefilter.decide(input) == .model)
}
