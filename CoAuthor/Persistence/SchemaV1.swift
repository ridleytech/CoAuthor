import Foundation
import SwiftData

/// Initial versioned schema. Add a `CoAuthorSchemaV2` and a migration
/// plan when the model graph changes.
enum CoAuthorSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, ReviewItem.self, Idea.self,
         Outline.self, OutlineChapter.self, OutlineCharacter.self,
         ScriptChapter.self, Voice.self, CastAssignment.self]
    }
}

enum CoAuthorSchema {
    static var current: Schema {
        Schema(versionedSchema: CoAuthorSchemaV1.self)
    }
}
