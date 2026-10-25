import Foundation
import SwiftData

/// Initial versioned schema — the graph as shipped in M1 plus the
/// additive models accumulated through M11. Kept as the migration
/// source for V2.
enum CoAuthorSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Project.self, ReviewItem.self, Idea.self,
         Outline.self, OutlineChapter.self, OutlineCharacter.self,
         ScriptChapter.self, Voice.self, CastAssignment.self,
         GenerationJob.self, SoundCue.self, PublishingKit.self,
         SoundAsset.self, ExportRecord.self, AccountProfile.self,
         NotificationSettings.self]
    }
}

/// V2 — same model set as V1; the bump formalizes the accumulated
/// additive changes (M4–M11) behind an explicit migration stage so
/// future schema edits get a real migration path.
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
        // V2 adds no new fields — all M4–M11 additions were already
        // present in the V1 store, so this is a lightweight bump.
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
