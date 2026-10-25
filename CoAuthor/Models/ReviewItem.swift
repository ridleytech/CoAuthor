import Foundation
import SwiftData

/// A row in the dashboard review queue — e.g. generated audio awaiting
/// source review or a suggestion awaiting approval.
@Model
final class ReviewItem {
    var id: UUID
    var title: String
    var detail: String
    /// Badge label, e.g. "Review" or "Approve".
    var actionLabel: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        actionLabel: String,
        sortOrder: Int
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.actionLabel = actionLabel
        self.sortOrder = sortOrder
    }
}
