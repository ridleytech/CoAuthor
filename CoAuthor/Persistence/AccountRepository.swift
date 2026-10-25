import Foundation
import SwiftData

/// Persistence boundary for the account profile and notification
/// preferences.
@MainActor
protocol AccountRepository {
    func fetchProfile() throws -> AccountProfile?
    func fetchNotificationSettings() throws -> NotificationSettings?
    func insert(_ profile: AccountProfile) throws
    func insert(_ settings: NotificationSettings) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataAccountRepository: AccountRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchProfile() throws -> AccountProfile? {
        try context.fetch(FetchDescriptor<AccountProfile>()).first
    }

    func fetchNotificationSettings() throws -> NotificationSettings? {
        try context.fetch(FetchDescriptor<NotificationSettings>()).first
    }

    func insert(_ profile: AccountProfile) throws {
        context.insert(profile)
        try context.save()
    }

    func insert(_ settings: NotificationSettings) throws {
        context.insert(settings)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Provider-credit snapshot matching the Credits designs. Default
/// values are illustrative; when backend mode is on, live fields are
/// populated from `GET /v1/credits`.
struct CreditsSnapshot {
    var connected = true
    var accountName = "Jordan's studio"
    var planLabel = "Creator (illustrative)"
    var remaining = 72_400
    var limit = 100_000
    var resetLabel = "Resets November 12"
    var lastRefresh = "Today, 9:42 AM"
    var apiKeyTail = "9b41"
    /// True when the figures came from the backend rather than the
    /// built-in illustrative values.
    var isLive = false

    /// Shape returned by `GET /v1/credits` on the backend scaffold.
    struct Response: Decodable {
        var provider: String?
        var remaining: Int
        var limit: Int
        var illustrative: Bool?
    }

    /// Copy of this snapshot with live figures applied.
    func applying(_ response: Response) -> CreditsSnapshot {
        var copy = self
        copy.remaining = response.remaining
        copy.limit = response.limit
        copy.isLive = true
        return copy
    }

    var used: Int { limit - remaining }
    var usedPercent: Double { Double(used) / Double(limit) }
    var usedPercentLabel: String {
        String(format: "%.1f%% used", usedPercent * 100)
    }

    /// "(21,400 credits)" style breakdown rows — illustrative.
    var breakdown: [(String, Int)] {
        [("Narration", 21_400), ("Sound effects", 4_200),
         ("Voice auditions", 2_000)]
    }
}
