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

/// Illustrative provider-credit snapshot matching the Credits
/// designs — explicitly not a live balance until M12.
struct CreditsSnapshot {
    let connected = true
    let accountName = "Jordan's studio"
    let planLabel = "Creator (illustrative)"
    let remaining = 72_400
    let limit = 100_000
    let resetLabel = "Resets November 12"
    let lastRefresh = "Today, 9:42 AM"
    let apiKeyTail = "9b41"

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
