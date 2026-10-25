import Foundation
import SwiftData

/// Lifecycle stage shown on project rows ("Outline review", "Premise saved").
enum ProjectStatus: String, Codable, CaseIterable {
    case draft
    case review
    case inProgress
    case complete
}

/// Creation workflow chosen on the new-project form.
enum ProjectWorkflow: String, Codable, CaseIterable {
    /// Review the outline before the full script is generated.
    case guided
    /// Generate story and production materials, then review.
    case completePackage
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
    /// "Intimate, tense · Adult"
    var toneAudience: String = ""
    var workflowRaw: String = ProjectWorkflow.guided.rawValue
    /// Assigned narrator name, e.g. "Marlene".
    var narratorName: String?
    /// Current script revision number (0 = no script yet).
    var scriptRevision: Int = 0
    // Production-stage progress (summaries for the overview checklist).
    var outlineApproved: Bool = false
    var scriptChapterCount: Int = 0
    var narratorConfirmed: Bool = false
    var cuesApproved: Int = 0
    var cuesTotal: Int = 0
    /// The idea the user chose as the story direction.
    var selectedIdeaID: UUID?
    /// True once an outline exists — steers the Story tab route.
    var hasOutline: Bool = false
    /// Voice Design prompt shown on the casting screen (M6).
    var voiceDesignPrompt: String = ""
    /// "Approve voice description" state on the casting screen.
    var voicePromptApproved: Bool = false
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
        toneAudience: String = "",
        workflow: ProjectWorkflow = .guided,
        narratorName: String? = nil,
        scriptRevision: Int = 0,
        outlineApproved: Bool = false,
        scriptChapterCount: Int = 0,
        narratorConfirmed: Bool = false,
        cuesApproved: Int = 0,
        cuesTotal: Int = 0,
        selectedIdeaID: UUID? = nil,
        hasOutline: Bool = false,
        voiceDesignPrompt: String = "",
        voicePromptApproved: Bool = false,
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
        self.toneAudience = toneAudience
        self.workflowRaw = workflow.rawValue
        self.narratorName = narratorName
        self.scriptRevision = scriptRevision
        self.outlineApproved = outlineApproved
        self.scriptChapterCount = scriptChapterCount
        self.narratorConfirmed = narratorConfirmed
        self.cuesApproved = cuesApproved
        self.cuesTotal = cuesTotal
        self.selectedIdeaID = selectedIdeaID
        self.hasOutline = hasOutline
        self.voiceDesignPrompt = voiceDesignPrompt
        self.voicePromptApproved = voicePromptApproved
        self.coverImageName = coverImageName
        self.createdAt = createdAt
        self.lastEditedAt = lastEditedAt
    }

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var workflow: ProjectWorkflow {
        get { ProjectWorkflow(rawValue: workflowRaw) ?? .guided }
        set { workflowRaw = newValue.rawValue }
    }
}
