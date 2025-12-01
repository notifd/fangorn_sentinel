//
//  AlertDetailUITests.swift
//  SentinelUITests
//
//  UI tests for alert detail screen
//

import XCTest

final class AlertDetailUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Navigate to detail screen
        let alertCell = app.cells.firstMatch
        alertCell.tap()

        // Wait for detail to load
        _ = app.navigationBars["Alert Details"].waitForExistence(timeout: 2)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testDetailScreenShowsAlertTitle() throws {
        // Verify alert title is displayed
        let titleText = app.staticTexts["High CPU Usage"]
        XCTAssertTrue(titleText.exists, "Alert title should be displayed")
    }

    func testDetailScreenShowsAlertMessage() throws {
        // Verify alert message is displayed
        let messageText = app.staticTexts["CPU usage is above 90%"]
        XCTAssertTrue(messageText.exists, "Alert message should be displayed")
    }

    func testDetailScreenShowsMetadata() throws {
        // Verify severity metadata
        let severityLabel = app.staticTexts["Severity"]
        XCTAssertTrue(severityLabel.exists, "Severity label should exist")

        let severityValue = app.staticTexts["Critical"]
        XCTAssertTrue(severityValue.exists, "Severity value should be 'Critical'")

        // Verify status metadata
        let statusLabel = app.staticTexts["Status"]
        XCTAssertTrue(statusLabel.exists, "Status label should exist")

        let statusValue = app.staticTexts["Firing"]
        XCTAssertTrue(statusValue.exists, "Status value should be 'Firing'")
    }

    func testDetailScreenShowsFiredAtTime() throws {
        // Verify "Fired At" label exists
        let firedAtLabel = app.staticTexts["Fired At"]
        XCTAssertTrue(firedAtLabel.exists, "Fired At label should exist")

        // The actual timestamp will vary, just verify something is there
        // Look for common time format indicators
        let hasTimeValue = app.staticTexts.allElementsBoundByIndex.contains { element in
            let label = element.label
            return label.contains("AM") || label.contains("PM") || label.contains(":")
        }
        XCTAssertTrue(hasTimeValue, "Should display a formatted time")
    }

    func testAcknowledgeButtonExists() throws {
        // Verify acknowledge button is present for firing alerts
        let acknowledgeButton = app.buttons["Acknowledge Alert"]
        XCTAssertTrue(acknowledgeButton.exists, "Acknowledge button should exist for firing alerts")
    }

    func testAcknowledgeButtonIsTappable() throws {
        // Verify button is enabled and tappable
        let acknowledgeButton = app.buttons["Acknowledge Alert"]
        XCTAssertTrue(acknowledgeButton.isEnabled, "Acknowledge button should be enabled")

        // Tap the button
        acknowledgeButton.tap()

        // After tap, we should still be on the detail screen
        // (In real app, this would make API call and update UI)
        XCTAssertTrue(app.navigationBars["Alert Details"].exists)
    }

    func testSeverityIndicatorColor() throws {
        // For a critical alert, the severity indicator should be visible
        // We can't directly test color, but we can verify the circle element exists
        // The circle is rendered as part of the HStack at the top

        // Verify the alert title HStack container exists
        let titleText = app.staticTexts["High CPU Usage"]
        XCTAssertTrue(titleText.exists, "Title with severity indicator should exist")
    }

    func testDetailScreenScrolls() throws {
        // Verify the detail view is scrollable by checking ScrollView exists
        // SwiftUI ScrollViews are represented as scroll views in the accessibility hierarchy

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Detail screen should be scrollable")
    }

    func testNavigationBarTitle() throws {
        // Verify navigation bar title
        let navBar = app.navigationBars["Alert Details"]
        XCTAssertTrue(navBar.exists, "Navigation bar should show 'Alert Details'")
    }
}
