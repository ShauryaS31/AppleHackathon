#if os(iOS)
import Foundation
import RecalledCore
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private var importTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        statusLabel.text = "Sending to Recalled…"
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        let close = UIButton(type: .system)
        close.setTitle("Close", for: .normal)
        close.addTarget(self, action: #selector(closeExtension), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [statusLabel, close])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        importTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveShare()
        }
    }

    @objc private func closeExtension() {
        importTask?.cancel()
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func receiveShare() async {
        do {
            let text = try await sharedText()
            try Task.checkCancellation()
            let manager = FileManager.default
            guard let container = manager.containerURL(
                forSecurityApplicationGroupIdentifier: "group.au.recalled.app"
            ) else { throw ShareError.containerUnavailable }
            let inbox = container.appendingPathComponent("Inbox", isDirectory: true)
            try manager.createDirectory(at: inbox, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete])
            try manager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: inbox.path)
            let message = SourceMessage(id: UUID().uuidString, source: .share, sender: "Shared",
                                        sentAt: .now, subject: "", body: text)
            // Timestamp orders queued shares; UUID prevents concurrent filename collisions.
            let filename = "\(Int64(message.sentAt.timeIntervalSince1970 * 1_000))-\(message.id).json"
            let file = inbox.appendingPathComponent(filename)
            try JSONEncoder().encode(message).write(to: file, options: [.atomic, .completeFileProtection])
            statusLabel.text = "Sent to Recalled"
            try await Task.sleep(for: .milliseconds(700))
            extensionContext?.completeRequest(returningItems: nil)
        } catch is CancellationError {
            // Close already completed the extension request.
        } catch {
            statusLabel.text = "Couldn't send to Recalled. \(error.localizedDescription)"
        }
    }

    private func sharedText() async throws -> String {
        var fragments: [String] = []
        var urlCount = 0
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            var loadedAttachment = false
            for provider in item.attachments ?? [] {
                let type: String
                let isURL: Bool
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    type = UTType.url.identifier
                    isURL = true
                    urlCount += 1
                    guard urlCount <= 1 else { throw ShareError.unsupportedContent }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    type = UTType.plainText.identifier
                    isURL = false
                } else {
                    throw ShareError.unsupportedContent
                }
                let text = try await loadText(provider, type: type)
                if isURL {
                    guard let url = URL(string: text), let scheme = url.scheme?.lowercased(),
                          ["http", "https"].contains(scheme), url.host != nil else {
                        throw ShareError.unsupportedContent
                    }
                }
                fragments.append(text)
                loadedAttachment = true
            }
            if !loadedAttachment, let text = item.attributedContentText?.string {
                fragments.append(text)
            }
        }
        let text = fragments.joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShareError.unsupportedContent
        }
        return text
    }

    private func loadText(_ provider: NSItemProvider, type: String) async throws -> String {
        // Convert provider objects inside the callback; only a Sendable String
        // crosses back to the main actor. No model ever runs in this extension.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, any Error>) in
            provider.loadItem(forTypeIdentifier: type, options: nil) { value, error in
                if let error { continuation.resume(throwing: error) }
                else if let url = value as? URL { continuation.resume(returning: url.absoluteString) }
                else if let text = value as? String { continuation.resume(returning: text) }
                else if let data = value as? Data, let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: text)
                } else { continuation.resume(throwing: ShareError.unsupportedContent) }
            }
        }
    }
}

private enum ShareError: LocalizedError {
    case containerUnavailable, unsupportedContent

    var errorDescription: String? {
        switch self {
        case .containerUnavailable: "The shared inbox is unavailable."
        case .unsupportedContent: "Share plain text or one web URL."
        }
    }
}
#endif
