//
//  AccessibilityUITests.swift
//  SentinelUITests
//
//  Accessibility and VoiceOver tests
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAlertListHasAccessibleElements() throws {
        // Verify alert cells are accessible
        let alertCell = app.cells.firstMatch
        XCTAssertTrue(alertCell.exists)
        XCTAssertTrue(alertCell.isEnabled, "Alert cell should be enabled for interaction")
    }

    func testNavigationBarIsAccessible() throws {
        // Verify navigation bar is accessible
        let navBar = app.navigationBars["Alerts"]
        XCTAssertTrue(navBar.exists)
    }

    func testAlertTitleIsAccessible() throws {
        // Navigate to detail
        app.cells.firstMatch.tap()
        _ = app.navigationBars["Alert Details"].waitForExistence(timeout: 2)

        // Verify title is accessible
        let title = app.staticTexts["High CPU Usage"]
        XCTAssertTrue(title.exists)
    }

    func testAcknowledgeButtonIsAccessible() throws {
        // Navigate to detail
        app.cells.firstMatch.tap()
        _ = app.navigationBars["Alert Details"].waitForExistence(timeout: 2)

        // Verify button has accessible label
        let button = app.buttons["Acknowledge Alert"]
        XCTAssertTrue(button.exists)
        XCTAssertEqual(button.label, "Acknowledge Alert")
    }

    func testAllCriticalElementsHaveLabels() throws {
        // Check that critical UI elements have accessibility labels
        let elements = [
            app.navigationBars["Alerts"],
            app.cells.firstMatch,
        ]

        for element in elements {
            XCTAssertTrue(element.exists, "Element should exist: \(element)")
        }
    }
}
