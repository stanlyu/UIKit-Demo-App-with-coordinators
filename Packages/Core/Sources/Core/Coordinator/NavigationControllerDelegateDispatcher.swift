import UIKit
import ObjectiveC

// MARK: - NavigationControllerDelegateDispatcher

/// Мультиплексор делегатов `UINavigationController`.
///
/// `UINavigationController` хранит только одного делегата, причём слабо.
/// Механизму координаторов нужно наблюдать навигацию — прежде всего событие
/// `didShow`, которое приходит после системной кнопки «назад» и после
/// свайпа-back, чтобы дерево flow-инстансов оставалось синхронным. При этом
/// делегат нельзя отбирать у внешнего кода. Dispatcher решает обе задачи: он
/// встаёт в слот `delegate`, а сам направляет события одновременно внешнему
/// делегату (зарегистрированному кодом приложения) и внутреннему наблюдателю
/// фреймворка.
///
/// # Как dispatcher удерживается в слоте
///
/// Слот `delegate` хранится слабо, поэтому dispatcher нельзя держать только
/// через него — иначе он освободится сразу после создания. Решение состоит из
/// двух независимых механизмов:
///
/// - **Перехват `setDelegate:` (method swizzling)** — даёт детерминированный
///   перехват любой установки и сброса делегата ровно в момент вызова.
///   Перехватив setter, dispatcher перерегистрирует внешний делегат и вернёт
///   себя в слот, сохранив внутреннего наблюдателя. Это закрывает ситуации
///   `nav.delegate = чужойОбъект` и `nav.delegate = nil`.
/// - **Удержание через associated object** — dispatcher дополнительно
///   удерживается через `objc_setAssociatedObject(...RETAIN_NONATOMIC)` на
///   самом `navigationController`, поэтому он живёт ровно столько, сколько
///   навигационный контроллер, и не освобождается из-за слабого слота.
///
/// # Почему swizzling, а не альтернативы
///
/// Есть альтернатива — наблюдение через KVO, — но она не подходит: `UIKit`
/// официально не поддерживает KVO для свойства `delegate`, такое наблюдение
/// нестабильно. Подклассирование `UINavigationController` тоже не годится:
/// навигационный контроллер в ряде сценариев создаётся внешним кодом и
/// приходит уже готовым, поэтому требовать конкретный подкласс невозможно.
/// Method swizzling `setDelegate:` — единственный механизм, дающий
/// детерминированный перехват и установки, и сброса делегата, без ограничений
/// на источник `UINavigationController`.
///
/// # Контракт для внешнего кода
///
/// Внешний код может свободно выполнять `nav.delegate = myObject` и
/// `nav.delegate = nil`: перехват зарегистрирует делегат и сохранит
/// внутреннего наблюдателя.
///
/// - Important: после `nav.delegate = nil` свойство `delegate` **не**
///   читается как `nil` — обёртка возвращает dispatcher обратно в слот.
///   Поэтому `nav.delegate` читается как `NavigationControllerDelegateDispatcher`,
///   а проверка «делегат снят» через `nav.delegate == nil` всегда ложна. Это
///   сознательное решение: так фреймворк сохраняет внутреннего наблюдателя, и
///   дерево flow-инстансов продолжает обновляться (события `didShow` после
///   системного «назад» и свайпа-back). Чтобы полностью убрать конкретного
///   наблюдателя, используйте `removeDelegateIfNeeded(_:)`, а не присваивание
///   `nil`. Аналогично, после `nav.delegate = чужойОбъект` свойство читается
///   как dispatcher (не как чужой объект): чужой объект получает события как
///   внешний делегат, а слот занят dispatcher'ом.
///
/// # Тестируемость
///
/// Логика «что сделать с новым делегатом» вынесена в отдельный метод
/// `reconcile(externalDelegate:)`, который не зависит от swizzling и может
/// быть вызван напрямую, например из юнит-теста. Swizzle-обёртка остаётся
/// тонкой: она достаёт dispatcher из associated object, делегирует решение
/// методу `reconcile` и пробрасывает итоговое значение в оригинальный setter.
@MainActor
final class NavigationControllerDelegateDispatcher: NSObject {
    // MARK: - Types

    /// Категория делегата, зарегистрированного в dispatcher.
    enum DelegateCategory {
        /// Внешний делегат, назначенный на `UINavigationController` кодом
        /// приложения. Одновременно активен максимум один такой делегат.
        case external
        /// Внутренний наблюдатель механизма координаторов: синхронизирует
        /// дерево flow-инстансов после системного «назад» и свайпа-back.
        case `internal`
    }

    // MARK: - Associated object storage

    /// Ключ для удержания dispatcher через associated object на navigation controller.
    fileprivate nonisolated(unsafe) static var dispatcherAssociationKey: UInt8 = 0

    /// Устанавливает dispatcher на `navigationController` и удерживает его через
    /// associated object, чтобы он пережил слабый слот `delegate`.
    ///
    /// Если dispatcher уже установлен — возвращает существующий. Существующий
    /// внешний делегат (если был) регистрируется как `.external`.
    ///
    /// - Parameter navigationController: Навигационный контроллер, для которого
    ///   включается перехват делегата.
    /// - Returns: Dispatcher, установленный в слот `delegate`.
    static func install(on navigationController: UINavigationController) -> NavigationControllerDelegateDispatcher {
        ensureSetDelegateSwizzled()

        if let dispatcher = currentDispatcher(for: navigationController) {
            return dispatcher
        }

        let dispatcher = NavigationControllerDelegateDispatcher()
        // Dispatcher удерживается через associated object, чтобы пережить
        // слабый слот delegate и жить столько же, сколько navigation controller.
        objc_setAssociatedObject(
            navigationController,
            &Self.dispatcherAssociationKey,
            dispatcher,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        if let existingDelegate = navigationController.delegate {
            dispatcher.addDelegate(existingDelegate, category: .external)
        }
        // Устанавливаем dispatcher в слот через оригинальный setter (после обмена
        // IMP это прямой вызов UIKit, без повторного входа в обёртку).
        navigationController.fl_setDelegate(dispatcher)
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

    // MARK: - Registration API

    /// Регистрирует делегат в dispatcher.
    ///
    /// Для категории `.external` одновременно активен максимум один делегат:
    /// регистрация нового заменяет прежнего (он снимается автоматически).
    ///
    /// - Parameters:
    ///   - delegate: Делегат навигационного контроллера.
    ///   - category: Категория делегата; по умолчанию `.external`.
    func addDelegate(
        _ delegate: any UINavigationControllerDelegate,
        category: DelegateCategory = .external
    ) {
        removeReleasedDelegates()
        // Инвариант: внешний делегат существует в единственном экземпляре.
        // Регистрация нового заменяет прежнего.
        if category == .external,
           let existingExternal = currentExternalDelegate(),
           existingExternal !== delegate {
            removeDelegate(existingExternal)
        }
        if !contains(delegate) {
            delegates.append(WeakNavigationControllerDelegate(delegate, context: category))
        }
    }

    /// Удаляет конкретного делегата из dispatcher.
    ///
    /// - Parameter delegate: Делегат, который больше не должен получать события.
    func removeDelegate(_ delegate: any UINavigationControllerDelegate) {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        delegates.removeAll { $0.object == nil || $0.id == delegateID }
    }

    /// Удаляет из списка освобождённые слабые ссылки.
    func removeReleasedDelegates() {
        delegates.removeAll { $0.object == nil }
    }

    // MARK: - Reconciliation (чистая, тестируемая логика)

    /// Решает, что сделать с делегатом, который внешний код только что записал в
    /// `nav.delegate`.
    ///
    /// Вынесен отдельно от swizzling, чтобы логику регистрации и замены
    /// внешнего делегата можно было тестировать без перехвата. Метод не
    /// записывает значение в свойство `delegate` напрямую — он только обновляет
    /// внутренний список делегатов. Установка итогового значения в слот остаётся
    /// ответственностью swizzle-обёртки.
    ///
    /// - Parameter externalDelegate: Делегат, переданный внешним кодом в `delegate`.
    /// - Returns: Значение, которое следует поместить в слот `delegate` (всегда
    ///   сам dispatcher, чтобы наблюдение за навигацией продолжалось).
    ///
    /// - Note: Метод помечен `internal` и существует отдельно от обёртки только
    ///   ради тестируемости — его вызывает swizzle-обёртка `fl_setDelegate(_:)`.
    @discardableResult
    func reconcile(externalDelegate: (any UINavigationControllerDelegate)?) -> any UINavigationControllerDelegate {
        // Dispatcher не конкурирует сам с собой.
        if externalDelegate === self {
            return self
        }

        if let externalDelegate {
            // Регистрируем внешний делегат; прежний заменяется автоматически
            // (инвариант в addDelegate: одновременно максимум один .external).
            addDelegate(externalDelegate, category: .external)
        } else if let previous = currentExternalDelegate() {
            // nav.delegate = nil снимает внешнего делегата. Внутренний
            // наблюдатель не трогается — дерево flow-инстансов должно
            // продолжать обновляться.
            removeDelegate(previous)
        }

        // Dispatcher возвращается в слот: механизм координаторов продолжает
        // направлять события и внешнему, и внутреннему делегатам даже после
        // nav.delegate = nil.
        return self
    }

    // MARK: - Dispatch ordering

    /// Текущий внешний делегат, если он ещё жив. Окно в массив `delegates`:
    /// отдельное хранилище не нужно, т.к. внешний делегат там в единственном
    /// экземпляре.
    private func currentExternalDelegate() -> (any UINavigationControllerDelegate)? {
        delegates
            .first { $0.context == .external && $0.object != nil }?
            .object
    }

    private func contains(_ delegate: any UINavigationControllerDelegate) -> Bool {
        let delegateID = ObjectIdentifier(delegate as AnyObject)
        return delegates.contains(where: { $0.id == delegateID })
    }

    private func activeDelegates(orderedBy order: DelegateDispatchOrder) -> [any UINavigationControllerDelegate] {
        removeReleasedDelegates()
        switch order {
        case .registration:
            // willShow идёт в порядке регистрации: на этом событии дерево
            // flow-инстансов не меняется, поэтому порядок доставки не важен.
            return delegates.compactMap(\.object)
        case .internalFirst:
            // didShow идёт «внутренний-наблюдатель-первым»: после системной
            // кнопки «назад» и свайпа-back внешний делегат должен видеть уже
            // обновлённое дерево flow-инстансов.
            return activeDelegates(in: [.internal, .external])
        case .externalFirst:
            // Анимации и ориентации принадлежат приложению, поэтому внешний
            // делегат опрашивается раньше внутреннего наблюдателя.
            return activeDelegates(in: [.external, .internal])
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
        for delegate in activeDelegates(orderedBy: .internalFirst) {
            delegate.navigationController?(navigationController, didShow: viewController, animated: animated)
        }
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
        for delegate in activeDelegates(orderedBy: .externalFirst) {
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
    case internalFirst
    case externalFirst
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

    /// Гарантирует, что `setDelegate:` перехвачен ровно один раз.
    private static func ensureSetDelegateSwizzled() {
        _ = swizzleToken
    }

    /// Обменивает IMP `setDelegate:` и обёртки `fl_setDelegate(_:)`.
    private static func swizzleSetDelegate() {
        let originalSelector = #selector(setter: UINavigationController.delegate)
        let swizzledSelector = #selector(UINavigationController.fl_setDelegate(_:))

        guard
            let originalMethod = class_getInstanceMethod(UINavigationController.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(UINavigationController.self, swizzledSelector)
        else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

/// Swizzle-обёртка над `setDelegate:`.
///
/// После обмена IMP становится реализацией `setDelegate:`. Достаёт dispatcher из
/// associated object и делегирует решение методу `reconcile(externalDelegate:)`.
/// Если для этого navigation controller dispatcher ещё не установлен, обёртка
/// просто пробрасывает значение в оригинал, не вмешиваясь.
private extension UINavigationController {
    /// Перехватывает любую установку `delegate` (включая `= nil`) после swizzling.
    @objc func fl_setDelegate(_ delegate: (any UINavigationControllerDelegate)?) {
        if let dispatcher = objc_getAssociatedObject(
            self,
            &NavigationControllerDelegateDispatcher.dispatcherAssociationKey
        ) as? NavigationControllerDelegateDispatcher {
            // Dispatcher установлен: принимаем решение через чистую логику и
            // возвращаем dispatcher в слот.
            let resolved = dispatcher.reconcile(externalDelegate: delegate)
            // Вызов оригинального setter'а (после обмена — это реализация UIKit).
            self.fl_setDelegate(resolved)
        } else {
            // Dispatcher не установлен для этого navigation controller — не вмешиваемся.
            self.fl_setDelegate(delegate)
        }
    }
}

// MARK: - UINavigationController convenience

extension UINavigationController {
    /// Регистрирует делегат в dispatcher этого navigation controller,
    /// установив dispatcher при необходимости.
    func addDelegateIfNeeded(
        _ delegate: any UINavigationControllerDelegate,
        category: NavigationControllerDelegateDispatcher.DelegateCategory = .external
    ) {
        let dispatcher = NavigationControllerDelegateDispatcher.install(on: self)
        dispatcher.addDelegate(delegate, category: category)
    }

    /// Удаляет делегат из dispatcher этого navigation controller, если
    /// dispatcher установлен.
    func removeDelegateIfNeeded(_ delegate: any UINavigationControllerDelegate) {
        if let dispatcher = self.delegate as? NavigationControllerDelegateDispatcher {
            dispatcher.removeDelegate(delegate)
        }
    }
}
