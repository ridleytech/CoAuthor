import Foundation
import SwiftData

/// A generated sound-effect asset — the library view of audio
/// produced (or selected) for a project's cues.
@Model
final class SoundAsset {
    var id: UUID
    var title: String
    /// "Ambience", "Spot", "Transition".
    var category: String
    var projectTitle: String
    /// The cue this asset serves, e.g. "SC-01" — optional for
    /// library sounds reused later.
    var cueCode: String?
    var seconds: Int
    var createdDate: Date
    /// "Approved" or "Draft".
    var reviewState: String
    /// When the asset has been reused into another project's cue,
    /// that cue's code ("SC-01").
    var reusedTargetCode: String?

    init(
        id: UUID = UUID(),
        title: String,
        category: String = "Ambience",
        projectTitle: String,
        cueCode: String? = nil,
        seconds: Int = 30,
        createdDate: Date = .now,
        reviewState: String = "Approved",
        reusedTargetCode: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.projectTitle = projectTitle
        self.cueCode = cueCode
        self.seconds = seconds
        self.createdDate = createdDate
        self.reviewState = reviewState
        self.reusedTargetCode = reusedTargetCode
    }
}
