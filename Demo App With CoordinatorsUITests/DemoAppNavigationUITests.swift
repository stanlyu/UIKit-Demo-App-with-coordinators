import XCTest

@MainActor
final class DemoAppNavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMainTabsAndSwitchesBetweenTabs() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        tapTab(named: "Корзина")
        XCTAssertTrue(app.navigationBars["Корзина"].waitForExistence(timeout: 5))

        tapTab(named: "Главная")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    func testHomePickupPointsStackSupportsAddScreenAndBackNavigation() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        tapButton(named: "ПВЗ", timeout: 8)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        tapButton(named: "Добавить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Добавить ПВЗ"].waitForExistence(timeout: 5))

        tapBackButton(onNavigationBar: "Добавить ПВЗ")
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        tapBackButton(onNavigationBar: "Выбор ПВЗ")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    func testCheckoutFlowSupportsPaymentBackModalDismissAndPaymentCompletion() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        tapButton(named: "Оформить заказ", timeout: 10)
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["ПВЗ: не выбран"].waitForExistence(timeout: 5))

        tapButton(named: "Продолжить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оплата"].waitForExistence(timeout: 5))

        tapBackButton(onNavigationBar: "Оплата")
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        tapButton(named: "Смена ПВЗ", timeout: 5)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))
        tapButton(named: "Закрыть", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        tapButton(named: "Продолжить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оплата"].waitForExistence(timeout: 5))
        tapButton(named: "Оплатить", timeout: 5)

        XCTAssertTrue(app.navigationBars["Финиш"].waitForExistence(timeout: 25))
        tapButton(named: "К началу", timeout: 5)
        XCTAssertTrue(app.navigationBars["Корзина"].waitForExistence(timeout: 5))
    }
}

private extension DemoAppNavigationUITests {
    func launchApp() {
        app = XCUIApplication()
        app.launchArguments = [
            "-ApplePersistenceIgnoreState",
            "YES"
        ]
        app.launchEnvironment["DEMO_APP_RESET_PERSISTED_STATE"] = "1"
        app.launch()
    }

    func waitForMainTabs() {
        XCTAssertTrue(app.tabBars.buttons["Главная"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Корзина"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 10))
    }

    func tapTab(named title: String) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    func tapButton(named title: String, timeout: TimeInterval) {
        let button = app.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "Button '\(title)' should exist")
        waitUntilHittable(button, timeout: timeout)
        button.tap()
    }

    func tapBackButton(onNavigationBar title: String) {
        let navigationBar = app.navigationBars[title]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Navigation bar '\(title)' should exist")

        let backButton = navigationBar.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button on '\(title)' should exist")
        waitUntilHittable(backButton, timeout: 5)
        backButton.tap()
    }

    func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed)
    }
}
