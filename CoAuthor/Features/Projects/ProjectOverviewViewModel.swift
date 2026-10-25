import Foundation

/// A row in the overview's production-stages checklist.
struct ProductionStage: Identifiable {
    /// Display line, e.g. "Script: 10 chapters drafted".
    let label: String
    /// Short stage key used for next-step derivation.
    let key: String
    let complete: Bool
    var id: String { key }
}

/// A row in the overview's recent-activity card.
struct ActivityEntry: Identifiable {
    let title: String
    let when: String
    var id: String { title + when }
}

@Observable
@MainActor
final class ProjectOverviewViewModel {
    private let repository: any DashboardRepository
    let projectID: UUID

    private(set) var project: Project?
    private(set) var loadError: String?

    init(projectID: UUID, repository: any DashboardRepository) {
        self.projectID = projectID
        self.repository = repository
    }

    func load() {
        do {
            project = try repository.fetchProject(id: projectID)
            loadError = project == nil ? "Project not found." : nil
        } catch {
            loadError = "Couldn't load project."
        }
    }

    // MARK: Derived state

    var subtitle: String {
        guard let project else { return "" }
        return [project.settingDescriptor, project.genre,
                "~\(project.runtimeTargetMinutes) min target"]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// "Single narrator · Marlene · Script r4" — skips absent parts.
    var storyMeta: String {
        guard let project else { return "" }
        var parts = [project.narratorFormat]
        if let narrator = project.narratorName { parts.append(narrator) }
        if project.scriptRevision > 0 { parts.append("Script r\(project.scriptRevision)") }
        return parts.joined(separator: " · ")
    }

    var productionStages: [ProductionStage] {
        guard let project else { return [] }
        return [
            ProductionStage(
                label: project.outlineApproved ? "Outline approved" : "Outline not approved yet",
                key: "Outline",
                complete: project.outlineApproved
            ),
            ProductionStage(
                label: "Script: " + (project.scriptChapterCount > 0
                    ? "\(project.scriptChapterCount) chapters drafted"
                    : "not drafted yet"),
                key: "Script",
                complete: project.scriptChapterCount > 0
            ),
            ProductionStage(
                label: "Voices: " + (project.narratorConfirmed ? "Narrator confirmed" : "not cast yet"),
                key: "Voices",
                complete: project.narratorConfirmed
            ),
            ProductionStage(
                label: "Narration: \(project.narratedChapters) of \(project.totalChapters) chapters generated",
                key: "Narration",
                complete: project.totalChapters > 0
                    && project.narratedChapters >= project.totalChapters
            ),
            ProductionStage(
                label: "Sounds: \(project.cuesApproved) of \(project.cuesTotal) cues approved",
                key: "Sounds",
                complete: project.cuesTotal > 0 && project.cuesApproved >= project.cuesTotal
            ),
        ]
    }

    /// Derived "recommended next step" — the design shows a specific
    /// stale-asset warning; that detection belongs to M8/M9, so here we
    /// surface the earliest incomplete stage instead.
    var recommendedNextStep: (title: String, detail: String)? {
        guard let stage = productionStages.first(where: { !$0.complete }) else {
            return nil
        }
        switch stage.key {
        case "Outline":
            return ("Outline needs review",
                    "Approve the outline before generating the script.")
        case "Script":
            return ("Script not drafted",
                    "Generate the script from your approved outline.")
        case "Voices":
            return ("No narrator confirmed",
                    "Cast a narrator before generating audio.")
        case "Narration":
            return ("Narration in progress",
                    stage.label + ". Review generated chapters.")
        case "Sounds":
            return ("Sound cues pending",
                    stage.label + ". Approve cues for production.")
        default:
            return nil
        }
    }

    var activityEntries: [ActivityEntry] {
        guard let project else { return [] }
        var entries: [ActivityEntry] = []
        if !Calendar.current.isDate(project.lastEditedAt, inSameDayAs: project.createdAt) {
            entries.append(ActivityEntry(
                title: "Project edited",
                when: relativeDescription(project.lastEditedAt)
            ))
        }
        entries.append(ActivityEntry(
            title: "Project created",
            when: relativeDescription(project.createdAt)
        ))
        return entries
    }

    /// "9:24 AM" / "Yesterday" / "Oct 21" — matches the overview design.
    func relativeDescription(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return DashboardViewModel.timeFormatter.string(from: date)
        }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
