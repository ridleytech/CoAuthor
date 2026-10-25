import SwiftUI
import SwiftData

/// Manage account — profile block, account actions, plan & billing,
/// delete-account entry.
/// Reference: Designs/Full Content/Account/Manage account/
struct ManageAccountView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ManageAccountViewModel?

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackBar { coordinator.pop() }
            Group {
                if let viewModel, let profile = viewModel.profile {
                    content(profile)
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
                let vm = ManageAccountViewModel(
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
    private func content(_ profile: AccountProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                Text("Manage account")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.caInk)
                    .padding(.vertical, 4)

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

                CardContainer {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsNavRow(title: "Edit profile") {
                            coordinator.push(.placeholder(
                                title: "Edit profile", milestone: "M12"
                            ))
                        }
                        SettingsNavRow(title: "Change email") {
                            coordinator.push(.placeholder(
                                title: "Change email", milestone: "M12"
                            ))
                        }
                        SettingsNavRow(title: "Security") {
                            coordinator.push(.placeholder(
                                title: "Security", milestone: "M12"
                            ))
                        }
                        SettingsNavRow(
                            title: "Linked sign-in methods", isLast: true
                        ) {
                            coordinator.push(.placeholder(
                                title: "Sign-in methods", milestone: "M12"
                            ))
                        }
                    }
                    .padding(Theme.Spacing.card)
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CoAuthor plan & billing")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Text("Plan: Not available · Price: Not available")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                        Divider().overlay(Color.caHairline)
                        SettingsNavRow(
                            title: "Manage CoAuthor subscription",
                            isLast: true
                        ) {
                            coordinator.push(.placeholder(
                                title: "CoAuthor plan", milestone: "M12"
                            ))
                        }
                        Text("Separate from ElevenLabs credits and "
                             + "provider billing.")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(Theme.Spacing.card)
                }

                SettingsNavRow(
                    title: "Delete account",
                    destructive: true
                ) {
                    coordinator.push(.deleteAccount)
                }
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.cardGap)
        }
    }
}
