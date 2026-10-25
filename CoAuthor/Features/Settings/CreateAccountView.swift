import SwiftUI

/// Create account — name/email/password form with inline validation
/// matching the Auth — validation reference. No account is created:
/// authentication is M12 backend work.
/// Reference: Designs/Full Content/Auth/Create account — validation/
struct CreateAccountView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @State private var viewModel = CreateAccountViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackBar { coordinator.pop() }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create your account")
                            .font(.title.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text("A home for your stories and audiobook audio.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    fieldBlock(
                        label: "Name",
                        text: $viewModel.name,
                        placeholder: "Your name",
                        error: viewModel.nameError
                    )
                    fieldBlock(
                        label: "Email",
                        text: $viewModel.email,
                        placeholder: "you@example.com",
                        error: viewModel.emailError
                    )
                    passwordBlock
                    termsRow

                    Button("Create account") {
                        if viewModel.submit() {
                            coordinator.push(.placeholder(
                                title: "Account creation",
                                milestone: "M12"
                            ))
                        }
                    }
                    .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))

                    HStack {
                        Rectangle().fill(Color.caHairline).frame(height: 1)
                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                            .fixedSize()
                        Rectangle().fill(Color.caHairline).frame(height: 1)
                    }

                    HStack(spacing: 10) {
                        Button("Continue with Apple") {
                            coordinator.push(.placeholder(
                                title: "Apple sign-in", milestone: "M12"
                            ))
                        }
                        .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                        Button("Continue with Google") {
                            coordinator.push(.placeholder(
                                title: "Google sign-in", milestone: "M12"
                            ))
                        }
                        .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                    }

                    Button {
                        coordinator.push(.placeholder(
                            title: "Sign in", milestone: "M12"
                        ))
                    } label: {
                        HStack(spacing: 6) {
                            Text("Already have an account? Sign in")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(Color.caInk)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func fieldBlock(
        label: String,
        text: Binding<String>,
        placeholder: String,
        error: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.caInk)
            TextField(placeholder, text: text)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.caSurface)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            error != nil ? Color.caDestructive
                                : Color.caHairline,
                            lineWidth: 1
                        )
                )
            if let error {
                Text("! \(error)")
                    .font(.caption)
                    .foregroundStyle(Color.caDestructive)
            }
        }
    }

    private var passwordBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.caInk)
            HStack {
                if viewModel.showPassword {
                    TextField("Password", text: $viewModel.password)
                } else {
                    SecureField("Password", text: $viewModel.password)
                }
                Spacer()
                Button(viewModel.showPassword ? "Hide" : "Show") {
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        viewModel.passwordError != nil
                            ? Color.caDestructive : Color.caHairline,
                        lineWidth: 1
                    )
            )
            if let error = viewModel.passwordError {
                Text("! \(error)")
                    .font(.caption)
                    .foregroundStyle(Color.caDestructive)
            }
            Text("At least 12 characters, with uppercase and lowercase "
                 + "letters and a number.")
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
        }
    }

    private var termsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                viewModel.acceptedTerms.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.acceptedTerms
                          ? "checkmark.square.fill" : "square")
                        .font(.body)
                        .foregroundStyle(Color.caInk)
                    Text("I agree to the Terms of Service and Privacy "
                         + "Policy.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            if let error = viewModel.termsError {
                Text("! \(error)")
                    .font(.caption)
                    .foregroundStyle(Color.caDestructive)
            }
        }
    }
}
