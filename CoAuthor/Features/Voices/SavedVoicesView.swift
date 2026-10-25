import SwiftUI
import SwiftData

/// Saved Voices — account voice list with search, filters, mock
/// capacity, and narrator assignment when opened in casting context.
/// Reference: Designs/Full Content/Saved Voices/Full Content.png
struct SavedVoicesView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    /// Casting context — nil when browsing from the Library tab.
    let projectID: UUID?
    @State private var viewModel: VoicesViewModel?

    var body: some View {
        VStack(spacing: 0) {
            if projectID == nil {
                BrandTopBar()
            } else {
                BackTopBar(title: "CoAuthor") {
                    coordinator.pop()
                }
            }
            Group {
                if let viewModel {
                    content(viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load voices",
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
                let vm = VoicesViewModel(
                    projectID: projectID,
                    projectsRepository: projectID == nil
                        ? nil
                        : SwiftDataDashboardRepository(context: modelContext),
                    voiceRepository: SwiftDataVoiceRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: VoicesViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(viewModel)
                    VoiceCapacityCard(
                        capacity: viewModel.capacity,
                        footnote: "Includes voices created outside CoAuthor"
                    )
                    Text("Slots are not credits; capacity includes voices "
                         + "created outside CoAuthor.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    VoiceSearchField(text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    ))
                    Button {
                        coordinator.push(.placeholder(title: "Voice sync", milestone: "M12"))
                    } label: {
                        Text("Sync ElevenLabs voices")
                    }
                    .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))
                    filterRow(viewModel)
                    Text(viewModel.countLine)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    ForEach(viewModel.filteredVoices) { voice in
                        voiceCard(voice, viewModel)
                    }
                    Text("Estimate unavailable · description approval separate "
                         + "from paid audition")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }

            if let auditioning = viewModel.auditioningVoice {
                VoiceAuditionStrip(
                    title: "\(auditioning.name) · audition",
                    position: "00:08",
                    duration: auditioning.sampleSeconds > 0
                        ? ScriptReaderViewModel.format(auditioning.sampleSeconds) : "0:00",
                    isPlaying: false
                ) {
                    viewModel.audition(auditioning)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.bottom, 6)
            }
            if projectID != nil {
                BottomCTA(
                    title: "Use this voice",
                    enabled: viewModel.auditioningVoice != nil
                ) {
                    if let voice = viewModel.auditioningVoice {
                        viewModel.assign(voice)
                        coordinator.pop()
                    }
                }
            }
        }
    }

    private func titleBlock(_ viewModel: VoicesViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Saved Voices")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.caInk)
                Spacer()
                Button {
                    coordinator.push(.placeholder(title: "Create voice", milestone: "M7"))
                } label: {
                    Text("Create Voice")
                }
                .buttonStyle(CAPrimaryButtonStyle())
            }
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: Filters

    private func filterRow(_ viewModel: VoicesViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                filterButton("All account voices", active: !viewModel.hasActiveFilters) {
                    viewModel.clearFilters()
                }
                filterButton("☆ Favorites", active: viewModel.favoritesOnly) {
                    viewModel.favoritesOnly.toggle()
                }
                filterMenu("Narrator", selection: Binding(
                    get: { viewModel.roleFilter },
                    set: { viewModel.roleFilter = $0 }
                ), options: VoicesViewModel.RoleFilter.allCases.map { ($0, $0.rawValue) })
                Spacer()
            }
            HStack(spacing: 8) {
                filterMenu("Custom", selection: Binding(
                    get: { viewModel.kindFilter },
                    set: { viewModel.kindFilter = $0 }
                ), options: VoicesViewModel.KindFilter.allCases.map { ($0, $0.rawValue) })
                filterMenu("Source", selection: Binding(
                    get: { viewModel.originFilter },
                    set: { viewModel.originFilter = $0 }
                ), options: VoicesViewModel.OriginFilter.allCases.map { ($0, $0.rawValue) })
                if viewModel.hasActiveFilters {
                    Button {
                        viewModel.clearFilters()
                    } label: {
                        Text("× clear")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private func filterButton(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(active ? Color.caInk : Color.caSurface)
                .foregroundStyle(active ? Color.caSurface : Color.caInk)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.caHairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func filterMenu<F: Hashable>(
        _ title: String,
        selection: Binding<F>,
        options: [(F, String)]
    ) -> some View {
        Menu {
            ForEach(Array(options.enumerated()), id: \.offset) { pair in
                Button(pair.element.1) { selection.wrappedValue = pair.element.0 }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.caSurface)
            .foregroundStyle(Color.caInk)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.caHairline, lineWidth: 1))
        }
    }

    // MARK: Voice card

    private func voiceCard(_ voice: Voice, _ viewModel: VoicesViewModel) -> some View {
        let isContextVoice = voice.assignedProjectID != nil
            && voice.assignedProjectID == projectID
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(voice.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Spacer()
                Button {
                    viewModel.toggleFavorite(voice)
                } label: {
                    Image(systemName: voice.isFavorite ? "star.fill" : "star")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
            }
            Text(voice.listSubtitle
                 + (!isContextVoice && !voice.assignmentLabel.isEmpty
                    ? " · \(voice.assignmentLabel)" : ""))
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
            Text(voice.summary)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            HStack(spacing: 6) {
                ForEach(voice.tags, id: \.self) { tag in
                    VoiceTagPill(tag)
                }
            }
            if isContextVoice {
                Text("Used in: \(voice.assignmentLabel)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            HStack(spacing: 8) {
                actionButton("▶ \(voice.sampleLabel)") {
                    viewModel.audition(voice)
                }
                actionButton("Details") {
                    coordinator.push(.voiceDetail(voiceID: voice.id, projectID: projectID))
                }
                actionButton("Favorite") {
                    viewModel.toggleFavorite(voice)
                }
                if projectID != nil {
                    actionButton("Assign") {
                        viewModel.assign(voice)
                    }
                }
                Spacer()
            }
            if voice.assignedProjectID != nil {
                HStack(spacing: 8) {
                    actionButton("Set default narrator") {
                        viewModel.assign(voice)
                    }
                    actionButton("Edit local metadata") {
                        coordinator.push(.voiceEdit(voiceID: voice.id))
                    }
                    Spacer()
                }
            }
        }
        .padding(Theme.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.caSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(
                    isContextVoice ? Color.caInk : Color.caHairline,
                    lineWidth: isContextVoice ? 2 : 1
                )
        )
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.caField)
                .foregroundStyle(Color.caInk)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
