import SwiftUI
import SwiftData

/// New-project form — "Start with a story." Step 1 of 3.
/// Reference: Designs/Full Content/Create project/Full Content.png
struct NewProjectView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NewProjectViewModel?
    @FocusState private var premiseFocused: Bool

    var body: some View {
        Group {
            if let viewModel {
                form(viewModel)
            } else {
                VStack(spacing: 0) {
                    BackTopBar(title: "CoAuthor") { coordinator.pop() }
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                viewModel = NewProjectViewModel(
                    repository: SwiftDataDashboardRepository(context: modelContext)
                )
            }
        }
    }

    @ViewBuilder
    private func form(_ viewModel: NewProjectViewModel) -> some View {
        VStack(spacing: 0) {
            BackTopBar(title: "CoAuthor") { coordinator.pop() }

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock
                    premiseCard(viewModel)
                    storyDetailsCard(viewModel)
                    workflowCard(viewModel)
                    preferencesCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.top, Theme.Spacing.cardGap)
                .padding(.bottom, Theme.Spacing.page)
            }
            .scrollDismissesKeyboard(.interactively)

            BottomCTA(
                title: "Generate story ideas",
                enabled: viewModel.canGenerate
            ) {
                if let id = viewModel.save() {
                    coordinator.push(.ideaGeneration(projectID: id))
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Start with a story.")
                .font(.title.weight(.bold))
            Text("Step 1 of 3 · Premise & preferences · Editable defaults")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func premiseCard(_ vm: NewProjectViewModel) -> some View {
        @Bindable var bindable = vm
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Premise")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $bindable.premise)
                        .focused($premiseFocused)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(Color.caField)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(
                                    premiseFocused ? Color.caInk : Color.caHairline,
                                    lineWidth: premiseFocused ? 2 : 1
                                )
                        )
                    if vm.premise.isEmpty {
                        Text("Describe your story premise…")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    @ViewBuilder
    private func storyDetailsCard(_ vm: NewProjectViewModel) -> some View {
        @Bindable var bindable = vm
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Story details")
                CAFormField(label: "Working title · optional", text: $bindable.title)
                CAPickerField(
                    label: "Genre",
                    options: NewProjectViewModel.genreOptions,
                    selection: $bindable.genre
                )
                CAFormField(label: "Setting / time", text: $bindable.setting)
                CAPickerField(
                    label: "Tone / audience",
                    options: NewProjectViewModel.toneOptions,
                    selection: $bindable.toneAudience
                )
                CAPickerField(
                    label: "Runtime / format",
                    options: NewProjectViewModel.runtimeOptions,
                    selection: $bindable.runtime,
                    optionLabel: { $0.label }
                )
            }
            .padding(Theme.Spacing.card)
        }
    }

    @ViewBuilder
    private func workflowCard(_ vm: NewProjectViewModel) -> some View {
        @Bindable var bindable = vm
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabel("Workflow")
                    Spacer()
                    Button {
                        coordinator.push(.placeholder(title: "Workflow", milestone: "M3"))
                    } label: {
                        HStack(spacing: 4) {
                            Text("Change")
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    }
                    .buttonStyle(.plain)
                }
                RadioOptionCard(
                    title: "Guided",
                    detail: "Review the outline before generating the full script.",
                    selected: bindable.workflow == .guided
                ) { vm.workflow = .guided }
                RadioOptionCard(
                    title: "Complete package",
                    detail: "Generate story and production materials, then review.",
                    selected: bindable.workflow == .completePackage
                ) { vm.workflow = .completePackage }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func preferencesCard(_ vm: NewProjectViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionLabel("Creative preferences")
                    Spacer()
                    Button {
                        coordinator.push(.placeholder(title: "Creative preferences", milestone: "M3"))
                    } label: {
                        HStack(spacing: 4) {
                            Text("Edit")
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    }
                    .buttonStyle(.plain)
                }
                Text(vm.creativePreferences)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
