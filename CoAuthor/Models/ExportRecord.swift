import Foundation
import SwiftData

/// A completed package export — the local record of what was
/// prepared for download (no files are produced in this build).
@Model
final class ExportRecord {
    var id: UUID
    var projectID: UUID
    /// "Documents package", "Complete project package".
    var title: String
    var fileCount: Int
    /// "1.8 MB"
    var sizeLabel: String
    var createdAt: Date
    /// "Complete" or "Preparing".
    var status: String

    init(
        id: UUID = UUID(),
        projectID: UUID,
        title: String,
        fileCount: Int,
        sizeLabel: String,
        createdAt: Date = .now,
        status: String = "Complete"
    ) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.fileCount = fileCount
        self.sizeLabel = sizeLabel
        self.createdAt = createdAt
        self.status = status
    }
}
