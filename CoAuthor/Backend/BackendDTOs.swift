import Foundation

/// Decoding shapes for the backend's data endpoints
/// (`backend/src/index.mjs`). Each DTO maps into the local @Model
/// so hydration stays behind the repository protocols — the app
/// remains SwiftData-backed either way.
enum BackendDTO {

    // MARK: GET /v1/projects — project card derived from the story
    // data files (genre/setting/premise from the outline's Story
    // overview section, runtime from the script front matter).

    struct ProjectMeta: Decodable {
        var title: String
        var genre: String
        var settingDescriptor: String
        var premise: String
        var narratorFormat: String
        var runtimeTargetMinutes: Int
        var totalChapters: Int
        var narratedChapters: Int
        var stageLabel: String
        var status: String

        func model() -> Project {
            Project(
                title: title,
                genre: genre,
                settingDescriptor: settingDescriptor,
                premise: premise,
                narratorFormat: narratorFormat,
                runtimeTargetMinutes: runtimeTargetMinutes,
                totalChapters: totalChapters,
                narratedChapters: narratedChapters,
                stageLabel: stageLabel,
                status: ProjectStatus(rawValue: status) ?? .draft
            )
        }
    }

    // MARK: GET /v1/projects/{id}/ideas

    struct Idea: Decodable {
        var title: String
        var tagline: String
        var pitch: String
        var expandedPitch: String
        var protagonist: String
        var stakes: String
        var angle: String

        func model(projectID: UUID, sortOrder: Int) -> CoAuthor.Idea {
            CoAuthor.Idea(
                projectID: projectID,
                title: title,
                tagline: tagline,
                pitch: pitch,
                expandedPitch: expandedPitch,
                protagonist: protagonist,
                stakes: stakes,
                angle: angle,
                sortOrder: sortOrder
            )
        }
    }

    // MARK: GET /v1/projects/{id}/outline — GPT schema_version 5
    //
    // The outline file carries narrative data inside titled
    // `sections` (paragraph lists) plus a flat `chapters` list.
    // The app-facing fields (writing approach, ending, central
    // question, characters) are parsed out of the section text.

    struct Outline: Decodable {
        var schemaVersion: String?
        var storyTitle: String?
        var sections: [Section]
        var chapters: [Chapter]

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "schema_version"
            case storyTitle = "story_title"
            case sections, chapters
        }

        struct Section: Decodable {
            var heading: String
            var level: Int?
            var paragraphs: [String]
        }

        struct Chapter: Decodable {
            var chapterNumber: Int
            var chapterTitle: String
            var paragraphs: [String]

            enum CodingKeys: String, CodingKey {
                case chapterNumber = "chapter_number"
                case chapterTitle = "chapter_title"
                case paragraphs
            }

            var summary: String {
                paragraphs.joined(separator: "\n\n")
            }

            /// Rough narration estimate (~140 spoken wpm).
            var estimatedMinutes: Int {
                let words = paragraphs.joined(separator: " ")
                    .split(whereSeparator: \.isWhitespace).count
                return max(1, words / 140)
            }
        }

        /// Workspace picker names — the section headings.
        var sectionHeadings: [String] { sections.map(\.heading) }

        func paragraphs(under heading: String) -> [String] {
            sections.first { $0.heading == heading }?.paragraphs ?? []
        }

        var writingApproach: String {
            paragraphs(under: "Writing approach")
                .joined(separator: "\n\n")
        }

        var privateEnding: String {
            paragraphs(under: "Ending and central question")
                .first { !$0.hasPrefix("Central question:") } ?? ""
        }

        var centralQuestion: String {
            paragraphs(under: "Ending and central question")
                .first { $0.hasPrefix("Central question:") }
                .map {
                    String($0.dropFirst("Central question:".count))
                        .trimmingCharacters(in: .whitespaces)
                } ?? ""
        }

        struct ParsedCharacter {
            var name: String
            var role: String
            var notes: String
        }

        /// "Main characters" paragraphs look like
        /// "Naomi Mercer, 32 — Payroll clerk and Isaiah's daughter.
        /// Her ability to follow accounts…". Name is the text before
        /// the first comma or em-dash; role is the phrase after the
        /// em-dash up to the first period; the full paragraph is the
        /// notes.
        var characters: [ParsedCharacter] {
            paragraphs(under: "Main characters").map { paragraph in
                let name = paragraph
                    .prefix { $0 != "," && $0 != "—" }
                    .trimmingCharacters(in: .whitespaces)
                let afterDash = paragraph
                    .components(separatedBy: "—")
                    .dropFirst()
                    .joined(separator: "—")
                    .trimmingCharacters(in: .whitespaces)
                let role = afterDash
                    .components(separatedBy: ".")
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                return ParsedCharacter(
                    name: name.isEmpty ? paragraph : name,
                    role: role,
                    notes: paragraph
                )
            }
        }
    }

    // MARK: GET /v1/projects/{id}/script — schema_version 5
    //
    // The full-script file shares the outline's chapter shape;
    // `front_matter` lines carry the setting/stats header text.

    struct Script: Decodable {
        var schemaVersion: String?
        var storyTitle: String?
        var frontMatter: [String]
        var chapters: [Outline.Chapter]

        enum CodingKeys: String, CodingKey {
            case schemaVersion = "schema_version"
            case storyTitle = "story_title"
            case frontMatter = "front_matter"
            case chapters
        }

        /// Reader eyebrow label — e.g. "Detroit November…".
        var settingLabel: String { frontMatter.first ?? "" }
    }

    // MARK: GET /v1/projects/{id}/cues — schema_version 5
    //
    // The cues file wraps the list in a metadata envelope
    // (`cue_count`, `chapters`, timing fields) — only `cues` is
    // decoded into models.

    struct CueSet: Decodable {
        var cueCount: Int?
        var cues: [Cue]

        enum CodingKeys: String, CodingKey {
            case cueCount = "cue_count"
            case cues
        }
    }

    struct Cue: Decodable {
        var cueId: String
        var chapterNumber: Int
        var chapterTitle: String
        var sound: String
        var priority: String
        var treatment: String
        var storyPassage: String
        var startAndPlacement: String?
        var stopAndFade: String?
        var soundToFindOrGenerate: String?
        var mixingGuidance: String?
        var generationComplete: String?

        enum CodingKeys: String, CodingKey {
            case cueId = "cue_id"
            case chapterNumber = "chapter_number"
            case chapterTitle = "chapter_title"
            case sound, priority, treatment
            case storyPassage = "story_passage"
            case startAndPlacement = "start_and_placement"
            case stopAndFade = "stop_and_fade"
            case soundToFindOrGenerate = "sound_to_find_or_generate"
            case mixingGuidance = "mixing_guidance"
            case generationComplete = "generation_complete"
        }

        /// Ordinal parsed from the cue id ("WCK07" → 7).
        var number: Int {
            Int(cueId.filter(\.isNumber)) ?? 0
        }

        /// treatment → the app's category vocabulary:
        /// "Bed" → "Ambience"; "Spot"/"Silence" pass through.
        var category: String {
            treatment == "Bed" ? "Ambience" : treatment
        }

        var generationState: String {
            if category == "Silence" || generationComplete == "N/A" {
                return "No audio file needed"
            }
            return generationComplete == "Yes" ? "Ready" : "Not generated"
        }

        var placementText: String {
            [startAndPlacement, stopAndFade, mixingGuidance]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
        }

        func model(projectID: UUID) -> SoundCue {
            SoundCue(
                projectID: projectID,
                number: number,
                title: sound,
                chapterTitle: chapterTitle,
                importance: priority,
                category: category,
                sourcePassage: storyPassage,
                placementText: placementText,
                generationPrompt: soundToFindOrGenerate ?? sound,
                generationState: generationState
            )
        }
    }

    // MARK: GET /v1/projects/{id}/voice-prompts — schema_version 5
    //
    // Per-story voice designs: each entry is a character/role the
    // single narrator performs. Maps to CastAssignment locally.

    struct VoicePrompts: Decodable {
        var voices: [Prompt]

        struct Prompt: Decodable {
            var characterName: String
            var role: String
            var voiceDesignPrompt: String
            var previewText: String?
            var performanceNotes: String?
            var savedVoiceName: String?
            var savedVoiceId: String?

            enum CodingKeys: String, CodingKey {
                case characterName = "character_name"
                case role
                case voiceDesignPrompt = "voice_design_prompt"
                case previewText = "preview_text"
                case performanceNotes = "performance_notes"
                case savedVoiceName = "saved_voice_name"
                case savedVoiceId = "saved_voice_id"
            }
        }
    }

    // MARK: GET /v1/projects/{id}/youtube — schema_version 5
    //
    // YouTube upload metadata for the publishing kit.

    struct YouTubeData: Decodable {
        var youtubeTitle: String
        var videoDescription: String
        var tags: [String]
        var pinnedComment: String

        enum CodingKeys: String, CodingKey {
            case youtubeTitle = "youtube_title"
            case videoDescription = "video_description"
            case tags
            case pinnedComment = "pinned_comment"
        }
    }

    // MARK: GET /v1/projects/{id}/thumbnails — schema_version 5
    //
    // Per-chapter thumbnail specs (image prompts anchored to script
    // text). The publishing kit surfaces the first thumbnail.

    struct ChapterThumbnails: Decodable {
        var storyTitle: String?
        var chapters: [Chapter]

        enum CodingKeys: String, CodingKey {
            case storyTitle = "story_title"
            case chapters
        }

        struct Chapter: Decodable {
            var chapterNumber: Int
            var title: String?
            var thumbnails: [Thumb]

            enum CodingKeys: String, CodingKey {
                case chapterNumber = "chapter_number"
                case title
                case thumbnails
            }
        }

        struct Thumb: Decodable {
            var id: String
            var title: String
            var imagePrompt: String?
            var order: Int?

            enum CodingKeys: String, CodingKey {
                case id, title, order
                case imagePrompt = "image_prompt"
            }
        }

        /// The first thumbnail across all chapters, in order —
        /// used for the kit's Selected-thumbnail card.
        var first: Thumb? {
            chapters
                .flatMap(\.thumbnails)
                .sorted { ($0.order ?? 0) < ($1.order ?? 0) }
                .first
        }
    }

    // MARK: GET /v1/projects/{id}/shorts{,-metadata}
    //
    // The shorts file carries per-chapter extraction text plus the
    // recommended clip list; the metadata file carries upload-ready
    // clip titles/descriptions/tags.

    struct YouTubeShorts: Decodable {
        var chapters: [Chapter]
        var clips: [ShortClip]?

        struct Chapter: Decodable {
            var chapterNumber: Int
            var chapterTitle: String?
            var scriptText: String?

            enum CodingKeys: String, CodingKey {
                case chapterNumber = "chapter_number"
                case chapterTitle = "chapter_title"
                case scriptText = "script_text"
            }
        }
    }

    struct ShortsMetadata: Decodable {
        var clips: [ShortClip]
        var recommendedFirstThreeClipIds: [String]?

        enum CodingKeys: String, CodingKey {
            case clips
            case recommendedFirstThreeClipIds =
                "recommended_first_three_clip_ids"
        }
    }

    struct ShortClip: Decodable {
        var clipId: String
        var recommendationHeading: String?
        var chapterNumber: Int?
        var title: String
        var description: String?
        var tags: [String]
        var pinnedComment: String?
        var estimatedDurationSeconds: Int?

        enum CodingKeys: String, CodingKey {
            case clipId = "clip_id"
            case recommendationHeading = "recommendation_heading"
            case chapterNumber = "chapter_number"
            case title, description, tags
            case pinnedComment = "pinned_comment"
            case estimatedDurationSeconds = "estimated_duration_seconds"
        }
    }

    // MARK: GET /v1/projects/{id}/cue-panel — schema_version 5
    //
    // Production mixing panel: track layout and level/pan
    // conventions. Decoded for completeness; the raw file also
    // ships inside export packages.

    struct CuePanel: Decodable {
        var fileNaming: String?
        var levelConvention: String?
        var panConvention: String?
        var tracks: [String: String]?

        enum CodingKeys: String, CodingKey {
            case fileNaming = "file_naming"
            case levelConvention = "level_convention"
            case panConvention = "pan_convention"
            case tracks
        }
    }

    // MARK: GET /v1/jobs

    struct Job: Decodable {
        var projectTitle: String
        var kind: String
        var subject: String
        var provider: String
        var status: String
        var detail: String
        /// Seconds since 1970.
        var startedAt: TimeInterval

        func model(projectID: UUID) -> GenerationJob {
            GenerationJob(
                projectID: projectID,
                projectTitle: projectTitle,
                kind: kind,
                subject: subject,
                provider: provider,
                status: status,
                startedAt: Date(timeIntervalSince1970: startedAt),
                detail: detail
            )
        }
    }

    // MARK: GET /v1/assets

    struct Asset: Decodable {
        var title: String
        var category: String
        var projectTitle: String
        var cueCode: String?
        var seconds: Int
        /// Seconds since 1970.
        var createdDate: TimeInterval
        var reviewState: String

        func model() -> SoundAsset {
            SoundAsset(
                title: title,
                category: category,
                projectTitle: projectTitle,
                cueCode: cueCode,
                seconds: seconds,
                createdDate: Date(timeIntervalSince1970: createdDate),
                reviewState: reviewState
            )
        }
    }

    // MARK: GET /v1/voices

    struct Voice: Decodable {
        var name: String
        var origin: String
        var kind: String
        var roleTag: String
        var descriptor: String?
        var summary: String
        var tags: [String]
        var sampleSeconds: Int
        var isFavorite: Bool?
        var designPrompt: String?
        var savedVoiceID: String?

        func model() -> CoAuthor.Voice {
            CoAuthor.Voice(
                name: name,
                origin: origin,
                kind: kind,
                roleTag: roleTag,
                descriptor: descriptor ?? "",
                summary: summary,
                tags: tags,
                sampleSeconds: sampleSeconds,
                isFavorite: isFavorite ?? false,
                designPrompt: designPrompt ?? "",
                savedVoiceID: savedVoiceID ?? ""
            )
        }
    }

    // MARK: POST /v1/exports

    struct ExportResponse: Decodable {
        var status: String
        var job: Job
        /// The packaged zip — base64, matching how audio is
        /// returned inline until S3 package delivery exists.
        var package: Package?

        struct Package: Decodable {
            var format: String
            var fileCount: Int
            var bytes: Int
            var files: [String]
            /// Inline mode — the zip itself, base64.
            var base64: String?
            /// S3 mode — object URL when AUDIO_STORAGE=s3 is
            /// configured on the backend.
            var downloadUrl: String?

            var zipData: Data? {
                base64.flatMap { Data(base64Encoded: $0) }
            }
            var remoteURL: URL? {
                downloadUrl.flatMap { URL(string: $0) }
            }
        }
    }

    // MARK: POST /v1/voices:sync · DELETE mutations

    struct VoiceSyncResponse: Decodable {
        var status: String
        var voices: [Voice]
    }

    struct MutationResponse: Decodable {
        var status: String
        var detail: String?
        var development: Bool?
    }

    // MARK: POST /v1/auth/signin|signup

    /// Development auth — the backend returns a dev token and the
    /// submitted profile; a real identity provider is not wired.
    struct AuthSession: Decodable {
        var token: String?
        var profile: Profile?
        var development: Bool?
        var error: String?

        struct Profile: Decodable {
            var name: String
            var email: String
        }
    }

    // MARK: POST /v1/projects/{id}/documents/{kind}:generate

    struct DocumentResponse: Decodable {
        var status: String
        var document: Document?

        struct Document: Decodable {
            var kind: String
            var title: String
            var body: String
        }
    }

    // MARK: POST …/audio:generate and /v1/voices/{id}/preview —
    // TTS responses carry inline base64 audio or an S3 download URL.

    struct AudioResult: Decodable {
        var status: String?
        var audioBase64: String?
        var audioUrl: String?
        var voiceId: String?
        var characters: Int?
        var bytes: Int?

        var audioData: Data? {
            audioBase64.flatMap { Data(base64Encoded: $0) }
        }
    }

    // MARK: GET /v1/account — ElevenLabs subscription data for the
    // Settings provider screen (plan tier, character usage, voice
    // slots). `live` is false for the stub fallback.

    struct ProviderAccount: Decodable {
        var provider: String?
        var tier: String?
        var status: String?
        var characterCount: Int?
        var characterLimit: Int?
        var remaining: Int?
        var nextResetUnix: TimeInterval?
        var voiceLimit: Int?
        var live: Bool?

        /// "Resets November 12" style label from the unix reset date.
        var resetLabel: String? {
            guard let nextResetUnix else { return nil }
            let date = Date(timeIntervalSince1970: nextResetUnix)
            return "Resets " + date.formatted(
                .dateTime.month(.wide).day()
            )
        }
    }
}
