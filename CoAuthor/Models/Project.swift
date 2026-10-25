import Foundation
import SwiftData

/// Lifecycle stage shown on project rows ("Outline review", "Premise saved").
enum ProjectStatus: String, Codable, CaseIterable {
    case draft
    case review
    case inProgress
    case complete
}

@Model
final class Project {
    var id: UUID
    var title: String
    var genre: String
    /// "Detroit, November 1972"
    var settingDescriptor: String
    var premise: String
    /// "Single narrator"
    var narratorFormat: String
    var runtimeTargetMinutes: Int
    var totalChapters: Int
    var narratedChapters: Int
    /// Human-readable stage, e.g. "Outline review", "Premise saved".
    var stageLabel: String
    var statusRaw: String
    /// Asset-catalog name for the featured cover image, if any.
    var coverImageName: String?
    var createdAt: Date
    var lastEditedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        genre: String,
        settingDescriptor: String,
        premise: String,
        narratorFormat: String,
        runtimeTargetMinutes: Int,
        totalChapters: Int,
        narratedChapters: Int,
        stageLabel: String,
        status: ProjectStatus,
        coverImageName: String? = nil,
        createdAt: Date = Date(),
        lastEditedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.genre = genre
        self.settingDescriptor = settingDescriptor
        self.premise = premise
        self.narratorFormat = narratorFormat
        self.runtimeTargetMinutes = runtimeTargetMinutes
        self.totalChapters = totalChapters
        self.narratedChapters = narratedChapters
        self.stageLabel = stageLabel
        self.statusRaw = status.rawValue
        self.coverImageName = coverImageName
        self.createdAt = createdAt
        self.lastEditedAt = lastEditedAt
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
}
