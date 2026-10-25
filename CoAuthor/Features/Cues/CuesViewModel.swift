import Foundation

/// Backs the sound-cues list — filters, selection, batch summary.
@Observable
@MainActor
final class CuesViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let cueRepository: any CueRepository
    private let scriptRepository: any ScriptRepository
    private let backendClient: any BackendClient
    private let generator = MockCueGenerator()

    private(set) var project: Project?
    private(set) var cues: [SoundCue] = []
    private(set) var loadError: String?

    var chapterFilter = "All chapters"
    var importanceFilter = "Core / Optional"
    var reviewFilter = "Review status"
    var generationFilter = "Generation"

    /// How many cards the list shows before the "more cues" row.
    var visibleLimit = 8

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        cueRepository: any CueRepository,
        scriptRepository: any ScriptRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.cueRepository = cueRepository
        self.scriptRepository = scriptRepository
        self.backendClient = backendClient
    }

    // MARK: Derived state

    var filteredCues: [SoundCue] {
        cues.filter { cue in
            (chapterFilter == "All chapters" || cue.chapterTitle == chapterFilter)
            && (importanceFilter == "Core / Optional" || cue.importance == importanceFilter)
            && (reviewFilter == "Review status" || cue.reviewState == reviewFilter)
            && (generationFilter == "Generation" || cue.generationState == generationFilter)
        }
    }

    var visibleCues: [SoundCue] {
        Array(filteredCues.prefix(visibleLimit))
    }

    var hiddenCount: Int {
        max(0, filteredCues.count - visibleCues.count)
    }

    var chapterOptions: [String] {
        ["All chapters"] + Array(Set(cues.map(\.chapterTitle))).sorted()
    }

    var reviewOptions: [String] {
        ["Review status", "Approved", "Suggested", "Skipped"]
    }

    var generationOptions: [String] {
        ["Generation", "Ready", "Not generated", "Queued",
         "No audio file needed"]
    }

    var importanceOptions: [String] {
        ["Core / Optional", "Core", "Optional"]
    }

    var selectedCues: [SoundCue] {
        cues.filter(\.isSelected)
    }

    /// "32 cues · 8 approved · Script r4 · 2 selected"
    var subtitle: String {
        let approved = cues.filter { $0.reviewState == "Approved" }.count
        let revision = project?.scriptRevision ?? 0
        return "\(cues.count) cues · \(approved) approved · Script r\(revision)"
            + " · \(selectedCues.count) selected"
    }

    /// Approved audio cues eligible for batch generation — silence
    /// cues are excluded by design.
    var batchEligible: [SoundCue] {
        cues.filter { $0.reviewState == "Approved" && $0.needsAudio }
    }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            let existing = try cueRepository.fetchCues(projectID: projectID)
            if existing.isEmpty, let project {
                if BackendConfiguration.shared.useBackend {
                    Task { await hydrateCues(project) }
                } else {
                    generateLocally(project)
                }
            } else {
                cues = existing
                syncProjectCounts()
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load sound cues."
        }
    }

    /// Mock path — deterministic starter set, no AI calls.
    private func generateLocally(_ project: Project) {
        do {
            let chapters = try scriptRepository.fetchChapters(projectID: projectID)
            let generated = generator.generate(for: project, chapters: chapters)
            for cue in generated {
                try cueRepository.insert(cue)
            }
            cues = generated
            syncProjectCounts()
        } catch {
            loadError = "Couldn't load sound cues."
        }
    }

    /// Backend path — fetches the cue set from the API; falls back
    /// to the mock generator on failure. Deduped by cue number so
    /// repeated hydration can't insert SC-NN twice.
    private func hydrateCues(_ project: Project) async {
        do {
            let dtos: [BackendDTO.Cue] = try await backendClient
                .get("/v1/projects/\(projectID.uuidString)/cues")
            // Re-fetch inside the async gap — a second load() may have
            // populated the store while the request was in flight.
            var numbers = Set(
                try cueRepository.fetchCues(projectID: projectID)
                    .map(\.number)
            )
            for dto in dtos where !numbers.contains(dto.number) {
                try? cueRepository.insert(dto.model(projectID: projectID))
                numbers.insert(dto.number)
            }
            cues = try cueRepository.fetchCues(projectID: projectID)
            syncProjectCounts()
        } catch {
            if cues.isEmpty {
                generateLocally(project)
            }
        }
    }

    // MARK: Actions

    func toggleSelection(_ cue: SoundCue) {
        guard cue.needsAudio else { return }
        cue.isSelected.toggle()
        try? cueRepository.saveChanges()
    }

    /// "Select approved →" — selects every approved cue that needs audio.
    func selectApproved() {
        for cue in cues where cue.reviewState == "Approved" && cue.needsAudio {
            cue.isSelected = true
        }
        try? cueRepository.saveChanges()
    }

    /// "Generate selected cues" — queues selected audio cues (local
    /// state change; paid generation is M12 backend work).
    func generateSelected() {
        for cue in cues where cue.isSelected && cue.needsAudio {
            cue.generationState = "Queued"
            cue.isSelected = false
        }
        try? cueRepository.saveChanges()
    }

    /// "Load →" on the more-cues card.
    func showAll() {
        visibleLimit = Int.max
    }

    /// Keeps `Project.cuesApproved`/`cuesTotal` (shown on the
    /// overview) in sync with the real cue records.
    private func syncProjectCounts() {
        guard let project else { return }
        project.cuesTotal = cues.count
        project.cuesApproved = cues.filter { $0.reviewState == "Approved" }.count
        try? projectsRepository.saveChanges()
    }
}

/// Backs a single cue's detail screen — placement editing, prompt
/// review, alternative selection, batch confirmation.
@Observable
@MainActor
final class CueDetailViewModel {
    let cueID: UUID
    private let projectsRepository: any DashboardRepository
    private let cueRepository: any CueRepository

    private(set) var cue: SoundCue?
    private(set) var project: Project?
    private(set) var batchCues: [SoundCue] = []
    private(set) var silenceExcluded: [SoundCue] = []
    private(set) var loadError: String?

    var isPlaying = false

    init(
        cueID: UUID,
        projectsRepository: any DashboardRepository,
        cueRepository: any CueRepository
    ) {
        self.cueID = cueID
        self.projectsRepository = projectsRepository
        self.cueRepository = cueRepository
    }

    /// "SC-01 · The Envelope · Core ambience · Script r4"
    var subtitle: String {
        guard let cue else { return "" }
        var text = "\(cue.code) · \(cue.chapterTitle) · \(cue.importance) "
            + "\(cue.category.lowercased())"
        if let revision = project?.scriptRevision {
            text += " · Script r\(revision)"
        }
        return text
    }

    /// "SC-01 + SC-04 · 2 approved audio cues. Silence SC-03 excluded."
    var batchSummary: String {
        let names = batchCues.map(\.code).joined(separator: " + ")
        var text = "\(names) · \(batchCues.count) approved audio cues."
        if let silence = silenceExcluded.first {
            text += " Silence \(silence.code) excluded."
        }
        text += " Paid generation requires confirmation."
        return text
    }

    var isApproved: Bool { cue?.reviewState == "Approved" }

    func load() {
        do {
            cue = try cueRepository.fetchCue(id: cueID)
            if let cue {
                project = try projectsRepository.fetchProject(id: cue.projectID)
                let all = try cueRepository.fetchCues(projectID: cue.projectID)
                batchCues = all.filter {
                    $0.reviewState == "Approved" && $0.needsAudio
                }
                silenceExcluded = all.filter(\.isSilence)
                syncProjectCounts(project: project, all: all)
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the cue."
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    /// "Edit cue instructions →" — saves the placement & mixing text.
    func updatePlacement(_ text: String) {
        cue?.placementText = text
        try? cueRepository.saveChanges()
    }

    /// Generation-prompt review actions.
    func approve() {
        cue?.reviewState = "Approved"
        try? cueRepository.saveChanges()
        refreshCounts()
    }

    func reject() {
        cue?.reviewState = "Skipped"
        try? cueRepository.saveChanges()
        refreshCounts()
    }

    func skip() {
        cue?.reviewState = "Skipped"
        try? cueRepository.saveChanges()
        refreshCounts()
    }

    func selectAlternative(_ index: Int) {
        cue?.selectedAlternative = index
        try? cueRepository.saveChanges()
    }

    /// "Confirm sound generation →" — queues the approved audio batch.
    func confirmGeneration() {
        for cue in batchCues {
            cue.generationState = "Queued"
        }
        try? cueRepository.saveChanges()
    }

    /// Keeps `Project.cuesApproved`/`cuesTotal` in sync after review
    /// changes on this detail screen.
    private func syncProjectCounts(project: Project?, all: [SoundCue]) {
        guard let project else { return }
        project.cuesTotal = all.count
        project.cuesApproved = all.filter { $0.reviewState == "Approved" }.count
        try? projectsRepository.saveChanges()
    }

    private func refreshCounts() {
        guard let cue else { return }
        if let all = try? cueRepository.fetchCues(projectID: cue.projectID) {
            syncProjectCounts(project: project, all: all)
        }
    }
}
