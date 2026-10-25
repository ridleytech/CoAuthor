import SwiftUI
import SwiftData

/// Settings tab root — profile card, illustrative credits summary,
/// creative preferences, account & services, support, danger zone.
/// Reference: Designs/Full Content/Settings/Full Content.png
struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: SettingsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BrandTopBar()
            Group {
                if let viewModel, let profile = viewModel.profile {
                    content(profile, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load settings",
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
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let vm = SettingsViewModel(
                    accountRepository: SwiftDataAccountRepository(
                        context: modelContext
                    )
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ profile: AccountProfile,
        _ viewModel: SettingsViewModel
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text("Account · Defaults · Connected services")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.vertical, 4)

                profileCard(profile)
                creditsCard(viewModel)
                preferencesCard(profile)
                servicesCard(profile)
                supportCard(viewModel)
                developerCard
                dangerCard
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.cardGap)
        }
    }

    // MARK: Profile card

    private func profileCard(_ profile: AccountProfile) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(profile.initials)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.caSecondary)
                        .frame(width: 52, height: 52)
                        .background(Color.caField)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Text(profile.email)
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                        Text("CoAuthor account")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    Spacer()
                }
                Divider().overlay(Color.caHairline)
                settingsRow("Manage account") {
                    coordinator.push(.manageAccount)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Credits card

    private func creditsCard(_ viewModel: SettingsViewModel) -> some View {
        let credits = viewModel.credits
        return CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Credits & Usage")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Illustrative data", kind: .ready)
                }
                Text("Connected account")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                HStack {
                    Text(credits.accountName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("ElevenLabs AUDIO")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.caSecondary)
                }
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Credits remaining")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                        Text(Self.format(credits.remaining))
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.caInk)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Used of \(Self.format(credits.limit))")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                        Text(Self.format(credits.used))
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.caInk)
                    }
                }
                progressBar(credits.usedPercent)
                HStack {
                    Text(credits.usedPercentLabel)
                        .font(.caption)
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text(credits.resetLabel)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Divider().overlay(Color.caHairline)
                HStack(spacing: 10) {
                    Text("Updated today, 9:42 AM")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    Spacer()
                    settingsButton("Refresh") {
                        coordinator.push(.placeholder(
                            title: "Credit refresh",
                            milestone: "M12"
                        ))
                    }
                    settingsButton("View usage") {
                        coordinator.push(.creditsUsage)
                    }
                }
                Text("Illustrative data · not a live balance. These are "
                     + "ElevenLabs AUDIO credits for connected account "
                     + "\(credits.accountName).")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func progressBar(_ fraction: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.caField)
                Capsule()
                    .fill(Color.caInk)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: 6)
    }

    // MARK: Preference + service cards

    private func preferencesCard(_ profile: AccountProfile) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Creative preferences")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                    .padding(.bottom, 10)
                settingsRow(
                    "Default genre/story settings",
                    detail: profile.defaultStorySettings
                ) {
                    coordinator.push(.placeholder(
                        title: "Story defaults", milestone: "M12"
                    ))
                }
                settingsRow("Default narrator", detail: profile.defaultNarrator) {
                    coordinator.push(.savedVoices(projectID: nil))
                }
                settingsRow("Document templates",
                            detail: profile.documentTemplate) {
                    coordinator.push(.placeholder(
                        title: "Document templates", milestone: "M12"
                    ))
                }
                settingsRow("Saved Voices", detail: nil, isLast: true) {
                    coordinator.push(.savedVoices(projectID: nil))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func servicesCard(_ profile: AccountProfile) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Account & services")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                    .padding(.bottom, 10)
                settingsRow("Manage usage limits") {
                    coordinator.push(.placeholder(
                        title: "Usage limits", milestone: "M12"
                    ))
                }
                settingsRow("Connected services",
                            detail: profile.connectedServices) {
                    coordinator.push(.providerConnection)
                }
                settingsRow("Notifications",
                            detail: "Generation finished + failed") {
                    coordinator.push(.notificationSettings)
                }
                settingsRow("Security",
                            detail: "Password and sign-in methods") {
                    coordinator.push(.placeholder(
                        title: "Security", milestone: "M12"
                    ))
                }
                settingsRow("CoAuthor plan",
                            detail: "Manage CoAuthor subscription",
                            isLast: true) {
                    coordinator.push(.placeholder(
                        title: "CoAuthor plan", milestone: "M12"
                    ))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func supportCard(_ viewModel: SettingsViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Support")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                    .padding(.bottom, 10)
                settingsRow("Help and support") {
                    coordinator.push(.placeholder(
                        title: "Help and support", milestone: "M12"
                    ))
                }
                settingsRow("Privacy Policy") {
                    coordinator.push(.placeholder(
                        title: "Privacy Policy", milestone: "M12"
                    ))
                }
                settingsRow("Terms of Service") {
                    coordinator.push(.placeholder(
                        title: "Terms of Service", milestone: "M12"
                    ))
                }
                HStack {
                    Text("App version")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    Spacer()
                    Text(viewModel.appVersion)
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                }
                .padding(.vertical, 10)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Developer card

    /// Global mock ↔ backend switch. Feature code reads
    /// `BackendConfiguration.shared.useBackend` at mock seams.
    private var developerCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Developer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Toggle(
                    "Use backend data",
                    isOn: Binding(
                        get: { BackendConfiguration.shared.useBackend },
                        set: { BackendConfiguration.shared.useBackend = $0 }
                    )
                )
                .font(.subheadline)
                .tint(Color.caInk)
                Text("Base URL: \(BackendConfiguration.shared.baseURL.absoluteString)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("When on, supported sections fetch from the "
                     + "backend API and fall back to mock data on "
                     + "failure. Backend: backend/ (gitignored Lambda "
                     + "scaffold).")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var dangerCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                Text("Danger zone")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                    .padding(.bottom, 10)
                settingsRow("Sign out") {
                    coordinator.push(.createAccount)
                }
                Button {
                    coordinator.push(.deleteAccount)
                } label: {
                    HStack {
                        Text("Delete account")
                            .font(.subheadline)
                            .foregroundStyle(Color.caDestructive)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Shared rows

    private func settingsRow(
        _ title: String,
        detail: String? = nil,
        isLast: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(detail == nil
                                           ? Color.caInk : Color.caSecondary)
                        if let detail {
                            Text(detail)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.caInk)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !isLast {
                Divider().overlay(Color.caHairline)
            }
        }
    }

    private func settingsButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.caInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private static func format(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
