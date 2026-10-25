import Foundation
import SwiftData

/// A provider job shown in Generation activity — narration, sound
/// auditions, script and thumbnail generation.
@Model
final class GenerationJob {
    var id: UUID
    var projectID: UUID
    var projectTitle: String
    /// Task kind — "Chapter narration", "Sound audition",
    /// "Full script", "Thumbnail alternatives".
    var kind: String
    /// Detail after the kind — "The Work", "revision 4".
    var subject: String
    /// "ElevenLabs" or "OpenAI".
    var provider: String
    /// queued / generating / ready / failed / canceled / outdated
    var status: String
    var startedAt: Date
    /// Trailing status detail — "6:06 audio", "Estimate unavailable",
    /// "No result returned", "Script r3".
    var detail: String
    /// Optional chapter the job produced (for "Open result").
    var chapterID: UUID?

    init(
        id: UUID = UUID(),
        projectID: UUID,
        projectTitle: String,
        kind: String,
        subject: String,
        provider: String,
        status: String,
        startedAt: Date,
        detail: String = "",
        chapterID: UUID? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.projectTitle = projectTitle
        self.kind = kind
        self.subject = subject
        self.provider = provider
        self.status = status
        self.startedAt = startedAt
        self.detail = detail
        self.chapterID = chapterID
    }

    /// "Chapter narration · The Work"
    var title: String {
        "\(kind) · \(subject)"
    }
}
