import Foundation

/// A generated audition preview (mock — provider previews are
/// backend/paid and land in M12).
struct VoiceAudition: Identifiable {
    let id = UUID()
    let label: String       // "A · intimate"
    let detail: String
    let seconds: Int
}

/// Backs the 4-step voice-creation flow rendered inside
/// `VoiceCreationView`. Draft state lives here; saving creates a real
/// `Voice` record, assignment updates the project.
@Observable
@MainActor
final class VoiceCreationViewModel {
    enum Step: Int, CaseIterable {
        case describe = 1, previews, save, assign
        var label: String {
            switch self {
            case .describe: "Describe"
            case .previews: "Previews"
            case .save: "Save"
            case .assign: "Assign"
            }
        }
    }

    let projectID: UUID?
    private let projectsRepository: (any DashboardRepository)?
    private let voiceRepository: any VoiceRepository

    private(set) var project: Project?
    private(set) var loadError: String?

    var step: Step = .describe
    /// True once the flow has ended (assignment success screen).
    private(set) var finished = false
    /// True when the kept/existing voice was reused rather than a
    /// newly saved one.
    private(set) var reusedExisting = false

    // Draft fields — prefilled from the project's voice design prompt.
    var draftName = ""
    var draftDescription = ""
    var draftAuditionText = ""

    let auditions: [VoiceAudition] = [
        VoiceAudition(
            label: "A · intimate",
            detail: "Warm lower register, subtle Great Lakes.",
            seconds: 23
        ),
        VoiceAudition(
            label: "B · textured",
            detail: "A little more grain, with reflective pauses. Same "
                + "passage and performance notes as audition A.",
            seconds: 23
        ),
        VoiceAudition(
            label: "C · composed",
            detail: "A clearer tone with a slightly brighter pace. "
                + "Compare against A before selecting your narrator.",
            seconds: 23
        ),
    ]
    var selectedAudition = 0
    var playingAudition: Int? = nil

    /// The saved provider voice (step 4+).
    private(set) var savedVoice: Voice?

    init(
        projectID: UUID?,
        projectsRepository: (any DashboardRepository)?,
        voiceRepository: any VoiceRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.voiceRepository = voiceRepository
    }

    var capacity: VoiceCapacity {
        // Illustrative: after saving, the new custom voice consumes a slot.
        VoiceCapacity(usedSlots: savedVoice == nil ? 8 : 9)
    }

    var subtitle: String {
        guard let project else { return "New custom voice" }
        return "\(project.title) → Series narrator"
    }

    var contextNote: String {
        var text = subtitle
        if let narrator = project?.narratorName, !narrator.isEmpty {
            text += ". \(narrator) remains assigned and default until you "
                + "explicitly assign another voice."
        }
        return text
    }

    func load() {
        do {
            if let projectID {
                project = try projectsRepository?.fetchProject(id: projectID)
            }
            if draftName.isEmpty { draftName = "Detroit Narrator" }
            if draftDescription.isEmpty {
                if let project, !project.voiceDesignPrompt.isEmpty {
                    draftDescription = project.voiceDesignPrompt
                } else {
                    draftDescription = "A mature American woman with a warm "
                        + "lower register, lightly textured tone, subtle "
                        + "Great Lakes vowels, clear consonants and measured "
                        + "pacing. Understated, intimate delivery; never "
                        + "theatrical."
                }
            }
            if draftAuditionText.isEmpty {
                draftAuditionText = "The envelope was waiting beneath the "
                    + "sugar bowl. Evelyn knew it had not been there when "
                    + "she left for the funeral."
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the project."
        }
    }

    // MARK: Step transitions

    /// "Generate previews" — previews are mock/provider-driven (M12);
    /// describing and generating previews do not consume a slot.
    func generatePreviews() {
        guard !draftName.trimmingCharacters(in: .whitespaces).isEmpty,
              !draftDescription.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }
        step = .previews
    }

    func selectAudition(_ index: Int) {
        selectedAudition = index
    }

    func playAudition(_ index: Int) {
        playingAudition = index
    }

    /// "Save Voice" — creates a local custom voice record. In M12 this
    /// also performs the provider save + capacity check.
    func saveVoice() {
        let audition = auditions[selectedAudition]
        let voice = Voice(
            name: draftName,
            localLabel: audition.label.replacingOccurrences(of: " · ", with: " "),
            origin: "Created in CoAuthor",
            kind: "Custom",
            roleTag: "Narrator",
            descriptor: audition.label,
            summary: audition.detail,
            tags: ["Custom", "Narrator"],
            sampleSeconds: audition.seconds,
            isAvailable: true,
            designPrompt: draftDescription,
            savedVoiceID: "ca_voice_"
                + draftName.lowercased().replacingOccurrences(of: " ", with: "_"),
            localName: draftName
        )
        try? voiceRepository.insert(voice)
        savedVoice = voice
        step = .assign
    }

    /// "Confirm assignment" — replaces the current narrator for this
    /// role; existing audio files are unchanged.
    func confirmAssignment() {
        guard let project, let savedVoice else { return }
        project.narratorName = savedVoice.name
        project.narratorConfirmed = true
        project.lastEditedAt = Date()
        savedVoice.assignedProjectID = project.id
        savedVoice.assignmentLabel = "\(project.title) · Series narrator"
        clearOtherAssignments(except: savedVoice.id)
        try? projectsRepository?.saveChanges()
        try? voiceRepository.saveChanges()
        finished = true
    }

    /// "Keep {current}" — declines the new voice; existing assignment
    /// stands and no slot was consumed beyond the save itself.
    func keepExisting() {
        reusedExisting = true
        finished = true
    }

    private func clearOtherAssignments(except voiceID: UUID) {
        guard let project else { return }
        guard let others = try? voiceRepository.fetchVoices() else { return }
        for other in others where other.id != voiceID
            && other.assignedProjectID == project.id {
            other.assignedProjectID = nil
            other.assignmentLabel = ""
        }
    }

    var assignedName: String {
        reusedExisting
            ? (project?.narratorName ?? "Marlene")
            : (savedVoice?.name ?? draftName)
    }
}
