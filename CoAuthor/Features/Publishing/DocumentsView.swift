import SwiftUI
import SwiftData

/// Documents hub — "Working documents." Readable exports derived
/// from project sources, plus export options.
/// Reference: Designs/Full Content/Documents hub/Full Content.png
struct DocumentsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: DocumentsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Documents") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load documents",
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
                let vm = DocumentsViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    publishingRepository: SwiftDataPublishingRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext),
                    outlineRepository: SwiftDataOutlineRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: DocumentsViewModel) -> some View {
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
                        Text("Working documents")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text("One story. Shared source revisions. "
                             + "Readable exports.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    ForEach(viewModel.documents) { document in
                        documentCard(document, viewModel)
                    }
                    exportOptionsCard(project)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Download complete package") {
                coordinator.push(.exports(projectID: project.id))
            }
        }
    }

    // MARK: Document card

    private func documentCard(
        _ document: ProjectDocument,
        _ viewModel: DocumentsViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(document.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    statusBadge(document.status)
                }
                Divider().overlay(Color.caHairline)
                Text(document.summary)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Text(document.sourceLine)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                if let note = document.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                        .opacity(0.7)
                }
                HStack(spacing: 10) {
                    docButton("Preview") {
                        if document.kind == "youtube" {
                            coordinator.push(.publishingKit(projectID: projectID))
                        } else {
                            coordinator.push(.documentPreview(
                                projectID: projectID,
                                kind: document.kind
                            ))
                        }
                    }
                    docButton("Download") {
                        coordinator.push(.placeholder(
                            title: "Document download",
                            milestone: "M12"
                        ))
                    }
                    if document.updatesContent {
                        Button("Update") {
                            viewModel.markTrackerUpdated()
                        }
                        .buttonStyle(CAPrimaryButtonStyle())
                    } else {
                        docButton("Regenerate") {
                            coordinator.push(.placeholder(
                                title: "Regenerate document",
                                milestone: "M12"
                            ))
                        }
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: ProjectDocument.DocumentStatus) -> some View {
        switch status {
        case .current:
            StatusBadge("Current", kind: .ready)
        case .updateAvailable:
            StatusBadge("Update available", kind: .warm)
        case .draft:
            StatusBadge("Draft", kind: .neutral)
        }
    }

    private func docButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.caInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.caField)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Export options

    private func exportOptionsCard(_ project: Project) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Export options")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                }
                FlowRow(spacing: 8) {
                    optionPill("Word documents")
                    optionPill("Excel tracker")
                    optionPill("Structured JSON")
                    optionPill("Complete project package")
                }
                Button {
                    coordinator.push(.exports(projectID: project.id))
                } label: {
                    HStack {
                        Text("Choose export formats")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.caInk)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caInk)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.caSurface)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Theme.Radius.button,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: Theme.Radius.button,
                            style: .continuous
                        )
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func optionPill(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.caField)
            .clipShape(Capsule())
    }
}

/// Simple wrapping row of views — used for option pills.
struct FlowRow<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        // A plain two-column grid approximates the design's wrapped
        // pill rows without a layout dependency.
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: spacing)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
    }
}
