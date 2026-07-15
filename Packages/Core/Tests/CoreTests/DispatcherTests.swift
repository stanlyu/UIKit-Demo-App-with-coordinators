import Testing
import UIKit
@testable import Core

// MARK: - Test doubles

/// Общий лог порядка вызовов (reference-тип), в который делегаты аппендят свою
/// метку при срабатывании `didShow`. Нужен для тестов ОТНОСИТЕЛЬНОГО порядка
/// доставки событий (instance раньше application и т.п.).
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
    /// Метка, которую делегат аппендит в `didShowOrderLog` при срабатывании didShow.
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
    ///
    /// Проверяется ОТНОСИТЕЛЬНЫЙ порядок (а не просто факт вызова): оба делегата
    /// аппендят себя в общий лог при didShow, и мы требуем, чтобы индекс instance
    /// был строго меньше индекса application. Это ловит регрессию, если кто-то
    /// случайно поменяет `DelegateDispatchOrder.instanceFirst` на `.registration`.
    @Test func didShowIsInstanceFirst() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let application = RecordingDelegate()
        let instance = RecordingDelegate()
        let orderLog = OrderLog()
        application.didShowOrderLog = orderLog
        application.didShowOrderLabel = "application"
        instance.didShowOrderLog = orderLog
        instance.didShowOrderLabel = "instance"
        // Намеренно регистрируем application раньше — порядок регистрации не должен
        // влиять на instanceFirst.
        dispatcher.addDelegate(application, category: .application)
        dispatcher.addDelegate(instance, category: .instance)

        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)

        // Каждый делегат получил ровно один didShow.
        #expect(application.calls.count == 1)
        #expect(instance.calls.count == 1)
        // Оба делегата отметились в общем логе.
        let applicationIndex = orderLog.entries.firstIndex(of: "application")
        let instanceIndex = orderLog.entries.firstIndex(of: "instance")
        #expect(applicationIndex != nil)
        #expect(instanceIndex != nil)
        // ОТНОСИТЕЛЬНЫЙ порядок: instance строго раньше application.
        if let applicationIndex, let instanceIndex {
            #expect(instanceIndex < applicationIndex)
        } else {
            Issue.record("Оба делегата должны отметиться в общем логе порядка didShow")
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

    /// Идемпотентность `reconcile`: повторная установка того же foreign не
    /// создаёт дубль в массиве delegates. Поведение проверяется через диспетчеризацию:
    /// foreign получает didShow ровно один раз (а не дважды) после двух вызовов
    /// `reconcile` с тем же объектом.
    @Test func reconcileSameForeignTwiceIsIdempotent() {
        let dispatcher = NavigationControllerDelegateDispatcher()
        let foreign = RecordingDelegate()

        _ = dispatcher.reconcile(externalDelegate: foreign)
        _ = dispatcher.reconcile(externalDelegate: foreign)

        // foreign зарегистрирован ровно один раз — получает событие один раз.
        let nav = UINavigationController()
        dispatcher.navigationController(nav, didShow: UIViewController(), animated: false)
        #expect(foreign.calls.count == 1)
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

    // MARK: - End-to-end swizzling (через РЕАЛЬНЫЙ setter `delegate`)

    /// Интеграционный тест P1: перехват `nav.delegate = foreign` / `= nil` через
    /// РЕАЛЬНЫЙ setter (swizzling подключается автоматически при первом `install`).
    ///
    /// В отличие от тестов `reconcile*`, здесь события и установка делегата идут
    /// через настоящий `nav.delegate` (setter после swizzling), а не через прямой
    /// вызов `dispatcher.reconcile`. Верифицируется контракт P1:
    /// - после `nav.delegate = foreign` слот читается как dispatcher (не foreign),
    ///   foreign тем не менее получает события как `.application`;
    /// - после `nav.delegate = nil` слот читается как dispatcher (не nil),
    ///   instance-наблюдатель Core не теряется, foreign больше не получает события;
    /// - доставка `didShow` instance-наблюдателю survives обеих операций.
    @Test func setDelegateInterceptorKeepsDispatcherInSlotAndSurvivesReset() {
        let nav = UINavigationController()
        // install запускает swizzling (один раз на процесс) и ставит dispatcher в слот.
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: nav)

        // Регистрируем instance-наблюдатель Core (как это делает StackRouter/InlineRouter).
        let instance = RecordingDelegate()
        dispatcher.addDelegate(instance, category: .instance)

        // Внешний код назначает своего делегата через РЕАЛЬНЫЙ setter.
        let foreign = RecordingDelegate()
        nav.delegate = foreign

        // Сознательное поведение обёртки: dispatcher возвращён в слот, поэтому
        // nav.delegate читается как dispatcher, а не как foreign.
        let slotAfterForeign = nav.delegate as? NavigationControllerDelegateDispatcher
        #expect(slotAfterForeign === dispatcher)

        // foreign получает события как .application, instance — как .instance,
        // через реальный вызов делегата nav (как это делает UIKit).
        let shown = UIViewController()
        nav.delegate?.navigationController?(nav, didShow: shown, animated: false)
        #expect(foreign.calls.count == 1)
        #expect(instance.calls.count == 1)

        // Внешний код сбрасывает делегата в nil через РЕАЛЬНЫЙ setter.
        nav.delegate = nil

        // Сюрприз для внешнего кода (см. документацию контракта): слот НЕ nil —
        // там снова dispatcher. Core сохраняет instance-наблюдатель.
        let slotAfterNil = nav.delegate as? NavigationControllerDelegateDispatcher
        #expect(slotAfterNil === dispatcher)
        #expect(nav.delegate != nil)

        // foreign больше не получает события (снят как .application)...
        let shown2 = UIViewController()
        nav.delegate?.navigationController?(nav, didShow: shown2, animated: false)
        #expect(foreign.calls.count == 1)
        // ...а instance-наблюдатель продолжает работать после сброса делегата.
        #expect(instance.calls.count == 2)
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
