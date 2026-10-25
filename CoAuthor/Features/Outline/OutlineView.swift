import SwiftUI
import SwiftData

/// Outline workspace — sections picker, featured chapter card,
/// chapter arc, character card, private ending, approval CTA.
/// Reference: Designs/Full Content/Outline workspace/Full Content.png
struct OutlineView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: OutlineViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Outline") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load outline",
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
                let vm = OutlineViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    outlineRepository: SwiftDataOutlineRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: OutlineViewModel) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .story,
                storyDestination: .outline(projectID: project.id),
                audioDestination: project.narratorConfirmed
                    ? .narrationStudio(projectID: project.id) : nil
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(viewModel)
                    sectionsPicker(viewModel)
                    featuredChapterCard(viewModel)
                    arcCard(viewModel)
                    if let character = viewModel.characters.first {
                        characterCard(character)
                    }
                    privateEndingCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }

            BottomCTA(
                title: viewModel.isApproved
                    ? "Outline approved — generate script"
                    : "Approve outline and generate script"
            ) {
                viewModel.approve()
                coordinator.push(.scriptChapters(projectID: project.id))
            }
        }
    }

    private func titleBlock(_ viewModel: OutlineViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Review your outline.")
                .font(.caSerif(28))
                .foregroundStyle(Color.caInk)
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: Sections picker

    private func sectionsPicker(_ viewModel: OutlineViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.outline?.sections ?? [], id: \.self) { section in
                    let focused = viewModel.focusedSection == section
                    Button {
                        viewModel.focusSection(section)
                    } label: {
                        Text(section)
                            .font(.caption.weight(focused ? .semibold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(focused ? Color.caInk : Color.caSurface)
                            .foregroundStyle(focused ? Color.caSurface : Color.caInk)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.caHairline, lineWidth: focused ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Featured chapter

    @ViewBuilder
    private func featuredChapterCard(_ viewModel: OutlineViewModel) -> some View {
        if let chapter = viewModel.featuredChapter {
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Chapter \(chapter.number) · ≈\(chapter.estimatedMinutes) min")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                        Spacer()
                        Button {
                            coordinator.push(.chapterEdit(chapterID: chapter.id))
                        } label: {
                            Text("Edit chapter")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.caInk)
                        }
                    }
                    Text(chapter.title)
                        .font(.caSerif(20))
                        .foregroundStyle(Color.caInk)
                    Text(chapter.summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    if !chapter.turn.isEmpty {
                        Text("Turn: \(chapter.turn)")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                }
                .padding(Theme.Spacing.card)
            }
        }
    }

    // MARK: Chapter arc

    private func arcCard(_ viewModel: OutlineViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel(viewModel.arcTitle)
                    Spacer()
                    if let outline = viewModel.outline {
                        Button {
                            coordinator.push(.chapterList(outlineID: outline.id))
                        } label: {
                            Text("View all")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.caSecondary)
                        }
                    }
                }
                ForEach(viewModel.chapters) { chapter in
                    Button {
                        viewModel.select(chapter)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(chapter.number)")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.caSecondary)
                                .frame(width: 20, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(chapter.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.caInk)
                                Text(chapter.summary)
                                    .font(.caption)
                                    .foregroundStyle(Color.caSecondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            if chapter.id == viewModel.featuredChapter?.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.caInk)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Character

    private func characterCard(_ character: OutlineCharacter) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Characters")
                HStack {
                    Text(character.name)
                        .font(.caSerif(20))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text(character.role.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                }
                Text(character.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.placeholder(title: "Edit character", milestone: "M12"))
                } label: {
                    Text("Edit character")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caInk)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Private ending

    private func privateEndingCard(_ viewModel: OutlineViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Label("Private ending", systemImage: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                if let ending = viewModel.outline?.privateEnding, !ending.isEmpty {
                    Text(ending)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                Text("Hidden from shared exports until you approve it.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
