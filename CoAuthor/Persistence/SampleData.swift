import Foundation
import SwiftData

/// Deterministic development/preview content matching the dashboard
/// design reference. Dates are relative to "now" so the seeded data
/// always reads naturally ("today", "yesterday").
enum SampleData {

    /// Fresh `Project` instances on every call — `@Model` objects are
    /// bound to a context on insert, so shared instances cannot be
    /// inserted into more than one store.
    static func makeProjects() -> [Project] {
        let now = Date()
        let cal = Calendar.current
        return [
            Project(
                id: UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!,
                title: "The Numbers Widow",
                genre: "Historical crime fiction",
                settingDescriptor: "Detroit, November 1972",
                premise: "Bookkeeper Evelyn Price investigates missing money "
                    + "after her husband's murder. She must discover the truth "
                    + "before his numbers-operation debt threatens her children.",
                narratorFormat: "Single narrator",
                runtimeTargetMinutes: 60,
                totalChapters: 10,
                narratedChapters: 3,
                stageLabel: "Narration in progress",
                status: .inProgress,
                toneAudience: "Intimate, tense · Adult",
                workflow: .guided,
                narratorName: "Marlene",
                scriptRevision: 4,
                outlineApproved: true,
                scriptChapterCount: 10,
                narratorConfirmed: true,
                cuesApproved: 8,
                cuesTotal: 32,
                selectedIdeaID: UUID(uuidString: "E5555555-5555-5555-5555-555555555551")!,
                coverImageName: "DashboardHero",
                createdAt: cal.date(byAdding: .day, value: -14, to: now)!,
                lastEditedAt: cal.date(byAdding: .hour, value: -2, to: now)!
            ),
            Project(
                id: UUID(uuidString: "B2222222-2222-2222-2222-222222222222")!,
                title: "The Last Lightkeeper",
                genre: "Coastal mystery",
                settingDescriptor: "Lake Michigan, 1986",
                premise: "A retiring lightkeeper uncovers a smuggling route "
                    + "recorded in her predecessor's logbooks.",
                narratorFormat: "Single narrator",
                runtimeTargetMinutes: 45,
                totalChapters: 8,
                narratedChapters: 0,
                stageLabel: "Outline review",
                status: .review,
                toneAudience: "Warm, reflective · Adult",
                workflow: .guided,
                narratorName: nil,
                scriptRevision: 0,
                outlineApproved: false,
                scriptChapterCount: 0,
                narratorConfirmed: false,
                cuesApproved: 0,
                cuesTotal: 0,
                createdAt: cal.date(byAdding: .day, value: -6, to: now)!,
                lastEditedAt: cal.date(byAdding: .day, value: -1, to: now)!
            ),
            Project(
                id: UUID(uuidString: "C3333333-3333-3333-3333-333333333333")!,
                title: "A Map of Small Returns",
                genre: "Literary fiction",
                settingDescriptor: "Chicago, present day",
                premise: "A debt collector keeps a ledger of everything he "
                    + "has taken — and everything he owes.",
                narratorFormat: "Single narrator",
                runtimeTargetMinutes: 30,
                totalChapters: 6,
                narratedChapters: 0,
                stageLabel: "Premise saved",
                status: .draft,
                toneAudience: "Intimate, tense · Adult",
                workflow: .completePackage,
                createdAt: cal.date(byAdding: .day, value: -4, to: now)!,
                lastEditedAt: cal.date(byAdding: .day, value: -4, to: now)!
            ),
        ]
    }

    /// Six queued items; the dashboard card previews the first two.
    static func makeReviewItems() -> [ReviewItem] { [
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444441")!,
            title: "The Envelope",
            detail: "Audio needs source review",
            actionLabel: "Review",
            sortOrder: 0
        ),
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444442")!,
            title: "Kitchen room tone",
            detail: "Suggestion to approve",
            actionLabel: "Approve",
            sortOrder: 1
        ),
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444443")!,
            title: "Chapter 2 ambience",
            detail: "Audio needs source review",
            actionLabel: "Review",
            sortOrder: 2
        ),
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444444")!,
            title: "Train platform",
            detail: "Suggestion to approve",
            actionLabel: "Approve",
            sortOrder: 3
        ),
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444445")!,
            title: "The Basement Desk",
            detail: "Audio needs source review",
            actionLabel: "Review",
            sortOrder: 4
        ),
        ReviewItem(
            id: UUID(uuidString: "D4444444-4444-4444-4444-444444444446")!,
            title: "Rain on windows",
            detail: "Suggestion to approve",
            actionLabel: "Approve",
            sortOrder: 5
        ),
    ] }

    /// Ideas for "The Numbers Widow" matching the Generated-ideas and
    /// comparison design references.
    static func makeIdeas() -> [Idea] {
        let projectID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        return [
            Idea(
                id: UUID(uuidString: "E5555555-5555-5555-5555-555555555551")!,
                projectID: projectID,
                title: "The Numbers Widow",
                tagline: "intimate financial mystery",
                pitch: "Her husband's murder exposes missing money in his numbers operation.",
                expandedPitch: "Evelyn Price, a bookkeeper and mother of two, follows "
                    + "missing money after her husband's murder. His debt threatens "
                    + "her children. Her eye for numbers becomes her only protection.",
                protagonist: "Evelyn Price · a precise, underestimated bookkeeper and mother of two.",
                stakes: "A debt threatens her children before she can discover who is collecting it.",
                angle: "Financial clues become the language of grief, trust and survival.",
                isSelected: true,
                isSaved: true,
                sortOrder: 0
            ),
            Idea(
                id: UUID(uuidString: "E5555555-5555-5555-5555-555555555552")!,
                projectID: projectID,
                title: "The Sunday Collector",
                tagline: "neighborhood moral mystery",
                pitch: "A missing collection book ties a respectable charity to an illegal lottery.",
                expandedPitch: "Ruth Bell, a church treasurer, discovers a missing "
                    + "collection book. Exposing the truth could save her neighbors—or "
                    + "destroy the charity that holds them together.",
                protagonist: "Ruth Bell · a church treasurer who knows every household on her route.",
                stakes: "To protect her neighborhood, Ruth must expose the person who once protected her.",
                angle: "One Sunday's collection route reveals a city's hidden moral economy.",
                isSelected: true,
                isSaved: true,
                sortOrder: 1
            ),
            Idea(
                id: UUID(uuidString: "E5555555-5555-5555-5555-555555555553")!,
                projectID: projectID,
                title: "A House on Dexter",
                tagline: "contained domestic mystery",
                pitch: "An old tenant returns for a ledger hidden inside a wall.",
                expandedPitch: "An old tenant returns for a ledger hidden inside a wall.",
                protagonist: "Gloria Watts · a seamstress preparing to sell her family home.",
                stakes: "The sale could free her family—or deliver their last refuge to the wrong hands.",
                angle: "A contained, domestic mystery unfolding across a single winter weekend.",
                isSelected: false,
                isSaved: false,
                sortOrder: 2
            ),
        ]
    }

    /// Inserts a fresh sample set. Used by previews, tests, and the
    /// repository's one-time development seed.
    @MainActor
    static func insertSamples(into context: ModelContext) {
        for project in makeProjects() { context.insert(project) }
        for item in makeReviewItems() { context.insert(item) }
        for idea in makeIdeas() { context.insert(idea) }
    }
}
