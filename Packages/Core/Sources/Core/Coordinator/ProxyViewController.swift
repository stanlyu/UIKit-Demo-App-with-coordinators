//
//  ProxyViewController.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 11.02.2026.
//

import UIKit

/// Протокол для получения эталонных системных значений по умолчанию.
@MainActor
protocol SystemDefaultProvider: NSObject {
    associatedtype Value
    static var systemDefault: Value { get }
}

extension UIViewController: SystemDefaultProvider {
    static let systemDefault = UIViewController()
}

extension UINavigationItem: SystemDefaultProvider {
    static let systemDefault = UINavigationItem()
}

extension UITabBarItem: SystemDefaultProvider {
    static let systemDefault = UITabBarItem()
}

open class ProxyViewController: UIViewController {

    // MARK: - Private Properties
    private(set) var contentViewController: UIViewController?
    private var observations: [NSKeyValueObservation] = []

    // MARK: - Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }

    // MARK: - Public Methods

    /// Устанавливает новый корневой контроллер.
    public func setContent(_ newContent: UIViewController) {
        let oldContent = contentViewController
        contentViewController = newContent
        observations.removeAll()
        setupProxying(for: newContent)

        // Уведомляем систему, что параметры (Status Bar, Orientation) изменились.
        // Так как contentViewController уже обновлен, система опросит новый контроллер.
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()

        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }

        transition(from: oldContent, to: newContent)
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

        // Title контроллера
        bind(from: child, to: self, \.title)

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

    func bind<Root: SystemDefaultProvider, Value: Equatable>(
        from source: Root,
        to target: Root,
        _ keyPath: ReferenceWritableKeyPath<Root, Value>
    ) where Root.Value == Root {
        // Smart Merge (Initial Sync)
        let systemDefaultValue = Root.systemDefault[keyPath: keyPath]

        if target[keyPath: keyPath] == systemDefaultValue {
            target[keyPath: keyPath] = source[keyPath: keyPath]
        }

        // KVO Подписка
        let observation = source.observe(keyPath, options: [.new]) { [weak target] _, change in
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

    // --- Transition ---
    open override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { contentViewController?.transitioningDelegate ?? super.transitioningDelegate }
        set { super.transitioningDelegate = newValue }
    }
}
