import SwiftUI

/// Delete account — reauthentication step. Explains what deletion
/// removes, asks for the current password, gates Continue.
/// Deletion itself requires the M12 backend.
/// Reference: Designs/Full Content/Account/Delete account
/// reauthentication/
struct DeleteAccountView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @State private var viewModel = DeleteAccountViewModel()
    @FocusState private var passwordFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackBar { coordinator.pop() }
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                        Text("Before you delete")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.caInk)
                            .padding(.vertical, 4)

                        Text("! Export anything you want to keep before "
                             + "continuing.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caInk)
                            .padding(Theme.Spacing.card)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.caBadgeWarm)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: Theme.Radius.card,
                                    style: .continuous
                                )
                            )

                        Text("Deleting your CoAuthor account removes your "
                             + "projects and saved assets, and you lose "
                             + "access to them.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caInk)
                        Text("Exported or downloaded copies and your "
                             + "ElevenLabs account remain untouched. Some "
                             + "billing and security records may be "
                             + "retained if legally required.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)

                        Button {
                            coordinator.push(.placeholder(
                                title: "Export projects", milestone: "M12"
                            ))
                        } label: {
                            HStack(spacing: 6) {
                                Text("Export projects first")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "arrow.right")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.caInk)
                        }
                        .buttonStyle(.plain)

                        Button {
                            coordinator.push(.placeholder(
                                title: "Privacy Policy", milestone: "M12"
                            ))
                        } label: {
                            HStack(spacing: 6) {
                                Text("Privacy Policy")
                                    .font(.subheadline.weight(.semibold))
                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.caInk)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current CoAuthor password")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.caInk)
                            HStack {
                                if viewModel.showPassword {
                                    TextField("Password",
                                              text: $viewModel.password)
                                        .focused($passwordFocused)
                                } else {
                                    SecureField("Password",
                                                text: $viewModel.password)
                                        .focused($passwordFocused)
                                }
                                Spacer()
                                Button(viewModel.showPassword
                                       ? "Hide" : "Show") {
                                    viewModel.showPassword.toggle()
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.caSecondary)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(Color.caSurface)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                            )
                            .overlay(
                                RoundedRectangle(
                                    cornerRadius: 10,
                                    style: .continuous
                                )
                                .strokeBorder(
                                    passwordFocused
                                        ? Color.caInk : Color.caHairline,
                                    lineWidth: 1
                                )
                            )
                            Text("Confirm it's you. You'll review one final "
                                 + "confirmation before deletion.")
                                .font(.caption)
                                .foregroundStyle(Color.caSecondary)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.page)
                    .padding(.vertical, Theme.Spacing.cardGap)
                }
                BottomCTA(
                    title: "Continue",
                    enabled: viewModel.canContinue
                ) {
                    coordinator.push(.placeholder(
                        title: "Final deletion confirmation",
                        milestone: "M12"
                    ))
                }
                Button("Cancel") {
                    coordinator.pop()
                }
                .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.bottom, 10)
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}
