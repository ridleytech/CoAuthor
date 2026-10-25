import Foundation

@Observable
@MainActor
final class OutlineViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let outlineRepository: any OutlineRepository
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
        outlineRepository: any OutlineRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.outlineRepository = outlineRepository
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
            } else if let project {
                // Deterministic local generation — no AI calls.
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
            }
            if let outline {
                chapters = try outlineRepository.fetchChapters(outlineID: outline.id)
                characters = try outlineRepository.fetchCharacters(outlineID: outline.id)
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the outline."
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
