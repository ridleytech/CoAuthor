import Foundation
import SwiftUI

/// Bottom-bar tabs shown across the app's primary screens.
enum AppTab: Hashable, CaseIterable {
    case projects
    case library
    case activity
    case settings

    var title: String {
        switch self {
        case .projects: "Projects"
        case .library: "Library"
        case .activity: "Activity"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .projects: "square.grid.2x2"
        case .library: "book"
        case .activity: "waveform.path.ecg"
        case .settings: "gearshape"
        }
    }
}

/// Typed navigation routes. Cases carry stable identifiers rather than
/// model objects so paths stay serializable later.
enum AppRoute: Hashable, Identifiable {
    case projectDetail(UUID)
    case newProject
    case ideaGeneration(projectID: UUID)
    case narration(projectID: UUID)
    case reviewItem(UUID)
    case reviewQueue
    /// Stand-in destination for screens owned by later milestones.
    case placeholder(title: String, milestone: String)

    var id: Self { self }
}

/// Owns tab selection, per-tab navigation stacks, and sheet state.
@Observable
@MainActor
final class AppCoordinator {
    var selectedTab: AppTab = .projects
    var sheet: AppRoute?

    private(set) var paths: [AppTab: NavigationPath] = [:]

    func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }

    func push(_ route: AppRoute) {
        var path = paths[selectedTab] ?? NavigationPath()
        path.append(route)
        paths[selectedTab] = path
    }

    func pop() {
        guard var path = paths[selectedTab], !path.isEmpty else { return }
        path.removeLast()
        paths[selectedTab] = path
    }

    func presentSheet(_ route: AppRoute) {
        sheet = route
    }
}