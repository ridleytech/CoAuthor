import SwiftUI
import SwiftData

/// Credits & Usage — illustrative provider balance, subscription
/// separation, usage breakdown, and recent job activity with
/// illustrative credit amounts.
/// Reference: Designs/Full Content/Credits & Usage/Connected/
struct CreditsUsageView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: CreditsUsageViewModel?

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackBar { coordinator.pop() }
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let vm = CreditsUsageViewModel(
                    generationRepository: SwiftDataGenerationRepository(
                        context: modelContext
                    )
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: CreditsUsageViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(viewModel)
                    creditsCard(viewModel)
                    subscriptionCard
                    breakdownCard(viewModel)
                    activitySection(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Open Generation activity") {
                coordinator.selectedTab = .activity
            }
        }
    }

    private func titleBlock(_ viewModel: CreditsUsageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Credits & Usage")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.caInk)
            Text("ElevenLabs provider credits, not a CoAuthor balance.")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            if viewModel.credits.isLive {
                StatusBadge("Live data · backend", kind: .ready)
            } else {
                StatusBadge("Illustrative data · not a live balance",
                            kind: .neutral)
            }
        }
        .padding(.vertical, 4)
    }

    private func creditsCard(_ viewModel: CreditsUsageViewModel) -> some View {
        let credits = viewModel.credits
        return CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ElevenLabs AUDIO credits")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("✓ Connected", kind: .ready)
                }
                Text("\(credits.accountName) · \(credits.planLabel)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("\(format(credits.remaining)) credits remaining")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.caInk)
                Text("\(format(credits.used)) of \(format(credits.limit)) used")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.caField)
                        Capsule()
                            .fill(Color.caInk)
                            .frame(width: geometry.size.width
                                   * credits.usedPercent)
                    }
                }
                .frame(height: 6)
                Text("\(credits.usedPercentLabel) · \(credits.resetLabel)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Last successful refresh: \(credits.lastRefresh)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button("Refresh") {
                    coordinator.push(.placeholder(
                        title: "Credit refresh", milestone: "M12"
                    ))
                }
                .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var subscriptionCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("CoAuthor subscription — separate from "
                     + "ElevenLabs credits")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Plan / tier: Not available · Price: Not available")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Divider().overlay(Color.caHairline)
                SettingsNavRow(
                    title: "Manage CoAuthor subscription", isLast: true
                ) {
                    coordinator.push(.placeholder(
                        title: "CoAuthor plan", milestone: "M12"
                    ))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func breakdownCard(_ viewModel: CreditsUsageViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Example usage breakdown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Illustrative provider activity · not fetched "
                     + "account data")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                ForEach(
                    Array(viewModel.credits.breakdown.enumerated()),
                    id: \.offset
                ) { pair in
                    Divider().overlay(Color.caHairline)
                    HStack {
                        Text(pair.element.0)
                            .font(.subheadline)
                            .foregroundStyle(Color.caInk)
                        Spacer()
                        Text("\(format(pair.element.1)) credits")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                }
                Divider().overlay(Color.caHairline)
                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("\(format(viewModel.credits.used)) credits")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caSecondary)
                }
                Text("Provider totals may include activity outside "
                     + "CoAuthor.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func activitySection(
        _ viewModel: CreditsUsageViewModel
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
            Text("Recent activity · illustrative examples")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.caInk)
            ForEach(viewModel.rows) { row in
                jobCard(row, viewModel)
            }
        }
    }

    private func jobCard(
        _ row: JobCreditRow,
        _ viewModel: CreditsUsageViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(row.job.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    let badge = row.statusBadge
                    StatusBadge(badge.0, kind: badge.1)
                }
                Text("\(row.job.projectTitle) · "
                     + viewModel.timeLabel(row.job.startedAt))
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Divider().overlay(Color.caHairline)
                HStack {
                    Text("Recorded credits")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text(row.credits.map { "\(format($0)) credits" }
                            ?? "Not available")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                Divider().overlay(Color.caHairline)
                Button {
                    if let chapterID = row.job.chapterID {
                        coordinator.push(.audioReview(chapterID: chapterID))
                    } else {
                        coordinator.push(.placeholder(
                            title: "Job details", milestone: "M12"
                        ))
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(row.job.status == "failed"
                             ? "View details" : "Open result")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
