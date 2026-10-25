import SwiftUI
import SwiftData

/// ElevenLabs provider connection — masked API key, custom-voice
/// capacity, sync, reconnect/disconnect actions.
/// Reference: Designs/Full Content/Account/ElevenLabs connected/
struct ProviderConnectionView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ProviderConnectionViewModel?

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
                let vm = ProviderConnectionViewModel(
                    voiceRepository: SwiftDataVoiceRepository(
                        context: modelContext
                    )
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: ProviderConnectionViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ElevenLabs")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text("Audio provider connection")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.vertical, 4)

                connectionCard(viewModel)
                voiceCapacityCard(viewModel)
                linksCard(viewModel)
                if let note = viewModel.statusNote {
                    Text(note)
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
                narratorCard
                Button("Reconnect ElevenLabs") {
                    coordinator.push(.placeholder(
                        title: "Reconnect provider", milestone: "M12"
                    ))
                }
                .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                disconnectCard
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.cardGap)
        }
    }

    private func connectionCard(
        _ viewModel: ProviderConnectionViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                StatusBadge("✓ Connected", kind: .ready)
                Text(viewModel.credits.accountName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                HStack {
                    Text("Saved API key")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("•••• \(viewModel.credits.apiKeyTail)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                Divider().overlay(Color.caHairline)
                Text("Last sync: \(viewModel.credits.lastRefresh)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button("Test connection") {
                    viewModel.testConnection()
                }
                .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func voiceCapacityCard(
        _ viewModel: ProviderConnectionViewModel
    ) -> some View {
        let slots = viewModel.capacitySlots
        return CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("ElevenLabs · Custom voices")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Button("Refresh") {
                        viewModel.load()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                    .buttonStyle(.plain)
                }
                Text("Custom voices: \(slots.used) of \(slots.total) "
                     + "slots used")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.caField)
                        Capsule()
                            .fill(Color.caInk)
                            .frame(width: geometry.size.width
                                   * Double(slots.used)
                                   / Double(max(slots.total, 1)))
                    }
                }
                .frame(height: 6)
                .accessibilityHidden(true)
                Text("\(Int(Double(slots.used) / Double(max(slots.total, 1)) * 100))% used"
                     + " · \(slots.total - slots.used) slots available")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Connected ElevenLabs account · "
                     + "\(viewModel.credits.accountName)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Illustrative account capacity · Includes voices "
                     + "created outside CoAuthor")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func linksCard(_ viewModel: ProviderConnectionViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                SettingsNavRow(
                    title: "Saved Voices",
                    detail: "\(viewModel.voiceCount) account voices"
                ) {
                    coordinator.push(.savedVoices(projectID: nil))
                }
                SettingsNavRow(title: "Voice-type limits",
                               detail: "View limits") {
                    coordinator.push(.placeholder(
                        title: "Voice-type limits", milestone: "M12"
                    ))
                }
                SettingsNavRow(title: "Manage ElevenLabs account",
                               detail: "Open") {
                    coordinator.push(.placeholder(
                        title: "ElevenLabs dashboard", milestone: "M12"
                    ))
                }
                SettingsNavRow(title: "Credits & Usage") {
                    coordinator.push(.creditsUsage)
                }
                SettingsNavRow(title: "Sync voices", isLast: true) {
                    viewModel.syncVoices()
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var narratorCard: some View {
        HStack {
            Text("Default narrator")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.caInk)
            Spacer()
            Text("Marlene")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .padding(.vertical, 4)
    }

    private var disconnectCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsNavRow(title: "Disconnect ElevenLabs",
                           destructive: true) {
                coordinator.push(.placeholder(
                    title: "Disconnect provider", milestone: "M12"
                ))
            }
            Text("Disconnecting prevents new provider requests. "
                 + "Previously saved project files remain accessible.")
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
        }
    }
}
