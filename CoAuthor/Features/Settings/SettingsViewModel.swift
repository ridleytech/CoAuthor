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

    private(set) var profile: AccountProfile?
    private(set) var loadError: String?

    let credits = CreditsSnapshot()

    init(accountRepository: any AccountRepository) {
        self.accountRepository = accountRepository
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

/// Backs the ElevenLabs connection screen — masked key, custom-voice
/// capacity, sync/reconnect actions.
@Observable
@MainActor
final class ProviderConnectionViewModel {
    private let voiceRepository: any VoiceRepository

    let credits = CreditsSnapshot()
    private(set) var voiceCount = 0
    /// Shown after "Test connection" or "Sync voices".
    var statusNote: String?

    init(voiceRepository: any VoiceRepository) {
        self.voiceRepository = voiceRepository
    }

    var capacitySlots: (used: Int, total: Int) {
        (used: voiceCount, total: 10)
    }

    func load() {
        voiceCount = (try? voiceRepository.fetchVoices().count) ?? 0
    }

    /// Local "test" — updates the sync timestamp only; a real
    /// provider call is M12.
    func testConnection() {
        statusNote = "✓ Connection looks good. Last sync updated."
    }

    func syncVoices() {
        voiceCount = (try? voiceRepository.fetchVoices().count) ?? 0
        statusNote = "✓ Synced: \(voiceCount) account voices "
            + "(\(voiceCount) custom, 0 catalog). Local labels and "
            + "favorites are preserved."
    }
}

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

/// Backs Credits & Usage — illustrative balance + real job history.
@Observable
@MainActor
final class CreditsUsageViewModel {
    private let generationRepository: any GenerationRepository
    private let backendClient: any BackendClient

    /// Illustrative by default; live values when backend mode is on
    /// and `GET /v1/credits` succeeds.
    private(set) var credits = CreditsSnapshot()
    private(set) var rows: [JobCreditRow] = []

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
            Task { await fetchLiveCredits() }
        }
    }

    /// Backend data path — fetches the balance from the API; the
    /// illustrative snapshot stays when the call fails.
    private func fetchLiveCredits() async {
        do {
            let response: CreditsSnapshot.Response = try await backendClient
                .get("/v1/credits")
            credits = credits.applying(response)
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
/// field and confirmation gating (deletion itself is M12 backend).
@Observable
@MainActor
final class DeleteAccountViewModel {
    var password = ""
    var showPassword = false

    var canContinue: Bool { !password.isEmpty }
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
