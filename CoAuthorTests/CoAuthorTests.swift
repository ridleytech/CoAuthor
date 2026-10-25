//
//  CoAuthorTests.swift
//  CoAuthorTests
//
//  Created by Randall Ridley on 10/25/26.
//

import XCTest
import SwiftData
@testable import CoAuthor

@MainActor
final class DashboardRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var defaults: UserDefaults!
    private var repository: SwiftDataDashboardRepository!

    override func setUpWithError() throws {
        let schema = CoAuthorSchema.current
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
        defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        repository = SwiftDataDashboardRepository(
            context: container.mainContext,
            defaults: defaults
        )
    }

    override func tearDownWithError() throws {
        container = nil
        defaults = nil
        repository = nil
    }

    func testSeedWritesSampleDataOnce() throws {
        try repository.seedDevelopmentDataIfNeeded()
        XCTAssertEqual(try repository.fetchProjects().count, 3)
        XCTAssertEqual(try repository.fetchReviewItems().count, 6)

        // Second call must not duplicate records.
        try repository.seedDevelopmentDataIfNeeded()
        XCTAssertEqual(try repository.fetchProjects().count, 3)
        XCTAssertEqual(try repository.fetchReviewItems().count, 6)
    }

    func testFetchProjectsSortedByLastEditedDescending() throws {
        SampleData.insertSamples(into: container.mainContext)
        try container.mainContext.save()

        let projects = try repository.fetchProjects()
        XCTAssertEqual(projects.count, 3)
        XCTAssertEqual(projects.first?.title, "The Numbers Widow")
        XCTAssertTrue(projects[0].lastEditedAt >= projects[1].lastEditedAt)
        XCTAssertTrue(projects[1].lastEditedAt >= projects[2].lastEditedAt)
    }

    func testSeedDoesNotRecreateDeletedRecords() throws {
        try repository.seedDevelopmentDataIfNeeded()
        for project in try repository.fetchProjects() {
            try repository.delete(project)
        }
        XCTAssertTrue(try repository.fetchProjects().isEmpty)

        // Records the user deleted must stay deleted across "relaunches".
        try repository.seedDevelopmentDataIfNeeded()
        XCTAssertTrue(try repository.fetchProjects().isEmpty)
    }

    func testViewModelSlicesFeaturedRecentAndReviewPreview() throws {
        SampleData.insertSamples(into: container.mainContext)
        try container.mainContext.save()
        defaults.set(true, forKey: SwiftDataDashboardRepository.seededKey)

        let viewModel = DashboardViewModel(repository: repository)
        viewModel.load()

        XCTAssertEqual(viewModel.featured?.title, "The Numbers Widow")
        XCTAssertEqual(viewModel.recentProjects.count, 2)
        XCTAssertEqual(viewModel.remainingProjectCount, 2)
        XCTAssertEqual(viewModel.previewReviewItems.count, 2)
        XCTAssertEqual(viewModel.reviewItems.count, 6)
    }

    func testViewModelEmptyState() throws {
        // Pretend seeding already ran so load() skips it.
        defaults.set(true, forKey: SwiftDataDashboardRepository.seededKey)
        let viewModel = DashboardViewModel(repository: repository)
        viewModel.load()
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertNil(viewModel.featured)
    }
}
