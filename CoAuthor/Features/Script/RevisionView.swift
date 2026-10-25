import SwiftUI
import SwiftData

/// Full-screen chapter edit & revision — original vs proposed passage,
/// revision actions, audio impact, accept/discard.
/// Reference: Designs/Full Content/Full-screen chapter edit & revision
struct RevisionView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let chapterID: UUID
    @State private var viewModel: RevisionViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Revision") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let chapter = viewModel.chapter {
                    content(chapter, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load chapter",
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
                let vm = RevisionViewModel(
                    chapterID: chapterID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ chapter: ScriptChapter, _ viewModel: RevisionViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    breadcrumb(viewModel)
                    Text("Revise a passage")
                        .font(.caSerif(28))
                        .foregroundStyle(Color.caInk)

                    beforeCard(chapter, viewModel)
                    afterCard(viewModel)
                    revisionActionsCard
                    Button {
                        viewModel.tryAnotherVariant()
                    } label: {
                        Text("Try another revision")
                    }
                    .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                    audioImpactCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }

            BottomCTA(title: "Accept revision") {
                viewModel.accept()
                coordinator.pop()
            }
        }
    }

    private func breadcrumb(_ viewModel: RevisionViewModel) -> some View {
        (Text(viewModel.chapter?.title ?? "").fontWeight(.semibold)
            + Text(" · r\(viewModel.currentRevision) → proposed r\(viewModel.proposedRevision)"
                   + " · Full-screen editor · Not applied"))
        .font(.caption)
        .foregroundStyle(Color.caSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Before / After

    private func beforeCard(_ chapter: ScriptChapter, _ viewModel: RevisionViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    StatusBadge("Before", kind: .neutral)
                    Text("Original r\(viewModel.currentRevision)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                }
                Text(chapter.body)
                    .font(.caSerif(16))
                    .lineSpacing(4)
                    .foregroundStyle(Color.caInk)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func afterCard(_ viewModel: RevisionViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("After")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSurface)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.caInk)
                        .clipShape(Capsule())
                    Text("Proposed r\(viewModel.proposedRevision)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Not yet applied", kind: .warmLight)
                }
                TextEditor(text: Binding(
                    get: { viewModel.proposedBody },
                    set: { viewModel.proposedBody = $0 }
                ))
                .font(.caSerif(16))
                .lineSpacing(4)
                .scrollContentBackground(.hidden)
                .foregroundStyle(Color.caInk)
                .frame(minHeight: 140)
                Button {
                    coordinator.pop()
                } label: {
                    HStack {
                        Text("Keep original r\(viewModel.currentRevision)")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.caField)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Revision actions

    private var revisionActionsCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Revision actions")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                    .padding(.bottom, 8)
                actionRow("Rewrite selection")
                Divider().overlay(Color.caHairline)
                actionRow("Expand description")
                Divider().overlay(Color.caHairline)
                actionRow("Adjust dialogue")
                SectionLabel("Production")
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                actionRow("Add production note")
                Divider().overlay(Color.caHairline)
                actionRow("Suggest sound cue")
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func actionRow(_ title: String) -> some View {
        Button {
            coordinator.push(.placeholder(title: title, milestone: "M12"))
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Audio impact

    private func audioImpactCard(_ viewModel: RevisionViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Audio impact")
                Text("Accepting saves r\(viewModel.proposedRevision) and marks "
                     + "r\(viewModel.currentRevision) narration Outdated. "
                     + "No paid audio is generated automatically. Your "
                     + "original remains in revision history.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                StatusBadge("Estimate unavailable", kind: .warm)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
