import SwiftUI
import SwiftData

/// Full chapter list — reached via "View all" on the outline workspace.
struct ChapterListView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let outlineID: UUID
    @State private var chapters: [OutlineChapter] = []
    @State private var loadError: String?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: "Chapters") {
                coordinator.pop()
            }
            Group {
                if let loadError {
                    ContentUnavailableView(
                        "Couldn't load chapters",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    List(chapters) { chapter in
                        Button {
                            coordinator.push(.chapterEdit(chapterID: chapter.id))
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(chapter.number)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.caSecondary)
                                    .frame(width: 20, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(chapter.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.caInk)
                                    Text(chapter.summary)
                                        .font(.caption)
                                        .foregroundStyle(Color.caSecondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .listRowBackground(Color.caSurface)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            do {
                chapters = try SwiftDataOutlineRepository(context: modelContext)
                    .fetchChapters(outlineID: outlineID)
            } catch {
                loadError = "Chapters couldn't be loaded."
            }
        }
    }
}
