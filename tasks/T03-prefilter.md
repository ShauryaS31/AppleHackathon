# T03: Normaliser, quote and signature stripper, rules prefilter

| Field | Value |
|---|---|
| Status | in_progress |
| Milestone | M1 |
| Window | Sat 24 Oct, 10:45 to 11:30 |
| Depends on | T02 |
| Assignee | codex |
| Branch | task/T03-prefilter |

## Goal
Cut most messages before they reach the model, and shrink the rest.

## Read
AGENTS.md; docs/SPEC.md: SPEC 7, step 0 and 1; 7.4 input budget

## Acceptance criteria
- [ ] `Normaliser` collapses whitespace, strips HTML tags, removes tracking URLs over 200 chars
- [ ] `QuoteStripper` removes quoted reply history (lines starting with '>' and blocks after 'On ... wrote:' in English) and common signatures ('-- ', 'Sent from my iPhone')
- [ ] `Prefilter.decide(message)` returns skip, model, or review. Skip when: Gmail labels include SPAM, TRASH, DRAFT, CATEGORY_PROMOTIONS, CATEGORY_SOCIAL; or a List-Unsubscribe header is present and NSDataDetector finds no date; or no date signal and no request phrase (list of about 20 phrases like 'can you', 'please', 'due', 'deadline', 'remind', 'rsvp')
- [ ] Review when stripped text exceeds about 2,500 tokens (estimate 4 chars per token)
- [ ] At least 15 unit tests with realistic fixtures, including a newsletter, a ticket email, a WhatsApp-style text and a long thread

### Added by manager (2026-10-23)
- [ ] `Prefilter.decide` reads Gmail labels and headers from `SourceMessage.labels` and `SourceMessage.headers` (header name match is case insensitive)
- [ ] The request phrase list is a single public static array so it can be tuned in one place

## Windows mode
The developer runs on Windows with no Swift toolchain and no Xcode. Do not try to install them. Write the code and tests carefully, state in the Dev Report that the verify commands could not be run locally, and do not claim they passed. The manager pushes the branch and the gate is GitHub Actions: `core-tests` must be green on `task/T03-prefilter`.

## Verify
```
swift test --package-path RecalledCore
```

## Out of scope
Model calls.

<!-- Developer appends "## Dev Report (round n)" below. Manager appends "## Review (round n)" below. Never delete earlier rounds. -->

## Dev Report (round 1)
- Date: 2026-10-23 14:06 AEDT
- Changed files: `RecalledCore/Sources/RecalledCore/Normaliser.swift`, `RecalledCore/Sources/RecalledCore/QuoteStripper.swift`, `RecalledCore/Sources/RecalledCore/Prefilter.swift`, `RecalledCore/Tests/RecalledCoreTests/PrefilterTests.swift`, `tasks/T03-prefilter.md`, `docs/LOG.md` (completion entry).
- What I did: Added Foundation-only text preprocessing and a stateless prefilter. HTML block boundaries and original line breaks survive until reply/signature stripping; final whitespace is collapsed. `preparedText` exposes the subject plus cleaned body for downstream extraction. Date detection uses `NSDataDetector` only as a boolean signal; there are no model calls or date computations. Request matching ignores case and respects word boundaries.
- Acceptance criteria (implementation and test coverage; tests have NOT been executed locally):
  - Normaliser collapses whitespace, strips HTML tags and removes long tracking URLs: covered by `normaliserCollapsesWhitespaceIncludingUnicode`, `normaliserRemovesHTMLAndPreservesWordBoundaries`, `normaliserRemovesLongTrackingURLsButRetainsShortLinks`, and `normaliserURLCutoffIsStrictlyGreaterThan200Characters`. The documented URL heuristic removes all HTTP(S) URLs longer than 200 characters.
  - QuoteStripper removes quoted lines, English reply blocks and common signatures: covered by `quoteStripperRemovesQuotedLinesButKeepsInlineReplies`, `quoteStripperRemovesEnglishReplyBlock`, `quoteStripperRemovesStandardSignature`, `quoteStripperRemovesIPhoneSignatureAndFollowingText`, and the HTML/CRLF fixtures.
  - Prefilter returns skip/model/review and implements the label, unsubscribe/date and request/date rules: covered by `prefilterSkipsEachExcludedGmailLabelEvenWithDateAndRequest`, `prefilterSkipsNewsletterWithUnsubscribeAndNoDateEvenWithRequest`, `prefilterRetainsDatedTicketEmailDespiteUnsubscribeHeader`, `prefilterRetainsDateWithoutRequestPhrase`, and `prefilterSkipsChatterWithoutDateOrRequest`.
  - Review above approximately 2,500 tokens: uses a strict greater-than-10,000-character threshold, including the subject. Covered by `prefilterBudgetBoundaryIncludesSubject`, `prefilterReviewsLongUnquotedMessageWithoutTruncation`, `prefilterUsesCharacterCountRatherThanUTF8ByteCountForBudget`, and `prefilterShrinksLongThreadBeforeCheckingBudget`.
  - At least 15 realistic unit tests: 38 new `@Test` functions counted by PowerShell, including the newsletter, ticket, WhatsApp-style shared message and long-thread fixtures.
  - Labels/headers read from SourceMessage, with case-insensitive header names: covered by the excluded-label test, `prefilterMatchesUnsubscribeHeaderCaseInsensitivelyAndByPresence`, and `prefilterDoesNotConfuseOtherHeadersWithUnsubscribe`.
  - Request phrases defined in one public static array: `Prefilter.requestPhrases` contains 20 entries; `prefilterUsesEveryPublicRequestPhrase` exercises every entry.
- Verify commands run and results: Attempted `swift test --package-path RecalledCore`; PowerShell returned CommandNotFoundException because Swift is unavailable. No Swift compilation or tests ran, and no toolchain was installed. `git diff --check` passed for tracked changes at the time of the check. Separate PowerShell static checks of all four new Swift files found no trailing whitespace or forbidden Core imports.
- Not done / risks / questions for the manager: GitHub Actions `core-tests` must be green on `task/T03-prefilter`; compilation and actual Apple date-detector behaviour remain unverified locally. Label exclusions take precedence over the input budget; all other oversized inputs go to Review before content-based skip rules, preserving long messages without truncation. HTML cleanup is a lightweight text transformation rather than a full HTML parser, and English reply markers are recognised on a single line. No changes outside T03 implementation and completion records.
- Commit result: `git add` succeeded and `git diff --cached --check` passed, but `git commit -m "T03: add message normalisation and rules prefilter"` failed with `fatal: Unable to create 'C:/Users/User/Desktop/projects/AppleHackathon/.git/index.lock': Permission denied`. Everything remains uncommitted because the sandbox prevents the required Git write. The manager must stage the final report/log updates, commit, push and check CI. Stopped without retrying or changing permissions.
