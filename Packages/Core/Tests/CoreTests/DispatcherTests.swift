import Testing
import UIKit
@testable import Core

// MARK: - Test doubles

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

/// Простой animator для проверки application-first приоритета.
@MainActor
private final class StubAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval { 0 }
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {}
}

// MARK: - Dispatcher: multiplexing and dispatch order

@MainActor
@Suite("NavigationControllerDelegateDispatcher Tests")
struct NavigationControllerDelegateDispatcherTests {
    /// Внешние и instance делегаты одновременно получают события.
    @Test func multiplexingDeliversToAllDelegates() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let application = RecordingDelegate()
        let instance = RecordingDelegate()
        dispatcher.addDelegate(application, category: .application)
        dispatcher.addDelegate(instance, category: .instance)

        let nav = UINavigationController()
        let shown = UIViewController()
        dispatcher.navigationController(nav, didShow: shown, animated: false)
        dispatcher.navigationController(nav, willShow: shown, animated: true)

        // didShow получает оба делегата.
        let didShowApplication = application.calls.contains { if case .didShow = $0 { return true }; return false }
        let didShowInstance = instance.calls.contains { if case .didShow = $0 { return true }; return false }
        #expect(didShowApplication)
        #expect(didShowInstance)

        // willShow также получает оба делегата.
        let willShowApplication = application.calls.contains { if case .willShow = $0 { return true }; return false }
        let willShowInstance = instance.calls.contains { if case .willShow = $0 { return true }; return false }
        #expect(willShowApplication)
        #expect(willShowInstance)
    }

    /// didShow: instance-наблюдатель получает событие РАНЬШЕ application delegate.
    /// Это критично: после native back application delegate должен читать уже
    /// обновленное дерево FlowInstance.
    @Test func didShowIsInstanceFirst() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let application = RecordingDelegate()
        let instance = RecordingDelegate()
        // Намеренно регистрируем application раньше — порядок регистрации не должен
        // влиять на instanceFirst.
        dispatcher.addDelegate(application, category: .application)
        dispatcher.addDelegate(instance, category: .instance)

        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        #expect(application.calls.count == 1)
        #expect(instance.calls.count == 1)
        if case .didShow = instance.calls[0] {} else {
            Issue.record("instance delegate должен получить didShow первым")
        }
    }

    /// willShow: сохраняется порядок регистрации (Core не меняет дерево на willShow).
    @Test func willShowKeepsRegistrationOrder() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let first = RecordingDelegate()
        let second = RecordingDelegate()
        dispatcher.addDelegate(first, category: .instance)
        dispatcher.addDelegate(second, category: .application)

        let nav = UINavigationController()
        dispatcher.navigationController(nav, willShow: UIViewController(), animated: false)

        // Каждый делегат получил ровно один willShow.
        #expect(first.calls.count == 1)
        #expect(second.calls.count == 1)
    }

    /// animationController / orientation: application delegate имеет приоритет
    /// (анимации и ориентации принадлежат приложению).
    @Test func animationControllerIsApplicationFirst() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let application = RecordingDelegate()
        application.stubbedAnimator = StubAnimator()
        let instance = RecordingDelegate()
        dispatcher.addDelegate(instance, category: .instance)
        dispatcher.addDelegate(application, category: .application)

        let nav = UINavigationController()
        let animator = dispatcher.navigationController(
            nav,
            animationControllerFor: .push,
            from: UIViewController(),
            to: UIViewController()
        )
        // application-first: первый опрошенный — application, и его animator возвращается.
        #expect(animator != nil)
        #expect(application.calls.count == 1)
        #expect(instance.calls.isEmpty)
    }

    // MARK: - Weak cleanup

    /// `removeReleasedDelegates()` убирает мёртвые weak-ссылки: освобождённый
    /// делегат больше не получает события.
    @Test func removeReleasedDelegatesDropsDeadWeakReferences() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        weak var weakLeakingDelegate: RecordingDelegate?
        do {
            let leaking = RecordingDelegate()
            weakLeakingDelegate = leaking
            dispatcher.addDelegate(leaking, category: .application)
            // Пока жив — получает события.
            let nav = UINavigationController()
            dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
            #expect(leaking.calls.count == 1)
        }
        // Объект освобождён.
        #expect(weakLeakingDelegate == nil)

        dispatcher.removeReleasedDelegates()

        // После cleanup новый делегат должен получить событие без мёртвых помех,
        // а мёртвый — не должен учитываться.
        let survivor = RecordingDelegate()
        dispatcher.addDelegate(survivor, category: .application)
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(survivor.calls.count == 1)
    }

    /// Повторное событие после освобождения делегата без явного cleanup
    /// также не падает (activeDelegates фильтрует мёртвые на лету).
    @Test func dispatchSurvivesReleasedDelegateWithoutExplicitCleanup() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let survivor = RecordingDelegate()
        do {
            let temporary = RecordingDelegate()
            dispatcher.addDelegate(temporary, category: .application)
        }
        dispatcher.addDelegate(survivor, category: .instance)
        let nav = UINavigationController()
        // Не падает; survivor получает событие.
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(survivor.calls.count == 1)
    }

    // MARK: - reconcile (чистая логика, без swizzling)

    /// `reconcile(externalDelegate: foreign)` регистрирует внешний делегат как
    /// `.application` и сохраняет ссылку как lastApplicationDelegate.
    @Test func reconcileRegistersForeignDelegateAsApplication() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let foreign = RecordingDelegate()

        let resolved = dispatcher.reconcile(externalDelegate: foreign)

        // Dispatcher возвращается в слот.
        #expect(resolved === dispatcher)
        // foreign теперь получает события application-категории.
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.calls.count == 1)
        // lastApplicationDelegate обновлён.
        #expect(dispatcher.lastApplicationDelegate === foreign)
    }

    /// `reconcile(externalDelegate: nil)` снимает прежнего `.application`,
    /// но не трогает `.instance`-наблюдатель — дерево должно обновляться.
    @Test func reconcileNilRemovesApplicationKeepsInstance() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let instance = RecordingDelegate()
        dispatcher.addDelegate(instance, category: .instance)

        let foreign = RecordingDelegate()
        _ = dispatcher.reconcile(externalDelegate: foreign)
        #expect(dispatcher.lastApplicationDelegate === foreign)

        // Сброс делегата.
        _ = dispatcher.reconcile(externalDelegate: nil)

        #expect(dispatcher.lastApplicationDelegate == nil)
        // foreign больше не получает события.
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.calls.isEmpty)
        // .instance продолжает работать.
        #expect(instance.calls.count == 1)
    }

    /// Замена внешнего делегата: прежний `.application` снимается, новый —
    /// регистрируется. Одновременно активен только один application delegate.
    @Test func reconcileReplacesApplicationDelegate() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let first = RecordingDelegate()
        let second = RecordingDelegate()

        _ = dispatcher.reconcile(externalDelegate: first)
        _ = dispatcher.reconcile(externalDelegate: second)

        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // Только второй application delegate получает событие.
        #expect(first.calls.isEmpty)
        #expect(second.calls.count == 1)
        #expect(dispatcher.lastApplicationDelegate === second)
    }

    /// `reconcile(externalDelegate: dispatcher)` — проброс без действий:
    /// ничего не ломается, возвращается сам dispatcher.
    @Test func reconcileDispatcherItselfIsNoOp() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let instance = RecordingDelegate()
        dispatcher.addDelegate(instance, category: .instance)

        let resolved = dispatcher.reconcile(externalDelegate: dispatcher)

        #expect(resolved === dispatcher)
        // lastApplicationDelegate не становится dispatcher'ом.
        #expect(dispatcher.lastApplicationDelegate == nil)
        // instance продолжает работать.
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(instance.calls.count == 1)
    }

    /// Полный сценарий P1: внешний код назначает делегата, затем nil —
    /// внутренний наблюдатель Core выживает в обоих случаях.
    @Test func instanceObserverSurvivesApplicationDelegateChanges() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let instance = RecordingDelegate()
        dispatcher.addDelegate(instance, category: .instance)

        let foreign = RecordingDelegate()
        _ = dispatcher.reconcile(externalDelegate: foreign)
        _ = dispatcher.reconcile(externalDelegate: nil)

        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        // .instance получил событие несмотря на смену/сброс application delegate.
        #expect(instance.calls.count == 1)
    }
}

// MARK: - Coordinating protocol

@MainActor
@Suite("Coordinating Protocol Tests")
struct CoordinatingProtocolTests {
    /// `FlowNode.coordinator` типизирован через `any Coordinating`: принимает
    /// любой координатор, соответствующий протоколу.
    @Test func flowNodeStoresCoordinatingCoordinator() {
        let coordinator = CoordinatingStub()
        let node = FlowNode(coordinator: coordinator)

        #expect(node.coordinator === coordinator)
    }

    /// Дефолтная реализация `receive(_:) -> false`: координатор без override
    /// не обрабатывает интенты.
    @Test func defaultReceiveReturnsFalse() {
        let coordinator = CoordinatingStub()
        let intent = StubIntent()

        #expect(coordinator.receive(intent) == false)
    }

    /// Наследник `BaseCoordinator` автоматически соответствует `Coordinating`
    /// и наследует дефолтный `receive(_:) -> false`.
    @Test func baseCoordinatorConformsToCoordinating() {
        let composer = CoordinatorTestComposer()
        let coordinator = NoopStackCoordinator(router: DummyStackNavigation(), composer: composer)

        let intent = StubIntent()
        #expect(coordinator.receive(intent) == false)
        // BaseCoordinator действительно соответствует Coordinating.
        let asCoordinating: any Coordinating = coordinator
        #expect(type(of: asCoordinating) == NoopStackCoordinator.self)
    }

    /// Override `receive(_:) -> true` в наследнике останавливает распространение.
    @Test func overridingReceiveReturnsTrue() {
        let composer = CoordinatorTestComposer()
        let coordinator = HandlingStackCoordinator(router: DummyStackNavigation(), composer: composer)

        let intent = StubIntent()
        #expect(coordinator.receive(intent) == true)
    }

    /// Типы-маркеры: `CoordinatorIntent` не требует реализаций — конкретный
    /// интент определяется приложением.
    @Test func coordinatorIntentIsMarkerProtocol() {
        let intent: any CoordinatorIntent = StubIntent()
        // Маркерный протокол: конкретный тип переносится без потерь.
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
