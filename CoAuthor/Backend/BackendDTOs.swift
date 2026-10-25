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
}
