import Foundation
import SwiftData

/// YouTube upload data prepared for a project — spoiler-free title,
/// description, tags, pinned comment, thumbnail selection.
/// "Not a publishing action": preparing files only.
@Model
final class PublishingKit {
    var id: UUID
    var projectID: UUID
    var youtubeTitle: String
    var descriptionText: String
    var tagsText: String
    var pinnedComment: String
    var thumbnailTitle: String
    var thumbnailDetail: String
    var disclosureText: String
    var isSaved: Bool
    var savedAt: Date?

    init(
        id: UUID = UUID(),
        projectID: UUID,
        youtubeTitle: String = "",
        descriptionText: String = "",
        tagsText: String = "",
        pinnedComment: String = "",
        thumbnailTitle: String = "",
        thumbnailDetail: String = "",
        disclosureText: String = "AI-assisted writing and synthetic "
            + "narration. Human-directed and reviewed. Mature themes; "
            + "implied violence.",
        isSaved: Bool = false,
        savedAt: Date? = nil
    ) {
        self.id = id
        self.projectID = projectID
        self.youtubeTitle = youtubeTitle
        self.descriptionText = descriptionText
        self.tagsText = tagsText
        self.pinnedComment = pinnedComment
        self.thumbnailTitle = thumbnailTitle
        self.thumbnailDetail = thumbnailDetail
        self.disclosureText = disclosureText
        self.isSaved = isSaved
        self.savedAt = savedAt
    }
}
