import Foundation
import SwiftData

/// Persistence boundary for saved voices and cast assignments.
@MainActor
protocol VoiceRepository {
    func fetchVoices() throws -> [Voice]
    func fetchVoice(id: UUID) throws -> Voice?
    func fetchCastAssignments(projectID: UUID) throws -> [CastAssignment]
    func insert(_ voice: Voice) throws
    func insert(_ assignment: CastAssignment) throws
    func delete(_ voice: Voice) throws
    func saveChanges() throws
}

@MainActor
final class SwiftDataVoiceRepository: VoiceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchVoices() throws -> [Voice] {
        let descriptor = FetchDescriptor<Voice>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchVoice(id: UUID) throws -> Voice? {
        let descriptor = FetchDescriptor<Voice>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    func fetchCastAssignments(projectID: UUID) throws -> [CastAssignment] {
        let descriptor = FetchDescriptor<CastAssignment>(
            predicate: #Predicate { $0.projectID == projectID }
        )
        return try context.fetch(descriptor)
    }

    func insert(_ voice: Voice) throws {
        context.insert(voice)
        try context.save()
    }

    func insert(_ assignment: CastAssignment) throws {
        context.insert(assignment)
        try context.save()
    }

    func delete(_ voice: Voice) throws {
        context.delete(voice)
        try context.save()
    }

    func saveChanges() throws {
        try context.save()
    }
}

/// Illustrative account capacity — a mock of the ElevenLabs custom-voice
/// slot limit shown on the voices screens. Slots are not credits; the
/// count includes voices created outside CoAuthor.
struct VoiceCapacity {
    let provider = "ElevenLabs"
    let groupLabel = "Custom voices"
    let accountName = "Jordan's studio"
    let usedSlots: Int
    let totalSlots: Int
    let lastRefreshed: Date

    init(usedSlots: Int = 8, totalSlots: Int = 10, lastRefreshed: Date = Date()) {
        self.usedSlots = usedSlots
        self.totalSlots = totalSlots
        self.lastRefreshed = lastRefreshed
    }

    var availableSlots: Int { totalSlots - usedSlots }
    var usedPercent: Int { usedSlots * 100 / totalSlots }
    var fraction: Double { Double(usedSlots) / Double(totalSlots) }

    /// "Custom voices: 8 of 10 slots used"
    var headline: String { "\(groupLabel): \(usedSlots) of \(totalSlots) slots used" }

    /// "80% used · 2 slots available"
    var detailLine: String { "\(usedPercent)% used · \(availableSlots) slots available" }

    var refreshedLine: String {
        "\(accountName) · Last refreshed Today, 9:42 AM"
    }
}

/// Mock account capacity — replaced by the provider account endpoint in M12.
enum MockVoiceCapacity {
    static let current = VoiceCapacity(lastRefreshed: Date())
}
