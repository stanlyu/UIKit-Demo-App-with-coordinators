import XCTest

@MainActor
final class DemoAppNavigationUITests: XCTestCase, DemoAppUITesting {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMainTabsAndSwitchesBetweenTabs() {
        // arrange
        launchApp()
        defer { app.terminate() }
        waitForMainTabs()

        // act
        tapTab(named: "Корзина")

        // assert
        XCTAssertTrue(app.navigationBars["Корзина"].waitForExistence(timeout: 5))

        // act
        tapTab(named: "Главная")

        // assert
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    func testHomePickupPointsStackSupportsAddScreenAndBackNavigation() {
        // arrange
        launchApp()
        defer { app.terminate() }
        waitForMainTabs()

        // act
        tapButton(named: "ПВЗ", timeout: 8)
        tapButton(named: "Добавить", timeout: 5)

        // assert
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Добавить ПВЗ"].waitForExistence(timeout: 5))

        // act
        tapBackButton(onNavigationBar: "Добавить ПВЗ")

        // assert
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        // act
        tapBackButton(onNavigationBar: "Выбор ПВЗ")

        // assert
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    func testCheckoutFlowSupportsPaymentBackModalDismissAndPaymentCompletion() {
        // arrange
        launchApp()
        defer { app.terminate() }
        waitForMainTabs()

        // act: открываем оформление заказа.
        tapButton(named: "Оформить заказ", timeout: 10)

        // assert: оформление открыто, ПВЗ ещё не выбран.
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["ПВЗ: не выбран"].waitForExistence(timeout: 5))

        // act: переход к оплате и возврат обратно.
        tapButton(named: "Продолжить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оплата"].waitForExistence(timeout: 5))
        tapBackButton(onNavigationBar: "Оплата")

        // assert: вернулись на оформление заказа.
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        // act: открываем выбор ПВЗ модально и закрываем его.
        tapButton(named: "Смена ПВЗ", timeout: 5)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))
        tapButton(named: "Закрыть", timeout: 5)

        // assert: модальный выбор ПВЗ закрылся, снова оформление заказа.
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        // act: оплачиваем и завершаем заказ.
        tapButton(named: "Продолжить", timeout: 5)
        tapButton(named: "Оплатить", timeout: 5)

        // assert: достигли экрана «Финиш».
        XCTAssertTrue(app.navigationBars["Финиш"].waitForExistence(timeout: 25))

        // act: возврат к началу.
        tapButton(named: "К началу", timeout: 5)

        // assert: оказались в корзине.
        XCTAssertTrue(app.navigationBars["Корзина"].waitForExistence(timeout: 5))
    }
}
