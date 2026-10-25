import SwiftUI
import SwiftData

/// App shell: per-tab navigation stacks over a custom bottom bar
/// matching the design (icons + labels, active tab in ink).
struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var dashboardViewModel: DashboardViewModel?

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch coordinator.selectedTab {
                case .projects:
                    NavigationStack(path: coordinator.path(for: .projects)) {
                        dashboardRoot
                            .navigationDestination(for: AppRoute.self, destination: destination)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .library:
                    tabStack(for: .library, title: "Library", milestone: "M10")
                case .activity:
                    tabStack(for: .activity, title: "Activity", milestone: "M8")
                case .settings:
                    tabStack(for: .settings, title: "Settings", milestone: "M11")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(item: sheetBinding, content: sheetContent)
        .task {
            if dashboardViewModel == nil {
                dashboardViewModel = DashboardViewModel(
                    repository: SwiftDataDashboardRepository(context: modelContext)
                )
            }
        }
    }

    @ViewBuilder
    private var dashboardRoot: some View {
        if let viewModel = dashboardViewModel {
            DashboardView(viewModel: viewModel)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.caBackground)
        }
    }

    private func tabStack(for tab: AppTab, title: String, milestone: String) -> some View {
        NavigationStack(path: coordinator.path(for: tab)) {
            DevelopmentPlaceholderView(title: title, milestone: milestone)
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .projectDetail:
            DevelopmentPlaceholderView(title: "Project overview", milestone: "M2")
        case .newProject:
            DevelopmentPlaceholderView(title: "New project", milestone: "M2")
        case .narration:
            DevelopmentPlaceholderView(title: "Narration studio", milestone: "M8")
        case .reviewItem:
            DevelopmentPlaceholderView(title: "Review item", milestone: "M8/M9")
        case .reviewQueue:
            DevelopmentPlaceholderView(title: "Review queue", milestone: "M8")
        }
    }

    // MARK: Bottom bar

    private var tabBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.caHairline)
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        coordinator.selectedTab = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.title)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(tab == coordinator.selectedTab ? Color.caInk : Color.caSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.caSurface)
    }

    // MARK: Sheet plumbing

    private var sheetBinding: Binding<AppRoute?> {
        Binding(
            get: { coordinator.sheet },
            set: { coordinator.sheet = $0 }
        )
    }

    private func sheetContent(_ route: AppRoute) -> some View {
        NavigationStack { destination(route) }
    }
}
