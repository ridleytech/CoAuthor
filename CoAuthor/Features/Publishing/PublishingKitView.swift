import SwiftUI
import SwiftData

/// Publishing kit — YouTube upload data: spoiler-free title,
/// description, tags, chapter placeholders, thumbnail preview.
/// Preparing files only — "Not a publishing action."
/// Reference: Designs/Full Content/Publishing kit/Full Content.png
struct PublishingKitView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: PublishingKitViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Publishing kit") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project,
                   let kit = viewModel.kit {
                    content(project, kit, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load the publishing kit",
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
                let vm = PublishingKitViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    publishingRepository: SwiftDataPublishingRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ project: Project,
        _ kit: PublishingKit,
        _ viewModel: PublishingKitViewModel
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
                    titleBlock(viewModel)
                    heroImage(project)
                    titleCard(kit, viewModel)
                    descriptionCard(kit, viewModel)
                    tagsCard(kit, viewModel)
                    chaptersCard(viewModel)
                    thumbnailCard(kit)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Save publishing kit") {
                viewModel.saveKit()
                coordinator.pop()
            }
        }
    }

    private func titleBlock(_ viewModel: PublishingKitViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ready to be discovered.")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.caInk)
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            HStack(spacing: 6) {
                StatusBadge("Kit ready", kind: .warmLight)
                StatusBadge("Estimate unavailable", kind: .neutral)
            }
            if let copied = viewModel.copiedLabel {
                Text("Copied \(copied) to the clipboard")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func heroImage(_ project: Project) -> some View {
        Image(project.coverImageName ?? "DashboardHero")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
            .accessibilityLabel("Selected thumbnail for \(project.title)")
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.image,
                    style: .continuous
                )
            )
    }

    private func titleCard(
        _ kit: PublishingKit,
        _ viewModel: PublishingKitViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("\(viewModel.titleCount) / 100")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text(kit.youtubeTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Divider().overlay(Color.caHairline)
                cardLink("Copy title") {
                    viewModel.copy(kit.youtubeTitle, label: "title")
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func descriptionCard(
        _ kit: PublishingKit,
        _ viewModel: PublishingKitViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(kit.descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Divider().overlay(Color.caHairline)
                cardLink("Copy description") {
                    viewModel.copy(kit.descriptionText, label: "description")
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func tagsCard(
        _ kit: PublishingKit,
        _ viewModel: PublishingKitViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags & pinned comment")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(kit.tagsText)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Text(kit.pinnedComment)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Divider().overlay(Color.caHairline)
                cardLink("Copy tags / Pinned comment") {
                    viewModel.copy(
                        kit.tagsText + "\n\n" + kit.pinnedComment,
                        label: "tags"
                    )
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func chaptersCard(_ viewModel: PublishingKitViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chapters & disclosure")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Add chapter timestamps after the final audio or "
                     + "video is assembled.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                ForEach(
                    viewModel.chapterPlaceholders,
                    id: \.self
                ) { placeholder in
                    Text(placeholder)
                        .font(.callout)
                        .foregroundStyle(Color.caInk)
                }
                if let disclosure = viewModel.kit?.disclosureText {
                    Text(disclosure)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Divider().overlay(Color.caHairline)
                cardLink("Copy chapter placeholders") {
                    viewModel.copy(
                        viewModel.chapterPlaceholders.joined(separator: "\n"),
                        label: "chapter placeholders"
                    )
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func thumbnailCard(_ kit: PublishingKit) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected thumbnail preview")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(kit.thumbnailTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Text(kit.thumbnailDetail)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Divider().overlay(Color.caHairline)
                cardLink("Generate / Compare / Download") {
                    coordinator.push(.placeholder(
                        title: "Thumbnail generation",
                        milestone: "M12"
                    ))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func cardLink(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.caInk)
        }
        .buttonStyle(.plain)
    }
}
