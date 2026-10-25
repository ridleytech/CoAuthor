import Foundation
import SwiftData

/// Persistence boundary for generation jobs (the Activity feed).
@MainActor
protocol GenerationRepository {
    func fetchJobs() throws -> [GenerationJob]
    func insert(_ job: GenerationJob) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataGenerationRepository: GenerationRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchJobs() throws -> [GenerationJob] {
        let descriptor = FetchDescriptor<GenerationJob>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ job: GenerationJob) throws {
        context.insert(job)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}
