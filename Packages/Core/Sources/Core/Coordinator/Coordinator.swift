import UIKit

/// Базовый абстрактный класс координатора.
///
/// Является связующим звеном между инфраструктурой навигации (Роутером) и навигационной логикой.
/// Управляет жизненным циклом потока и обеспечивает типобезопасный доступ к методам навигации.
///
/// - Generic Parameter R: Тип роутера (`Routing`), с которым работает данный координатор.
/// - Generic Parameter Route: Тип маршрута, который использует компоузер координатора.
@MainActor
open class Coordinator<R: Routing, Route>: _BaseCoordinator<R>, Coordinating {
    
    // MARK: - Public API
    
    public private(set) weak var parentCoordinator: (any Coordinating)?
    
    public var childCoordinators: [any Coordinating] {
        _children.compactMap(\.ref)
    }
    
    public var coordinatorLabel: String {
        String(describing: type(of: self))
    }

    /// Capability-токен, подтверждающий право запустить координатор.
    public struct Start<Router: Routing> {
        internal init() {}
    }

    /// Псевдоним capability-токена запуска для текущего типа координатора.
    public typealias StartCapability = Start<R>

    /// Роутер, через который осуществляется навигация.
    ///
    /// - Warning: Безопасный доступ гарантирован только внутри метода `start(_:)` и после него.
    public var router: R? {
        return _router
    }

    /// Компоузер-обертка, связанная с этим координатором.
    public private(set) var composer: ComposerBox<Route>

    /// Инициализирует координатор с конкретным компоузером.
    ///
    /// - Parameter composer: Компоузер, собирающий `UIViewController` для данного `Route`.
    public init<C: Composing>(composer: C) where C.Route == Route {
        self.composer = ComposerBox(wrappedComposer: composer)
        super.init()
        self.composer.owner = self
    }

    deinit {
        MainActor.assumeIsolated {
            (parentCoordinator as? AnyCoordinatorTreeNode)?.removeChild(self)
        }
    }

    /// Служебная точка входа для связывания Роутера и Координатора.
    override internal final func start(with router: R) {
        guard _router == nil else { return }
        _router = router
        
        start(.init())
        
        // Тегируем VC координатором — единственная точка записи
        // Вызывается после start(.init()), чтобы роутеры со снятым UI (SwitchRouter, InlineRouter) успели установить контент.
        CoordinatorLink.tag(self, on: router.root.viewController)
    }

    /// Точка входа в бизнес-логику навигации.
    ///
    /// - Parameter capability: Маркер права на запуск, создаваемый инфраструктурой Core.
    /// - Warning: Базовая реализация вызывает `fatalError`. Метод должен быть переопределен.
    open func start(_ capability: StartCapability) {
        fatalError("Метод start(_:) должен быть переопределен в наследнике \(String(describing: self))")
    }

    // MARK: - Internal Tree Management

    func addChild(_ child: any Coordinating) {
        _children.removeAll { $0.ref == nil }
        guard !_children.contains(where: { $0.ref === child }) else { return }
        _children.append(WeakCoordinator(child))
        (child as? AnyCoordinatorTreeNode)?.setParent(self)
    }

    func removeChild(_ child: any Coordinating) {
        _children.removeAll { $0.ref === child || $0.ref == nil }
        (child as? AnyCoordinatorTreeNode)?.setParent(nil)
    }

    // MARK: - Private members

    private var _children: [WeakCoordinator] = []
    private weak var _router: R?
}

// MARK: - Internal Starter

@MainActor
open class _BaseCoordinator<R: Routing> {
    internal init() {}
    internal func start(with router: R) {
        fatalError("Must be overridden in Coordinator")
    }
}

// MARK: - Tree Node Extensions

@MainActor
protocol AnyCoordinatorTreeNode: AnyObject {
    func setParent(_ parent: (any Coordinating)?)
    func removeChild(_ child: any Coordinating)
}

extension Coordinator: AnyCoordinatorTreeNode {
    func setParent(_ p: (any Coordinating)?) { 
        parentCoordinator = p 
    }
}

// ChildAdopting — единственная точка чтения CoordinatorLink
extension Coordinator: ChildAdopting {
    func adoptTaggedChild(from vc: UIViewController) {
        if let child = CoordinatorLink.take(from: vc) {
            addChild(child)
        }
    }
}
