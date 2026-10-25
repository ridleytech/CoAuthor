import Foundation
import SwiftData

/// A generated story idea for a project. Persisted so selection,
/// saved flags, and later refinement survive relaunch.
@Model
final class Idea {
    var id: UUID
    var projectID: UUID
    var title: String
    /// Short descriptor shown under the title ("intimate financial mystery").
    var tagline: String
    /// One-line pitch on the ideas list.
    var pitch: String
    /// Longer paragraph shown on the comparison cards.
    var expandedPitch: String
    var protagonist: String
    var stakes: String
    var angle: String
    /// In the comparison set.
    var isSelected: Bool
    /// Saved to the project by the user.
    var isSaved: Bool
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectID: UUID,
        title: String,
        tagline: String,
        pitch: String,
        expandedPitch: String,
        protagonist: String,
        stakes: String,
        angle: String,
        isSelected: Bool = false,
        isSaved: Bool = false,
        sortOrder: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.tagline = tagline
        self.pitch = pitch
        self.expandedPitch = expandedPitch
        self.protagonist = protagonist
        self.stakes = stakes
        self.angle = angle
        self.isSelected = isSelected
        self.isSaved = isSaved
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
