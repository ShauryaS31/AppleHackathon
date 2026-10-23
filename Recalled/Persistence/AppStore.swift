import Foundation
import Observation
import OSLog
import RecalledCore
import SwiftData

@MainActor
@Observable
final class AppStore {
    let container: ModelContainer
    private(set) var calendarStore: any CalendarStore
    private(set) var calendarRevision = 0
    // T05b replaces the default extractor here, shared by paste and inbox imports.
    let extractor: any CommitmentExtractor
    var isImporting = false
    var inboxError: String?
    private let usesDemoCalendar: Bool
    private static var loggedFallback = false
    private static let logger = Logger(subsystem: "au.recalled.app", category: "Persistence")

    init(calendarStore: (any CalendarStore)? = nil,
         extractor: any CommitmentExtractor = PendingModelExtractor()) throws {
        self.container = try Self.makeContainer()
        self.extractor = extractor
        self.usesDemoCalendar = calendarStore == nil
        self.calendarStore = calendarStore ?? InMemoryCalendarStore(events: Seed.calendarEvents())
        container.mainContext.autosaveEnabled = false
    }

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            StoredCommitment.self, StoredEvidence.self, StoredReviewItem.self,
            StoredLedgerEntry.self, StoredActionReceipt.self, StoredInboxReceipt.self
        ])
        let configuration: ModelConfiguration
        if let directory = try groupDirectory() {
            configuration = ModelConfiguration(schema: schema,
                url: directory.appendingPathComponent("Recalled.store"), cloudKitDatabase: .none)
        } else {
            if !loggedFallback {
                logger.notice("App Group unavailable; using the default local SwiftData location.")
                loggedFallback = true
            }
            configuration = ModelConfiguration(schema: schema, groupContainer: .none, cloudKitDatabase: .none)
        }
        let directory = configuration.url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try protectStore(at: configuration.url)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        // Include SQLite's existing database, WAL and SHM files. New files inherit
        // complete protection from the directory and the iOS default entitlement.
        try protectStore(at: configuration.url)
        return container
    }

    private static func groupDirectory() throws -> URL? {
        let manager = FileManager.default
        guard let group = manager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.au.recalled.app"
        ) else { return nil }
        let directory = group.appendingPathComponent("Library/Application Support/Recalled", isDirectory: true)
        #if os(macOS)
        // An unprovisioned Mac can return a group URL which the sandbox cannot
        // actually access. Detect that before attempting to open SwiftData.
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            guard manager.isWritableFile(atPath: directory.path) else { return nil }
        } catch {
            return nil
        }
        #else
        // On iOS, a locked protected store is not a missing App Group. Surface
        // that error instead of silently switching to a different database.
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        #endif
        return directory
    }

    private static func protectStore(at url: URL) throws {
        #if os(iOS)
        let manager = FileManager.default
        let directory = url.deletingLastPathComponent()
        let attributes: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        try manager.setAttributes(attributes, ofItemAtPath: directory.path)
        for file in try manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        where file.lastPathComponent.hasPrefix(url.lastPathComponent) {
            try manager.setAttributes(attributes, ofItemAtPath: file.path)
        }
        #endif
    }

    /// Pass Core commitments and detached evidence/review rows. Reuse each row's
    /// UUID on retries or edits (Core Evidence and ReviewItem have no row ID).
    /// All inserts and updates commit together; failures roll the batch back.
    func ingest(commitments: [Commitment], evidence: [StoredEvidence],
                reviewItems: [StoredReviewItem], sourceMessageID: String? = nil) throws {
        let context = container.mainContext
        do {
            for value in commitments {
                let id = value.id
                let descriptor = FetchDescriptor<StoredCommitment>(
                    predicate: #Predicate { $0.id == id })
                if let row = try context.fetch(descriptor).first {
                    row.title = value.title
                    row.kind = value.kind
                    row.status = value.status
                    row.actor = value.actor
                    row.dueText = value.dueText
                    row.dueStart = value.dueStart
                    row.dueEnd = value.dueEnd
                    row.timezone = value.timezone
                    row.version = value.version
                    row.calendarEventId = value.calendarEventId
                } else {
                    context.insert(StoredCommitment(value))
                }
            }
            for value in evidence {
                let id = value.id
                let descriptor = FetchDescriptor<StoredEvidence>(
                    predicate: #Predicate { $0.id == id })
                if let row = try context.fetch(descriptor).first {
                    row.update(from: value)
                } else {
                    context.insert(value)
                }
            }
            for value in reviewItems {
                let id = value.id
                let descriptor = FetchDescriptor<StoredReviewItem>(
                    predicate: #Predicate { $0.id == id })
                if let row = try context.fetch(descriptor).first {
                    row.update(from: value)
                } else {
                    context.insert(value)
                }
            }
            if let sourceMessageID {
                context.insert(StoredInboxReceipt(sourceMessageID: sourceMessageID))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func resetDemo(now: Date = .now) throws {
        let context = container.mainContext
        do {
            try deleteRows(in: context)
            Seed.insert(into: context, now: now)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        if usesDemoCalendar {
            calendarStore = InMemoryCalendarStore(events: Seed.calendarEvents(now: now))
        }
        calendarRevision += 1
    }

    func forgetAll() throws {
        let context = container.mainContext
        do {
            try deleteRows(in: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        if usesDemoCalendar { calendarStore = InMemoryCalendarStore() }
        calendarRevision += 1
    }

    private func deleteRows(in context: ModelContext) throws {
        for row in try context.fetch(FetchDescriptor<StoredInboxReceipt>()) { context.delete(row) }
        for row in try context.fetch(FetchDescriptor<StoredEvidence>()) { context.delete(row) }
        for row in try context.fetch(FetchDescriptor<StoredReviewItem>()) { context.delete(row) }
        for row in try context.fetch(FetchDescriptor<StoredLedgerEntry>()) { context.delete(row) }
        for row in try context.fetch(FetchDescriptor<StoredActionReceipt>()) { context.delete(row) }
        for row in try context.fetch(FetchDescriptor<StoredCommitment>()) { context.delete(row) }
    }
}
