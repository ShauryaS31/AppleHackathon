import Foundation
import RecalledCore
import SwiftData

@MainActor
extension AppStore {
    /// The flag serializes launch/activation imports and user initiated paste.
    func processInbox() async {
        guard !isImporting else { return }
        isImporting = true
        defer { isImporting = false }
        inboxError = nil
        let manager = FileManager.default
        guard let group = manager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.au.recalled.app"
        ) else { return }
        let directory = group.appendingPathComponent("Inbox", isDirectory: true)
        guard manager.fileExists(atPath: directory.path) else { return }
        do {
            let files = try manager.contentsOfDirectory(at: directory,
                includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
                .filter { $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            for file in files {
                do {
                    guard try file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else { continue }
                    let message = try JSONDecoder().decode(SourceMessage.self, from: Data(contentsOf: file))
                    _ = try await importMessage(message)
                    // importMessage returns only after a successful transaction (or a
                    // durable receipt from an earlier successful transaction).
                    try manager.removeItem(at: file)
                } catch {
                    // Keep failed input for retry and surface the failure; never log bodies.
                    inboxError = "Couldn't finish importing shared text. The inbox file was kept for retry."
                }
            }
        } catch {
            inboxError = "Couldn't read shared text. Try again after unlocking your device."
        }
    }

    func pasteMessage(_ text: String?) async -> String {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "The clipboard has no plain text."
        }
        guard !isImporting else { return "An import is in progress. Please try again shortly." }
        isImporting = true
        let message = SourceMessage(id: UUID().uuidString, source: .share, sender: "Shared",
                                    sentAt: .now, subject: "", body: text)
        let notice: String
        do {
            if let result = try await importMessage(message) {
                if !result.reviewItems.isEmpty {
                    notice = "Message added to Review."
                } else if result.newCommitments.isEmpty && result.updatedCommitments.isEmpty {
                    notice = "No commitments found in this message."
                } else {
                    notice = "Message imported."
                }
            } else {
                notice = "Message already imported."
            }
        } catch {
            notice = "Couldn't save this message. Please paste it again."
        }
        isImporting = false
        // Drain a share that arrived while paste extraction was suspended.
        await processInbox()
        return notice
    }

    private func importMessage(_ message: SourceMessage) async throws -> InboxPipeline.Result? {
        let context = container.mainContext
        let sourceID = message.id
        let receipts = FetchDescriptor<StoredInboxReceipt>(
            predicate: #Predicate { $0.sourceMessageID == sourceID })
        guard try context.fetch(receipts).isEmpty else { return nil }
        let existing = try context.fetch(FetchDescriptor<StoredCommitment>())
            .map { $0.toCore() }
            .filter { $0.status != .cancelled && $0.status != .completed && $0.status != .superseded }
            .sorted { $0.id.uuidString < $1.id.uuidString }
        let refs = existing.enumerated().map { index, value in
            ItemRef(ref: "t\(index + 1)", commitmentId: value.id, title: value.title,
                    kind: value.kind, status: value.status)
        }
        let result = await InboxPipeline.process(message, extractor: extractor,
            existing: existing, refs: refs, timeZone: .current)
        let prepared = Prefilter.preparedText(message)
        let evidence = result.evidence.map {
            StoredEvidence($0, sender: message.sender, subject: message.subject,
                           sentAt: message.sentAt, body: prepared)
        }
        let reviews = result.reviewItems.map { review in
            let excerpt = result.evidence.first { $0.commitmentId == review.commitmentId }?.excerpt
            return StoredReviewItem(review, sender: message.sender,
                                    excerpt: excerpt ?? prepared, createdAt: .now)
        }
        try ingest(commitments: result.newCommitments + result.updatedCommitments,
                   evidence: evidence, reviewItems: reviews, sourceMessageID: message.id)
        return result
    }
}
