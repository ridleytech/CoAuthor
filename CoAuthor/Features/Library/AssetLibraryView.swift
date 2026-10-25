import SwiftUI
import SwiftData

/// Pill strip shared by Library sections — Voices / Narration /
/// Sound Effects — matching the Asset-library reference's top tabs.
struct LibrarySectionTabs: View {
    @Environment(AppCoordinator.self) private var coordinator
    /// "voices" or "sounds".
    let active: String

    var body: some View {
        HStack(spacing: 24) {
            sectionItem("Voices", key: "voices")
            sectionItem("Narration", key: "narration")
            sectionItem("Sound Effects", key: "sounds")
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, 8)
        .background(Color.caSurface)
    }

    @ViewBuilder
    private func sectionItem(_ title: String, key: String) -> some View {
        if key == active {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.caInk)
        } else {
            Button {
                switch key {
                case "voices":
                    coordinator.push(.savedVoices(projectID: nil))
                case "sounds":
                    coordinator.push(.assetLibrary)
                default:
                    coordinator.push(.placeholder(
                        title: "Narration assets",
                        milestone: "M12"
                    ))
                }
            } label: {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Asset library — generated sound effects across projects with
/// search, playback selection, and reuse into another project's cue.
/// Reference: Designs/Full Content/Asset Library/Full Content.png
struct AssetLibraryView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: AssetLibraryViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BrandTopBar()
            Group {
                if let viewModel {
                    content(viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load assets",
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
                let vm = AssetLibraryViewModel(
                    publishingRepository: SwiftDataPublishingRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext),
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: AssetLibraryViewModel) -> some View {
        VStack(spacing: 0) {
            LibrarySectionTabs(active: "sounds")
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    searchRow(viewModel)
                    contextCard(viewModel)
                    ForEach(viewModel.filteredAssets) { asset in
                        assetCard(asset, viewModel)
                    }
                    if viewModel.reuseAsset != nil {
                        reuseCard(viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            if let asset = viewModel.selectedAsset {
                playerStrip(asset, viewModel)
            }
            BottomCTA(title: "Open Saved Voices") {
                coordinator.push(.savedVoices(projectID: nil))
            }
        }
    }

    // MARK: Search + context

    private func searchRow(_ viewModel: AssetLibraryViewModel) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                TextField(
                    "Search sounds…",
                    text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    )
                )
                .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.caSurface)
            .clipShape(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.caHairline, lineWidth: 1)
            )
            Button("Filter") {
                coordinator.push(.placeholder(
                    title: "Asset filters",
                    milestone: "M12"
                ))
            }
            .buttonStyle(CASecondaryButtonStyle())
        }
    }

    private func contextCard(_ viewModel: AssetLibraryViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.contextTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                if !viewModel.contextSubtitle.isEmpty {
                    Text(viewModel.contextSubtitle)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Asset card

    private func assetCard(
        _ asset: SoundAsset,
        _ viewModel: AssetLibraryViewModel
    ) -> some View {
        let selected = viewModel.selectedAssetID == asset.id
        return Button {
            viewModel.tap(asset)
        } label: {
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if selected {
                            Image(systemName: "checkmark.square.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.caInk)
                        }
                        Text(asset.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Spacer()
                        if asset.reviewState == "Approved" {
                            StatusBadge("Approved", kind: .ready)
                        } else {
                            StatusBadge(asset.reviewState, kind: .neutral)
                        }
                        if let reused = asset.reusedTargetCode {
                            StatusBadge("Reused → \(reused)", kind: .warmLight)
                        }
                    }
                    Text("\(asset.category) · \(asset.projectTitle)"
                         + (asset.cueCode.map { " · \($0)" } ?? ""))
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    Text("\(viewModel.secondsLabel(asset.seconds)) · "
                         + viewModel.dateLabel(asset.createdDate))
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    if selected {
                        RoundedRectangle(
                            cornerRadius: 4,
                            style: .continuous
                        )
                        .fill(Color.caField)
                        .frame(height: 24)
                        .overlay(
                            Rectangle()
                                .fill(Color.caSecondary.opacity(0.4))
                                .frame(height: 2)
                        )
                    }
                    actionRow(asset, viewModel)
                }
                .padding(Theme.Spacing.card)
            }
            .overlay(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.card,
                    style: .continuous
                )
                .strokeBorder(
                    selected ? Color.caInk : Color.clear,
                    lineWidth: 1.5
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func actionRow(
        _ asset: SoundAsset,
        _ viewModel: AssetLibraryViewModel
    ) -> some View {
        HStack(spacing: 10) {
            Button {
                viewModel.tap(asset)
                viewModel.isPlaying = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.caption2)
                    Text("Play")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.caInk)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            assetButton("Reuse") {
                viewModel.markForReuse(asset)
            }
            assetButton("Download") {
                coordinator.push(.placeholder(
                    title: "Asset download",
                    milestone: "M12"
                ))
            }
        }
    }

    private func assetButton(
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

    // MARK: Reuse + player

    private func reuseCard(_ viewModel: AssetLibraryViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reuse in another project")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(viewModel.reuseTargetLine)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Text("Reuse approved sounds without generating again. "
                     + "The original is preserved.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    viewModel.useAsset()
                } label: {
                    HStack(spacing: 6) {
                        Text("Use this sound")
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

    private func playerStrip(
        _ asset: SoundAsset,
        _ viewModel: AssetLibraryViewModel
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying
                      ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.caInk)
                    .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("00:08 ——— \(viewModel.secondsLabel(asset.seconds))")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer()
            Text("1×")
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, 6)
        .background(Color.caSurface)
    }
}
