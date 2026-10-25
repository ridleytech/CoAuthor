import Foundation

/// Backs the asset library (Library tab · Sound Effects) — search,
/// playback selection, reuse targeting.
@Observable
@MainActor
final class AssetLibraryViewModel {
    private let publishingRepository: any PublishingRepository
    private let cueRepository: any CueRepository
    private let projectsRepository: any DashboardRepository
    private let backendClient: any BackendClient

    private(set) var assets: [SoundAsset] = []
    private(set) var loadError: String?
    /// The project whose cues can receive reused assets — the one
    /// with the most cues, mirroring the design's context card.
    private(set) var contextProject: Project?
    private(set) var contextCueCount = 0

    var searchText = ""
    var selectedAssetID: UUID?
    var isPlaying = false
    /// The asset currently targeted by the reuse card.
    var reuseTargetID: UUID?

    init(
        publishingRepository: any PublishingRepository,
        cueRepository: any CueRepository,
        projectsRepository: any DashboardRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.publishingRepository = publishingRepository
        self.cueRepository = cueRepository
        self.projectsRepository = projectsRepository
        self.backendClient = backendClient
    }

    var filteredAssets: [SoundAsset] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return assets }
        return assets.filter {
            $0.title.lowercased().contains(query)
                || $0.projectTitle.lowercased().contains(query)
                || ($0.cueCode?.lowercased().contains(query) ?? false)
        }
    }

    /// "The Numbers Widow · Sound Effects / 8 of 32 approved ·
    /// Detroit Nov 1972 · Single narrator"
    var contextTitle: String {
        guard let contextProject else { return "Sound Effects" }
        return "\(contextProject.title) · Sound Effects"
    }

    var contextSubtitle: String {
        guard let contextProject else { return "" }
        var text = "\(contextCueCount) approved sounds"
            + " · \(contextProject.settingDescriptor)"
        if contextProject.narratorName != nil {
            text += " · Single narrator"
        }
        return text
    }

    func load() {
        do {
            var fetched = try publishingRepository.fetchAssets()
            if fetched.isEmpty && BackendConfiguration.shared.useBackend {
                Task { await hydrateAssets() }
            }
            // Dev stores seeded before M10 have no assets — insert the
            // design's starter set once so the library isn't empty.
            if fetched.isEmpty && !BackendConfiguration.shared.useBackend {
                for asset in SampleData.makeSoundAssets() {
                    try publishingRepository.insertAsset(asset)
                }
                fetched = try publishingRepository.fetchAssets()
            }
            assets = fetched
            // Pick the project with the most cues as the reuse context.
            let projects = try projectsRepository.fetchProjects()
            var best: Project?
            var bestCount = 0
            for project in projects {
                let count = try cueRepository
                    .fetchCues(projectID: project.id).count
                if count > bestCount {
                    best = project
                    bestCount = count
                }
            }
            contextProject = best
            if let best {
                contextCueCount = try cueRepository
                    .fetchCues(projectID: best.id)
                    .filter { $0.reviewState == "Approved" }.count
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load assets."
        }
    }

    /// Backend path — fetches the asset catalog from the API;
    /// falls back to the local starter set on failure.
    private func hydrateAssets() async {
        do {
            let dtos: [BackendDTO.Asset] = try await backendClient
                .get("/v1/assets")
            for dto in dtos {
                try? publishingRepository.insertAsset(dto.model())
            }
            load()
        } catch {
            // Fall back to the seeded starter set.
            for asset in SampleData.makeSoundAssets() {
                try? publishingRepository.insertAsset(asset)
            }
            load()
        }
    }

    func secondsLabel(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    func tap(_ asset: SoundAsset) {
        if selectedAssetID == asset.id {
            selectedAssetID = nil
            isPlaying = false
        } else {
            selectedAssetID = asset.id
            isPlaying = false
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    /// "Reuse" — targets the asset for reuse into the context
    /// project's first approved audio cue.
    func markForReuse(_ asset: SoundAsset) {
        reuseTargetID = asset.id
    }

    /// "Use this sound →" — records the reuse locally; the original
    /// asset is preserved (copy semantics are M12 backend work).
    func useAsset() {
        guard let asset = assets.first(where: { $0.id == reuseTargetID }),
              let target = targetCue()
        else { return }
        asset.reusedTargetCode = target.code
        reuseTargetID = nil
        try? publishingRepository.saveChanges()
    }

    /// "Target: The Numbers Widow → SC-01"
    var reuseTargetLine: String {
        guard let target = targetCue(), let contextProject else {
            return "No eligible target cue"
        }
        return "Target: \(contextProject.title) → \(target.code)"
    }

    var reuseAsset: SoundAsset? {
        assets.first { $0.id == reuseTargetID }
    }

    var selectedAsset: SoundAsset? {
        assets.first { $0.id == selectedAssetID }
    }

    /// First approved audio cue in the context project.
    private func targetCue() -> SoundCue? {
        guard let contextProject else { return nil }
        return try? cueRepository.fetchCues(projectID: contextProject.id)
            .first { $0.needsAudio }
    }
}
