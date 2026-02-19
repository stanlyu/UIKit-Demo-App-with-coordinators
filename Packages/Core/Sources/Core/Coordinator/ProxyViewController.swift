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
public class ProxyViewController: UIViewController {

    // MARK: - Init

    internal override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupProtection()
    }

    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        if let content = contentViewController {
            // from: nil, так как это первичная установка
            transition(from: nil, to: content)
        }
    }

    // MARK: - Public Methods

    /// Устанавливает новый контент и синхронизирует состояние прокси с ним.
    internal func setContent(_ newContent: UIViewController) {
        let oldContent = contentViewController
        contentViewController = newContent
        // Сбрасываем только подписки на старый контент
        syncObservations.removeAll()

        // Настраиваем новые подписки (Content -> Proxy)
        setupSync(for: newContent)

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

        // Визуальный переход делаем ТОЛЬКО если view уже загружена.
        // Если это вызов из init, то isViewLoaded == false, и мы пропускаем этот шаг.
        // Он выполнится автоматически во viewDidLoad.
        if isViewLoaded {
            transition(from: oldContent, to: newContent)
        }
    }

    /// Метод перехода от старого контроллера к новому.
    /// По умолчанию выполняет мгновенную замену.
    /// Переопредели этот метод для добавления анимаций (CrossDissolve, Slide и т.д.).
    internal func transition(from oldViewController: UIViewController?, to newViewController: UIViewController) {
        if let old = oldViewController {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        setupChildViewController(newViewController)
    }

    // MARK: - Private Properties

    private(set) var contentViewController: UIViewController?

    /// Флаг, разрешающий изменение свойств.
    /// true = изменение идет от механизма синхронизации (легально).
    /// false = изменение идет извне (ошибка разработчика).
    private var isSyncingContent: Bool = false

    /// Наблюдатели защиты (живут вечно, следят за self)
    private var protectionObservations: [NSKeyValueObservation] = []

    /// Наблюдатели синхронизации (живут пока жив контент, следят за contentVC)
    private var syncObservations: [NSKeyValueObservation] = []
}

// MARK: - Protection Logic (Self Observation)
private extension ProxyViewController {

    /// Устанавливает "сигнализацию" на свойства самого Proxy.
    /// Вызывается один раз в init.
    func setupProtection() {
        // 1. Свойства UIViewController
        protect(self, \.hidesBottomBarWhenPushed)
        protect(self, \.definesPresentationContext)
        protect(self, \.providesPresentationContextTransitionStyle)
        protect(self, \.restoresFocusAfterTransition)
        protect(self, \.isModalInPresentation)
        protect(self, \.modalPresentationStyle)
        protect(self, \.modalTransitionStyle)
        protect(self, \.overrideUserInterfaceStyle)
        protect(self, \.edgesForExtendedLayout)
        protect(self, \.extendedLayoutIncludesOpaqueBars)

        // 2. Navigation Item
        // Примечание: Обращение к self.navigationItem создает его, если его не было.
        // Для Proxy это нормально, так как он все равно будет мимикрировать.
        let nav = self.navigationItem
        protect(nav, \.title)
        protect(nav, \.prompt)
        protect(nav, \.titleView)
        protect(nav, \.largeTitleDisplayMode)

        // Buttons
        protect(nav, \.rightBarButtonItem)
        protect(nav, \.rightBarButtonItems)
        protect(nav, \.leftBarButtonItem)
        protect(nav, \.leftBarButtonItems)

        // Back Button
        protect(nav, \.hidesBackButton)
        protect(nav, \.backBarButtonItem)
        protect(nav, \.leftItemsSupplementBackButton)
        protect(nav, \.backButtonTitle)
        protect(nav, \.backButtonDisplayMode)

        if #available(iOS 16.0, *) {
            protect(nav, \.backAction)
        }

        // Search
        protect(nav, \.searchController)
        protect(nav, \.hidesSearchBarWhenScrolling)

        if #available(iOS 16.0, *) {
            protect(nav, \.preferredSearchBarPlacement)
        }

        // Appearance
        protect(nav, \.standardAppearance)
        protect(nav, \.compactAppearance)
        protect(nav, \.scrollEdgeAppearance)
        protect(nav, \.compactScrollEdgeAppearance)

        // 3. Toolbar & TabBar

        protect(self, \.toolbarItems)

        if let tab = self.tabBarItem {
            protect(tab, \.badgeValue)
            protect(tab, \.title)
            protect(tab, \.image)
            protect(tab, \.selectedImage)

            protect(tab, \.standardAppearance)
            protect(tab, \.scrollEdgeAppearance)
        }
    }

    func protect<Root: NSObject, Value>(_ target: Root, _ keyPath: KeyPath<Root, Value>) {
        let observation = target.observe(keyPath, options: [.new]) { [weak self] _, _ in
            guard let self = self else { return }

            // Если изменение происходит НЕ внутри механизма синхронизации — это атака извне.
            if !self.isSyncingContent {
                let property = String(describing: keyPath)
                let message = """
                🛑 ОШИБКА КОНФИГУРАЦИИ \(type(of: self)):
                
                Вы попытались изменить свойство `\(property)` напрямую у \(type(of: self)).
                
                Почему это ошибка:
                \(type(of: self)) — это Proxy ("зеркало"). Он не хранит своего состояния.
                Любое значение, которое вы установите сейчас, будет молча перезаписано
                значением из ContentViewController, как только он загрузится.
                
                Как исправить:
                Настраивайте `\(property)` у того контроллера, который вы показываете (Content).
                """
                assertionFailure(message)
            }
        }
        protectionObservations.append(observation)
    }
}

// MARK: - Sync Logic (Content Observation)
private extension ProxyViewController {
    // Настраивает одностороннюю синхронизацию Content -> Proxy.
    func setupSync(for child: UIViewController) {

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
        let observation = source.observe(keyPath, options: [.initial, .new]) { [weak self, weak target] _, change in
            guard let self = self, let target = target, let newValue = change.newValue else { return }

            self.isSyncingContent = true
            target[keyPath: keyPath] = newValue
            self.isSyncingContent = false
        }
        syncObservations.append(observation)
    }
}

// MARK: - System Overrides
extension ProxyViewController {

    // --- Status Bar ---
    public override var childForStatusBarStyle: UIViewController? {
        contentViewController
    }

    public override var childForStatusBarHidden: UIViewController? {
        contentViewController
    }
    
    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        contentViewController
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        contentViewController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }

    // --- Orientation ---
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        contentViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        contentViewController?.preferredInterfaceOrientationForPresentation
        ??
        super.preferredInterfaceOrientationForPresentation
    }

    public override var shouldAutorotate: Bool {
        contentViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    // --- System Gestures ---
    public override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
        contentViewController
    }

    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        contentViewController?.preferredScreenEdgesDeferringSystemGestures ?? super.preferredScreenEdgesDeferringSystemGestures
    }

    // --- Transition ---
    public override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { contentViewController?.transitioningDelegate ?? super.transitioningDelegate }
        set { super.transitioningDelegate = newValue }
    }
}
