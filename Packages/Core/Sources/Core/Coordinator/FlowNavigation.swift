import UIKit

/// Общие modal-команды, доступные всем типам навигации.
@MainActor
public protocol BaseNavigation: AnyObject {
    /// Показывает экран модально.
    ///
    /// - Parameters:
    ///   - item: Навигационный элемент для показа.
    ///   - animated: Нужно ли анимировать показ.
    ///   - completion: Вызывается после завершения показа; может быть `nil`.
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)

    /// Закрывает текущий модальный экран.
    ///
    /// - Parameters:
    ///   - animated: Нужно ли анимировать закрытие.
    ///   - completion: Вызывается после завершения закрытия; может быть `nil`.
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

public extension BaseNavigation {
    /// Показывает экран модально без обработчика завершения.
    func present(_ item: RouterItem, animated: Bool) {
        present(item, animated: animated, completion: nil)
    }

    /// Закрывает текущий модальный экран без обработчика завершения.
    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}

/// Навигация с линейным стеком экранов.
///
/// Используется и для `UINavigationController`, и для inline-flow внутри уже
/// существующего навигационного стека.
@MainActor
public protocol StackNavigation: BaseNavigation {
    /// Текущий стек экранов: от корня до вершины.
    var items: [RouterItem] { get }

    /// Устанавливает корневой экран, заменяя весь стек.
    func setRoot(_ item: RouterItem, animated: Bool)

    /// Помещает экран на вершину стека.
    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)

    /// Снимает экран с вершины стека.
    func pop(animated: Bool, completion: (() -> Void)?)

    /// Снимает все экраны, кроме корневого.
    func popToRoot(animated: Bool, completion: (() -> Void)?)

    /// Снимает экраны до заданного включительно.
    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)

    /// Полностью заменяет стек экранов.
    func setStack(_ items: [RouterItem], animated: Bool)
}

public extension StackNavigation {
    /// Помещает экран на вершину стека без обработчика завершения.
    func push(_ item: RouterItem, animated: Bool) {
        push(item, animated: animated, completion: nil)
    }

    /// Снимает экран с вершины стека без обработчика завершения.
    func pop(animated: Bool) {
        pop(animated: animated, completion: nil)
    }

    /// Снимает все экраны, кроме корневого, без обработчика завершения.
    func popToRoot(animated: Bool) {
        popToRoot(animated: animated, completion: nil)
    }

    /// Снимает экраны до заданного без обработчика завершения.
    func popTo(_ item: RouterItem, animated: Bool) {
        popTo(item, animated: animated, completion: nil)
    }
}

/// Навигация вкладок на базе `UITabBarController`.
@MainActor
public protocol TabsNavigation: BaseNavigation {
    /// Индекс выбранной вкладки.
    var selectedIndex: Int { get }

    /// Выбранная вкладка, либо `nil`, если вкладок нет.
    var selectedItem: RouterItem? { get }

    /// Полностью задаёт набор вкладок.
    func setItems(_ items: [RouterItem], animated: Bool)

    /// Выбирает вкладку по индексу.
    func selectTab(at index: Int)

    /// Выбирает вкладку по навигационному элементу.
    func selectItem(_ item: RouterItem)
}

/// Навигация, где одновременно активен только один корневой экран.
@MainActor
public protocol SwitchNavigation: BaseNavigation {
    /// Текущий активный экран, либо `nil`, если экран ещё не задан.
    var currentItem: RouterItem? { get }

    /// Заменяет текущий корневой экран новым.
    func switchTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?)
}

public extension SwitchNavigation {
    /// Заменяет текущий корневой экран без обработчика завершения.
    func switchTo(_ item: RouterItem, animated: Bool) {
        switchTo(item, animated: animated, completion: nil)
    }
}
