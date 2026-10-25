import Foundation

/// Backs the Voices & casting detail screen — "Find your narrator."
/// Shows capacity, the suggested narrator, the voice design prompt,
/// audition direction, and per-character cast assignments.
@Observable
@MainActor
final class CastingViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let voiceRepository: any VoiceRepository

    private(set) var project: Project?
    private(set) var assignments: [CastAssignment] = []
    private(set) var suggestedVoice: Voice?
    private(set) var loadError: String?

    let capacity = MockVoiceCapacity.current

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        voiceRepository: any VoiceRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.voiceRepository = voiceRepository
    }

    var subtitle: String {
        guard let project else { return "" }
        return "\(project.title) · Single-narrator production"
    }

    /// Suggestion card headline — the project's narrator if assigned,
    /// otherwise a deterministic catalog suggestion.
    var suggestionTitle: String {
        if let name = project?.narratorName, !name.isEmpty { return name }
        return suggestedVoice?.name ?? "Marlene"
    }

    var suggestionDetail: String {
        suggestedVoice?.summary
            ?? "Warm, mature lower register. Intimate, measured and "
            + "grounded. Subtle Great Lakes American accent."
    }

    var voiceDesignPrompt: String {
        guard let project else { return "" }
        return project.voiceDesignPrompt.isEmpty
            ? "A mature American woman with a warm lower register and "
                + "lightly textured tone. Clear consonants, measured "
                + "pacing. Understated emotional range; never theatrical."
            : project.voiceDesignPrompt
    }

    /// Direction text for the Audition & performance card.
    var auditionDirection: String {
        """
        "He had never taught her what to do when the missing number was his."

        Trust the listener. Keep Evelyn firm, Odessa easy, Calvin patient. \
        Character descriptions guide one narrator; separate voices are \
        not required.
        """
    }

    var isPromptApproved: Bool { project?.voicePromptApproved ?? false }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            assignments = try voiceRepository.fetchCastAssignments(projectID: projectID)
            // Deterministic suggestion: prefer the project's assigned
            // voice, else the first catalog narrator.
            let voices = try voiceRepository.fetchVoices()
            if let assigned = voices.first(where: { $0.assignedProjectID == projectID }) {
                suggestedVoice = assigned
            } else {
                suggestedVoice = voices.first { $0.roleTag.contains("Narrator") && $0.isAvailable }
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load casting."
        }
    }

    /// "Approve voice description" — approval is real and persisted;
    /// paid audition generation remains a separate M7/M12 step.
    func approveDescription() {
        guard let project else { return }
        project.voicePromptApproved = true
        project.lastEditedAt = Date()
        try? projectsRepository.saveChanges()
    }
}
