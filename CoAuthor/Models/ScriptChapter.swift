import Foundation
import SwiftData

/// A generated script chapter — the prose a narrator reads.
/// `audioRevision` tracks which script revision the existing audio was
/// generated from; when it lags `revision`, the audio is outdated.
@Model
final class ScriptChapter {
    var id: UUID
    var projectID: UUID
    var number: Int
    var title: String
    /// Reader eyebrow label, e.g. "DETROIT, NOVEMBER 1972".
    var settingLabel: String
    var body: String
    /// Current script revision (shown as "Script r4").
    var revision: Int
    /// Revision the generated audio was produced from. Nil = no audio yet.
    var audioRevision: Int?
    /// Duration of the generated audio in seconds. 0 = no audio.
    var audioSeconds: Int
    /// Last playback position in seconds.
    var audioPosition: Int
    /// Generation/job state: "none", "queued", "generating",
    /// "failed", "canceled", or "ready" (audio exists).
    var audioState: String = "none"
    /// Human review state for generated audio: "—", "Suggested",
    /// or "Approved".
    var reviewState: String = "—"
    /// Checked in the narration studio for the next generation batch.
    var isSelectedForGeneration: Bool = false
    /// Which audio take the current file is ("Audio take 1").
    var audioTake: Int = 1

    init(
        id: UUID = UUID(),
        projectID: UUID,
        number: Int,
        title: String,
        settingLabel: String = "",
        body: String,
        revision: Int = 1,
        audioRevision: Int? = nil,
        audioSeconds: Int = 0,
        audioPosition: Int = 0,
        audioState: String = "none",
        reviewState: String = "—",
        isSelectedForGeneration: Bool = false,
        audioTake: Int = 1
    ) {
        self.id = id
        self.projectID = projectID
        self.number = number
        self.title = title
        self.settingLabel = settingLabel
        self.body = body
        self.revision = revision
        self.audioRevision = audioRevision
        self.audioSeconds = audioSeconds
        self.audioPosition = audioPosition
        self.audioState = audioState
        self.reviewState = reviewState
        self.isSelectedForGeneration = isSelectedForGeneration
        self.audioTake = audioTake
    }

    var wordCount: Int {
        body.split(whereSeparator: \.isWhitespace).count
    }

    /// Estimated narration length from word count (~150 wpm).
    var estimatedSeconds: Int {
        max(1, Int((Double(wordCount) / 150.0 * 60).rounded()))
    }

    /// The audio exists but was generated from an older script revision.
    var isAudioOutdated: Bool {
        guard let audioRevision else { return false }
        return audioRevision < revision
    }
}
