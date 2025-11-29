//
//  AlertListUITests.swift
//  SentinelUITests
//
//  UI tests for alert list and navigation
//

import XCTest

final class AlertListUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunches() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.exists)
    }

    func testNavigationTitleExists() throws {
        // Verify "Alerts" navigation title is present
        let navigationBar = app.navigationBars["Alerts"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar with 'Alerts' title should exist")
    }

    func testAlertListDisplaysMockAlert() throws {
        // Verify the mock "High CPU Usage" alert appears
        let alertCell = app.cells.containing(.staticText, identifier: "High CPU Usage").element

        // Wait for the alert to appear (in case of async loading)
        let exists = alertCell.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Mock alert 'High CPU Usage' should be displayed")
    }

    func testAlertCellShowsSeverityIndicator() throws {
        // Verify alert cell has all expected components
        let alertCell = app.cells.firstMatch
        XCTAssertTrue(alertCell.exists, "At least one alert cell should exist")

        // Check for alert title
        let titleText = alertCell.staticTexts["High CPU Usage"]
        XCTAssertTrue(titleText.exists, "Alert title should be visible")

        // Check for alert message
        let messageText = alertCell.staticTexts["CPU usage is above 90%"]
        XCTAssertTrue(messageText.exists, "Alert message should be visible")
    }

    func testAlertCellShowsFireIcon() throws {
        // Verify firing alerts show the warning icon
        let alertCell = app.cells.firstMatch
        let warningIcon = alertCell.images["exclamationmark.triangle.fill"]
        XCTAssertTrue(warningIcon.exists, "Firing alert should show warning icon")
    }

    func testTapAlertNavigatesToDetail() throws {
        // Tap the alert cell
        let alertCell = app.cells.firstMatch
        XCTAssertTrue(alertCell.exists, "Alert cell should exist")

        alertCell.tap()

        // Verify we navigated to detail screen
        let detailNavBar = app.navigationBars["Alert Details"]
        let exists = detailNavBar.waitForExistence(timeout: 2)
        XCTAssertTrue(exists, "Should navigate to alert detail screen")
    }

    func testBackNavigationFromDetail() throws {
        // Navigate to detail
        let alertCell = app.cells.firstMatch
        alertCell.tap()

        // Wait for detail to appear
        let detailNavBar = app.navigationBars["Alert Details"]
        _ = detailNavBar.waitForExistence(timeout: 2)

        // Tap back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()

        // Verify we're back at the list
        let listNavBar = app.navigationBars["Alerts"]
        XCTAssertTrue(listNavBar.exists, "Should navigate back to alert list")
    }

    func testPullToRefresh() throws {
        // Get the first cell
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.exists)

        // Pull down to refresh
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
        let end = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
        start.press(forDuration: 0.1, thenDragTo: end)

        // Verify list still exists after refresh
        XCTAssertTrue(app.navigationBars["Alerts"].exists)
    }
}
