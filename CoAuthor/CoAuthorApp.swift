//
//  CoAuthorApp.swift
//  CoAuthor
//
//  Created by Randall Ridley on 10/25/26.
//

import SwiftUI
import SwiftData

@main
struct CoAuthorApp: App {
    let container: ModelContainer
    @State private var coordinator = AppCoordinator()

    init() {
        let schema = CoAuthorSchema.current
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
        .environment(coordinator)
    }
}
