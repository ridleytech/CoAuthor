import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    private let repository: any DashboardRepository

    private(set) var projects: [Project] = []
    private(set) var reviewItems: [ReviewItem] = []
    private(set) var loadError: String?
    private var didSeed = false

    /// Placeholder until M11 (account) supplies a real profile.
    let welcomeName = "Jordan"

    init(repository: any DashboardRepository) {
        self.repository = repository
    }

    // MARK: Derived state

    /// The continue card surfaces the most recently edited project.
    var featured: Project? { projects.first }

    /// Projects beyond the featured one, matching the design's
    /// two-row "Recent projects" preview.
    var recentProjects: [Project] { Array(projects.dropFirst().prefix(2)) }

    /// "2 more" — count of projects other than the featured one.
    var remainingProjectCount: Int { max(projects.count - 1, 0) }

    /// The review-queue card previews two rows and labels the header
    /// with the total queue size.
    var previewReviewItems: [ReviewItem] { Array(reviewItems.prefix(2)) }

    var isEmpty: Bool { projects.isEmpty }

    // MARK: Loading

    func load() {
        do {
            if !didSeed {
                try repository.seedDevelopmentDataIfNeeded()
                didSeed = true
            }
            projects = try repository.fetchProjects()
            reviewItems = try repository.fetchReviewItems()
            loadError = nil
        } catch {
            loadError = "Couldn't load projects."
        }
    }

    // MARK: Formatting

    /// "h:mm a" matching the design's "9:24 AM" style.
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    /// "today, 9:24 AM" / "Yesterday, 4:10 PM" / "Oct 21, 11:35 AM"
    func editedDescription(for project: Project) -> String {
        let date = project.lastEditedAt
        let time = Self.timeFormatter.string(from: date)
        if Calendar.current.isDateInToday(date) { return "today, \(time)" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday, \(time)" }
        return "\(date.formatted(.dateTime.month(.abbreviated).day())), \(time)"
    }

    /// Short day label for the "Last edit" stat tile.
    func editedDayLabel(for project: Project) -> String {
        let date = project.lastEditedAt
        if Calendar.current.isDateInToday(date) { return "today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
