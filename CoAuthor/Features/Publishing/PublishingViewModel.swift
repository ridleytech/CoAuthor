import Foundation
import UIKit

/// One row in the documents hub — a readable export derived from
/// project sources. Statuses are computed, not stored.
struct ProjectDocument: Identifiable {
    let id: String
    /// "outline" / "script" / "cueGuide" / "tracker" / "voicePrompts" /
    /// "youtube" — drives which preview card is shown.
    let kind: String
    let title: String
    let status: DocumentStatus
    let summary: String
    let sourceLine: String
    var note: String? = nil
    /// Whether the trailing action says "Update" instead of
    /// "Regenerate" (tracker card).
    var updatesContent = false

    enum DocumentStatus: String {
        case current = "Current"
        case updateAvailable = "Update available"
        case draft = "Draft"
    }
}

/// Backs the documents hub — computed document list with live
/// source lines.
@Observable
@MainActor
final class DocumentsViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let publishingRepository: any PublishingRepository
    private let cueRepository: any CueRepository
    private let outlineRepository: any OutlineRepository
    private let scriptRepository: any ScriptRepository

    private(set) var project: Project?
    private(set) var documents: [ProjectDocument] = []
    private(set) var loadError: String?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        publishingRepository: any PublishingRepository,
        cueRepository: any CueRepository,
        outlineRepository: any OutlineRepository,
        scriptRepository: any ScriptRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.publishingRepository = publishingRepository
        self.cueRepository = cueRepository
        self.outlineRepository = outlineRepository
        self.scriptRepository = scriptRepository
    }

    func load() {
        do {
            guard let project = try projectsRepository.fetchProject(id: projectID)
            else {
                loadError = "Couldn't find that project."
                return
            }
            self.project = project
            let outline = try outlineRepository.fetchOutline(projectID: projectID)
            let cues = try cueRepository.fetchCues(projectID: projectID)
            let kit = try publishingRepository.fetchKit(projectID: projectID)
            let generated = "Generated today, 9:13 AM"
            let approved = cues.filter { $0.reviewState == "Approved" }.count
            let approvedAudio = cues.filter {
                $0.reviewState == "Approved" && $0.needsAudio
            }.count
            let pendingGeneration = cues.contains {
                $0.reviewState == "Approved"
                    && $0.generationState == "Not generated"
            }
            let silenceApproved = cues.contains {
                $0.isSilence && $0.reviewState == "Approved"
            }

            documents = [
                ProjectDocument(
                    id: "outline", kind: "outline",
                    title: "Story Outline",
                    status: .current,
                    summary: "Approved story arc, characters and chapter plan.",
                    sourceLine: "Source: Outline r\(outline?.revision ?? 1) "
                        + "· \(generated)"
                ),
                ProjectDocument(
                    id: "script", kind: "script",
                    title: "Full Script",
                    status: .current,
                    summary: "Ten chapters, formatted for comfortable reading.",
                    sourceLine: "Source: Script r\(project.scriptRevision) "
                        + "· \(generated)"
                ),
                ProjectDocument(
                    id: "cueGuide", kind: "cueGuide",
                    title: "Sound Cue Guide",
                    status: .current,
                    summary: "Source passages, placement and mixing instructions.",
                    sourceLine: "Source: Script r\(project.scriptRevision) "
                        + "· cues r2 · \(generated)",
                    note: "\(approved) of \(cues.count) sounds approved"
                ),
                ProjectDocument(
                    id: "tracker", kind: "tracker",
                    title: "Sound Generation Tracker",
                    status: pendingGeneration ? .updateAvailable : .current,
                    summary: "Cue approvals, generation jobs and selected takes.",
                    sourceLine: "Source: Cues r2 · live assets · \(generated)",
                    note: "\(approvedAudio) approved audio cues"
                        + (silenceApproved
                           ? " · Silence cues approved, not generated" : ""),
                    updatesContent: true
                ),
                ProjectDocument(
                    id: "voicePrompts", kind: "voicePrompts",
                    title: "Voice Prompts",
                    status: .current,
                    summary: "Narrator design, audition passage and "
                        + "performance notes.",
                    sourceLine: "Source: Voice direction r1 · \(generated)",
                    note: "Single narrator"
                        + (project.narratorName.map { " · \($0)" } ?? "")
                ),
                ProjectDocument(
                    id: "youtube", kind: "youtube",
                    title: "YouTube Upload Data",
                    status: (kit?.isSaved == true) ? .current : .draft,
                    summary: "Spoiler-free title, description, tags and "
                        + "chapter placeholders.",
                    sourceLine: "Source: Publishing kit r1 · \(generated)"
                ),
            ]
            loadError = nil
        } catch {
            loadError = "Couldn't load documents."
        }
    }

    /// The tracker card's "Update" action — refreshes its status to
    /// Current locally.
    func markTrackerUpdated() {
        guard let index = documents.firstIndex(where: { $0.id == "tracker" })
        else { return }
        documents[index] = ProjectDocument(
            id: documents[index].id,
            kind: documents[index].kind,
            title: documents[index].title,
            status: .current,
            summary: documents[index].summary,
            sourceLine: documents[index].sourceLine,
            note: documents[index].note,
            updatesContent: documents[index].updatesContent
        )
    }
}

/// Backs the publishing kit screen — YouTube metadata, thumbnail
/// selection, copy actions, save.
@Observable
@MainActor
final class PublishingKitViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let publishingRepository: any PublishingRepository
    private let scriptRepository: any ScriptRepository

    private(set) var project: Project?
    private(set) var kit: PublishingKit?
    private(set) var chapters: [ScriptChapter] = []
    private(set) var loadError: String?

    /// Confirmation shown briefly after a copy action.
    var copiedLabel: String?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        publishingRepository: any PublishingRepository,
        scriptRepository: any ScriptRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.publishingRepository = publishingRepository
        self.scriptRepository = scriptRepository
    }

    /// "YouTube preparation · Spoiler-free · Not a publishing action"
    var subtitle: String {
        "YouTube preparation · Spoiler-free · Not a publishing action"
    }

    func load() {
        do {
            guard let project = try projectsRepository.fetchProject(id: projectID)
            else {
                loadError = "Couldn't find that project."
                return
            }
            self.project = project
            chapters = try scriptRepository.fetchChapters(projectID: projectID)
            if let kit = try publishingRepository.fetchKit(projectID: projectID) {
                self.kit = kit
            } else {
                let kit = Self.makeDefault(for: project)
                try publishingRepository.insertKit(kit)
                self.kit = kit
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the publishing kit."
        }
    }

    /// Chapter placeholder rows — "[timestamp] The Envelope".
    var chapterPlaceholders: [String] {
        chapters.map { "[timestamp] \($0.title)" }
    }

    var titleCount: Int { kit?.youtubeTitle.count ?? 0 }

    func saveKit() {
        guard let kit else { return }
        kit.isSaved = true
        kit.savedAt = .now
        try? publishingRepository.saveChanges()
    }

    /// Local copy action — real clipboard write.
    func copy(_ text: String, label: String) {
        UIPasteboard.general.string = text
        copiedLabel = label
    }

    private static func makeDefault(for project: Project) -> PublishingKit {
        PublishingKit(
            projectID: project.id,
            youtubeTitle: "\(project.title) | An Audiobook",
            descriptionText: project.premise.isEmpty
                ? "An atmospheric story told by a single narrator."
                : project.premise,
            tagsText: "audiobook, fiction, \(project.genre.lowercased())",
            pinnedComment: "Please keep comments spoiler-free.",
            thumbnailTitle: "\(project.title) · Cover",
            thumbnailDetail: "Story title over cover art."
        )
    }
}

/// Backs the exports screen — package contents, issues, latest
/// export, prepare action.
@Observable
@MainActor
final class ExportsViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let publishingRepository: any PublishingRepository
    private let cueRepository: any CueRepository
    private let scriptRepository: any ScriptRepository
    private let generationRepository: any GenerationRepository
    private let backendClient: any BackendClient

    private(set) var project: Project?
    private(set) var latestExport: ExportRecord?
    private(set) var loadError: String?

    private var chapters: [ScriptChapter] = []
    private var cues: [SoundCue] = []

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        publishingRepository: any PublishingRepository,
        cueRepository: any CueRepository,
        scriptRepository: any ScriptRepository,
        generationRepository: any GenerationRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.publishingRepository = publishingRepository
        self.cueRepository = cueRepository
        self.scriptRepository = scriptRepository
        self.generationRepository = generationRepository
        self.backendClient = backendClient
    }

    /// "N Outdated" narration count.
    var outdatedChapters: Int {
        chapters.filter(\.isAudioOutdated).count
    }

    /// Approved audio cues that still need a generated file.
    var missingSounds: Int {
        cues.filter {
            $0.needsAudio && $0.generationState == "Not generated"
                && $0.reviewState == "Approved"
        }.count
    }

    var issueCount: Int {
        (outdatedChapters > 0 ? 1 : 0) + (missingSounds > 0 ? 1 : 0)
    }

    var exportDateLine: String {
        guard let latestExport else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if Calendar.current.isDateInToday(latestExport.createdAt) {
            return "Today, \(formatter.string(from: latestExport.createdAt))"
        }
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: latestExport.createdAt)
    }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            chapters = try scriptRepository.fetchChapters(projectID: projectID)
            cues = try cueRepository.fetchCues(projectID: projectID)
            latestExport = try publishingRepository
                .fetchExports(projectID: projectID).first
            loadError = nil
        } catch {
            loadError = "Couldn't load exports."
        }
    }

    /// "Prepare selected package" — records a completed export and a
    /// matching activity job. No files are produced (local only).
    func preparePackage() {
        guard let project else { return }
        let export = ExportRecord(
            projectID: project.id,
            title: "Complete project package",
            fileCount: 8 + chapters.count,
            sizeLabel: "2.4 MB",
            status: "Complete"
        )
        try? publishingRepository.insertExport(export)
        if BackendConfiguration.shared.useBackend {
            // Backend path — the API records the package job.
            Task { await postExportJob(project: project, export: export) }
        } else {
            insertLocalJob(project: project)
        }
        latestExport = export
    }

    private func postExportJob(project: Project, export: ExportRecord) async {
        struct Payload: Encodable {
            let projectTitle: String
            let fileCount: Int
        }
        do {
            let response: BackendDTO.ExportResponse = try await backendClient
                .post("/v1/exports", body: Payload(
                    projectTitle: project.title,
                    fileCount: export.fileCount
                ))
            try? generationRepository.insert(
                response.job.model(projectID: project.id)
            )
        } catch {
            insertLocalJob(project: project)
        }
    }

    private func insertLocalJob(project: Project) {
        let job = GenerationJob(
            projectID: project.id,
            projectTitle: project.title,
            kind: "Package export",
            subject: "Complete project package",
            provider: "CoAuthor",
            status: "ready",
            startedAt: .now,
            detail: "Documents + JSON + kit"
        )
        try? generationRepository.insert(job)
    }
}
