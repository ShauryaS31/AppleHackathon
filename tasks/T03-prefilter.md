# T03: Normaliser, quote and signature stripper, rules prefilter

| Field | Value |
|---|---|
| Status | todo |
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
