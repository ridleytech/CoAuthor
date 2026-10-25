import Foundation
import SwiftData

/// Persistence boundary for publishing data — kits, sound assets,
/// and export records.
@MainActor
protocol PublishingRepository {
    func fetchKit(projectID: UUID) throws -> PublishingKit?
    func fetchAssets() throws -> [SoundAsset]
    func fetchAssets(projectTitle: String) throws -> [SoundAsset]
    func fetchExports(projectID: UUID) throws -> [ExportRecord]
    func insertKit(_ kit: PublishingKit) throws
    func insertAsset(_ asset: SoundAsset) throws
    func insertExport(_ export: ExportRecord) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataPublishingRepository: PublishingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchKit(projectID: UUID) throws -> PublishingKit? {
        let descriptor = FetchDescriptor<PublishingKit>(
            predicate: #Predicate { $0.projectID == projectID }
        )
        return try context.fetch(descriptor).first
    }

    func fetchAssets() throws -> [SoundAsset] {
        let descriptor = FetchDescriptor<SoundAsset>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchAssets(projectTitle: String) throws -> [SoundAsset] {
        let descriptor = FetchDescriptor<SoundAsset>(
            predicate: #Predicate { $0.projectTitle == projectTitle },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchExports(projectID: UUID) throws -> [ExportRecord] {
        let descriptor = FetchDescriptor<ExportRecord>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func insertKit(_ kit: PublishingKit) throws {
        context.insert(kit)
        try context.save()
    }

    func insertAsset(_ asset: SoundAsset) throws {
        context.insert(asset)
        try context.save()
    }

    func insertExport(_ export: ExportRecord) throws {
        context.insert(export)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}
