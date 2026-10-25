import Foundation
import SwiftData

/// Persisted notification preferences — one record per install.
@Model
final class NotificationSettings {
    var id: UUID
    var generationFinished: Bool
    var generationFailed: Bool
    var lowProviderCredits: Bool
    /// Security alerts can't be turned off — kept as a constant.
    var emailEnabled: Bool
    var pushEnabled: Bool

    init(
        id: UUID = UUID(),
        generationFinished: Bool = true,
        generationFailed: Bool = true,
        lowProviderCredits: Bool = true,
        emailEnabled: Bool = true,
        pushEnabled: Bool = false
    ) {
        self.id = id
        self.generationFinished = generationFinished
        self.generationFailed = generationFailed
        self.lowProviderCredits = lowProviderCredits
        self.emailEnabled = emailEnabled
        self.pushEnabled = pushEnabled
    }
}
