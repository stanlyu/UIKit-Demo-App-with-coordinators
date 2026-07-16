import Testing
import UIKit
import ObjectiveC
@testable import Core

// MARK: - Tags

extension Tag {
    /// Доставка событий нескольким делегатам и порядок доставки.
    @Tag static var dispatch: Tag
    /// Жизненный цикл слабых ссылок на делегатов.
    @Tag static var weakLifecycle: Tag
    /// Чистая логика согласования делегата (без swizzling).
    @Tag static var reconcile: Tag
    /// Сквозные сценарии через перехваченный setter `delegate`.
    @Tag static var swizzling: Tag
}

// MARK: - Test doubles

/// Общий лог порядка вызовов (reference-тип), в который делегаты дописывают свою
/// метку при срабатывании `didShow`. Нужен для тестов ОТНОСИТЕЛЬНОГО порядка
/// доставки событий (внутренний наблюдатель раньше внешнего и т.п.).
@MainActor
private final class OrderLog {
    var entries: [String] = []
}

/// Записывает вызовы `UINavigationControllerDelegate` и опционально
/// возвращает тестовый animator/interaction/orientation.
@MainActor
private final class RecordingDelegate: NSObject, UINavigationControllerDelegate {
    enum Call {
        case willShow(viewController: UIViewController, animated: Bool)
        case didShow(viewController: UIViewController, animated: Bool)
        case animationController(operation: UINavigationController.Operation)
        case interactionController
        case supportedOrientations
        case preferredInterfaceOrientation
    }

    var calls: [Call] = []

    var stubbedAnimator: (any UIViewControllerAnimatedTransitioning)?
    var stubbedInteractionController: (any UIViewControllerInteractiveTransitioning)?
    var stubbedOrientations: UIInterfaceOrientationMask?
    var stubbedPreferredOrientation: UIInterfaceOrientation?

    /// Общий лог порядка для тестов относительного порядка didShow.
    /// Опциональный — в большинстве тестов не задаётся и не влияет на поведение.
    var didShowOrderLog: OrderLog?
    /// Метка, которую делегат дописывает в `didShowOrderLog` при срабатывании didShow.
    var didShowOrderLabel: String = ""

    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        calls.append(.willShow(viewController: viewController, animated: animated))
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        if let didShowOrderLog {
            didShowOrderLog.entries.append(didShowOrderLabel)
        }
        calls.append(.didShow(viewController: viewController, animated: animated))
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        calls.append(.animationController(operation: operation))
        return stubbedAnimator
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        calls.append(.interactionController)
        return stubbedInteractionController
    }

    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        calls.append(.supportedOrientations)
        return stubbedOrientations ?? .allButUpsideDown
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        calls.append(.preferredInterfaceOrientation)
        return stubbedPreferredOrientation ?? .portrait
    }
}

extension RecordingDelegate {
    /// `true`, если делегат получил хотя бы одно событие `didShow`.
    var didReceiveDidShow: Bool {
        calls.contains { if case .didShow = $0 { return true }; return false }
    }
}

/// Простой animator для проверки external-first приоритета.
@MainActor
private final class StubAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval { 0 }
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {}
}

// MARK: - Dispatcher: multiplexing and dispatch order

@MainActor
@Suite("NavigationControllerDelegateDispatcher")
struct NavigationControllerDelegateDispatcherTests {
    /// Внешние и внутренние делегаты одновременно получают события.
    @Test(.tags(.dispatch)) func multiplexingDeliversToAllDelegates() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let external = RecordingDelegate()
        let observer = RecordingDelegate()
        dispatcher.addDelegate(external, category: .external)
        dispatcher.addDelegate(observer, category: .internal)
        let nav = UINavigationController()
        let shown = UIViewController()

        // act
        dispatcher.navigationController(nav, didShow: shown, animated: false)
        dispatcher.navigationController(nav, willShow: shown, animated: true)

        // assert
        #expect(external.didReceiveDidShow)
        #expect(observer.didReceiveDidShow)
        #expect(external.calls.contains { if case .willShow = $0 { return true }; return false })
        #expect(observer.calls.contains { if case .willShow = $0 { return true }; return false })
    }

    /// didShow: внутренний наблюдатель получает событие РАНЬШЕ внешнего делегата.
    ///
    /// После системной кнопки «назад» и свайпа-back внешний делегат должен видеть
    /// уже обновлённое дерево flow-инстансов. Проверяется ОТНОСИТЕЛЬНЫЙ порядок
    /// (а не просто факт вызова): оба делегата дописывают себя в общий лог при
    /// didShow, и индекс наблюдателя должен быть строго меньше индекса внешнего.
    @Test(.tags(.dispatch)) func didShowIsInternalObserverFirst() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let external = RecordingDelegate()
        let observer = RecordingDelegate()
        let orderLog = OrderLog()
        external.didShowOrderLog = orderLog
        external.didShowOrderLabel = "external"
        observer.didShowOrderLog = orderLog
        observer.didShowOrderLabel = "observer"
        // Намеренно регистрируем внешний раньше — порядок регистрации не должен
        // влиять на «наблюдатель-первым».
        dispatcher.addDelegate(external, category: .external)
        dispatcher.addDelegate(observer, category: .internal)
        let nav = UINavigationController()

        // act
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(external.calls.count == 1)
        #expect(observer.calls.count == 1)
        guard let externalIndex = orderLog.entries.firstIndex(of: "external"),
              let observerIndex = orderLog.entries.firstIndex(of: "observer")
        else {
            Issue.record("Оба делегата должны отметиться в общем логе порядка didShow")
            return
        }
        // ОТНОСИТЕЛЬНЫЙ порядок: наблюдатель строго раньше внешнего.
        #expect(observerIndex < externalIndex)
    }

    /// willShow: сохраняется порядок регистрации (дерево на willShow не меняется,
    /// поэтому порядок доставки не важен — проверяем лишь факт доставки обоим).
    @Test(.tags(.dispatch)) func willShowKeepsRegistrationOrder() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let first = RecordingDelegate()
        let second = RecordingDelegate()
        dispatcher.addDelegate(first, category: .internal)
        dispatcher.addDelegate(second, category: .external)
        let nav = UINavigationController()

        // act
        dispatcher.navigationController(nav, willShow: UIViewController(), animated: false)

        // assert
        #expect(first.calls.count == 1)
        #expect(second.calls.count == 1)
    }

    /// animationController / orientation: внешний делегат имеет приоритет
    /// (анимации и ориентации принадлежат приложению).
    @Test(.tags(.dispatch)) func animationControllerIsExternalFirst() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let external = RecordingDelegate()
        external.stubbedAnimator = StubAnimator()
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)
        dispatcher.addDelegate(external, category: .external)
        let nav = UINavigationController()

        // act
        let animator = dispatcher.navigationController(
            nav,
            animationControllerFor: .push,
            from: UIViewController(),
            to: UIViewController()
        )

        // assert
        #expect(animator != nil)
        #expect(external.calls.count == 1)
        #expect(observer.calls.isEmpty)
    }

    // MARK: - Weak cleanup

    /// `removeReleasedDelegates()` убирает мёртвые слабые ссылки:
    /// освобождённый делегат больше не получает события.
    @Test(.tags(.weakLifecycle)) func removeReleasedDelegatesDropsDeadWeakReferences() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        weak var weakLeakingDelegate: RecordingDelegate?
        var leakingWasDelivered = false
        do {
            let leaking = RecordingDelegate()
            weakLeakingDelegate = leaking
            dispatcher.addDelegate(leaking, category: .external)
            let nav = UINavigationController()

            // act (часть 1): пока жив — получает событие.
            dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
            leakingWasDelivered = leaking.didReceiveDidShow
        }
        dispatcher.removeReleasedDelegates()

        // act (часть 2): после cleanup новый делегат должен получить событие.
        let survivor = RecordingDelegate()
        dispatcher.addDelegate(survivor, category: .external)
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(leakingWasDelivered)
        #expect(weakLeakingDelegate == nil)
        #expect(survivor.didReceiveDidShow)
    }

    /// Повторное событие после освобождения делегата без явного cleanup
    /// также не падает (мёртвые ссылки фильтруются на лету).
    @Test(.tags(.weakLifecycle)) func dispatchSurvivesReleasedDelegateWithoutExplicitCleanup() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let survivor = RecordingDelegate()
        do {
            let temporary = RecordingDelegate()
            dispatcher.addDelegate(temporary, category: .external)
        }
        dispatcher.addDelegate(survivor, category: .internal)
        let nav = UINavigationController()

        // act
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(survivor.didReceiveDidShow)
    }

    // MARK: - reconcile (чистая логика, без swizzling)

    /// `reconcile(externalDelegate: foreign)` регистрирует внешний делегат и
    /// возвращает dispatcher в слот.
    @Test(.tags(.reconcile)) func reconcileRegistersForeignDelegate() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let foreign = RecordingDelegate()
        let nav = UINavigationController()

        // act
        let resolved = dispatcher.reconcile(externalDelegate: foreign)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(resolved === dispatcher)
        #expect(foreign.didReceiveDidShow)
    }

    /// `reconcile(externalDelegate: nil)` снимает внешнего делегата, но не
    /// трогает внутреннего наблюдателя — дерево должно обновляться.
    @Test(.tags(.reconcile)) func reconcileNilRemovesExternalKeepsObserver() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)
        let foreign = RecordingDelegate()
        _ = dispatcher.reconcile(externalDelegate: foreign)
        let nav = UINavigationController()

        // act
        _ = dispatcher.reconcile(externalDelegate: nil)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(foreign.calls.isEmpty)
        #expect(observer.didReceiveDidShow)
    }

    /// Замена внешнего делегата: прежний снимается, новый регистрируется.
    /// Одновременно активен только один внешний делегат.
    @Test(.tags(.reconcile)) func reconcileReplacesExternalDelegate() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let first = RecordingDelegate()
        let second = RecordingDelegate()
        let nav = UINavigationController()

        // act
        _ = dispatcher.reconcile(externalDelegate: first)
        _ = dispatcher.reconcile(externalDelegate: second)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(first.calls.isEmpty)
        #expect(second.didReceiveDidShow)
    }

    /// `reconcile(externalDelegate: dispatcher)` — проброс без действий:
    /// ничего не ломается, возвращается сам dispatcher.
    @Test(.tags(.reconcile)) func reconcileDispatcherItselfIsNoOp() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)
        let nav = UINavigationController()

        // act
        let resolved = dispatcher.reconcile(externalDelegate: dispatcher)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(resolved === dispatcher)
        #expect(observer.didReceiveDidShow)
    }

    /// Идемпотентность `reconcile`: повторная установка того же делегата не
    /// создаёт дубль — событие доставляется ровно один раз.
    @Test(.tags(.reconcile)) func reconcileSameForeignTwiceIsIdempotent() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let foreign = RecordingDelegate()
        let nav = UINavigationController()

        // act
        _ = dispatcher.reconcile(externalDelegate: foreign)
        _ = dispatcher.reconcile(externalDelegate: foreign)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(foreign.calls.count == 1)
    }

    /// Внешний код назначает делегата, затем nil — внутренний наблюдатель
    /// выживает в обоих случаях.
    @Test(.tags(.reconcile)) func observerSurvivesExternalDelegateChanges() {
        // arrange
        let dispatcher = NavigationControllerDelegateDispatcher()
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)
        let foreign = RecordingDelegate()
        let nav = UINavigationController()

        // act
        _ = dispatcher.reconcile(externalDelegate: foreign)
        _ = dispatcher.reconcile(externalDelegate: nil)
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // assert
        #expect(observer.didReceiveDidShow)
    }

    // MARK: - End-to-end swizzling (через РЕАЛЬНЫЙ setter `delegate`)

    /// Перехват `nav.delegate = foreign` / `= nil` через реальный setter
    /// (swizzling подключается автоматически при первом `install`).
    @Test(.tags(.swizzling)) func setDelegateInterceptorKeepsDispatcherInSlotAndSurvivesReset() {
        // arrange
        let nav = UINavigationController()
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)

        // act (часть 1): внешний код назначает своего делегата через реальный setter.
        let foreign = RecordingDelegate()
        nav.delegate = foreign

        // assert (часть 1): слот читается как dispatcher (не foreign),
        // оба делегата получают события.
        #expect((nav.delegate as? NavigationControllerDelegateDispatcher) === dispatcher)
        nav.delegate?.navigationController?(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.didReceiveDidShow)
        #expect(observer.didReceiveDidShow)

        // act (часть 2): внешний код сбрасывает делегата в nil.
        nav.delegate = nil

        // assert (часть 2): слот НЕ nil — там снова dispatcher; наблюдатель
        // продолжает работать, foreign больше не получает события.
        #expect((nav.delegate as? NavigationControllerDelegateDispatcher) === dispatcher)
        #expect(nav.delegate != nil)
        nav.delegate?.navigationController?(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.calls.count == 1)
        #expect(observer.calls.count == 2)
    }
}

// MARK: - Swizzling co-existence

@MainActor
@Suite("Swizzling co-existence")
struct DispatcherSwizzlingCoexistenceTests {
    /// Сценарий: другая библиотека тоже свиззлит `setDelegate:` уже после нас.
    ///
    /// Принцип: если чужой swizzle сделан правильно — вызывает исходную
    /// реализацию селектора, — наша обёртка `fl_setDelegate` по-прежнему
    /// отрабатывает, а оригинальный setter UIKit всё равно вызывается. Проверяем,
    /// что при двойном swizzle: (а) dispatcher остаётся в слоте и `reconcile`
    /// выполняется; (б) оригинальный setter UIKit выполняется (значение слота
    /// реально меняется на dispatcher).
    ///
    /// IMP обязательно восстанавливается (обратный обмен), чтобы не загрязнять
    /// остальные тесты.
    @Test(.tags(.swizzling)) func foreignSwizzleOnSameSelectorDoesNotBreakDispatcher() {
        // arrange
        let nav = UINavigationController()
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)
        let observer = RecordingDelegate()
        dispatcher.addDelegate(observer, category: .internal)

        // act + assert с восстановлением IMP в любом случае.
        defer {
            // Возвращаем IMP в состояние «как было»: снова обмениваем те же методы.
            Self.swapSetDelegateWithTestWrapper()
        }
        // Дополнительный swizzle поверх нашего: имитируем чужую библиотеку,
        // которая правильно вызывает исходную реализацию.
        Self.swapSetDelegateWithTestWrapper()

        // act: внешний код назначает делегата — вызов идёт через
        // testWrapper -> fl_setDelegate -> UIKit setter.
        let foreign = RecordingDelegate()
        nav.delegate = foreign

        // assert: оригинальный setter UIKit вызвался (слот реально равен
        // dispatcher), а наша обёртка отработала (foreign зарегистрирован,
        // наблюдатель цел).
        #expect((nav.delegate as? NavigationControllerDelegateDispatcher) === dispatcher)
        nav.delegate?.navigationController?(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.didReceiveDidShow)
        #expect(observer.didReceiveDidShow)

        // act: сброс через nil тоже проходит через двойной swizzle.
        nav.delegate = nil

        // assert: слот снова dispatcher, foreign снят, наблюдатель продолжает работу.
        #expect((nav.delegate as? NavigationControllerDelegateDispatcher) === dispatcher)
        nav.delegate?.navigationController?(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.calls.count == 1)
        #expect(observer.calls.count == 2)
    }

    /// Обменивает IMP селектора `setDelegate:` и тестовой обёртки.
    ///
    /// Тестовая обёртка «чужой библиотеки» корректно вызывает предыдущую
    /// реализацию селектора (`setDelegate:`), поэтому цепочка swizzling-ов
    /// сохраняется.
    private static func swapSetDelegateWithTestWrapper() {
        let originalSelector = #selector(setter: UINavigationController.delegate)
        let testSelector = #selector(UINavigationController.dispatcherTests_foreignSetDelegate(_:))

        guard
            let originalMethod = class_getInstanceMethod(UINavigationController.self, originalSelector),
            let testMethod = class_getInstanceMethod(UINavigationController.self, testSelector)
        else {
            Issue.record("Не удалось найти методы для тестового swizzle")
            return
        }
        method_exchangeImplementations(originalMethod, testMethod)
    }
}

/// Тестовая обёртка «чужой библиотеки»: вызывает предыдущую реализацию
/// селектора `setDelegate:` (после нашего swizzle это наша `fl_setDelegate`).
///
/// После обмена IMP селектор `setDelegate:` указывает на эту обёртку, а селектор
/// `dispatcherTests_foreignSetDelegate:` — на предыдущую реализацию. Вызов
/// `self.dispatcherTests_foreignSetDelegate(value)` — переход к предыдущей
/// реализации в цепочке swizzling.
private extension UINavigationController {
    @objc func dispatcherTests_foreignSetDelegate(_ delegate: (any UINavigationControllerDelegate)?) {
        // Корректно делегируем предыдущей реализации цепочки swizzling-ов.
        self.dispatcherTests_foreignSetDelegate(delegate)
    }
}

// MARK: - Coordinating protocol

@MainActor
@Suite("Coordinating Protocol")
struct CoordinatingProtocolTests {
    /// `FlowNode.coordinator` типизирован через `any Coordinating`: принимает
    /// любой координатор, соответствующий протоколу.
    @Test func flowNodeStoresCoordinatingCoordinator() {
        // arrange
        let coordinator = CoordinatingStub()

        // act
        let node = FlowNode(coordinator: coordinator)

        // assert
        #expect(node.coordinator === coordinator)
    }

    /// Дефолтная реализация `receive(_:) -> false`: координатор без override
    /// не обрабатывает интенты.
    @Test func defaultReceiveReturnsFalse() {
        // arrange
        let coordinator = CoordinatingStub()
        let intent = StubIntent()

        // act
        let result = coordinator.receive(intent)

        // assert
        #expect(result == false)
    }

    /// Наследник `BaseCoordinator` автоматически соответствует `Coordinating`
    /// и наследует дефолтный `receive(_:) -> false`.
    @Test func baseCoordinatorConformsToCoordinating() {
        // arrange
        let composer = CoordinatorTestComposer()
        let coordinator = NoopStackCoordinator(router: DummyStackNavigation(), composer: composer)
        let intent = StubIntent()

        // act
        let result = coordinator.receive(intent)

        // assert
        #expect(result == false)
        let asCoordinating: any Coordinating = coordinator
        #expect(type(of: asCoordinating) == NoopStackCoordinator.self)
    }

    /// Override `receive(_:) -> true` в наследнике останавливает распространение.
    @Test func overridingReceiveReturnsTrue() {
        // arrange
        let composer = CoordinatorTestComposer()
        let coordinator = HandlingStackCoordinator(router: DummyStackNavigation(), composer: composer)
        let intent = StubIntent()

        // act
        let result = coordinator.receive(intent)

        // assert
        #expect(result == true)
    }

    /// `CoordinatorIntent` — маркерный протокол: конкретный тип переносится
    /// без потерь.
    @Test func coordinatorIntentIsMarkerProtocol() {
        // arrange
        let intent: any CoordinatorIntent = StubIntent()

        // act + assert
        #expect(type(of: intent) == StubIntent.self)
    }
}

// MARK: - Coordinating test doubles

/// Минимальный координатор-заглушка, соответствующий `Coordinating`.
@MainActor
private final class CoordinatingStub: Coordinating {}

/// Маркерный интент без полезной нагрузки.
@MainActor
private final class StubIntent: CoordinatorIntent {}

/// Конкретная навигация-заглушка для конструирования BaseCoordinator-наследников.
@MainActor
private final class DummyStackNavigation: StubStackNavigation {}

/// Минимальный composer для тестов BaseCoordinator-наследников.
@MainActor
private final class CoordinatorTestComposer: Composing {
    typealias Route = CoordinatingTestRoute
    func makeViewController(for route: CoordinatingTestRoute) -> UIViewController { UIViewController() }
}

private enum CoordinatingTestRoute { case anyRoute }

@MainActor
private protocol StubStackNavigation: AnyObject {}

/// Coordinator без override `receive(_:)` — должен наследовать дефолт false.
@MainActor
private final class NoopStackCoordinator: BaseCoordinator<any StubStackNavigation, CoordinatingTestRoute> {
    override func start(_ context: CoordinatorStartContext) {}
}

/// Coordinator с собственной реализацией `receive(_:) -> true`.
@MainActor
private final class HandlingStackCoordinator: BaseCoordinator<any StubStackNavigation, CoordinatingTestRoute> {
    override func start(_ context: CoordinatorStartContext) {}
    func receive(_ intent: any CoordinatorIntent) -> Bool { true }
}
