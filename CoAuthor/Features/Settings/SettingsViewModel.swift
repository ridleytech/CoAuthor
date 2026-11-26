import Foundation

/// Illustrative credit row derived from a generation job — real
/// job data with illustrative credit amounts (provider reporting
/// is M12).
struct JobCreditRow: Identifiable {
    let job: GenerationJob
    let credits: Int?

    var id: UUID { job.id }
    var statusBadge: (String, StatusBadgeKind) {
        switch job.status {
        case "ready": ("✓ Ready", .ready)
        case "failed": ("! Failed", .failed)
        default: (job.status.capitalized, .neutral)
        }
    }
}

/// Backs the Settings tab root — profile, illustrative credits,
/// preference rows.
@Observable
@MainActor
final class SettingsViewModel {
    private let accountRepository: any AccountRepository
    private let backendClient: any BackendClient

    private(set) var profile: AccountProfile?
    private(set) var loadError: String?

    /// Illustrative default; live subscription figures when backend
    /// mode is on and GET /v1/account succeeds.
    private(set) var credits = CreditsSnapshot()

    init(
        accountRepository: any AccountRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.accountRepository = accountRepository
        self.backendClient = backendClient
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "1.0.0"
    }

    func load() {
        do {
            var profile = try accountRepository.fetchProfile()
            if profile == nil {
                // Dev stores seeded before M11 — create the default.
                let fresh = AccountProfile(
                    name: "Jordan Davis",
                    email: "jordan@example.com",
                    defaultNarrator: "Marlene"
                )
                try accountRepository.insert(fresh)
                profile = fresh
            }
            self.profile = profile
            loadError = nil
        } catch {
            loadError = "Couldn't load settings."
        }
        if BackendConfiguration.shared.useBackend {
            Task { await fetchAccount() }
        }
    }

    /// Live subscription snapshot for the root credits card —
    /// keeps the illustrative snapshot when the call fails.
    private func fetchAccount() async {
        do {
            let account: BackendDTO.ProviderAccount =
                try await backendClient.get("/v1/account")
            credits = credits.applying(account)
        } catch {
            // Backend unreachable — illustrative card stays.
        }
    }
}

/// Backs the Manage account screen.
@Observable
@MainActor
final class ManageAccountViewModel {
    private let accountRepository: any AccountRepository
    private(set) var profile: AccountProfile?

    init(accountRepository: any AccountRepository) {
        self.accountRepository = accountRepository
    }

    func load() {
        profile = try? accountRepository.fetchProfile()
    }
}

/// Backs the ElevenLabs connection screen — API key entry, account
/// subscription data, custom-voice capacity, sync/disconnect.
@Observable
@MainActor
final class ProviderConnectionViewModel {
    private let voiceRepository: any VoiceRepository
    private let backendClient: any BackendClient

    private(set) var credits = CreditsSnapshot()
    private(set) var voiceCount = 0
    /// Slots available for custom voices on the account (live value
    /// from the subscription when connected).
    private(set) var voiceLimit = 10
    /// API key entry field — empty until the user pastes a key.
    var apiKeyInput = ""
    /// Shown after "Test connection"/"Sync voices"/connect actions.
    var statusNote: String?

    init(
        voiceRepository: any VoiceRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.voiceRepository = voiceRepository
        self.backendClient = backendClient
    }

    /// True when a key is stored in the Keychain.
    var hasKey: Bool { APIKeyStore.elevenLabsKey != nil }
    /// True when /v1/account returned live subscription data —
    /// possible via the backend env key without a stored app key.
    private(set) var accountLive = false
    /// Last four characters of the stored key, for masked display.
    var keyTail: String? { APIKeyStore.elevenLabsKeyTail }

    var capacitySlots: (used: Int, total: Int) {
        (used: voiceCount, total: voiceLimit)
    }

    func load() {
        voiceCount = (try? voiceRepository.fetchVoices().count) ?? 0
        // Fetch whenever the backend is reachable — the env key
        // serves account data even before a key is stored in-app.
        loadAccount()
    }

    /// Saves the entered key to the Keychain and pulls the real
    /// subscription + voice library — the "Connect" action.
    func connect() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            statusNote = "! Paste your ElevenLabs API key first."
            return
        }
        APIKeyStore.elevenLabsKey = key
        apiKeyInput = ""
        statusNote = nil
        loadAccount()
    }

    /// Clears the stored key — provider calls revert to stubs.
    /// Cached voice previews go too; they belong to the account
    /// the key was tied to.
    func disconnect() {
        APIKeyStore.elevenLabsKey = nil
        AudioPreviewPlayer.clearCachedClips()
        credits = CreditsSnapshot()
        voiceLimit = 10
        statusNote = "Disconnected — stored API key removed."
    }

    /// Fetches GET /v1/account with the stored key — real plan tier,
    /// character usage, reset date, and voice-slot limit.
    func loadAccount() {
        guard BackendConfiguration.shared.useBackend else {
            statusNote = "Key saved. Turn on backend mode "
                + "(Settings → Developer) to fetch account data."
            return
        }
        Task {
            do {
                let account: BackendDTO.ProviderAccount =
                    try await backendClient.get("/v1/account")
                credits = credits.applying(account)
                if let voiceLimit = account.voiceLimit, voiceLimit > 0 {
                    self.voiceLimit = voiceLimit
                }
                if let tail = keyTail {
                    var copy = credits
                    copy.apiKeyTail = tail
                    credits = copy
                }
                accountLive = account.live == true
                statusNote = accountLive
                    ? "✓ Connected — \(account.tier?.capitalized ?? "ElevenLabs") "
                        + "plan, \(credits.remaining) characters remaining."
                    : "Account data is illustrative — "
                        + (hasKey ? "backend is in stub mode."
                           : "connect a key or set PROVIDER_MODE=live.")
            } catch {
                statusNote = "! Key rejected or backend unreachable — "
                    + "check the key and the base URL."
            }
        }
    }

    /// Backend mode pings GET /health; otherwise a local note.
    func testConnection() {
        guard BackendConfiguration.shared.useBackend else {
            statusNote = "✓ Connection looks good. Last sync updated."
            return
        }
        Task {
            struct Health: Decodable {
                var status: String
                var providers: Providers?
                struct Providers: Decodable {
                    var mode: String
                    var openai: String
                    var elevenlabs: String
                }
            }
            do {
                let health: Health = try await backendClient.get("/health")
                statusNote = "✓ Backend reachable"
                    + (health.providers.map {
                        " · OpenAI \($0.openai), ElevenLabs \($0.elevenlabs)"
                    } ?? "")
            } catch {
                statusNote = "! Backend unreachable — check the base URL."
            }
        }
    }

    /// Backend mode posts /v1/voices:sync and merges the returned
    /// catalog (deduped by name); otherwise a local recount.
    func syncVoices() {
        guard BackendConfiguration.shared.useBackend else {
            voiceCount = (try? voiceRepository.fetchVoices().count) ?? 0
            statusNote = "✓ Synced: \(voiceCount) account voices "
                + "(\(voiceCount) custom, 0 catalog). Local labels and "
                + "favorites are preserved."
            return
        }
        Task {
            do {
                let response: BackendDTO.VoiceSyncResponse = try await backendClient
                    .post("/v1/voices:sync", body: EmptyBody())
                var names = Set(
                    try voiceRepository.fetchVoices().map(\.name)
                )
                var added = 0
                for dto in response.voices where !names.contains(dto.name) {
                    try? voiceRepository.insert(dto.model())
                    names.insert(dto.name)
                    added += 1
                }
                voiceCount = (try? voiceRepository.fetchVoices().count) ?? 0
                statusNote = "✓ Synced from backend: \(voiceCount) voices"
                    + (added > 0 ? " (\(added) new)" : "")
                    + ". Local labels and favorites preserved."
            } catch {
                statusNote = "! Sync failed — backend unreachable."
            }
        }
    }
}

/// Empty JSON object for POSTs that take no payload.
private struct EmptyBody: Encodable {}

/// Backs the Notifications screen — persisted toggles + save.
@Observable
@MainActor
final class NotificationSettingsViewModel {
    private let accountRepository: any AccountRepository

    private(set) var settings: NotificationSettings?
    /// "✓ Notification preferences saved." after Save.
    var showSavedNote = false

    init(accountRepository: any AccountRepository) {
        self.accountRepository = accountRepository
    }

    var notificationsSummary: String {
        guard let settings else { return "Generation finished + failed" }
        var on: [String] = []
        if settings.generationFinished { on.append("Generation finished") }
        if settings.generationFailed { on.append("failed") }
        if settings.lowProviderCredits { on.append("low credits") }
        return on.isEmpty ? "Off" : on.joined(separator: " + ")
    }

    func load() {
        do {
            var settings = try accountRepository.fetchNotificationSettings()
            if settings == nil {
                let fresh = NotificationSettings()
                try accountRepository.insert(fresh)
                settings = fresh
            }
            self.settings = settings
        } catch {
            self.settings = nil
        }
    }

    func save() {
        try? accountRepository.saveChanges()
        showSavedNote = true
    }
}

/// Backs Credits & Usage — live ElevenLabs subscription data +
/// real job history; illustrative fallback when backend is off.
@Observable
@MainActor
final class CreditsUsageViewModel {
    private let generationRepository: any GenerationRepository
    private let backendClient: any BackendClient

    /// Illustrative by default; live values when backend mode is on
    /// and `GET /v1/account` succeeds.
    private(set) var credits = CreditsSnapshot()
    private(set) var account: BackendDTO.ProviderAccount?
    /// Custom voices in the ElevenLabs library (live /v1/voices).
    private(set) var voiceCountUsed: Int?
    private(set) var rows: [JobCreditRow] = []
    private(set) var isRefreshing = false

    init(
        generationRepository: any GenerationRepository,
        backendClient: any BackendClient = URLSessionBackendClient()
    ) {
        self.generationRepository = generationRepository
        self.backendClient = backendClient
    }

    /// Illustrative credit amounts by job kind.
    private func credits(for kind: String) -> Int? {
        if kind.contains("narration") || kind.contains("Chapter") {
            return 2_400
        }
        if kind.contains("Sound") { return 600 }
        if kind.contains("audition") || kind.contains("Audition") {
            return 800
        }
        return nil
    }

    func load() {
        let jobs = (try? generationRepository.fetchJobs()) ?? []
        rows = jobs.prefix(4).map { job in
            JobCreditRow(
                job: job,
                credits: job.status == "failed"
                    ? nil : credits(for: job.kind)
            )
        }
        if BackendConfiguration.shared.useBackend {
            refresh()
        }
    }

    /// Breakdown rows for the account card — real subscription
    /// figures when live, the illustrative examples otherwise.
    /// Values are preformatted strings (mixed credits + labels).
    var breakdownRows: [(String, String)] {
        if let account, account.live == true {
            var rows: [(String, String)] = [
                ("Characters used this period",
                 "\(account.characterCount ?? 0)"),
                ("Character limit", "\(account.characterLimit ?? 0)"),
            ]
            if let used = voiceCountUsed, let limit = account.voiceLimit {
                rows.append(("Custom voice slots", "\(used) of \(limit)"))
            }
            if let label = account.resetLabel {
                rows.append(("Next reset",
                    label.replacingOccurrences(of: "Resets ", with: "")))
            }
            if let status = account.status {
                rows.append(("Subscription", status.capitalized))
            }
            return rows
        }
        return credits.breakdown.map { ($0.0, "\($0.1) credits") }
    }

    /// Refetches the account snapshot — wired to the card's
    /// Refresh button.
    func refresh() {
        guard BackendConfiguration.shared.useBackend else { return }
        Task { await fetchLiveCredits() }
    }

    /// Backend data path — pulls the real subscription
    /// (`/v1/account`) and the voice library size (`/v1/voices`);
    /// the illustrative snapshot stays when the call fails.
    private func fetchLiveCredits() async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let response: BackendDTO.ProviderAccount =
                try await backendClient.get("/v1/account")
            account = response
            credits = credits.applying(response)
            if let voices: [BackendDTO.Voice] =
                try? await backendClient.get("/v1/voices") {
                voiceCountUsed = voices.count
            }
        } catch {
            // Keep the illustrative snapshot — backend unreachable.
        }
    }

    func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let time = formatter.string(from: date)
        if Calendar.current.isDateInToday(date) {
            return "Today, \(time)"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, \(time)"
        }
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

/// Backs the delete-account reauthentication screen — password
/// field and confirmation gating. In backend mode, Continue calls
/// DELETE /v1/account (dev auth — no identity store exists).
@Observable
@MainActor
final class DeleteAccountViewModel {
    private let backendClient: any BackendClient

    var password = ""
    var showPassword = false
    private(set) var deletionConfirmed = false
    var serverError: String?

    init(backendClient: any BackendClient = URLSessionBackendClient()) {
        self.backendClient = backendClient
    }

    var canContinue: Bool { !password.isEmpty }

    /// Posts the deletion when backend mode is on; returns true so
    /// the caller can proceed to the final confirmation either way
    /// (mock mode keeps the placeholder path).
    @discardableResult
    func confirmDeletion() async -> Bool {
        guard BackendConfiguration.shared.useBackend else { return true }
        do {
            let response: BackendDTO.MutationResponse = try await backendClient
                .delete("/v1/account")
            deletionConfirmed = response.status == "deleted"
            return deletionConfirmed
        } catch {
            serverError = "Couldn't reach the server — try again."
            return false
        }
    }
}

/// Backs the create-account screen — field validation matching the
/// Auth — validation reference. In backend mode, submit posts to
/// POST /v1/auth/signup (development auth — see backend README).
@Observable
@MainActor
final class CreateAccountViewModel {
    private let backendClient: any BackendClient

    var name = ""
    var email = ""
    var password = ""
    var showPassword = false
    var acceptedTerms = false
    var attemptedSubmit = false
    /// Set when a backend signup succeeds — the caller can show a
    /// real confirmation instead of the placeholder.
    private(set) var sessionToken: String?
    var serverError: String?

    init(backendClient: any BackendClient = URLSessionBackendClient()) {
        self.backendClient = backendClient
    }

    var nameError: String? {
        guard attemptedSubmit else { return nil }
        return name.split(separator: " ").count >= 2
            ? nil : "Enter your full name."
    }

    var emailError: String? {
        guard attemptedSubmit else { return nil }
        let valid = email.contains("@")
            && email.split(separator: "@").count == 2
            && email.hasSuffix("@") == false
            && email.contains(".")
        return valid ? nil : "Enter a valid email address."
    }

    var passwordError: String? {
        guard attemptedSubmit else { return nil }
        let hasUpper = password.rangeOfCharacter(
            from: .uppercaseLetters) != nil
        let hasLower = password.rangeOfCharacter(
            from: .lowercaseLetters) != nil
        let hasDigit = password.rangeOfCharacter(
            from: .decimalDigits) != nil
        let valid = password.count >= 12 && hasUpper && hasLower && hasDigit
        return valid ? nil : "Use 12+ characters, both letter cases "
            + "and a number."
    }

    var termsError: String? {
        guard attemptedSubmit else { return nil }
        return acceptedTerms ? nil : "Accept the terms to create an account."
    }

    /// Validates the form, then — in backend mode — posts the
    /// signup. Returns true on success so the caller can route
    /// onward; on a backend error `serverError` is set and the
    /// caller falls back to the placeholder flow.
    @discardableResult
    func submit() async -> Bool {
        attemptedSubmit = true
        guard nameError == nil && emailError == nil
            && passwordError == nil && termsError == nil
        else { return false }

        guard BackendConfiguration.shared.useBackend else { return true }
        struct Payload: Encodable {
            let name: String
            let email: String
            let password: String
        }
        do {
            let session: BackendDTO.AuthSession = try await backendClient
                .post("/v1/auth/signup", body: Payload(
                    name: name, email: email, password: password
                ))
            guard let token = session.token else {
                serverError = session.error?
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized ?? "Signup failed."
                return false
            }
            sessionToken = token
            return true
        } catch {
            serverError = "Couldn't reach the server — try again."
            return false
        }
    }
}
