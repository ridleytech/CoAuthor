import Foundation

/// Backs the full-screen chapter edit & revision screen.
/// Holds a proposed rewrite alongside the original; accepting persists
/// the proposal as the next revision (leaving generated audio outdated).
@Observable
@MainActor
final class RevisionViewModel {
    let chapterID: UUID
    private let projectsRepository: any DashboardRepository
    private let scriptRepository: any ScriptRepository

    private(set) var chapter: ScriptChapter?
    private(set) var project: Project?
    private(set) var loadError: String?

    /// The proposed r(n+1) text — editable in the full-screen editor.
    var proposedBody = ""
    private var variantIndex = 0

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
            }
            if proposedBody.isEmpty, let chapter {
                proposedBody = Self.variants(of: chapter.body)[0]
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the chapter."
        }
    }

    var currentRevision: Int { chapter?.revision ?? 1 }
    var proposedRevision: Int { currentRevision + 1 }

    /// "The Envelope · r3 → proposed r4 · Full-screen editor · Not applied"
    var breadcrumb: String {
        guard let chapter else { return "" }
        return "\(chapter.title) · r\(currentRevision) → proposed "
            + "r\(proposedRevision) · Full-screen editor · Not applied"
    }

    /// "Try another revision" — cycles deterministic mock variants.
    /// Real rewrite suggestions are backend-driven (M12).
    func tryAnotherVariant() {
        guard let chapter else { return }
        let variants = Self.variants(of: chapter.body)
        variantIndex = (variantIndex + 1) % variants.count
        proposedBody = variants[variantIndex]
    }

    /// Accept: save the proposal as the next revision. Generated audio
    /// stays at its old revision and becomes outdated.
    func accept() {
        guard let chapter, !proposedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        chapter.body = proposedBody
        chapter.revision += 1
        try? scriptRepository.saveChanges()
    }

    /// Deterministic mock rewrites — tightened / expanded takes on the
    /// original. Backend rewrite styles land in M12.
    static func variants(of body: String) -> [String] {
        let paragraphs = body.components(separatedBy: "\n\n")
        let tightened = paragraphs.first ?? body
        let expanded = body + "\n\nShe folded the thought away with the rest "
            + "of them — the ones she kept for later, when the house was "
            + "quiet enough to be honest."
        return [tightened == body ? expanded : tightened, expanded]
    }
}
