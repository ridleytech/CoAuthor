import Foundation
import SwiftData

/// Persistence boundary for script chapters.
@MainActor
protocol ScriptRepository {
    func fetchChapter(id: UUID) throws -> ScriptChapter?
    func fetchChapters(projectID: UUID) throws -> [ScriptChapter]
    func insert(_ chapter: ScriptChapter) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataScriptRepository: ScriptRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchChapter(id: UUID) throws -> ScriptChapter? {
        let descriptor = FetchDescriptor<ScriptChapter>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchChapters(projectID: UUID) throws -> [ScriptChapter] {
        let descriptor = FetchDescriptor<ScriptChapter>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.number)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ chapter: ScriptChapter) throws {
        context.insert(chapter)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Builds a first script locally and deterministically from an outline —
/// no AI calls. Replaced by backend generation in M12.
struct MockScriptGenerator {
    func generate(
        for project: Project,
        outline: Outline,
        chapters: [OutlineChapter]
    ) -> [ScriptChapter] {
        let setting = project.settingDescriptor.isEmpty
            ? ""
            : project.settingDescriptor.uppercased()
        return chapters.map { outlineChapter in
            ScriptChapter(
                projectID: project.id,
                number: outlineChapter.number,
                title: outlineChapter.title,
                settingLabel: setting,
                body: Self.prose(
                    title: outlineChapter.title,
                    summary: outlineChapter.summary,
                    turn: outlineChapter.turn
                ),
                revision: 1
            )
        }
    }

    /// Generic seed prose for chapters without bespoke sample text.
    static func proseForSeed(title: String, number: Int) -> String {
        prose(
            title: title,
            summary: "Chapter \(number) opens on \(title.lowercased()), "
                + "with Evelyn still weighing what the envelope set in motion.",
            turn: "a number in the ledger refuses to balance."
        )
    }

    private static func prose(title: String, summary: String, turn: String) -> String {
        [
            "\(summary) The details arrived quietly, the way they always did — "
                + "not as revelation, but as arithmetic that refused to balance.",
            "By evening the shape of it had settled. Every explanation she "
                + "reached for came apart at the same seam, and she began to "
                + "understand that the missing thing had been missing on purpose.",
            turn.isEmpty
                ? "She wrote it down anyway, because writing it down was the "
                    + "only part she could still control."
                : "It ended the way these things ended: \(turn) She wrote it "
                    + "down anyway, because writing it down was the only part "
                    + "she could still control.",
        ].joined(separator: "\n\n")
    }
}
