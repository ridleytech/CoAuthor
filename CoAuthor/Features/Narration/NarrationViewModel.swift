import Foundation

/// Backs the narration studio — narrator summary, chapter job states,
/// generation selection, per-state actions.
@Observable
@MainActor
final class NarrationViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let scriptRepository: any ScriptRepository

    private(set) var project: Project?
    private(set) var chapters: [ScriptChapter] = []
    private(set) var loadError: String?

    /// The chapter currently loaded in the bottom player.
    private(set) var playingChapter: ScriptChapter?
    var isPlaying = false

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        scriptRepository: any ScriptRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.scriptRepository = scriptRepository
    }

    // MARK: Derived state

    var narratorName: String {
        project?.narratorName ?? "Narrator"
    }

    /// "ElevenLabs · Marlene · 3 of 10 chapters generated"
    var subtitle: String {
        "ElevenLabs · \(narratorName) · "
            + "\(generatedCount) of \(chapters.count) chapters generated"
    }

    var generatedCount: Int {
        chapters.filter { $0.audioState == "ready" }.count
    }

    var selectedChapters: [ScriptChapter] {
        chapters.filter(\.isSelectedForGeneration)
    }

    /// "☑ The House Key + What the River Keeps"
    var selectionSummary: String {
        selectedChapters.map(\.title).joined(separator: " + ")
    }

    /// Estimated audio for the selection ("11:48") — from script length.
    var selectionEstimate: String {
        let total = selectedChapters.reduce(0) { $0 + $1.estimatedSeconds }
        return ScriptReaderViewModel.format(total)
    }

    var hasSelection: Bool { !selectedChapters.isEmpty }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            chapters = try scriptRepository.fetchChapters(projectID: projectID)
            if playingChapter == nil {
                playingChapter = chapters.first { $0.audioState == "ready" }
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load chapter recordings."
        }
    }

    // MARK: Actions

    /// Chapter checkbox — toggles generation selection (persisted).
    func toggleSelection(_ chapter: ScriptChapter) {
        guard chapter.audioState == "none" || chapter.audioState == "canceled"
        else { return }
        chapter.isSelectedForGeneration.toggle()
        try? scriptRepository.saveChanges()
    }

    /// "Cancel job →" — queued/generating back to canceled.
    func cancelJob(_ chapter: ScriptChapter) {
        chapter.audioState = "canceled"
        try? scriptRepository.saveChanges()
    }

    /// "Retry →" — failed back to queued.
    func retry(_ chapter: ScriptChapter) {
        chapter.audioState = "queued"
        try? scriptRepository.saveChanges()
    }

    /// "Select chapter →" — same as toggling the checkbox on.
    func selectForGeneration(_ chapter: ScriptChapter) {
        chapter.isSelectedForGeneration = true
        try? scriptRepository.saveChanges()
    }

    /// The first selected chapter — the review screen's confirm card
    /// covers the whole selection.
    var firstSelectedChapter: ScriptChapter? {
        selectedChapters.first
    }

    /// "Generate selected chapters" — routes to the review screen's
    /// confirm-generation card (no fake job kickoff).
    func chapterForReview() -> ScriptChapter? {
        firstSelectedChapter ?? chapters.first { $0.audioState == "ready" }
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func loadPlayer(_ chapter: ScriptChapter) {
        playingChapter = chapter
        isPlaying = false
    }
}

/// Backs the audio review screen — playback of a generated take plus
/// the paid confirm-generation card for the selected batch.
@Observable
@MainActor
final class AudioReviewViewModel {
    let chapterID: UUID
    private let projectsRepository: any DashboardRepository
    private let scriptRepository: any ScriptRepository

    private(set) var chapter: ScriptChapter?
    private(set) var project: Project?
    private(set) var selectedBatch: [ScriptChapter] = []
    private(set) var loadError: String?

    var isPlaying = false
    var positionSeconds: Int = 84

    init(
        chapterID: UUID,
        projectsRepository: any DashboardRepository,
        scriptRepository: any ScriptRepository
    ) {
        self.chapterID = chapterID
        self.projectsRepository = projectsRepository
        self.scriptRepository = scriptRepository
    }

    /// "The Basement Desk · Script r4 · Audio take 1 · 06:06"
    var subtitle: String {
        guard let chapter else { return "" }
        var text = "\(chapter.title) · Script r\(chapter.revision)"
            + " · Audio take \(chapter.audioTake)"
        if chapter.audioSeconds > 0 {
            text += " · \(ScriptReaderViewModel.format(chapter.audioSeconds))"
        }
        return text
    }

    var narratorName: String {
        project?.narratorName ?? "Marlene"
    }

    var batchSummary: String {
        selectedBatch.map(\.title).joined(separator: " + ")
    }

    var batchEstimate: String {
        let total = selectedBatch.reduce(0) { $0 + $1.estimatedSeconds }
        return ScriptReaderViewModel.format(total)
    }

    /// Source-passage timestamps — the played slice in the design.
    var sourceRange: String { "01:24–01:48" }

    /// The excerpt shown in the Source card — first paragraph.
    var sourceExcerpt: String {
        guard let chapter else { return "" }
        let paragraph = chapter.body
            .components(separatedBy: "\n\n").first ?? chapter.body
        return "\"\(paragraph)\""
    }

    var isApproved: Bool { chapter?.reviewState == "Approved" }

    func load() {
        do {
            chapter = try scriptRepository.fetchChapter(id: chapterID)
            if let chapter {
                project = try projectsRepository.fetchProject(id: chapter.projectID)
                positionSeconds = chapter.audioPosition
                selectedBatch = try scriptRepository
                    .fetchChapters(projectID: chapter.projectID)
                    .filter(\.isSelectedForGeneration)
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the audio."
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    /// "Approve audio" — persists the review state on the take.
    func approve() {
        guard let chapter else { return }
        chapter.reviewState = "Approved"
        try? scriptRepository.saveChanges()
    }

    /// "Confirm generation →" — queues the selected batch. Actual paid
    /// generation is backend work (M12); this records intent + state.
    func confirmGeneration() {
        for chapter in selectedBatch {
            chapter.audioState = "queued"
            chapter.isSelectedForGeneration = false
        }
        selectedBatch = []
        try? scriptRepository.saveChanges()
    }
}
