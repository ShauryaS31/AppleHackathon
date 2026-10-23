import Foundation
import RecalledCore
import SwiftData

enum Seed {
    private struct Item: Sendable {
        let title: String
        let sender: String
        let due: String
        let excerpt: String
        var kind: Commitment.Kind = .event
        var status: Commitment.Status = .confirmed
    }

    private static let items: [Item] = [
        Item(title: "Design catch-up", sender: "Email · Maya", due: "today at 9am",
             excerpt: "Let's have a design catch-up today at 9am."),
        Item(title: "Sprint check-in", sender: "Slack · Adit", due: "today at 10am",
             excerpt: "Sprint check-in today at 10am in the team room."),
        Item(title: "Coffee with Jess", sender: "WhatsApp · Jess", due: "today at 11am",
             excerpt: "Coffee today at 11am?", status: .tentative),
        Item(title: "Send proposal", sender: "Email · Sam", due: "today",
             excerpt: "Please send the proposal by today.", kind: .deadline),
        Item(title: "Review prototype", sender: "Slack · Priya", due: "today at 2pm",
             excerpt: "Let's review the prototype today at 2pm."),
        Item(title: "Pick up parcel", sender: "WhatsApp · Leo", due: "today at 4pm",
             excerpt: "I'll pick up the parcel today at 4pm.", kind: .commitment),
        Item(title: "Dinner at Bar Totti's", sender: "WhatsApp · Adit", due: "today at 7pm",
             excerpt: "Dinner moved to today at 7pm at Bar Totti's?", status: .tentative),
        Item(title: "Breakfast with Noah", sender: "WhatsApp · Noah", due: "tomorrow at 8am",
             excerpt: "Breakfast tomorrow at 8am at our usual place."),
        Item(title: "Customer interview", sender: "Email · Nina", due: "tomorrow at 9am",
             excerpt: "Your customer interview is tomorrow at 9am."),
        Item(title: "Engineering sync", sender: "Slack · Kai", due: "tomorrow at 10am",
             excerpt: "Engineering sync tomorrow at 10am."),
        Item(title: "Submit expenses", sender: "Email · Finance", due: "tomorrow",
             excerpt: "Please submit your expenses by tomorrow.", kind: .deadline),
        Item(title: "Send demo recording", sender: "Slack · Maya", due: "tomorrow at 3pm",
             excerpt: "I'll send the demo recording tomorrow at 3pm.", kind: .commitment),
        Item(title: "Walk with Jess", sender: "WhatsApp · Jess", due: "tomorrow at 5pm",
             excerpt: "Maybe a walk tomorrow at 5pm?", status: .tentative),
        Item(title: "Book club", sender: "Email · Book club", due: "tomorrow at 7pm",
             excerpt: "Book club is tomorrow at 7pm in the library."),
        Item(title: "Lunch with Priya", sender: "Slack · Priya", due: "sometime soon",
             excerpt: "Let's have lunch sometime soon.", status: .needsReview)
    ]

    @MainActor
    static func insert(into context: ModelContext, now: Date) {
        for (index, item) in items.enumerated() {
            let resolution = DateResolver.resolve(dueText: item.due, sentAt: now, timeZone: .current)
            var commitment = Commitment(
                title: item.title, kind: item.kind, status: item.status,
                actor: item.sender, dueText: item.due, timezone: TimeZone.current.identifier
            )
            switch resolution {
            case .exact(let interval):
                commitment.dueStart = interval.start
                commitment.dueEnd = interval.end
            case .dateOnly(let date):
                commitment.dueStart = date
            case .ambiguous:
                commitment.status = .needsReview
            }
            let messageID = "demo-\(index + 1)"
            context.insert(StoredCommitment(commitment))
            context.insert(StoredEvidence(
                Evidence(commitmentId: commitment.id, sourceMessageId: messageID,
                         excerpt: item.excerpt, source: .seed, capturedAt: now),
                sender: item.sender, subject: item.title, sentAt: now,
                body: "Quick update: " + item.excerpt + " Let me know what works."
            ))
            if commitment.status == .needsReview,
               let review = ReviewItem(commitmentId: commitment.id, sourceMessageId: messageID,
                                       reason: "Choose a date and time for lunch.") {
                context.insert(StoredReviewItem(review, sender: item.sender,
                    excerpt: item.excerpt, createdAt: now))
            }
        }
        // Demo loading never fabricates outbound requests or action receipts.
    }

    static func calendarEvents(now: Date = .now) -> [CalendarEvent] {
        let fixtures = [
            ("demo-calendar-1", "Existing team meeting", "today at 10am"),
            ("demo-calendar-2", "Dentist", "today at 5pm"),
            ("demo-calendar-3", "Gym", "tomorrow at 6am")
        ]
        return fixtures.compactMap { id, title, due in
            guard case .exact(let interval) = DateResolver.resolve(
                dueText: due, sentAt: now, timeZone: .current
            ) else { return nil }
            return CalendarEvent(id: id, title: title, start: interval.start, end: interval.end,
                                 timezone: TimeZone.current.identifier)
        }
    }
}
