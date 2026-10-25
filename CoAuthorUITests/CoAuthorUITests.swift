//
//  CoAuthorUITests.swift
//  CoAuthorUITests
//
//  Created by Randall Ridley on 10/25/26.
//

import XCTest

final class CoAuthorUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testDashboardRendersAndScrollsToReviewQueue() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Your stories"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["CONTINUE"].exists)
        XCTAssertTrue(app.buttons["New project"].exists)

        // Content below the fold must be reachable by scrolling.
        let reviewQueue = app.staticTexts["Review queue"]
        while !reviewQueue.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(reviewQueue.isHittable)

        // Fixed chrome must not scroll away or swallow content.
        XCTAssertTrue(app.staticTexts["CoAuthor"].isHittable)
        XCTAssertTrue(app.buttons["Projects"].isHittable)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
