import SwiftUI
import SwiftData

/// Notifications — persisted preference toggles and delivery
/// channels. Security alerts are required and can't be disabled.
/// Reference: Designs/Full Content/Account/Notifications/
struct NotificationSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: NotificationSettingsViewModel?

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackBar { coordinator.pop() }
            Group {
                if let viewModel, let settings = viewModel.settings {
                    content(settings, viewModel)
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
                let vm = NotificationSettingsViewModel(
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
        _ settings: NotificationSettings,
        _ viewModel: NotificationSettingsViewModel
    ) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("Notifications")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.caInk)
                        .padding(.vertical, 4)

                    CardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            toggleRow(
                                "Generation finished",
                                "When your audio is ready",
                                isOn: binding(\.generationFinished, settings)
                            )
                            toggleRow(
                                "Generation failed",
                                "When a job needs your attention",
                                isOn: binding(\.generationFailed, settings)
                            )
                            toggleRow(
                                "Low provider credits",
                                "A reminder to check ElevenLabs usage",
                                isOn: binding(\.lowProviderCredits, settings)
                            )
                            toggleRow(
                                "Security alerts",
                                "Required · can't be turned off",
                                isOn: .constant(true),
                                disabled: true,
                                isLast: true
                            )
                        }
                        .padding(Theme.Spacing.card)
                    }

                    CardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Delivery channels")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.caInk)
                                .padding(.bottom, 10)
                            toggleRow(
                                "Email", "jordan@example.com",
                                isOn: binding(\.emailEnabled, settings)
                            )
                            toggleRow(
                                "Push notifications", "For this device",
                                isOn: binding(\.pushEnabled, settings),
                                isLast: true
                            )
                        }
                        .padding(Theme.Spacing.card)
                    }

                    if viewModel.showSavedNote {
                        Text("✓ Notification preferences saved.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caInk)
                            .padding(Theme.Spacing.card)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.caNoteSuccess)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Theme.Radius.card,
                                    style: .continuous
                                )
                            )
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Save preferences") {
                viewModel.save()
            }
        }
    }

    private func binding(
        _ keyPath: ReferenceWritableKeyPath<NotificationSettings, Bool>,
        _ settings: NotificationSettings
    ) -> Binding<Bool> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0 }
        )
    }

    private func toggleRow(
        _ title: String,
        _ detail: String,
        isOn: Binding<Bool>,
        disabled: Bool = false,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(Color.caInk)
                    .disabled(disabled)
                    .opacity(disabled ? 0.5 : 1)
            }
            .padding(.vertical, 10)
            if !isLast {
                Divider().overlay(Color.caHairline)
            }
        }
    }
}
