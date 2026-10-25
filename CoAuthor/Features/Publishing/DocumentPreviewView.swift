import SwiftUI
import SwiftData

/// Backs a single document's preview — loads the source records the
/// preview renders (script chapters, cues, outline, kit).
@Observable
@MainActor
final class DocumentPreviewViewModel {
    let projectID: UUID
    private let projectsRepository: any DashboardRepository
    private let scriptRepository: any ScriptRepository
    private let cueRepository: any CueRepository
    private let outlineRepository: any OutlineRepository
    private let publishingRepository: any PublishingRepository

    private(set) var project: Project?
    private(set) var chapters: [ScriptChapter] = []
    private(set) var cues: [SoundCue] = []
    private(set) var outlineChapters: [OutlineChapter] = []
    private(set) var kit: PublishingKit?
    private(set) var loadError: String?

    init(
        projectID: UUID,
        projectsRepository: any DashboardRepository,
        scriptRepository: any ScriptRepository,
        cueRepository: any CueRepository,
        outlineRepository: any OutlineRepository,
        publishingRepository: any PublishingRepository
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.scriptRepository = scriptRepository
        self.cueRepository = cueRepository
        self.outlineRepository = outlineRepository
        self.publishingRepository = publishingRepository
    }

    func load() {
        do {
            project = try projectsRepository.fetchProject(id: projectID)
            chapters = try scriptRepository.fetchChapters(projectID: projectID)
            cues = try cueRepository.fetchCues(projectID: projectID)
            if let outline = try outlineRepository.fetchOutline(projectID: projectID) {
                outlineChapters = try outlineRepository
                    .fetchChapters(outlineID: outline.id)
            }
            kit = try publishingRepository.fetchKit(projectID: projectID)
            loadError = nil
        } catch {
            loadError = "Couldn't load the preview."
        }
    }
}

/// Document preview — renders the real source content: script prose
/// for Word exports, a cue table for the Excel tracker, or a text
/// summary for the other documents.
/// Reference: Designs/Full Content/Document previews/Full Content.png
struct DocumentPreviewView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    let kind: String
    @State private var viewModel: DocumentPreviewViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Preview") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load the preview",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let vm = DocumentPreviewViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext),
                    outlineRepository: SwiftDataOutlineRepository(context: modelContext),
                    publishingRepository: SwiftDataPublishingRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ project: Project,
        _ viewModel: DocumentPreviewViewModel
    ) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .publish,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id) : nil,
                audioDestination: project.narratorConfirmed
                    ? .narrationStudio(projectID: project.id) : nil
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(project, viewModel)
                    switch kind {
                    case "tracker", "cueGuide":
                        trackerCard(viewModel)
                    case "outline":
                        outlineCard(project, viewModel)
                    case "voicePrompts":
                        voicePromptsCard(project)
                    case "youtube":
                        youtubeCard(viewModel)
                    default:
                        scriptCard(project, viewModel)
                        trackerCard(viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: ctaTitle) {
                coordinator.push(.placeholder(
                    title: "Document download",
                    milestone: "M12"
                ))
            }
        }
    }

    private var ctaTitle: String {
        switch kind {
        case "tracker", "cueGuide": "Download Excel tracker"
        default: "Download Word document"
        }
    }

    private var formatLabel: String {
        switch kind {
        case "tracker", "cueGuide": "Excel preview"
        default: "Word preview"
        }
    }

    private var documentTitle: String {
        switch kind {
        case "outline": "Story Outline"
        case "cueGuide": "Sound Cue Guide"
        case "tracker": "Sound Generation Tracker"
        case "voicePrompts": "Voice Prompts"
        case "youtube": "YouTube Upload Data"
        default: "Full Script"
        }
    }

    // MARK: Header

    private func titleBlock(
        _ project: Project,
        _ viewModel: DocumentPreviewViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(documentTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.caInk)
                Spacer()
                Text("100%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
            }
            Text("\(formatLabel) · Script r\(project.scriptRevision) · Current")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            HStack(spacing: 6) {
                InfoPill("Script r\(project.scriptRevision) · Current")
                StatusBadge("Outdated check", kind: .warmLight)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Script preview card

    private func scriptCard(
        _ project: Project,
        _ viewModel: DocumentPreviewViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Text("Full Script · Chapter 1–\(viewModel.chapters.count)")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    Spacer()
                    InfoPill("Preview")
                    Button("Download") {}
                        .buttonStyle(CAPrimaryButtonStyle())
                }
                Divider().overlay(Color.caHairline)
                Text(project.title)
                    .font(.caSerif(20))
                    .foregroundStyle(Color.caInk)
                Text(project.genre)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text(project.settingDescriptor)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                if let first = viewModel.chapters.first {
                    Text("Chapter \(first.number) · \(first.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                        .padding(.top, 6)
                    ForEach(
                        first.body.components(separatedBy: "\n\n"),
                        id: \.self
                    ) { paragraph in
                        Text(paragraph)
                            .font(.caSerif(15))
                            .foregroundStyle(Color.caInk)
                            .lineSpacing(4)
                    }
                }
                Divider().overlay(Color.caHairline)
                HStack {
                    Text("Estimate unavailable")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    Spacer()
                    Button {
                        coordinator.push(.placeholder(
                            title: "Regenerate document",
                            milestone: "M12"
                        ))
                    } label: {
                        Text("Regenerate")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: 8,
                                    style: .continuous
                                )
                                .strokeBorder(Color.caHairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Sound tracker card

    private func trackerCard(_ viewModel: DocumentPreviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sound tracker")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Text("Excel preview · \(viewModel.cues.count) cues")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    Spacer()
                    Button("Download Excel") {
                        coordinator.push(.placeholder(
                            title: "Document download",
                            milestone: "M12"
                        ))
                    }
                    .buttonStyle(CAPrimaryButtonStyle())
                }
                Divider().overlay(Color.caHairline)
                HStack {
                    Text("ID").frame(width: 44, alignment: .leading)
                    Text("Cue").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Review").frame(width: 86, alignment: .leading)
                    Text("Generation").frame(width: 96, alignment: .leading)
                }
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
                ForEach(viewModel.cues) { cue in
                    HStack(alignment: .top) {
                        Text(cue.code)
                            .frame(width: 44, alignment: .leading)
                        Text(cue.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(cue.reviewState)
                            .frame(width: 86, alignment: .leading)
                        Text(cue.isSilence ? "No file" : cue.generationState)
                            .frame(width: 96, alignment: .leading)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.caInk)
                    Divider().overlay(Color.caHairline)
                }
                Text("Estimate unavailable")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Other preview cards

    private func outlineCard(
        _ project: Project,
        _ viewModel: DocumentPreviewViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                previewHeader(
                    title: project.title,
                    subtitle: "Story Outline · "
                        + "\(viewModel.outlineChapters.count) chapters"
                )
                Divider().overlay(Color.caHairline)
                ForEach(viewModel.outlineChapters) { chapter in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(chapter.number). \(chapter.title)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.caInk)
                        Text(chapter.summary)
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                            .lineLimit(2)
                    }
                }
                Text("Estimate unavailable")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func voicePromptsCard(_ project: Project) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                previewHeader(
                    title: "Voice Prompts",
                    subtitle: "Voice direction r1 · Single narrator"
                )
                Divider().overlay(Color.caHairline)
                if !project.voiceDesignPrompt.isEmpty {
                    Text(project.voiceDesignPrompt)
                        .font(.callout)
                        .foregroundStyle(Color.caInk)
                } else {
                    Text("No voice design prompt saved yet.")
                        .font(.callout)
                        .foregroundStyle(Color.caSecondary)
                }
                if let narrator = project.narratorName {
                    Text("Narrator: \(narrator)")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text("Estimate unavailable")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func youtubeCard(_ viewModel: DocumentPreviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                previewHeader(
                    title: "YouTube Upload Data",
                    subtitle: "Publishing kit · Spoiler-free"
                )
                Divider().overlay(Color.caHairline)
                if let kit = viewModel.kit {
                    previewLine("Title", kit.youtubeTitle)
                    previewLine("Description", kit.descriptionText)
                    previewLine("Tags", kit.tagsText)
                    previewLine("Pinned comment", kit.pinnedComment)
                } else {
                    Text("No publishing kit saved yet.")
                        .font(.callout)
                        .foregroundStyle(Color.caSecondary)
                }
                Text("Estimate unavailable")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func previewHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.caInk)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
        }
    }

    private func previewLine(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.caSecondary)
            Text(value)
                .font(.callout)
                .foregroundStyle(Color.caInk)
        }
    }
}
