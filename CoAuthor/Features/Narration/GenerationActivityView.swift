import SwiftUI
import SwiftData

@Observable
@MainActor
final class GenerationViewModel {
    private let repository: any GenerationRepository

    private(set) var jobs: [GenerationJob] = []
    private(set) var loadError: String?

    var projectFilter = "All projects"
    var taskFilter = "All tasks"
    var statusFilter = "All statuses"

    init(repository: any GenerationRepository) {
        self.repository = repository
    }

    var projectOptions: [String] {
        ["All projects"] + Array(Set(jobs.map(\.projectTitle))).sorted()
    }

    var taskOptions: [String] {
        ["All tasks"] + Array(Set(jobs.map(\.kind))).sorted()
    }

    var statusOptions: [String] {
        ["All statuses", "generating", "queued", "ready",
         "failed", "canceled", "outdated"]
    }

    var filteredJobs: [GenerationJob] {
        jobs.filter { job in
            (projectFilter == "All projects" || job.projectTitle == projectFilter)
            && (taskFilter == "All tasks" || job.kind == taskFilter)
            && (statusFilter == "All statuses" || job.status == statusFilter)
        }
    }

    func load() {
        do {
            jobs = try repository.fetchJobs()
            loadError = nil
        } catch {
            loadError = "Couldn't load activity."
        }
    }

    /// "Started Today 9:30 AM" / "Started Yesterday 3:40 PM"
    func startedLine(_ job: GenerationJob) -> String {
        let day = Calendar.current.isDateInToday(job.startedAt) ? "Today"
            : Calendar.current.isDateInYesterday(job.startedAt) ? "Yesterday"
            : job.startedAt.formatted(date: .abbreviated, time: .omitted)
        let time = job.startedAt.formatted(date: .omitted, time: .shortened)
        var line = "Started \(day) \(time) · \(job.provider)"
        if !job.detail.isEmpty { line += " · \(job.detail)" }
        return line
    }

    func cancel(_ job: GenerationJob) {
        job.status = "canceled"
        job.detail = "Canceled"
        try? repository.saveChanges()
    }

    func retry(_ job: GenerationJob) {
        job.status = "queued"
        job.detail = "Estimate unavailable"
        try? repository.saveChanges()
    }
}

/// Generation activity — the Activity tab feed of provider jobs with
/// status filters and per-state actions.
/// Reference: Designs/Full Content/Generation activity
struct GenerationActivityView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: GenerationViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BrandTopBar()
            Group {
                if let viewModel {
                    content(viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load activity",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .task {
            if viewModel == nil {
                let vm = GenerationViewModel(
                    repository: SwiftDataGenerationRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    private func content(_ viewModel: GenerationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("Generation activity")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    filterRow(viewModel)
                    ForEach(viewModel.filteredJobs) { job in
                        jobCard(job, viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Refresh activity") {
                viewModel.load()
            }
        }
    }

    // MARK: Filters

    private func filterRow(_ viewModel: GenerationViewModel) -> some View {
        HStack(spacing: 8) {
            filterMenu(viewModel.projectFilter, options: viewModel.projectOptions) {
                viewModel.projectFilter = $0
            }
            filterMenu(viewModel.taskFilter, options: viewModel.taskOptions) {
                viewModel.taskFilter = $0
            }
            filterMenu(viewModel.statusFilter, options: viewModel.statusOptions) {
                viewModel.statusFilter = $0
            }
            Spacer()
        }
    }

    private func filterMenu(
        _ title: String, options: [String], onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caInk)
        }
    }

    // MARK: Job card

    private func jobCard(_ job: GenerationJob, _ viewModel: GenerationViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(job.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    statusBadge(job.status)
                }
                Text(job.projectTitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Text(viewModel.startedLine(job))
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                actionLink(job, viewModel)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func statusBadge(_ status: String) -> some View {
        switch status {
        case "generating": StatusBadge("Generating", kind: .info)
        case "queued": StatusBadge("Queued", kind: .neutral)
        case "ready": StatusBadge("Ready", kind: .ready)
        case "failed": StatusBadge("Failed", kind: .failed)
        case "canceled": StatusBadge("Canceled", kind: .neutral)
        case "outdated": StatusBadge("Outdated", kind: .warm)
        default: StatusBadge(status.capitalized, kind: .neutral)
        }
    }

    @ViewBuilder
    private func actionLink(_ job: GenerationJob, _ viewModel: GenerationViewModel) -> some View {
        switch job.status {
        case "generating", "queued":
            jobLink("Cancel") { viewModel.cancel(job) }
        case "ready":
            jobLink("Open result") {
                if let chapterID = job.chapterID {
                    coordinator.push(.audioReview(chapterID: chapterID))
                } else {
                    coordinator.push(.placeholder(title: job.kind, milestone: "M12"))
                }
            }
        case "failed":
            jobLink("Retry") { viewModel.retry(job) }
        case "canceled":
            jobLink("View details") {
                coordinator.push(.placeholder(title: "Job details", milestone: "M12"))
            }
        case "outdated":
            jobLink("Review source") {
                if let chapterID = job.chapterID {
                    coordinator.push(.scriptReader(chapterID: chapterID))
                } else {
                    coordinator.push(.placeholder(title: "Job details", milestone: "M12"))
                }
            }
        default:
            EmptyView()
        }
    }

    private func jobLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(title == "Cancel" ? Color.red : Color.caInk)
        }
    }
}
