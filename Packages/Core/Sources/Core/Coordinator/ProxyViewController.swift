//
//  ProxyViewController.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 11.02.2026.
//

import UIKit

// Базовый контейнер-прокси.
/// Мимикрирует под своего дочернего контроллера (`contentViewController`) для системы навигации.
///
/// **Принцип работы (Mirror Mode):**
/// Этот контроллер является прозрачной оберткой. Он автоматически синхронизирует свои свойства
/// (`title`, `tabBarItem`, `navigationItem`, `hidesBottomBarWhenPushed` и др.) со свойствами
/// текущего контента.
///
/// - Warning: **Конфигурация:** Не пытайтесь настраивать визуальные свойства (например, `title` или `tabBarItem`)
///   напрямую у экземпляра `ProxyViewController`. Эти настройки будут **перезаписаны** значениями
///   из `contentViewController` в момент вызова `setContent`.
///   Настраивайте эти свойства у самого контентного контроллера (в Factory/Composer).
open class ProxyViewController: UIViewController {

    // MARK: - Private Properties
    private(set) var contentViewController: UIViewController?
    private var observations: [NSKeyValueObservation] = []

    // MARK: - Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if let content = contentViewController {
            // from: nil, так как это первичная установка
            transition(from: nil, to: content)
        }
    }

    // MARK: - Public Methods

    /// Устанавливает новый контент и синхронизирует состояние прокси с ним.
    public func setContent(_ newContent: UIViewController) {
        let oldContent = contentViewController
        contentViewController = newContent
        observations.removeAll()
        setupProxying(for: newContent)

        // Уведомляем систему, что параметры (Status Bar, Orientation) изменились.
        // Так как contentViewController уже обновлен, система опросит новый контроллер.
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()

        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }

        // 3. Визуальный переход делаем ТОЛЬКО если view уже загружена.
        // Если это вызов из init, то isViewLoaded == false, и мы пропускаем этот шаг.
        // Он выполнится автоматически во viewDidLoad.
        if isViewLoaded {
            transition(from: oldContent, to: newContent)
        }
    }

    /// Метод перехода от старого контроллера к новому.
    /// По умолчанию выполняет мгновенную замену.
    /// Переопредели этот метод для добавления анимаций (CrossDissolve, Slide и т.д.).
    open func transition(from oldViewController: UIViewController?, to newViewController: UIViewController) {
        if let old = oldViewController {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        setupChildViewController(newViewController)
    }
}

// MARK: - KVO Proxying Logic
private extension ProxyViewController {
    func setupProxying(for child: UIViewController) {

        // --- 1. View Controller Properties ---
        bind(from: child, to: self, \.hidesBottomBarWhenPushed)
        bind(from: child, to: self, \.definesPresentationContext)
        bind(from: child, to: self, \.providesPresentationContextTransitionStyle)
        bind(from: child, to: self, \.restoresFocusAfterTransition)
        bind(from: child, to: self, \.isModalInPresentation)
        bind(from: child, to: self, \.modalPresentationStyle)
        bind(from: child, to: self, \.modalTransitionStyle)
        bind(from: child, to: self, \.overrideUserInterfaceStyle)
        bind(from: child, to: self, \.edgesForExtendedLayout)
        bind(from: child, to: self, \.extendedLayoutIncludesOpaqueBars)

        // --- 2. Navigation Item Properties ---

        let navItem = self.navigationItem
        let childNavItem = child.navigationItem

        bind(from: childNavItem, to: navItem, \.title)
        bind(from: childNavItem, to: navItem, \.prompt)
        bind(from: childNavItem, to: navItem, \.titleView)
        bind(from: childNavItem, to: navItem, \.largeTitleDisplayMode)

        // Buttons
        bind(from: childNavItem, to: navItem, \.rightBarButtonItem)
        bind(from: childNavItem, to: navItem, \.rightBarButtonItems)
        bind(from: childNavItem, to: navItem, \.leftBarButtonItem)
        bind(from: childNavItem, to: navItem, \.leftBarButtonItems)

        // Back Button
        bind(from: childNavItem, to: navItem, \.hidesBackButton)
        bind(from: childNavItem, to: navItem, \.backBarButtonItem)
        bind(from: childNavItem, to: navItem, \.leftItemsSupplementBackButton)
        bind(from: childNavItem, to: navItem, \.backButtonTitle)
        bind(from: childNavItem, to: navItem, \.backButtonDisplayMode)

        if #available(iOS 16.0, *) {
            bind(from: childNavItem, to: navItem, \.backAction)
        }

        // Search
        bind(from: childNavItem, to: navItem, \.searchController)
        bind(from: childNavItem, to: navItem, \.hidesSearchBarWhenScrolling)

        if #available(iOS 16.0, *) {
            bind(from: childNavItem, to: navItem, \.preferredSearchBarPlacement)
        }

        // Appearance
        bind(from: childNavItem, to: navItem, \.standardAppearance)
        bind(from: childNavItem, to: navItem, \.compactAppearance)
        bind(from: childNavItem, to: navItem, \.scrollEdgeAppearance)
        bind(from: childNavItem, to: navItem, \.compactScrollEdgeAppearance)

        // --- 3. Toolbar & TabBar Properties ---

        bind(from: child, to: self, \.toolbarItems)

        if let tab = self.tabBarItem, let childTab = child.tabBarItem {
            bind(from: childTab, to: tab, \.badgeValue)
            bind(from: childTab, to: tab, \.title)
            bind(from: childTab, to: tab, \.image)
            bind(from: childTab, to: tab, \.selectedImage)

            bind(from: childTab, to: tab, \.standardAppearance)
            bind(from: childTab, to: tab, \.scrollEdgeAppearance)
        }
    }

    func bind<Root: NSObject, Value: Equatable>(
        from source: Root,
        to target: Root,
        _ keyPath: ReferenceWritableKeyPath<Root, Value>
    ) {
        target[keyPath: keyPath] = source[keyPath: keyPath]

        // KVO Подписка
        let observation = source.observe(keyPath, options: [.new, .initial]) { [weak target] _, change in
            if let newValue = change.newValue {
                target?[keyPath: keyPath] = newValue
            }
        }
        observations.append(observation)
    }
}

// MARK: - System Overrides
extension ProxyViewController {

    // --- Status Bar ---
    open override var childForStatusBarStyle: UIViewController? {
        contentViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        contentViewController
    }
    
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        contentViewController
    }

    open override var prefersHomeIndicatorAutoHidden: Bool {
        contentViewController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }

    // --- Orientation ---
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        contentViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        contentViewController?.preferredInterfaceOrientationForPresentation
        ??
        super.preferredInterfaceOrientationForPresentation
    }

    open override var shouldAutorotate: Bool {
        contentViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    // --- System Gestures ---
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        contentViewController
    }

    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        contentViewController?.preferredScreenEdgesDeferringSystemGestures ?? super.preferredScreenEdgesDeferringSystemGestures
    }

    // --- Transition ---
    open override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { contentViewController?.transitioningDelegate ?? super.transitioningDelegate }
        set { super.transitioningDelegate = newValue }
    }
}
