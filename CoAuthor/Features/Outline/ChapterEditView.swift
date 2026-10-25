import SwiftUI
import SwiftData

/// Chapter editing — title, summary, turn, estimated narration length.
/// Edits persist via the model context on save.
struct ChapterEditView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let chapterID: UUID
    @State private var chapter: OutlineChapter?
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: chapter.map { "Chapter \($0.number)" } ?? "Edit chapter") {
                coordinator.pop()
            }
            Group {
                if let chapter {
                    ChapterEditForm(chapter: chapter)
                } else if let loadError {
                    ContentUnavailableView(
                        "Couldn't load chapter",
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
                chapter = try SwiftDataOutlineRepository(context: modelContext)
                    .fetchChapter(id: chapterID)
            } catch {
                loadError = "Chapter couldn't be loaded."
            }
        }
        .onDisappear {
            try? modelContext.save()
        }
    }
}

private struct ChapterEditForm: View {
    @Bindable var chapter: OutlineChapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                CAFormField(label: "Chapter title", text: $chapter.title)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary")
                        .font(.subheadline.weight(.medium))
                    TextEditor(text: $chapter.summary)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.caField)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.caHairline, lineWidth: 1)
                        )
                }
                CAFormField(label: "Turn", text: $chapter.turn)
                Stepper(
                    "Estimated length: \(chapter.estimatedMinutes) min",
                    value: $chapter.estimatedMinutes,
                    in: 1...60
                )
                .font(.subheadline.weight(.medium))
            }
            .padding(Theme.Spacing.page)
        }
        .background(Color.caBackground)
    }
}
