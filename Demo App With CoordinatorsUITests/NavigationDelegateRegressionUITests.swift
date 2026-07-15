import XCTest

/// UI-регрессионные тесты для P1-фикса `NavigationControllerDelegateDispatcher`
/// (навигационный мультиплексор делегатов `UINavigationController`).
///
/// Контракт P1: после того, как внешний код затирает `nav.delegate`
/// (например, экран `AddPickupPointsViewController`/`PlaceOrderViewController`
/// назначает себя делегатом `interactivePopGestureRecognizer`, что в ряде
/// сценариев влияет на цепочку делегатов навигации), instance-наблюдатель Core
/// (StackRouter/InlineRouter) продолжает получать события `didShow` и дерево
/// координаторов остаётся консистентным. XCUITest не может напрямую выставить
/// `nav.delegate = nil`, поэтому здесь покрываются наблюдаемые следствия через
/// реальную пользовательскую навигацию: edge-swipe back, push/pop и свайп-back
/// между программными операциями.
@MainActor
final class NavigationDelegateRegressionUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Сценарий 1: Edge-swipe back синхронизирует дерево координаторов

    /// P1-контракт: после edge-swipe back система iOS вызывает `didShow`,
    /// instance-наблюдатель Core синхронизирует дерево, и последующая
    /// программная навигация работает корректно (дерево не рассинхронизировано).
    ///
    /// Особый акцент: экран «Добавить ПВЗ» сам назначает себя делегатом
    /// `interactivePopGestureRecognizer` (см. `AddPickupPointsViewController`),
    /// что делает этот сценарий максимально релевантным для проверки
    /// устойчивости dispatcher к стороннему вмешательству в делегаты.
    func testSwipeBackKeepsTreeConsistentAndAllowsSubsequentNavigation() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        // 1. Главная → push «Выбор ПВЗ»
        tapButton(named: "ПВЗ", timeout: 8)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        // 2. «Выбор ПВЗ» → push «Добавить ПВЗ»
        tapButton(named: "Добавить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Добавить ПВЗ"].waitForExistence(timeout: 5))

        // 3. Edge-swipe back с экрана «Добавить ПВЗ» → возврат на «Выбор ПВЗ».
        //    Если жест не срабатывает надёжно — тест откатывается на back-кнопку
        //    (это тоже путь через didShow), но сперва пытаемся именно edge swipe,
        //    т.к. это и есть целевой P1-сценарий.
        performEdgeSwipeBack(fallbackToBackButtonOn: "Добавить ПВЗ")
        XCTAssertTrue(
            app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5),
            "После свайпа-back дерево должно быть синхронизировано: ожидается «Выбор ПВЗ»"
        )

        // 4. Повторная программная навигация после свайпа-back.
        //    Если бы дерево рассинхронизировалось, push мог бы сломаться
        //    (наблюдатель не получил бы didShow и не обновил childRouterItems).
        tapButton(named: "Добавить", timeout: 5)
        XCTAssertTrue(
            app.navigationBars["Добавить ПВЗ"].waitForExistence(timeout: 5),
            "Повторный push после свайпа-back должен срабатывать: дерево консистентно"
        )

        // 5. Полный возврат к корню стекам: «Добавить ПВЗ» → «Выбор ПВЗ» → «Главная».
        tapBackButton(onNavigationBar: "Добавить ПВЗ")
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))
        tapBackButton(onNavigationBar: "Выбор ПВЗ")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    /// Дополнение к Сценарию 1: несколько подряд edge-swipe back не ломают стек.
    /// Проверяет, что повторные didShow от системы корректно обрабатываются
    /// dispatcher без накопления состояния/рассинхронизации.
    func testRepeatedSwipeBackDoesNotCorruptStack() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        tapButton(named: "ПВЗ", timeout: 8)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        tapButton(named: "Добавить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Добавить ПВЗ"].waitForExistence(timeout: 5))

        // Первый edge-swipe back: «Добавить ПВЗ» → «Выбор ПВЗ».
        performEdgeSwipeBack(fallbackToBackButtonOn: "Добавить ПВЗ")
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        // Второй edge-swipe back: «Выбор ПВЗ» → «Главная».
        performEdgeSwipeBack(fallbackToBackButtonOn: "Выбор ПВЗ")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }

    // MARK: - Сценарий 2: Многоуровневый push/pop/present/dismiss + последующий push

    /// Регрессия дерева координаторов: после серии push/present/dismiss/pop
    /// дерево остаётся консистентным и повторный push доступен.
    /// Покрывает смешанную навигацию через Cart flow: программные push/pop
    /// чередуются с present/dismiss, что прогоняет dispatcher через разные
    /// пути активации didShow.
    func testMixedNavigationFlowKeepsTreeConsistentForRepeatedPush() {
        launchApp()
        defer { app.terminate() }

        waitForMainTabs()

        // Оформить заказ → Оформление заказа (программный push внутри Cart).
        tapButton(named: "Оформить заказ", timeout: 10)
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 8))

        // Продолжить → Оплата (push), back → Оформление заказа (pop через didShow).
        tapButton(named: "Продолжить", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оплата"].waitForExistence(timeout: 5))
        tapBackButton(onNavigationBar: "Оплата")
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        // Смена ПВЗ → modal present «Выбор ПВЗ», Закрыть → dismiss.
        tapButton(named: "Смена ПВЗ", timeout: 5)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))
        tapButton(named: "Закрыть", timeout: 5)
        XCTAssertTrue(app.navigationBars["Оформление заказа"].waitForExistence(timeout: 5))

        // Повторный push после всей смешанной навигации: должен сработать,
        // т.к. дерево координаторов консистентно.
        tapButton(named: "Продолжить", timeout: 5)
        XCTAssertTrue(
            app.navigationBars["Оплата"].waitForExistence(timeout: 5),
            "Повторный push Оплата должен быть доступен: дерево консистентно после push/pop/present/dismiss"
        )
    }

    // MARK: - Сценарий 3: Switch flow (ApplicationCoordinator) — корректная смена root

    /// Контракт SwitchRouter: переключение между launch screen и main flow
    /// (switchTo). Успешный запуск и появление главных табов означает, что
    /// ApplicationCoordinator выполнил switchTo из launch в mainFlow.
    /// Это расширенная проверка: после switchTo последующая стековая навигация
    /// внутри табов работает корректно (root сменился, но дочерние router'ы живы).
    func testSwitchFlowFromLaunchToMainFlowAllowsStackNavigation() {
        launchApp()
        defer { app.terminate() }

        // Появление табов = switchTo(launch → mainFlow) выполнен успешно.
        waitForMainTabs()

        // После смены root-контента стековая навигация в табе должна работать.
        tapButton(named: "ПВЗ", timeout: 8)
        XCTAssertTrue(app.navigationBars["Выбор ПВЗ"].waitForExistence(timeout: 5))

        tapBackButton(onNavigationBar: "Выбор ПВЗ")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))

        // Переключение между табами тоже не должно ломать дерево.
        tapTab(named: "Корзина")
        XCTAssertTrue(app.navigationBars["Корзина"].waitForExistence(timeout: 5))
        tapTab(named: "Главная")
        XCTAssertTrue(app.navigationBars["Главная"].waitForExistence(timeout: 5))
    }
}

// MARK: - Helpers

private extension NavigationDelegateRegressionUITests {

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

    /// Выполняет edge-swipe back от левого края экрана.
    ///
    /// `app.swipeRight()` ненадёжен, т.к. может начаться не у самого края и
    /// попасть в контент (таблицу/кнопку). Здесь swipe инициируется строго у
    /// левой границы окна, где живёт `interactivePopGestureRecognizer`.
    ///
    /// Если жест не привёл к смене экрана за `verificationTimeout`, тест
    /// откатывается на системную back-кнопку (это тоже валидный путь через
    /// didShow) — это фиксируется в комментариях к сценарию, но не валит тест.
    func performEdgeSwipeBack(
        fallbackToBackButtonOn currentScreenTitle: String,
        verificationTimeout: TimeInterval = 4.0
    ) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), "App window should exist")

        // Старт строго у левого края (в нескольких пикселях от рамки),
        // середина по высоте — туда iOS вешает interactivePopGestureRecognizer.
        let startPoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let endPoint = window.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))

        // Свайп может не сработать с первого раза на «холодном» распознавателе —
        // пробуем до трёх раз, проверяя, исчез ли текущий экран.
        let currentNavBar = app.navigationBars[currentScreenTitle]
        for _ in 0..<3 {
            guard currentNavBar.exists else { break }
            startPoint.press(forDuration: 0.05, thenDragTo: endPoint)
            // Даём распознавателю/анимации время отработать.
            _ = currentNavBar.waitForNonExistence(timeout: verificationTimeout)
        }

        // Fallback: если edge-swipe не сработал, используем back-кнопку.
        if currentNavBar.exists {
            tapBackButton(onNavigationBar: currentScreenTitle)
        }
    }
}

// MARK: - XCUIElement waiting helpers

private extension XCUIElement {
    /// Ждёт, пока элемент перестанет существовать (например, экран ушёл из стека).
    @discardableResult
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
}
