import Foundation

/// Backs the script chapter list. Generates a deterministic local draft
/// from the outline when a project reaches the script stage without one.
@Observable
@MainActor
final class ScriptViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let outlineRepository: any OutlineRepository
    private let scriptRepository: any ScriptRepository
    private let backendClient: any BackendClient
    private let generator = MockScriptGenerator()

    private(set) var project: Project?
    private(set) var chapters: [ScriptChapter] = []
    private(set) var loadError: String?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        outlineRepository: any OutlineRepository,
        scriptRepository: any ScriptRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.outlineRepository = outlineRepository
        self.scriptRepository = scriptRepository
        self.backendClient = backendClient
    }

    var subtitle: String {
        let count = chapters.count
        return "\(count) chapter\(count == 1 ? "" : "s") · Script"
    }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            var existing = try scriptRepository.fetchChapters(projectID: projectID)
            if existing.isEmpty, let project {
                if BackendConfiguration.shared.useBackend {
                    Task { await hydrateScript(project) }
                } else {
                    existing = try generateIfPossible(project)
                }
            }
            chapters = existing
            loadError = nil
        } catch {
            loadError = "Couldn't load the script."
        }
    }

    /// Deterministic local generation from the approved outline.
    /// Returns the existing (empty) list when there's no outline to build from.
    private func generateIfPossible(_ project: Project) throws -> [ScriptChapter] {
        guard let outline = try outlineRepository.fetchOutline(projectID: project.id)
        else { return [] }
        let outlineChapters = try outlineRepository.fetchChapters(outlineID: outline.id)
        guard !outlineChapters.isEmpty else { return [] }
        let generated = generator.generate(
            for: project, outline: outline, chapters: outlineChapters
        )
        for chapter in generated {
            try scriptRepository.insert(chapter)
        }
        project.scriptChapterCount = generated.count
        project.stageLabel = "Script ready"
        project.lastEditedAt = Date()
        try projectsRepository.saveChanges()
        return generated
    }

    /// Backend path — fetches the full-script document (GPT
    /// schema_version 5) and hydrates ScriptChapters; falls back to
    /// the local generator on failure. Deduped by chapter number.
    private func hydrateScript(_ project: Project) async {
        do {
            let dto: BackendDTO.Script = try await backendClient
                .get("/v1/projects/\(projectID.uuidString)/script")
            var numbers = Set(
                try scriptRepository.fetchChapters(projectID: projectID)
                    .map(\.number)
            )
            for chapter in dto.chapters
            where !numbers.contains(chapter.chapterNumber) {
                try scriptRepository.insert(ScriptChapter(
                    projectID: projectID,
                    number: chapter.chapterNumber,
                    title: chapter.chapterTitle,
                    settingLabel: dto.settingLabel,
                    body: chapter.paragraphs.joined(separator: "\n\n")
                ))
                numbers.insert(chapter.chapterNumber)
            }
            if !numbers.isEmpty {
                project.scriptChapterCount = numbers.count
                project.stageLabel = "Script ready"
                project.lastEditedAt = Date()
                try projectsRepository.saveChanges()
            }
            chapters = try scriptRepository.fetchChapters(projectID: projectID)
        } catch {
            if chapters.isEmpty,
               let project = try? projectsRepository.fetchProject(id: projectID) {
                chapters = (try? generateIfPossible(project)) ?? []
            }
        }
    }
}

/// Backs the script reader for a single chapter.
@Observable
@MainActor
final class ScriptReaderViewModel {
    let chapterID: UUID
    private let projectsRepository: any DashboardRepository
    private let scriptRepository: any ScriptRepository

    private(set) var chapter: ScriptChapter?
    private(set) var project: Project?
    private(set) var totalChapters = 0
    private(set) var loadError: String?

    var isPlaying = false

    init(
        chapterID: UUID,
        projectsRepository: any DashboardRepository,
        scriptRepository: any ScriptRepository
    ) {
        self.chapterID = chapterID
        self.projectsRepository = projectsRepository
        self.scriptRepository = scriptRepository
    }

    func load() {
        do {
            chapter = try scriptRepository.fetchChapter(id: chapterID)
            if let chapter {
                project = try projectsRepository.fetchProject(id: chapter.projectID)
                totalChapters = try scriptRepository
                    .fetchChapters(projectID: chapter.projectID).count
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the chapter."
        }
    }

    /// "Marlene · ElevenLabs · 1×"
    var narratorLine: String {
        let narrator = project?.narratorName ?? "Narrator"
        return "\(narrator) · ElevenLabs · 1×"
    }

    var revisionsLabel: String {
        "Revisions (\(chapter?.revision ?? 0))"
    }

    /// "Chapter 1 / 10 · 812 words · ~5:42 · Script r4 · Saved"
    var metaLine: String {
        guard let chapter else { return "" }
        return "Chapter \(chapter.number) / \(totalChapters)"
            + " · \(chapter.wordCount) words"
            + " · ~\(Self.format(chapter.estimatedSeconds))"
            + " · Script r\(chapter.revision)"
            + " · Saved"
    }

    var hasAudio: Bool {
        chapter?.audioRevision != nil
    }

    var audioTimeLine: String {
        guard let chapter else { return "" }
        return "\(Self.format(chapter.audioPosition)) / \(Self.format(chapter.audioSeconds))"
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    static func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
