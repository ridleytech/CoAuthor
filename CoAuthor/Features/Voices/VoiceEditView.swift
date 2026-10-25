import SwiftUI
import SwiftData

/// Edit local voice metadata — display name, labels, notes.
/// Local-only edits; provider voice fields are untouched.
struct VoiceEditView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let voiceID: UUID
    @State private var voice: Voice?
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: "Edit voice") {
                coordinator.pop()
            }
            Group {
                if let voice {
                    VoiceEditForm(voice: voice)
                } else if let loadError {
                    ContentUnavailableView(
                        "Couldn't load voice",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
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
            do {
                voice = try SwiftDataVoiceRepository(context: modelContext)
                    .fetchVoice(id: voiceID)
            } catch {
                loadError = "Voice couldn't be loaded."
            }
        }
        .onDisappear {
            try? modelContext.save()
        }
    }
}

private struct VoiceEditForm: View {
    @Bindable var voice: Voice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                CAFormField(label: "Local name", text: $voice.localName)
                CAFormField(label: "Labels (slash-separated)", text: $voice.localLabels)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $voice.localNotes)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.caField)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.caHairline, lineWidth: 1)
                        )
                }
            }
            .padding(Theme.Spacing.page)
        }
        .background(Color.caBackground)
    }
}
