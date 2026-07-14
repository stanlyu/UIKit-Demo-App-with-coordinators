import UIKit

/// Общие modal-команды, доступные всем типам навигации.
@MainActor
public protocol BaseNavigation: AnyObject {
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

public extension BaseNavigation {
    func present(_ item: RouterItem, animated: Bool) {
        present(item, animated: animated, completion: nil)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}

/// Навигация с линейным стеком экранов.
///
/// Используется и для `UINavigationController`, и для inline-flow внутри уже
/// существующего navigation stack.
@MainActor
public protocol StackNavigation: BaseNavigation {
    var items: [RouterItem] { get }

    func setRoot(_ item: RouterItem, animated: Bool)
    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func pop(animated: Bool, completion: (() -> Void)?)
    func popToRoot(animated: Bool, completion: (() -> Void)?)
    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
    func setStack(_ items: [RouterItem], animated: Bool)
}

public extension StackNavigation {
    func push(_ item: RouterItem, animated: Bool) {
        push(item, animated: animated, completion: nil)
    }

    func pop(animated: Bool) {
        pop(animated: animated, completion: nil)
    }

    func popToRoot(animated: Bool) {
        popToRoot(animated: animated, completion: nil)
    }

    func popTo(_ item: RouterItem, animated: Bool) {
        popTo(item, animated: animated, completion: nil)
    }
}

/// Навигация вкладок на базе `UITabBarController`.
@MainActor
public protocol TabsNavigation: BaseNavigation {
    var selectedIndex: Int { get }
    var selectedItem: RouterItem? { get }

    func setItems(_ items: [RouterItem], animated: Bool)
    func selectTab(at index: Int)
    func selectItem(_ item: RouterItem)
}

/// Навигация, где активен только один root content.
@MainActor
public protocol SwitchNavigation: BaseNavigation {
    var currentItem: RouterItem? { get }

    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
}

public extension SwitchNavigation {
    func switchTo(_ item: RouterItem, animated: Bool) {
        switchTo(item, animated: animated, completion: nil)
    }
}
