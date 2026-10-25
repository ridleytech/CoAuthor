import Foundation
import SwiftData

/// Persistence boundary for the Projects dashboard. View models depend
/// on this protocol; SwiftData stays behind it.
@MainActor
protocol DashboardRepository {
    /// Projects sorted by most recently edited first.
    func fetchProjects() throws -> [Project]
    /// A single project by stable identifier.
    func fetchProject(id: UUID) throws -> Project?
    /// Review-queue items sorted by `sortOrder`.
    func fetchReviewItems() throws -> [ReviewItem]
    func insert(_ project: Project) throws
    func delete(_ project: Project) throws
    /// Writes development seed data once. A UserDefaults flag prevents
    /// reseeding after the user deletes records.
    func seedDevelopmentDataIfNeeded() throws
}

@MainActor
final class SwiftDataDashboardRepository: DashboardRepository {
    private let context: ModelContext
    private let defaults: UserDefaults
    static let seededKey = "coauthor.seeded.v1"

    init(context: ModelContext, defaults: UserDefaults = .standard) {
        self.context = context
        self.defaults = defaults
    }

    func fetchProjects() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.lastEditedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func fetchProject(id: UUID) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchReviewItems() throws -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItem>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ project: Project) throws {
        context.insert(project)
        try context.save()
    }

    func delete(_ project: Project) throws {
        context.delete(project)
        try context.save()
    }

    func seedDevelopmentDataIfNeeded() throws {
        #if DEBUG
        guard !defaults.bool(forKey: Self.seededKey) else { return }
        SampleData.insertSamples(into: context)
        try context.save()
        defaults.set(true, forKey: Self.seededKey)
        #endif
    }
}
