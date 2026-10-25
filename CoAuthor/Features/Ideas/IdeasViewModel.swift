import Foundation

@Observable
@MainActor
final class IdeasViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let ideasRepository: any IdeasRepository
    private let generator = MockIdeaGenerator()

    /// Ideas produced on first open — deterministic, no AI calls.
    static let initialGenerationCount = 3

    private(set) var project: Project?
    private(set) var ideas: [Idea] = []
    private(set) var loadError: String?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        ideasRepository: any IdeasRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.ideasRepository = ideasRepository
    }

    // MARK: Derived state

    var selectedIdeas: [Idea] { ideas.filter(\.isSelected) }

    /// The story direction chosen on the comparison screen.
    var chosenIdeaID: UUID? { project?.selectedIdeaID }

    var subtitle: String {
        let setting = project?.settingDescriptor ?? ""
        let premise = "Inspired by your original premise"
        return setting.isEmpty ? premise : "\(setting) · \(premise)"
    }

    var title: String {
        "\(ideas.count) ways into your story."
    }

    /// Rows for the comparison screen's "Story configuration" card.
    var storyConfigRows: [(label: String, value: String)] {
        guard let project else { return [] }
        let audience = project.toneAudience
            .components(separatedBy: "·").last?
            .trimmingCharacters(in: .whitespaces) ?? project.toneAudience
        var runtime = "~\(project.runtimeTargetMinutes) min"
        if project.totalChapters > 0 {
            runtime += " · \(project.totalChapters) chapters"
        }
        let workflowLabel = project.workflow == .guided ? "Guided" : "Complete package"
        return [
            ("Title", project.title),
            ("Genre", project.genre),
            ("Setting", project.settingDescriptor),
            ("Audience / POV", "\(audience) · close third · past tense"),
            ("Target runtime", runtime),
            ("Narrator", "\(project.narratorFormat) · \(workflowLabel) workflow"),
        ]
    }

    // MARK: Loading and generation

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            ideas = try ideasRepository.fetchIdeas(projectID: projectID)
            if ideas.isEmpty, let project {
                for index in 0..<Self.initialGenerationCount {
                    let idea = generator.generate(for: project, index: index)
                    try ideasRepository.insert(idea)
                    ideas.append(idea)
                }
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load ideas."
        }
    }

    /// "Generate more ideas" — appends the next deterministic idea.
    func generateMore() {
        guard let project else { return }
        let idea = generator.generate(for: project, index: ideas.count)
        do {
            try ideasRepository.insert(idea)
            ideas.append(idea)
        } catch {
            loadError = "Couldn't generate an idea."
        }
    }

    // MARK: Selection and saving

    func toggleSelected(_ idea: Idea) {
        idea.isSelected.toggle()
        try? ideasRepository.saveChanges()
    }

    func toggleSaved(_ idea: Idea) {
        idea.isSaved.toggle()
        try? ideasRepository.saveChanges()
    }

    /// Picks an idea as the story direction (comparison screen).
    func choose(_ idea: Idea) {
        project?.selectedIdeaID = idea.id
        try? projectsRepository.saveChanges()
    }
}
