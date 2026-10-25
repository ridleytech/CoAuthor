import Foundation
import SwiftData

/// A sound cue — a placed audio moment (ambience, spot effect,
/// transition) or a deliberate silence in the narration.
@Model
final class SoundCue {
    var id: UUID
    var projectID: UUID
    /// Ordinal used for the "SC-01" code.
    var number: Int
    var title: String
    var chapterTitle: String
    /// "Core" or "Optional".
    var importance: String
    /// "Ambience", "Spot", "Transition", or "Silence".
    var category: String
    /// The exact source passage the cue anchors to.
    var sourcePassage: String
    /// Placement & mixing instructions.
    var placementText: String
    /// The prompt used for sound generation.
    var generationPrompt: String
    /// Review state: "Approved", "Suggested", or "Skipped".
    var reviewState: String
    /// Generation state: "Ready", "Not generated", "Queued",
    /// or "No audio file needed" (silence cues).
    var generationState: String
    /// Selected for the next batch generation (the list's dot).
    var isSelected: Bool
    /// Alternative takes offered for comparison ("A", "B").
    var alternativeLabels: [String]
    var selectedAlternative: Int

    init(
        id: UUID = UUID(),
        projectID: UUID,
        number: Int,
        title: String,
        chapterTitle: String,
        importance: String,
        category: String,
        sourcePassage: String = "",
        placementText: String = "",
        generationPrompt: String = "",
        reviewState: String = "Suggested",
        generationState: String = "Not generated",
        isSelected: Bool = false,
        alternativeLabels: [String] = [],
        selectedAlternative: Int = 0
    ) {
        self.id = id
        self.projectID = projectID
        self.number = number
        self.title = title
        self.chapterTitle = chapterTitle
        self.importance = importance
        self.category = category
        self.sourcePassage = sourcePassage
        self.placementText = placementText
        self.generationPrompt = generationPrompt
        self.reviewState = reviewState
        self.generationState = generationState
        self.isSelected = isSelected
        self.alternativeLabels = alternativeLabels
        self.selectedAlternative = selectedAlternative
    }

    /// "SC-01"
    var code: String {
        String(format: "SC-%02d", number)
    }

    var isSilence: Bool { category == "Silence" }

    var needsAudio: Bool {
        !isSilence && generationState != "No audio file needed"
    }
}
