import UIKit
import ObjectiveC

// MARK: - NavigationControllerDelegateDispatcher

/// Мультиплексор делегатов `UINavigationController`.
///
/// `UINavigationController` хранит только одного `delegate`. `Core` нуждается в
/// наблюдении за навигацией (в первую очередь — `didShow` после native back,
/// чтобы синхронизировать дерево `FlowInstance`), но не должен отбирать
/// делегат у прикладного кода. Dispatcher решает обе задачи: он встаёт в слот
/// `delegate`, а сам маршрутизирует события одновременно внешним
/// (`.application`) делегатам и внутреннему (`.instance`) наблюдателю `Core`.
///
/// # Проблема (P1) и двухслойная оборона
///
/// Исторически dispatcher удерживался только как weak-значение свойства
/// `delegate` (слот `UINavigationController` хранит `delegate` слабо). Это
/// приводило к трём сценариям отказа:
///
/// 1. **Dispatcher освобождается ARC** — слот `delegate` обнуляется, `Core`
///    перестаёт получать события (включая didShow → дерево не обновляется).
/// 2. **`nav.delegate = foreignObject`** — внешний делегат вытесняет
///    dispatcher из слота, внутренний `.instance`-наблюдатель теряет события.
/// 3. **`nav.delegate = nil`** — снимается dispatcher целиком (вместе с
///    `.instance`-наблюдателем), дерево координаторов не обновляется.
///    Сюда же относится свайп-back между программными операциями: UIKit на
///    время снимает/меняет делегата, и без перехвата `Core` теряет синхронизацию.
///
/// Решение состоит из двух независимых слоёв:
///
/// - **Method swizzling `UINavigationController.setDelegate:`** (основной
///   механизм) — даёт детерминированный перехват установки/сброса `delegate`
///   ровно в момент вызова. Перехватив setter, `Core` перерегистрирует
///   внешний делегат как `.application` и вернёт dispatcher в слот, сохранив
///   `.instance`-наблюдатель.
/// - **Associated object retain** (второй слой) — dispatcher дополнительно
///   удерживается через `objc_setAssociatedObject(...RETAIN_NONATOMIC)` на
///   самом `navigationController`. Это закрывает освобждение ARC из сценария
///   1 и снижает частоту вытеснения даже без swizzling.
///
/// # Почему swizzling, а не альтернативы
///
/// Исследование альтернатив выполнено и все они отклонены:
///
/// - **KVO** — `UIKit` не KVO-совместим: наблюдение `delegate` через KVO
///   официально не поддерживается и нестабильно (framework полагается на
///   частные механизмы уведомлений).
/// - **Subclassing `UINavigationController`** — ломает `InlineRouter`, где
///   навигационный контроллер приходит из внешнего кода (хост-приложение
///   создаёт свой `UINavigationController`), и нарушает контракт
///   `FlowBuilder.stack(makeNavigationController:)`, требующий произвольного
///   `UINavigationController`.
/// - **Сторонние фреймворки** — `XCoordinator` явно запрещает/конкурирует за
///   контракт делегата; `RxFlow` вообще не опирается на `delegate`. Ни один
///   не закрывает три сценария P1 одновременно.
///
/// Method swizzling `setDelegate:` — единственный механизм, дающий
/// детерминированный перехват и в момент установки, и в момент сброса
/// делегата, без ограничений на источник `UINavigationController`.
///
/// # Архитектура для тестируемости
///
/// Вся логика «что делать с новым делегатом» вынесена в чистый метод
/// `reconcile(externalDelegate:)`, который не зависит от swizzling и может
/// быть вызван напрямую из юнит-теста (см. `DispatcherReconcileTests`).
/// Swizzle-обёртка `nav_core_setDelegate(_:)` остаётся тонкой: она лишь
/// достаёт dispatcher из associated object, делегирует решение методу
/// `reconcile` и пробрасывает итоговое значение в оригинальный setter.
///
/// # Контракт для внешнего кода
///
/// Внешний код МОЖЕТ свободно выполнять `nav.delegate = myObject` и
/// `nav.delegate = nil` — `Core` перехватит вызов, перерегистрирует
/// делегат и сохранит внутренний `.instance`-наблюдатель. Тем не менее
/// предпочтительный путь — регистрировать внешних делегатов через
/// `addDelegateIfNeeded(_:category:)`: это явно выражает намерение и не
/// зависит от swizzling.
///
/// # Ограничения и риски
///
/// - **Конфликт с другими либами**, которые также swizzle-ят
///   `setDelegate:` (например, Firebase/Sentry/аналитика). Если несколько
///   библиотур обменивают IMP одного селектора, порядок имеет значение.
///   Обёртка `Core` идемпотентна относительно своих действий и корректно
///   работает, даже если вызвана повторно с тем же делегатом.
/// - **Одноразовость swizzling** гарантируется `static let`-токеном
///   (`swizzleToken`) — обмен IMP выполняется ровно один раз на процесс.
/// - **Префикс методов**: обёртка и внутренний API используют
///   уникальный префикс `nav_core_`, чтобы минимизировать коллизию имён.
@MainActor
final class NavigationControllerDelegateDispatcher: NSObject {
    // MARK: - Types

    enum DelegateCategory {
        /// Delegate, который приложение уже назначило на `UINavigationController`.
        case application
        /// Внутренний observer Core для cleanup дерева FlowInstance после native back.
        case instance
    }

    // MARK: - Associated object storage

    /// Ключ для удержания dispatcher через associated object на nav controller (второй слой обороны).
    fileprivate nonisolated(unsafe) static var dispatcherAssociationKey: UInt8 = 0

    /// Устанавливает dispatcher на `navigationController` и удерживает его через
    /// associated object (закрывает освобождение ARC из сценария P1.1).
    ///
    /// Возвращает существующий dispatcher, если он уже установлен. Существующий
    /// внешний делегат (если был) регистрируется как `.application`.
    static func install(on navigationController: UINavigationController) -> NavigationControllerDelegateDispatcher {
        ensureSetDelegateSwizzled()

        if let dispatcher = currentDispatcher(for: navigationController) {
            return dispatcher
        }

        let dispatcher = NavigationControllerDelegateDispatcher()
        // Второй слой обороны: dispatcher живёт, пока жив nav controller.
        objc_setAssociatedObject(
            navigationController,
            &Self.dispatcherAssociationKey,
            dispatcher,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        if let existingDelegate = navigationController.delegate {
            dispatcher.addDelegate(existingDelegate, category: .application)
            dispatcher.lastApplicationDelegate = existingDelegate
        }
        // Устанавливаем dispatcher в слот через оригинальный setter (после обмена IMP
        // это прямой вызов UIKit, без повторного входа в обёртку).
        navigationController.nav_core_setDelegate(dispatcher)
        return dispatcher
    }

    /// Достаёт dispatcher из associated object, не устанавливая новый.
    private static func currentDispatcher(
        for navigationController: UINavigationController
    ) -> NavigationControllerDelegateDispatcher? {
        objc_getAssociatedObject(
            navigationController,
            &Self.dispatcherAssociationKey
        ) as? NavigationControllerDelegateDispatcher
    }

    // MARK: - Public registration API

    func addDelegate(
        _ delegate: any UINavigationControllerDelegate,
        category: DelegateCategory = .application
    ) {
        removeReleasedDelegates()
        if !contains(delegate) {
            delegates.append(WeakNavigationControllerDelegate(delegate, context: category))
        }
    }

    func removeDelegate(_ delegate: any UINavigationControllerDelegate) {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.object == nil || $0.id == delegateID }
    }

    /// Удаляет из списка мёртвые weak-делегаты. Точка для тестирования cleanup.
    func removeReleasedDelegates() {
        delegates.removeAll { $0.object == nil }
    }

    // MARK: - Reconciliation (чистая, тестируемая логика)

    /// Последний зарегистрированный внешний (`.application`) делегат.
    ///
    /// Хранится слабо: как только внешний объект освобождается, `Core` не должен
    /// его удерживать. Используется `reconcile`, чтобы понять, чем был прежний
    /// `.application`, и при необходимости снять его.
    weak var lastApplicationDelegate: (any UINavigationControllerDelegate)?

    /// Чистая (без swizzling) логика решения «что делать с новым делегатом».
    ///
    /// Вызывается swizzle-обёрткой `nav_core_setDelegate(_:)` после того, как
    /// внешний код сделал `nav.delegate = newValue`. Метод не трогает сам слот
    /// `delegate` — он только обновляет внутренний список делегатов
    /// dispatcher'а. Установка итогового значения в слот — ответственность
    /// обёртки.
    ///
    /// Контракт:
    /// - `externalDelegate === self` (dispatcher сам) → никаких действий.
    /// - `externalDelegate` — внешний объект → прежний `.application`
    ///   (если был и отличается) снимается, новый регистрируется как
    ///   `.application`, `lastApplicationDelegate` обновляется.
    /// - `externalDelegate == nil` → прежний `.application` снимается,
    ///   `lastApplicationDelegate` зануляется. `.instance`-наблюдатель не
    ///   трогается: дерево координаторов должно продолжать обновляться.
    ///
    /// Возвращает значение, которое следует поместить в слот `delegate`:
    /// - сам dispatcher (чтобы Core продолжал получать события);
    /// - либо `externalDelegate` без изменений, если Core не инициализирован
    ///   (этот путь обрабатывается обёрткой до вызова reconcile — здесь
    ///   возвращается dispatcher).
    @discardableResult
    func reconcile(externalDelegate: (any UINavigationControllerDelegate)?) -> any UINavigationControllerDelegate {
        // Dispatcher не конкурирует сам с собой.
        if externalDelegate === self {
            return self
        }

        // Снимаем прежнего .application, если он был.
        if let previous = lastApplicationDelegate,
           previous !== externalDelegate {
            removeDelegate(previous)
        }

        if let externalDelegate {
            // Регистрируем внешний делегат как .application.
            addDelegate(externalDelegate, category: .application)
            lastApplicationDelegate = externalDelegate
        } else {
            lastApplicationDelegate = nil
        }
        // Dispatcher возвращается в слот: Core продолжает мультиплексировать
        // события между .application и .instance даже после nav.delegate = nil.
        return self
    }

    // MARK: - Dispatch ordering

    private func contains(_ delegate: any UINavigationControllerDelegate) -> Bool {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        return delegates.contains(where: { $0.id == delegateID })
    }

    private func activeDelegates(orderedBy order: DelegateDispatchOrder) -> [any UINavigationControllerDelegate] {
        removeReleasedDelegates()
        switch order {
        case .registration:
            // willShow остается в порядке регистрации: Core не меняет состояние дерева на willShow.
            return delegates.compactMap(\.object)
        case .instanceFirst:
            // didShow сначала нужен Core: после native back application delegate
            // должен читать уже обновленное дерево FlowInstance.
            return activeDelegates(in: [.instance, .application])
        case .applicationFirst:
            // Анимации и ориентации принадлежат приложению, поэтому application delegate
            // получает приоритет над instance observer-ом Core.
            return activeDelegates(in: [.application, .instance])
        }
    }

    private func activeDelegates(
        in categories: [DelegateCategory]
    ) -> [any UINavigationControllerDelegate] {
        categories.flatMap { category in
            delegates
                .filter { $0.context == category }
                .compactMap(\.object)
        }
    }

    fileprivate typealias WeakNavigationControllerDelegate = WeakContainer<any UINavigationControllerDelegate, DelegateCategory>

    private var delegates: [WeakNavigationControllerDelegate] = []
}

// MARK: - UINavigationControllerDelegate

extension NavigationControllerDelegateDispatcher: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates(orderedBy: .registration) {
            delegate.navigationController?(navigationController, willShow: viewController, animated: animated)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        for delegate in activeDelegates(orderedBy: .instanceFirst) {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let animator = delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            ) {
                return animator
            }
        }
        return nil
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let interactionController = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            ) {
                return interactionController
            }
        }
        return nil
    }

    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let supportedOrientations = delegate.navigationControllerSupportedInterfaceOrientations?(
                navigationController
            ) {
                return supportedOrientations
            }
        }
        return navigationController.topViewController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        for delegate in activeDelegates(orderedBy: .applicationFirst) {
            if let preferredOrientation = delegate.navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) {
                return preferredOrientation
            }
        }
        return navigationController.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
}

// MARK: - Dispatch order

private enum DelegateDispatchOrder {
    case registration
    case instanceFirst
    case applicationFirst
}

// MARK: - setDelegate swizzling

extension NavigationControllerDelegateDispatcher {
    /// Токен одноразовости swizzling (эквивалент dispatch_once).
    ///
    /// `static let` инициализируется потокобезопасно и ровно один раз на процесс.
    /// После первой инициализации `ensureSetDelegateSwizzled()` обмена IMP больше нет.
    private static let swizzleToken: Void = {
        swizzleSetDelegate()
    }()

    /// Гарантирует, что `setDelegate:` свиззлен ровно один раз.
    /// Вызывается из `install(on:)`, который всегда выполняется на main actor.
    private static func ensureSetDelegateSwizzled() {
        _ = swizzleToken
    }

    /// Обменивает IMP `setDelegate:` и обёртки `nav_core_setDelegate(_:)`.
    ///
    /// После обмена селектор `setDelegate:` указывает на нашу обёртку
    /// (`nav_core_setDelegate`), а селектор `nav_core_setDelegate:` — на
    /// оригинальную реализацию UIKit. Поэтому вызов
    /// `self.nav_core_setDelegate(value)` внутри обёртки — это НЕ рекурсия,
    /// а прямой вызов оригинала.
    private static func swizzleSetDelegate() {
        let originalSelector = #selector(setter: UINavigationController.delegate)
        let swizzledSelector = #selector(UINavigationController.nav_core_setDelegate(_:))

        guard
            let originalMethod = class_getInstanceMethod(UINavigationController.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledSelector)
        else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

/// Swizzling-обёртка и точка доступа к оригинальному setter'у.
///
/// `nav_core_setDelegate(_:)` после обмена IMP становится реализацией
/// `setDelegate:`. Она достаёт dispatcher из associated object и делегирует
/// решение чистому методу `reconcile(externalDelegate:)`. Если для этого
/// nav controller Core ещё не инициализирован (dispatcher отсутствует),
/// обёртка просто пробрасывает значение в оригинал, не вмешиваясь.
private extension UINavigationController {
    /// Тонкая обёртка над `setDelegate:`. Вызывается UIKit-ом и внешним кодом
    /// при любой установке `delegate` (включая `= nil`) после swizzling.
    @objc func nav_core_setDelegate(_ delegate: (any UINavigationControllerDelegate)?) {
        if let dispatcher = objc_getAssociatedObject(
            self,
            &NavigationControllerDelegateDispatcher.dispatcherAssociationKey
        ) as? NavigationControllerDelegateDispatcher {
            // Core уже инициализирован для этого nav controller: принимаем
            // решение через чистую логику и возвращаем dispatcher в слот.
            let resolved = dispatcher.reconcile(externalDelegate: delegate)
            // Вызов оригинального setter'а (после exchange — это UIKit).
            // Это НЕ рекурсия: селектор nav_core_setDelegate указывает на оригинал.
            self.nav_core_setDelegate(resolved)
        } else {
            // Core не инициализирован для этого nav controller — не вмешиваемся.
            self.nav_core_setDelegate(delegate)
        }
    }
}

// MARK: - UINavigationController convenience

extension UINavigationController {
    func addDelegateIfNeeded(
        _ delegate: any UINavigationControllerDelegate,
        category: NavigationControllerDelegateDispatcher.DelegateCategory = .application
    ) {
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: self)
        dispatcher.addDelegate(delegate, category: category)
    }

    func removeDelegateIfNeeded(_ delegate: any UINavigationControllerDelegate) {
        if let dispatcher = self.delegate as? NavigationControllerDelegateDispatcher {
            dispatcher.removeDelegate(delegate)
        }
    }
}
