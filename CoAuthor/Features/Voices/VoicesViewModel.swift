import Foundation

/// Backs the Saved Voices list — search, favorites/role/kind filters,
/// mock account capacity, narrator assignment in casting context.
@Observable
@MainActor
final class VoicesViewModel {
    /// Casting context — set when picking a narrator for a project.
    let projectID: UUID?
    private let projectsRepository: (any DashboardRepository)?
    private let voiceRepository: any VoiceRepository
    private let backendClient: any BackendClient

    private(set) var voices: [Voice] = []
    private(set) var contextProject: Project?
    private(set) var loadError: String?

    let capacity = MockVoiceCapacity.current

    var searchText = ""
    var favoritesOnly = false
    var roleFilter: RoleFilter = .all
    var kindFilter: KindFilter = .all
    var originFilter: OriginFilter = .all

    /// The voice whose audition is loaded in the bottom player.
    private(set) var auditioningVoice: Voice?

    enum RoleFilter: String, CaseIterable {
        case all = "All roles", narrator = "Narrator",
             character = "Character"
        var matches: (Voice) -> Bool {
            switch self {
            case .all: { _ in true }
            case .narrator: { $0.roleTag.contains("Narrator") }
            case .character: { $0.roleTag.contains("Character") && !$0.roleTag.contains("Narrator") }
            }
        }
    }

    enum KindFilter: String, CaseIterable {
        case all = "All kinds", custom = "Custom", catalog = "Catalog"
        var matches: (Voice) -> Bool {
            switch self {
            case .all: { _ in true }
            case .custom: { $0.kind == "Custom" }
            case .catalog: { $0.kind == "Catalog" }
            }
        }
    }

    enum OriginFilter: String, CaseIterable {
        case all = "All sources", coAuthor = "CoAuthor", provider = "ElevenLabs"
        var matches: (Voice) -> Bool {
            switch self {
            case .all: { _ in true }
            case .coAuthor: { $0.origin == "Created in CoAuthor" }
            case .provider: { $0.origin != "Created in CoAuthor" }
            }
        }
    }

    init(
        projectID: UUID? = nil,
        projectsRepository: (any DashboardRepository)? = nil,
        voiceRepository: any VoiceRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.voiceRepository = voiceRepository
        self.backendClient = backendClient
    }

    var subtitle: String {
        if let contextProject {
            return "Choosing for \(contextProject.title) → Series narrator"
        }
        return "All account voices"
    }

    /// "Showing 7 of 10 account voices · Synced Today, 9:18 AM"
    var countLine: String {
        "Showing \(filteredVoices.count) of \(voices.count) account voices"
            + " · Synced Today, 9:18 AM"
    }

    var filteredVoices: [Voice] {
        voices.filter { voice in
            (searchText.isEmpty || voice.name.localizedCaseInsensitiveContains(searchText)
                || voice.summary.localizedCaseInsensitiveContains(searchText)
                || voice.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
            && (!favoritesOnly || voice.isFavorite)
            && roleFilter.matches(voice)
            && kindFilter.matches(voice)
            && originFilter.matches(voice)
        }
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty || favoritesOnly
            || roleFilter != .all || kindFilter != .all || originFilter != .all
    }

    func clearFilters() {
        searchText = ""
        favoritesOnly = false
        roleFilter = .all
        kindFilter = .all
        originFilter = .all
    }

    func load() {
        do {
            voices = try voiceRepository.fetchVoices()
            if let projectID {
                contextProject = try projectsRepository?.fetchProject(id: projectID)
            }
            if BackendConfiguration.shared.useBackend {
                Task { await hydrateVoices() }
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load saved voices."
        }
    }

    /// Backend path — merges the catalog from `GET /v1/voices`,
    /// deduped by name so repeated syncs and locally-created voices
    /// are preserved.
    private func hydrateVoices() async {
        do {
            let dtos: [BackendDTO.Voice] = try await backendClient
                .get("/v1/voices")
            // Re-fetch inside the async gap in case the store changed
            // while the request was in flight.
            var names = Set(
                try voiceRepository.fetchVoices().map(\.name)
            )
            for dto in dtos where !names.contains(dto.name) {
                try? voiceRepository.insert(dto.model())
                names.insert(dto.name)
            }
            voices = try voiceRepository.fetchVoices()
        } catch {
            // Keep the local catalog — backend unreachable.
        }
    }

    func toggleFavorite(_ voice: Voice) {
        voice.isFavorite.toggle()
        try? voiceRepository.saveChanges()
    }

    func audition(_ voice: Voice) {
        auditioningVoice = voice
    }

    /// "Use this voice" — assigns the voice as the project's narrator.
    func assign(_ voice: Voice) {
        guard let contextProject else { return }
        contextProject.narratorName = voice.name
        contextProject.narratorConfirmed = true
        contextProject.lastEditedAt = Date()
        voice.assignedProjectID = contextProject.id
        voice.assignmentLabel = "\(contextProject.title) · Series narrator"
        try? projectsRepository?.saveChanges()
        try? voiceRepository.saveChanges()
    }
}

/// Backs a single voice's detail / casting-picker screen.
@Observable
@MainActor
final class VoiceDetailViewModel {
    let voiceID: UUID
    let projectID: UUID?
    private let projectsRepository: (any DashboardRepository)?
    private let voiceRepository: any VoiceRepository
    private let backendClient: any BackendClient

    private(set) var voice: Voice?
    private(set) var contextProject: Project?
    private(set) var loadError: String?
    let capacity = MockVoiceCapacity.current

    var isPlaying = false

    init(
        voiceID: UUID,
        projectID: UUID? = nil,
        projectsRepository: (any DashboardRepository)? = nil,
        voiceRepository: any VoiceRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.voiceID = voiceID
        self.projectID = projectID
        self.projectsRepository = projectsRepository
        self.voiceRepository = voiceRepository
        self.backendClient = backendClient
    }

    var subtitle: String {
        if let contextProject {
            return "\(contextProject.title) → Series narrator · Context-preserving picker"
        }
        return "Saved voice detail"
    }

    var assignmentLine: String {
        voice?.assignmentLabel.isEmpty == false
            ? "Assignment: \(voice?.assignmentLabel ?? "")"
            : "Assignment: none"
    }

    func load() {
        do {
            voice = try voiceRepository.fetchVoice(id: voiceID)
            if let projectID {
                contextProject = try projectsRepository?.fetchProject(id: projectID)
            }
            loadError = nil
        } catch {
            loadError = "Couldn't load the voice."
        }
    }

    func toggleFavorite() {
        guard let voice else { return }
        voice.isFavorite.toggle()
        try? voiceRepository.saveChanges()
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    /// "Use this voice — {project}" — assigns the narrator and persists.
    func useThisVoice() {
        guard let voice, let contextProject else { return }
        contextProject.narratorName = voice.name
        contextProject.narratorConfirmed = true
        contextProject.lastEditedAt = Date()
        voice.assignedProjectID = contextProject.id
        voice.assignmentLabel = "\(contextProject.title) · Series narrator"
        try? projectsRepository?.saveChanges()
        try? voiceRepository.saveChanges()
    }

    /// Removes the local reference; in backend mode also tells the
    /// API (which deletes the provider voice in live provider mode).
    /// Local removal proceeds regardless of the remote result.
    func removeFromCoAuthor() {
        guard let voice else { return }
        let providerID = voice.savedVoiceID
        if BackendConfiguration.shared.useBackend && !providerID.isEmpty {
            Task {
                let _: BackendDTO.MutationResponse? = try? await backendClient
                    .delete("/v1/voices/\(providerID)")
            }
        }
        try? voiceRepository.delete(voice)
    }
}
