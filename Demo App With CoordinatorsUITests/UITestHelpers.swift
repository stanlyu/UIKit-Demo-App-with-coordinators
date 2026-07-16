import XCTest

// Общие UI-хелперы для UI-тестов Demo App.
//
// Раньше `launchApp`, `waitForMainTabs`, `tapTab`, `tapButton`,
// `tapBackButton` и `waitUntilHittable` дублировались в `private extension`
// каждого UI-тест-класса. Здесь они вынесены в одно место: любой
// `XCTestCase`-подкласс, соответствующий `DemoAppUITesting`, автоматически
// получает эти хелперы. Экземпляр `XCUIApplication` остаётся собственностью
// конкретного тест-класса (свойство `app`), хелперы работают с `self.app`.

/// Контракт UI-тестов Demo App: класс владеет экземпляром `XCUIApplication`.
///
/// `app` объявлен как `var` (не `private`), чтобы хелперы в расширении протокола
/// могли читать/перезаписывать его (например, `launchApp()` создаёт новый
/// экземпляр при каждом запуске).
@MainActor
protocol DemoAppUITesting: AnyObject {
    var app: XCUIApplication! { get set }
}

@MainActor
extension DemoAppUITesting where Self: XCTestCase {
    /// Запускает приложение с флагами, гарантирующими чистое состояние
    /// (игнорирование сохранённого state + сброс persisted state Demo App).
    func launchApp() {
        app = XCUIApplication()
        app.launchArguments = [
            "-ApplePersistenceIgnoreState",
            "YES"
        ]
        app.launchEnvironment["DEMO_APP_RESET_PERSISTED_STATE"] = "1"
        app.launch()
    }

    /// Ожидает появления обоих табов и стартового navigation bar «Главная».
    func waitForMainTabs() {
        XCTAssertTrue(app.tabBars.buttons["Главная"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Корзина"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 10))
    }

    /// Тапает по табу по заголовку.
    func tapTab(named title: String) {
        let tab = app.tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }

    /// Ожидает кнопку, дожидается её hittable-состояния и тапает.
    func tapButton(named title: String, timeout: TimeInterval) {
        let button = app.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "Button '\(title)' should exist")
        waitUntilHittable(button, timeout: timeout)
        button.tap()
    }

    /// Тапает системную back-кнопку (первый элемент `navigationBar.buttons`).
    func tapBackButton(onNavigationBar title: String) {
        let navigationBar = app.navigationBars[title]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Navigation bar '\(title)' should exist")

        let backButton = navigationBar.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Back button on '\(title)' should exist")
        waitUntilHittable(backButton, timeout: 5)
        backButton.tap()
    }

    /// Ждёт, пока элемент не станет существующим и hittable.
    func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed)
    }
}
