import Foundation
import SwiftData

/// Persistence boundary for sound cues.
@MainActor
protocol CueRepository {
    func fetchCue(id: UUID) throws -> SoundCue?
    func fetchCues(projectID: UUID) throws -> [SoundCue]
    func insert(_ cue: SoundCue) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataCueRepository: CueRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCue(id: UUID) throws -> SoundCue? {
        let descriptor = FetchDescriptor<SoundCue>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchCues(projectID: UUID) throws -> [SoundCue] {
        let descriptor = FetchDescriptor<SoundCue>(
            predicate: #Predicate { $0.projectID == projectID },
            sortBy: [SortDescriptor(\.number)]
        )
        return try context.fetch(descriptor)
    }

    func insert(_ cue: SoundCue) throws {
        context.insert(cue)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Builds a starter cue set locally and deterministically — ambience
/// for early chapters plus one silence cue. No AI calls; replaced by
/// backend cue generation in M12.
struct MockCueGenerator {
    func generate(for project: Project, chapters: [ScriptChapter]) -> [SoundCue] {
        let ambienceTitles = [
            "Room tone", "Street ambience", "Quiet interior",
        ]
        return chapters.prefix(3).enumerated().map { pair in
            SoundCue(
                projectID: project.id,
                number: pair.offset + 1,
                title: ambienceTitles[pair.offset % ambienceTitles.count],
                chapterTitle: pair.element.title,
                importance: pair.offset == 0 ? "Core" : "Optional",
                category: pair.offset == 2 ? "Silence" : "Ambience",
                sourcePassage: pair.element.body
                    .components(separatedBy: "\n\n").first ?? "",
                generationState: pair.offset == 2
                    ? "No audio file needed" : "Not generated",
                alternativeLabels: ["A · Ambience", "B · Ambience"]
            )
        }
    }
}
