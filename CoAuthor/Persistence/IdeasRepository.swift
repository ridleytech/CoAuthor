import Foundation
import SwiftData

/// Persistence boundary for story ideas.
@MainActor
protocol IdeasRepository {
    /// Ideas for a project, ordered as generated.
    func fetchIdeas(projectID: UUID) throws -> [Idea]
    func insert(_ idea: Idea) throws
    func delete(_ idea: Idea) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataIdeasRepository: IdeasRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchIdeas(projectID: UUID) throws -> [Idea] {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ idea: Idea) throws {
        context.insert(idea)
        try context.save()
    }

    func delete(_ idea: Idea) throws {
        context.delete(idea)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Produces story ideas locally and deterministically — no AI calls.
/// The same inputs always yield the same ideas, so generation is
/// testable and free. Replaced by the backend generator in M12.
struct MockIdeaGenerator {
    /// Fixed pool used when a project has no bespoke sample ideas.
    private static let pool: [(title: String, tagline: String)] = [
        ("The Quiet Ledger", "small-town reckoning"),
        ("Second Harvest", "family debt drama"),
        ("The Borrowed Name", "identity mystery"),
        ("Winter Accounts", "contained domestic thriller"),
        ("The Final Tally", "slow-burn revenge"),
        ("Half a Life Insured", "moral dilemma"),
    ]

    /// Index-deterministic: the Nth generation always returns the
    /// same idea for a given project.
    func generate(for project: Project, index: Int) -> Idea {
        let template = Self.pool[index % Self.pool.count]
        let setting = project.settingDescriptor.isEmpty
            ? "an unnamed town"
            : project.settingDescriptor
        let premise = project.premise.isEmpty
            ? "a buried secret"
            : "the events set out in the premise"
        return Idea(
            projectID: project.id,
            title: template.title,
            tagline: template.tagline,
            pitch: "In \(setting), \(premise) resurfaces through an unexpected witness.",
            expandedPitch: "In \(setting), a quiet ordinary life is disturbed when "
                + "\(premise) comes back into the open. What follows tests loyalties "
                + "built over a lifetime.",
            protagonist: "A methodical outsider with everything to lose.",
            stakes: "The truth protects some and ruins others — there is no clean win.",
            angle: "Told through small accumulating details rather than revelation.",
            sortOrder: index
        )
    }
}
