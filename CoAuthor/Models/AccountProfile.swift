import Foundation
import SwiftData

/// The local CoAuthor account profile shown across Settings.
/// Authentication itself is M12 backend work — this record holds
/// the display profile only.
@Model
final class AccountProfile {
    var id: UUID
    var name: String
    var email: String
    /// Connected provider summary — "OpenAI + ElevenLabs".
    var connectedServices: String
    /// Default narrator shown in creative preferences.
    var defaultNarrator: String
    /// "Adult · ~60 minutes · Guided workflow"
    var defaultStorySettings: String
    var documentTemplate: String

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        connectedServices: String = "OpenAI + ElevenLabs",
        defaultNarrator: String = "",
        defaultStorySettings: String = "Adult · ~60 minutes · Guided workflow",
        documentTemplate: String = "CoAuthor Editorial"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.connectedServices = connectedServices
        self.defaultNarrator = defaultNarrator
        self.defaultStorySettings = defaultStorySettings
        self.documentTemplate = documentTemplate
    }

    /// "JD" from "Jordan Davis"
    var initials: String {
        name.split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
            .uppercased()
    }
}
