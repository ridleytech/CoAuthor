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
                hasOutline: true,
                scriptChapterCount: 10,
                narratorConfirmed: true,
                cuesApproved: 8,
                cuesTotal: 32,
                selectedIdeaID: UUID(uuidString: "E5555555-5555-5555-5555-555555555551")!,
                voiceDesignPrompt: "A mature American woman with a warm lower "
                    + "register and lightly textured tone. Subtle Great Lakes "
                    + "vowels, clear consonants, measured pacing. Understated "
                    + "emotional range; never theatrical.",
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

    /// Outline content for "The Numbers Widow" matching the
    /// Outline-workspace design reference (r2, approved).
    static func makeOutline() -> (outline: Outline, chapters: [OutlineChapter], characters: [OutlineCharacter]) {
        let projectID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        let outline = Outline(
            projectID: projectID,
            revision: 2,
            approved: true,
            sections: ["Overview", "Writing approach", "Settings",
                       "Characters", "Chapters", "Private ending"],
            writingApproach: "Close third person, past tense.",
            privateEnding: "Evelyn uses a duplicate ledger to negotiate her "
                + "family's release from the debt, refusing to continue the "
                + "operation.",
            centralQuestion: "Can she protect her children without inheriting "
                + "Leon's compromises?"
        )
        let titles = [
            "The Envelope", "The Basement Desk", "Odessa on Dexter",
            "The House Key", "The Work", "A Name in the Ledger",
            "Sunday Collections", "The Second Set of Books",
            "What the River Keeps", "A Balance Owed",
        ]
        let chapters = titles.enumerated().map { pair in
            OutlineChapter(
                outlineID: outline.id,
                number: pair.offset + 1,
                title: pair.element,
                summary: pair.offset == 0
                    ? "Evelyn returns from the funeral to an unmarked envelope "
                        + "beneath the sugar bowl. A collection total does not "
                        + "match Leon's ledger. She hides it before her daughter sees."
                    : "The investigation deepens as \(pair.element.lowercased()) forces "
                        + "Evelyn to choose what she can afford to know.",
                turn: pair.offset == 0
                    ? "a handwriting habit suggests someone she knows sent the demand."
                    : "the cost of silence rises.",
                estimatedMinutes: 6
            )
        }
        let characters = [
            OutlineCharacter(
                outlineID: outline.id,
                name: "Evelyn Price",
                role: "protagonist",
                notes: "Bookkeeper, 34, mother of two. Controlled, observant and "
                    + "quietly stubborn. Keep her active in the investigation."
            )
        ]
        return (outline, chapters, characters)
    }

    /// Script content for "The Numbers Widow" matching the Script-reader
    /// design reference: chapter 1 at r4 with audio generated from r3
    /// (outdated) and playback mid-chapter.
    static func makeScriptChapters() -> [ScriptChapter] {
        let projectID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        let envelopeBody = [
            "The envelope was waiting beneath the sugar bowl. Evelyn knew it "
                + "had not been there when she left for the funeral. She had "
                + "washed the bowl that morning, dried its scalloped rim with "
                + "the good towel, and set it squarely between the salt and "
                + "the radio. Now one corner of brown paper showed beneath it, "
                + "darkened by a thumbprint.",
            "Outside, a bus sighed at the curb. November had stripped the "
                + "maple in front of the house down to its black arithmetic. "
                + "Evelyn kept her coat on. From the hallway came the small, "
                + "deliberate sound of her daughter turning a page.",
            "She lifted the bowl. No stamp. No return address. Just her name, "
                + "written by someone who had taken care not to make it look "
                + "familiar.",
        ].joined(separator: "\n\n")
        let titles = [
            "The Envelope", "The Basement Desk", "Odessa on Dexter",
            "The House Key", "The Work", "A Name in the Ledger",
            "Sunday Collections", "The Second Set of Books",
            "What the River Keeps", "A Balance Owed",
        ]
        // Per-chapter states matching the Narration studio reference:
        // ready-outdated / ready-suggested / ready-approved / selected /
        // queued / generating / failed / canceled / selected / none.
        struct Spec {
            let audioRevision: Int?
            let audioSeconds: Int
            let audioPosition: Int
            let state: String
            let review: String
            let selected: Bool
        }
        let specs = [
            Spec(audioRevision: 3, audioSeconds: 342, audioPosition: 84,
                 state: "ready", review: "—", selected: false),
            Spec(audioRevision: 4, audioSeconds: 366, audioPosition: 84,
                 state: "ready", review: "Suggested", selected: false),
            Spec(audioRevision: 4, audioSeconds: 360, audioPosition: 0,
                 state: "ready", review: "Approved", selected: false),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "none", review: "—", selected: true),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "queued", review: "—", selected: false),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "generating", review: "—", selected: false),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "failed", review: "—", selected: false),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "canceled", review: "—", selected: false),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "none", review: "—", selected: true),
            Spec(audioRevision: nil, audioSeconds: 0, audioPosition: 0,
                 state: "none", review: "—", selected: false),
        ]
        return titles.enumerated().map { pair in
            let index = pair.offset
            let spec = specs[index]
            return ScriptChapter(
                projectID: projectID,
                number: index + 1,
                title: pair.element,
                settingLabel: "DETROIT, NOVEMBER 1972",
                body: index == 0
                    ? envelopeBody
                    : MockScriptGenerator.proseForSeed(
                        title: pair.element, number: index + 1
                    ),
                revision: 4,
                audioRevision: spec.audioRevision,
                audioSeconds: spec.audioSeconds,
                audioPosition: spec.audioPosition,
                audioState: spec.state,
                reviewState: spec.review,
                isSelectedForGeneration: spec.selected
            )
        }
    }

    /// Generation activity matching the Generation-activity reference —
    /// narration jobs in several states plus other task kinds/projects.
    /// `basementDeskID`/`envelopeID` link jobs to their script chapters.
    static func makeGenerationJobs(
        basementDeskID: UUID? = nil,
        envelopeID: UUID? = nil
    ) -> [GenerationJob] {
        let widowID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        let lightkeeperID = UUID(uuidString: "B2222222-2222-2222-2222-222222222222")!
        let now = Date()
        let cal = Calendar.current
        func at(_ hour: Int, _ minute: Int, dayOffset: Int = 0) -> Date {
            let day = cal.date(byAdding: .day, value: dayOffset, to: now)!
            return cal.date(
                bySettingHour: hour, minute: minute, second: 0, of: day
            ) ?? now
        }
        return [
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Chapter narration", subject: "The Work",
                provider: "ElevenLabs", status: "generating",
                startedAt: at(9, 30), detail: "Estimate unavailable"
            ),
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Chapter narration", subject: "Sunday Collections",
                provider: "ElevenLabs", status: "queued",
                startedAt: at(9, 30), detail: "Estimate unavailable"
            ),
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Chapter narration", subject: "The Basement Desk",
                provider: "ElevenLabs", status: "ready",
                startedAt: at(9, 24), detail: "6:06 audio",
                chapterID: basementDeskID
            ),
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Sound audition", subject: "Basement hum",
                provider: "ElevenLabs", status: "failed",
                startedAt: at(9, 22), detail: "No result returned"
            ),
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Full script", subject: "revision 4",
                provider: "OpenAI", status: "ready",
                startedAt: at(9, 12), detail: "Usage pending"
            ),
            GenerationJob(
                projectID: lightkeeperID, projectTitle: "The Last Lightkeeper",
                kind: "Thumbnail alternatives", subject: "",
                provider: "OpenAI", status: "canceled",
                startedAt: at(4, 15, dayOffset: -1), detail: "No result selected"
            ),
            GenerationJob(
                projectID: widowID, projectTitle: "The Numbers Widow",
                kind: "Chapter narration", subject: "The Envelope",
                provider: "ElevenLabs", status: "outdated",
                startedAt: at(15, 40, dayOffset: -1), detail: "Script r3",
                chapterID: envelopeID
            ),
        ]
    }

    /// Saved voices matching the Saved Voices design reference —
    /// ten account voices (8 custom + catalog), Marlene assigned to
    /// The Numbers Widow.
    static func makeVoices() -> [Voice] {
        let widowID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        let mapID = UUID(uuidString: "C3333333-3333-3333-3333-333333333333")!
        return [
            Voice(
                name: "Marlene", localLabel: "Detroit narrator",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Narrator", descriptor: "Detroit narrator",
                summary: "Warm, grounded storytelling with a mature lower register.",
                tags: ["Narrator", "Warm", "Mature", "Great Lakes American"],
                sampleSeconds: 23, isFavorite: true,
                designPrompt: "Mature American woman, warm lower register, "
                    + "lightly textured tone. Clear consonants, unhurried "
                    + "pacing, understated emotional range.",
                savedVoiceID: "ca_voice_marlene_detroit",
                localName: "Marlene · Detroit narrator",
                localLabels: "Narrator / Warm / Mature",
                localNotes: "Note: keep dialogue firm and restrained.",
                assignedProjectID: widowID,
                assignmentLabel: "The Numbers Widow · Series narrator"
            ),
            Voice(
                name: "Samuel", origin: "ElevenLabs catalog", kind: "Catalog",
                roleTag: "Narrator",
                summary: "Calm, resonant delivery for thoughtful nonfiction and fiction.",
                tags: ["Resonant", "Calm", "General American"],
                sampleSeconds: 31,
                assignedProjectID: mapID,
                assignmentLabel: "A Map of Small Returns"
            ),
            Voice(
                name: "June", origin: "ElevenLabs catalog", kind: "Catalog",
                roleTag: "Narrator · Character",
                summary: "Bright, conversational delivery with natural character range.",
                tags: ["Narrator · Character", "Conversational", "Midwestern American"],
                sampleSeconds: 28
            ),
            Voice(
                name: "Odessa", localLabel: "performance study",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance study",
                summary: "Warm and direct; laughter close to the surface.",
                tags: ["Character", "Textured", "Warm", "Detroit American"],
                sampleSeconds: 19
            ),
            Voice(
                name: "Calvin", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Dry, measured delivery for procedural and technical scenes.",
                tags: ["Custom", "Dry", "Measured", "Neutral American"],
                sampleSeconds: 0, isAvailable: false
            ),
            Voice(
                name: "Evelyn", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Bright, intimate delivery with a subtle emotional edge.",
                tags: ["Custom", "Intimate", "Emotional", "Upper Midwest American"],
                sampleSeconds: 0, isAvailable: false
            ),
            Voice(
                name: "Ruth", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Clear, authoritative delivery for exposition and guidance.",
                tags: ["Custom", "Authoritative", "Clear", "Standard American"],
                sampleSeconds: 0, isAvailable: false
            ),
            Voice(
                name: "Gloria", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Warm, expressive delivery for character-driven scenes.",
                tags: ["Custom", "Expressive", "Warm", "Inland American"],
                sampleSeconds: 0, isAvailable: false
            ),
            Voice(
                name: "Leon", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Deep, steady delivery for dramatic and reflective scenes.",
                tags: ["Custom", "Deep", "Steady", "Great Lakes American"],
                sampleSeconds: 0, isAvailable: false
            ),
            Voice(
                name: "Dexter", localLabel: "performance guide",
                origin: "Created in CoAuthor", kind: "Custom",
                roleTag: "Character", descriptor: "performance guide",
                summary: "Sharp, agile delivery for fast-paced dialogue and action.",
                tags: ["Custom", "Agile", "Sharp", "Urban American"],
                sampleSeconds: 0, isAvailable: false
            ),
        ]
    }

    /// Cast assignments for The Numbers Widow — Odessa already approved
    /// per the casting-detail reference.
    static func makeCastAssignments() -> [CastAssignment] {
        let widowID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        return [
            CastAssignment(projectID: widowID, characterName: "Evelyn",
                           roleLabel: "Lead · firm"),
            CastAssignment(projectID: widowID, characterName: "Odessa",
                           roleLabel: "Supporting · easy", approved: true),
            CastAssignment(projectID: widowID, characterName: "Calvin",
                           roleLabel: "Supporting · patient"),
        ]
    }

    /// Sound cues matching the Sound-cues reference — SC-01…SC-06 with
    /// the design's review/generation state mix (2 selected).
    static func makeSoundCues() -> [SoundCue] {
        let widowID = UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!
        return [
            SoundCue(
                projectID: widowID, number: 1, title: "Kitchen room tone",
                chapterTitle: "The Envelope", importance: "Core",
                category: "Ambience",
                sourcePassage: "\"The envelope was waiting beneath the sugar "
                    + "bowl. Evelyn knew it had not been there when she left "
                    + "for the funeral.\"",
                placementText: "Start before first line; fade in 1.5 sec.\n"
                    + "Stop at \"She lifted the bowl\"; fade out 2 sec.\n"
                    + "Keep well below narration; duck under dialogue.",
                generationPrompt: "Quiet Detroit kitchen, 1972. Low "
                    + "refrigerator hum, distant traffic, faint radiator "
                    + "tick. No voices, no music. Seamless, restrained "
                    + "ambience.",
                reviewState: "Approved", generationState: "Ready",
                isSelected: true,
                alternativeLabels: ["A · Kitchen ambience", "B · Kitchen ambience"]
            ),
            SoundCue(
                projectID: widowID, number: 2, title: "Bus at the curb",
                chapterTitle: "The Envelope", importance: "Optional",
                category: "Spot",
                sourcePassage: "\"Outside, a bus sighed at the curb.\"",
                reviewState: "Suggested", generationState: "Not generated",
                isSelected: true,
                alternativeLabels: ["A · Bus pass", "B · Bus pass"]
            ),
            SoundCue(
                projectID: widowID, number: 3, title: "The unmarked name",
                chapterTitle: "The Envelope", importance: "Core",
                category: "Silence",
                sourcePassage: "\"Just her name, written by someone who had "
                    + "taken care not to make it look familiar.\"",
                reviewState: "Approved",
                generationState: "No audio file needed"
            ),
            SoundCue(
                projectID: widowID, number: 4, title: "Basement hum",
                chapterTitle: "The Basement Desk", importance: "Core",
                category: "Ambience",
                sourcePassage: "\"The basement light came on reluctantly.\"",
                reviewState: "Approved", generationState: "Not generated",
                alternativeLabels: ["A · Basement hum", "B · Basement hum"]
            ),
            SoundCue(
                projectID: widowID, number: 5,
                title: "Dexter street transition",
                chapterTitle: "Odessa on Dexter", importance: "Optional",
                category: "Transition",
                sourcePassage: "\"Odessa was already on the porch.\"",
                reviewState: "Suggested", generationState: "Not generated",
                alternativeLabels: ["A · Street bed", "B · Street bed"]
            ),
            SoundCue(
                projectID: widowID, number: 6, title: "Key on the table",
                chapterTitle: "The House Key", importance: "Optional",
                category: "Spot",
                sourcePassage: "\"He put the key beside her cup.\"",
                reviewState: "Skipped", generationState: "Not generated",
                alternativeLabels: ["A · Key set-down", "B · Key set-down"]
            ),
        ]
    }

    /// Publishing kit matching the Publishing-kit reference —
    /// spoiler-free title, description, tags, thumbnail selection.
    static func makePublishingKit() -> PublishingKit {
        PublishingKit(
            projectID: UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!,
            youtubeTitle: "The Numbers Widow | A Detroit Crime Story — 1972",
            descriptionText: "Detroit, November 1972. A bookkeeper. A "
                + "mysterious envelope. A balance that will not settle. "
                + "Follow Evelyn Price in this intimate historical crime "
                + "story, told by a single narrator. Approximately one "
                + "hour of atmospheric fiction.",
            tagsText: "historical fiction, crime story, Detroit 1972, audiobook",
            pinnedComment: "Which detail first caught your attention? "
                + "Please keep comments spoiler-free.",
            thumbnailTitle: "Detroit Stories · 1972",
            thumbnailDetail: "Literary typography over a dark teal Detroit "
                + "street and warm kitchen light.",
            isSaved: true,
            savedAt: .now
        )
    }

    /// Sound assets matching the Asset-library reference — two Widow
    /// ambiences plus one from another project.
    static func makeSoundAssets() -> [SoundAsset] {
        [
            SoundAsset(
                title: "Kitchen room tone", projectTitle: "The Numbers Widow",
                cueCode: "SC-01", seconds: 30,
                createdDate: Date(timeIntervalSince1970: 1_793_500_800)
            ),
            SoundAsset(
                title: "Basement hum - alternate",
                projectTitle: "The Numbers Widow",
                cueCode: "SC-04", seconds: 30,
                createdDate: Date(timeIntervalSince1970: 1_793_414_400)
            ),
            SoundAsset(
                title: "Lakeshore wind",
                projectTitle: "The Last Lightkeeper",
                cueCode: "SC-07", seconds: 45,
                createdDate: Date(timeIntervalSince1970: 1_793_328_000)
            ),
        ]
    }

    /// Latest completed export shown on the Exports screen.
    static func makeExportRecord() -> ExportRecord {
        ExportRecord(
            projectID: UUID(uuidString: "A1111111-1111-1111-1111-111111111111")!,
            title: "Documents package",
            fileCount: 6,
            sizeLabel: "1.8 MB"
        )
    }

    /// Inserts a fresh sample set. Used by previews, tests, and the
    /// repository's one-time development seed.
    @MainActor
    static func insertSamples(into context: ModelContext) {
        for project in makeProjects() { context.insert(project) }
        for item in makeReviewItems() { context.insert(item) }
        for idea in makeIdeas() { context.insert(idea) }
        let (outline, chapters, characters) = makeOutline()
        context.insert(outline)
        for chapter in chapters { context.insert(chapter) }
        for character in characters { context.insert(character) }
        let scriptChapters = makeScriptChapters()
        for chapter in scriptChapters { context.insert(chapter) }
        for voice in makeVoices() { context.insert(voice) }
        for assignment in makeCastAssignments() { context.insert(assignment) }
        for job in makeGenerationJobs(
            basementDeskID: scriptChapters.count > 1 ? scriptChapters[1].id : nil,
            envelopeID: scriptChapters.first?.id
        ) { context.insert(job) }
        for cue in makeSoundCues() { context.insert(cue) }
        context.insert(makePublishingKit())
        for asset in makeSoundAssets() { context.insert(asset) }
        context.insert(makeExportRecord())
    }
}
