import Foundation
import SwiftData

/// A project's story outline, revised as a unit ("Outline r2").
@Model
final class Outline {
    var id: UUID
    var projectID: UUID
    var revision: Int
    var approved: Bool
    /// Section names shown in the workspace picker.
    var sections: [String]
    var writingApproach: String
    var privateEnding: String
    var centralQuestion: String

    init(
        id: UUID = UUID(),
        projectID: UUID,
        revision: Int = 1,
        approved: Bool = false,
        sections: [String] = [],
        writingApproach: String = "",
        privateEnding: String = "",
        centralQuestion: String = ""
    ) {
        self.id = id
        self.projectID = projectID
        self.revision = revision
        self.approved = approved
        self.sections = sections
        self.writingApproach = writingApproach
        self.privateEnding = privateEnding
        self.centralQuestion = centralQuestion
    }
}

/// A chapter in the outline arc.
@Model
final class OutlineChapter {
    var id: UUID
    var outlineID: UUID
    var number: Int
    var title: String
    var summary: String
    /// The turn the chapter ends on ("a handwriting habit suggests…").
    var turn: String
    var estimatedMinutes: Int

    init(
        id: UUID = UUID(),
        outlineID: UUID,
        number: Int,
        title: String,
        summary: String,
        turn: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.outlineID = outlineID
        self.number = number
        self.title = title
        self.summary = summary
        self.turn = turn
        self.estimatedMinutes = estimatedMinutes
    }
}

/// A character tracked in the outline.
@Model
final class OutlineCharacter {
    var id: UUID
    var outlineID: UUID
    var name: String
    var role: String
    var notes: String

    init(
        id: UUID = UUID(),
        outlineID: UUID,
        name: String,
        role: String,
        notes: String
    ) {
        self.id = id
        self.outlineID = outlineID
        self.name = name
        self.role = role
        self.notes = notes
    }
}
