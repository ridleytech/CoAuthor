import Foundation
import SwiftData

/// Initial versioned schema — the model graph as it stood after M3
/// (Project + ReviewItem from M1, Idea added in M3). V2 adds every
/// model accumulated through M11; the lightweight stage migrates
/// the real additive delta.
enum CoAuthorSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, ReviewItem.self, Idea.self]
    }
}

/// V2 — the accumulated graph: outline, script, voices, cues,
/// generation jobs, publishing, and account models (M4–M11).
enum CoAuthorSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, ReviewItem.self, Idea.self,
         Outline.self, OutlineChapter.self, OutlineCharacter.self,
         ScriptChapter.self, Voice.self, CastAssignment.self,
         GenerationJob.self, SoundCue.self, PublishingKit.self,
         SoundAsset.self, ExportRecord.self, AccountProfile.self,
         NotificationSettings.self]
    }
}

enum CoAuthorMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CoAuthorSchemaV1.self, CoAuthorSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // V2 is purely additive over V1 — new entities only — so a
        // lightweight stage covers it. (A stage between identical
        // checksums crashes Core Data's NSLightweightMigrationStage;
        // V1 must therefore be the true pre-M4 model set.)
        [.lightweight(
            fromVersion: CoAuthorSchemaV1.self,
            toVersion: CoAuthorSchemaV2.self
        )]
    }
}

enum CoAuthorSchema {
    static var current: Schema {
        Schema(versionedSchema: CoAuthorSchemaV2.self)
    }
}
