import Foundation

/// A runtime/format dropdown option ("~60 minutes · Single narrator").
struct RuntimeOption: Hashable {
    let label: String
    let minutes: Int
    let format: String
}

@Observable
@MainActor
final class NewProjectViewModel {
    private let repository: any DashboardRepository

    var premise = ""
    var title = ""
    var setting = ""
    var genre: String
    var toneAudience: String
    var runtime: RuntimeOption
    var workflow: ProjectWorkflow = .guided
    /// Default creative-preferences summary; editing lands in a later
    /// milestone. Rendered read-only like the design.
    let creativePreferences =
        "Close third person · past tense. Implied violence; no graphic "
        + "detail or sexual violence. All defaults are editable."

    static let genreOptions = [
        "Historical crime fiction",
        "Coastal mystery",
        "Literary fiction",
        "Domestic thriller",
        "Contemporary drama",
    ]

    static let toneOptions = [
        "Intimate, tense · Adult",
        "Warm, reflective · Adult",
        "Dark, propulsive · Adult",
        "Gentle, hopeful · General",
    ]

    static let runtimeOptions = [
        RuntimeOption(label: "~30 minutes · Single narrator", minutes: 30, format: "Single narrator"),
        RuntimeOption(label: "~45 minutes · Single narrator", minutes: 45, format: "Single narrator"),
        RuntimeOption(label: "~60 minutes · Single narrator", minutes: 60, format: "Single narrator"),
        RuntimeOption(label: "~60 minutes · Full cast", minutes: 60, format: "Full cast"),
    ]

    init(repository: any DashboardRepository) {
        self.repository = repository
        genre = Self.genreOptions[0]
        toneAudience = Self.toneOptions[0]
        runtime = Self.runtimeOptions[2]
    }

    /// CTA stays disabled until a premise exists.
    var canGenerate: Bool {
        !premise.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Persists the project and returns its id so the caller can route.
    @discardableResult
    func save() -> UUID? {
        guard canGenerate else { return nil }
        let now = Date()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = Project(
            title: trimmedTitle.isEmpty ? "Untitled story" : trimmedTitle,
            genre: genre,
            settingDescriptor: setting.trimmingCharacters(in: .whitespacesAndNewlines),
            premise: premise.trimmingCharacters(in: .whitespacesAndNewlines),
            narratorFormat: runtime.format,
            runtimeTargetMinutes: runtime.minutes,
            totalChapters: 0,
            narratedChapters: 0,
            stageLabel: "Premise saved",
            status: .draft,
            toneAudience: toneAudience,
            workflow: workflow,
            createdAt: now,
            lastEditedAt: now
        )
        do {
            try repository.insert(project)
            return project.id
        } catch {
            return nil
        }
    }
}
