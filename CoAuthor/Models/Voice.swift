import Foundation
import SwiftData

/// A narrator/character voice — either created in CoAuthor (occupies a
/// provider custom-voice slot) or an ElevenLabs catalog voice.
@Model
final class Voice {
    var id: UUID
    var name: String
    /// Local label, e.g. "Detroit narrator" / "performance guide".
    var localLabel: String
    /// "Created in CoAuthor" or "ElevenLabs catalog".
    var origin: String
    /// "Custom" or "Catalog".
    var kind: String
    /// Role tag: "Narrator", "Character", "Narrator · Character".
    var roleTag: String
    /// Short descriptor shown after the name ("Detroit narrator",
    /// "Reference only", "Performance guide").
    var descriptor: String
    /// One-line delivery summary.
    var summary: String
    var tags: [String]
    /// Audition sample length in seconds. 0 = not generated.
    var sampleSeconds: Int
    var isFavorite: Bool
    var isAvailable: Bool
    /// The original Voice Design prompt used to create it.
    var designPrompt: String
    /// Provider-side identifier.
    var savedVoiceID: String
    /// Local metadata ("Local name, labels & notes" card).
    var localName: String
    var localLabels: String
    var localNotes: String
    /// Current assignment, if any ("The Numbers Widow · Series narrator").
    var assignedProjectID: UUID?
    var assignmentLabel: String

    init(
        id: UUID = UUID(),
        name: String,
        localLabel: String = "",
        origin: String,
        kind: String,
        roleTag: String,
        descriptor: String = "",
        summary: String,
        tags: [String] = [],
        sampleSeconds: Int = 0,
        isFavorite: Bool = false,
        isAvailable: Bool = true,
        designPrompt: String = "",
        savedVoiceID: String = "",
        localName: String = "",
        localLabels: String = "",
        localNotes: String = "",
        assignedProjectID: UUID? = nil,
        assignmentLabel: String = ""
    ) {
        self.id = id
        self.name = name
        self.localLabel = localLabel
        self.origin = origin
        self.kind = kind
        self.roleTag = roleTag
        self.descriptor = descriptor
        self.summary = summary
        self.tags = tags
        self.sampleSeconds = sampleSeconds
        self.isFavorite = isFavorite
        self.isAvailable = isAvailable
        self.designPrompt = designPrompt
        self.savedVoiceID = savedVoiceID
        self.localName = localName
        self.localLabels = localLabels
        self.localNotes = localNotes
        self.assignedProjectID = assignedProjectID
        self.assignmentLabel = assignmentLabel
    }

    /// Display name — "Marlene · Detroit narrator" on the list card.
    var displayName: String {
        descriptor.isEmpty ? name : "\(name) · \(descriptor)"
    }

    var sampleLabel: String {
        sampleSeconds > 0
            ? String(format: "%d:%02d sample", sampleSeconds / 60, sampleSeconds % 60)
            : "Not available"
    }

    /// Second line on the list card — e.g.
    /// "Created in CoAuthor · Custom · Detroit narrator" or
    /// "ElevenLabs catalog · Narrator".
    var listSubtitle: String {
        var parts = [origin, kind == "Custom" ? "Custom" : roleTag]
        if !descriptor.isEmpty { parts.append(descriptor) }
        return parts.joined(separator: " · ")
    }
}

/// A character cast assignment on the Voices & casting detail screen —
/// guides the single narrator's performance rather than generating
/// separate character voices.
@Model
final class CastAssignment {
    var id: UUID
    var projectID: UUID
    var characterName: String
    /// e.g. "Lead · firm" / "Supporting · easy".
    var roleLabel: String
    var approved: Bool

    init(
        id: UUID = UUID(),
        projectID: UUID,
        characterName: String,
        roleLabel: String,
        approved: Bool = false
    ) {
        self.id = id
        self.projectID = projectID
        self.characterName = characterName
        self.roleLabel = roleLabel
        self.approved = approved
    }
}
