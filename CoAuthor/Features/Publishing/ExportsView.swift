import SwiftUI
import SwiftData

/// Exports — "Bring your story with you." Package contents,
/// source-issue resolution, latest export, prepare action.
/// Reference: Designs/Full Content/Exports/Full Content.png
struct ExportsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: ExportsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Exports") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load exports",
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
                let vm = ExportsViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    publishingRepository: SwiftDataPublishingRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext),
                    generationRepository: SwiftDataGenerationRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: ExportsViewModel) -> some View {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bring your story with you.")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text("Select files · Resolve source changes · Download")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    packageCard(project, viewModel)
                    if viewModel.issueCount > 0 {
                        resolveCard(viewModel)
                    }
                    latestExportCard(viewModel)
                    noPublishCard
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Prepare selected package") {
                viewModel.preparePackage()
            }
        }
    }

    // MARK: Package contents

    private func packageCard(
        _ project: Project,
        _ viewModel: ExportsViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Package contents", systemImage: "checkmark.square.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Ready", kind: .ready)
                }
                packageRow("Documents · Word + Excel · Ready")
                packageRow("Structured JSON · Ready")
                if viewModel.outdatedChapters > 0 {
                    flaggedRow(
                        "Narration",
                        "\(viewModel.outdatedChapters) Outdated",
                        badge: "Outdated"
                    )
                } else {
                    packageRow("Narration · Ready")
                }
                if viewModel.missingSounds > 0 {
                    flaggedRow(
                        "Sounds",
                        "\(viewModel.missingSounds) Missing audio files",
                        badge: "Missing"
                    )
                } else {
                    packageRow("Sounds · Ready")
                }
                packageRow("Thumbnail + kit · Ready")
                packageRow("Complete project package", bold: true)
                Divider().overlay(Color.caHairline)
                Button {
                    coordinator.push(.placeholder(
                        title: "Package selection",
                        milestone: "M12"
                    ))
                } label: {
                    HStack(spacing: 6) {
                        Text("Edit package selection")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func packageRow(_ text: String, bold: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.caInk)
            Text(text)
                .font(.subheadline.weight(bold ? .semibold : .regular))
                .foregroundStyle(Color.caInk)
        }
    }

    private func flaggedRow(
        _ title: String,
        _ detail: String,
        badge: String
    ) -> some View {
        HStack(spacing: 8) {
            StatusBadge(badge, kind: .warm)
            Text("\(title) · \(detail)")
                .font(.subheadline)
                .foregroundStyle(Color.caInk)
        }
    }

    // MARK: Resolve card

    private func resolveCard(_ viewModel: ExportsViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Resolve before packaging")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("\(viewModel.issueCount) issues", kind: .warmLight)
                }
                Text("Exclude outdated audio or regenerate it. Missing "
                     + "sounds can be listed in a manifest without audio "
                     + "files.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Divider().overlay(Color.caHairline)
                Button {
                    coordinator.push(.narrationStudio(projectID: projectID))
                } label: {
                    HStack(spacing: 6) {
                        Text("Review affected assets")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Latest export

    private func latestExportCard(_ viewModel: ExportsViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Latest export")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    if viewModel.latestExport != nil {
                        StatusBadge("Complete", kind: .ready)
                    }
                }
                if let export = viewModel.latestExport {
                    Text("\(export.title) · \(export.fileCount) files "
                         + "· \(export.sizeLabel)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                    Text("\(viewModel.exportDateLine) · Estimate unavailable")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    Divider().overlay(Color.caHairline)
                    if let url = viewModel.packageFileURL {
                        // Real package — share sheet hands off the zip.
                        ShareLink(item: url) {
                            HStack(spacing: 6) {
                                Text("Share package")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.caInk)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            coordinator.push(.placeholder(
                                title: "Package download",
                                milestone: "M12"
                            ))
                        } label: {
                            HStack(spacing: 6) {
                                Text("Download package")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.caInk)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("No exports yet — prepare a package to see it here.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: No-publish note

    private var noPublishCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Download does not publish to YouTube")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("CoAuthor prepares files only. Upload through your "
                     + "own account when you're ready.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
