import Foundation

@Observable
@MainActor
final class OutlineViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let outlineRepository: any OutlineRepository
    private let backendClient: any BackendClient
    private let generator = MockOutlineGenerator()

    private(set) var project: Project?
    private(set) var outline: Outline?
    private(set) var chapters: [OutlineChapter] = []
    private(set) var characters: [OutlineCharacter] = []
    private(set) var loadError: String?

    /// Currently featured chapter — the expanded card.
    var selectedChapterID: UUID?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        outlineRepository: any OutlineRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.outlineRepository = outlineRepository
        self.backendClient = backendClient
    }

    // MARK: Derived state

    var featuredChapter: OutlineChapter? {
        chapters.first { $0.id == selectedChapterID } ?? chapters.first
    }

    /// Section picker label — e.g. "Chapters selected".
    var focusedSection: String = "Chapters"

    var subtitle: String {
        guard let outline else { return "" }
        let review = project?.workflow == .guided ? "Guided review" : "Review"
        return "Outline r\(outline.revision) · \(review) · Before script generation"
    }

    var arcTitle: String {
        "\(chapters.count)-chapter arc"
    }

    var isApproved: Bool { outline?.approved ?? false }

    // MARK: Loading

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            if let existing = try outlineRepository.fetchOutline(projectID: projectID) {
                outline = existing
                try reloadSections()
            } else if BackendConfiguration.shared.useBackend {
                Task { await hydrateOutline() }
            } else if let project {
                generateLocally(project)
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the outline."
        }
    }

    /// Mock path — deterministic, no AI calls.
    private func generateLocally(_ project: Project) {
        do {
            let generated = generator.generate(for: project)
            try outlineRepository.insert(generated.outline)
            for chapter in generated.chapters {
                try outlineRepository.insert(chapter)
            }
            for character in generated.characters {
                try outlineRepository.insert(character)
            }
            project.hasOutline = true
            try projectsRepository.saveChanges()
            outline = generated.outline
            try reloadSections()
        } catch {
            loadError = "Couldn't load the outline."
        }
    }

    /// Backend path — fetches the outline from the API and hydrates
    /// the local store; falls back to the mock generator on failure.
    /// Idempotent: re-checks for an existing outline after the await
    /// and dedupes chapters by number / characters by name.
    private func hydrateOutline() async {
        guard let project else { return }
        do {
            let dto: BackendDTO.Outline = try await backendClient
                .get("/v1/projects/\(projectID.uuidString)/outline")
            // Re-check inside the async gap — a second load() may have
            // created an outline while the request was in flight.
            if let existing = try outlineRepository.fetchOutline(projectID: projectID) {
                outline = existing
                try reloadSections()
                return
            }
            let newOutline = Outline(
                projectID: projectID,
                revision: dto.revision,
                sections: dto.sections,
                writingApproach: dto.writingApproach,
                privateEnding: dto.privateEnding,
                centralQuestion: dto.centralQuestion
            )
            try outlineRepository.insert(newOutline)
            for chapter in dto.chapters {
                try outlineRepository.insert(OutlineChapter(
                    outlineID: newOutline.id,
                    number: chapter.number,
                    title: chapter.title,
                    summary: chapter.summary,
                    turn: chapter.turn,
                    estimatedMinutes: chapter.estimatedMinutes
                ))
            }
            for character in dto.characters {
                try outlineRepository.insert(OutlineCharacter(
                    outlineID: newOutline.id,
                    name: character.name,
                    role: character.role,
                    notes: character.notes
                ))
            }
            project.hasOutline = true
            try projectsRepository.saveChanges()
            outline = newOutline
            try reloadSections()
        } catch {
            if outline == nil {
                generateLocally(project)
            }
        }
    }

    private func reloadSections() throws {
        if let outline {
            chapters = try outlineRepository.fetchChapters(outlineID: outline.id)
            characters = try outlineRepository.fetchCharacters(outlineID: outline.id)
        }
    }

    // MARK: Actions

    func select(_ chapter: OutlineChapter) {
        selectedChapterID = chapter.id
    }

    func focusSection(_ section: String) {
        focusedSection = section
    }

    /// "Approve outline and generate script" — approval is real;
    /// script generation itself lands in M5.
    func approve() {
        guard let outline else { return }
        outline.approved = true
        project?.outlineApproved = true
        project?.stageLabel = "Outline approved"
        project?.lastEditedAt = Date()
        try? outlineRepository.saveChanges()
        try? projectsRepository.saveChanges()
    }
}
