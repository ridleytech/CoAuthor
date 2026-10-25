import Foundation

/// Decoding shapes for the backend's data endpoints
/// (`backend/src/index.mjs`). Each DTO maps into the local @Model
/// so hydration stays behind the repository protocols — the app
/// remains SwiftData-backed either way.
enum BackendDTO {

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

    // MARK: GET /v1/projects/{id}/outline

    struct Outline: Decodable {
        var revision: Int
        var sections: [String]
        var writingApproach: String
        var privateEnding: String
        var centralQuestion: String
        var chapters: [Chapter]
        var characters: [Character]

        struct Chapter: Decodable {
            var number: Int
            var title: String
            var summary: String
            var turn: String
            var estimatedMinutes: Int
        }

        struct Character: Decodable {
            var name: String
            var role: String
            var notes: String
        }
    }

    // MARK: GET /v1/projects/{id}/cues

    struct Cue: Decodable {
        var number: Int
        var title: String
        var chapterTitle: String
        var importance: String
        var category: String
        var sourcePassage: String
        var generationState: String

        func model(projectID: UUID) -> SoundCue {
            SoundCue(
                projectID: projectID,
                number: number,
                title: title,
                chapterTitle: chapterTitle,
                importance: importance,
                category: category,
                sourcePassage: sourcePassage,
                generationState: generationState
            )
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
}
