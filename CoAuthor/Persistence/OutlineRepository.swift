import Foundation
import SwiftData

/// Persistence boundary for outlines, chapters, and characters.
@MainActor
protocol OutlineRepository {
    func fetchOutline(projectID: UUID) throws -> Outline?
    func fetchChapter(id: UUID) throws -> OutlineChapter?
    func fetchChapters(outlineID: UUID) throws -> [OutlineChapter]
    func fetchCharacters(outlineID: UUID) throws -> [OutlineCharacter]
    func insert(_ outline: Outline) throws
    func insert(_ chapter: OutlineChapter) throws
    func insert(_ character: OutlineCharacter) throws
    func delete(_ chapter: OutlineChapter) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataOutlineRepository: OutlineRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchOutline(projectID: UUID) throws -> Outline? {
        let descriptor = FetchDescriptor<Outline>(
            predicate: #Predicate { $0.projectID == projectID }
        )
        return try context.fetch(descriptor).first
    }

    func fetchChapter(id: UUID) throws -> OutlineChapter? {
        let descriptor = FetchDescriptor<OutlineChapter>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchChapters(outlineID: UUID) throws -> [OutlineChapter] {
        let descriptor = FetchDescriptor<OutlineChapter>(
            predicate: #Predicate { $0.outlineID == outlineID },
            sortBy: [SortDescriptor(\.number)]
        )
        return try context.fetch(descriptor)
    }

    func fetchCharacters(outlineID: UUID) throws -> [OutlineCharacter] {
        let descriptor = FetchDescriptor<OutlineCharacter>(
            predicate: #Predicate { $0.outlineID == outlineID }
        )
        return try context.fetch(descriptor)
    }

    func insert(_ outline: Outline) throws {
        context.insert(outline)
        try context.save()
    }

    func insert(_ chapter: OutlineChapter) throws {
        context.insert(chapter)
        try context.save()
    }

    func insert(_ character: OutlineCharacter) throws {
        context.insert(character)
        try context.save()
    }

    func delete(_ chapter: OutlineChapter) throws {
        context.delete(chapter)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Builds a first outline locally and deterministically — no AI calls.
/// Replaced by backend generation in M12.
struct MockOutlineGenerator {
    func generate(for project: Project) -> (outline: Outline, chapters: [OutlineChapter], characters: [OutlineCharacter]) {
        let outline = Outline(
            projectID: project.id,
            revision: 1,
            sections: ["Overview", "Writing approach", "Settings",
                       "Characters", "Chapters", "Private ending"],
            writingApproach: "Close third person, past tense.",
            privateEnding: "The ending is withheld until review: the protagonist "
                + "settles the central debt at a personal cost.",
            centralQuestion: "Can the truth be exposed without destroying "
                + "what the family still has?"
        )
        let chapters = (1...10).map { number in
            OutlineChapter(
                outlineID: outline.id,
                number: number,
                title: "Chapter \(number)",
                summary: "The protagonist confronts a new piece of the central "
                    + "mystery as the pressure from the premise tightens.",
                turn: "A detail reframes what seemed settled.",
                estimatedMinutes: max(1, project.runtimeTargetMinutes / 10)
            )
        }
        let characters = [
            OutlineCharacter(
                outlineID: outline.id,
                name: "Protagonist",
                role: "protagonist",
                notes: "Defined by the project premise; refine in a later draft."
            )
        ]
        return (outline, chapters, characters)
    }
}
