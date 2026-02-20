//
//  SwitchContainer.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

/// Контейнер переключения контента с поддержкой анимированных переходов.
///
/// Контейнер держит **ровно один** активный дочерний контроллер и умеет безопасно
/// заменять его на новый (с анимацией или без).
///
/// Чаще всего используется как root-контроллер окна приложения, но не ограничен этим сценарием:
/// его можно применять в любом месте, где нужен хост для последовательной смены одного контента другим.
///
/// - Note: **Конфигурация:** Этот контейнер проксирует свойства (ориентация экрана, статус бар) от своего текущего контента.
///   Настраивайте эти параметры в контроллерах, которые вы передаете в `setRoot`.
public final class SwitchContainer: ProxyViewController, SwitchRouting {

    /// Инициализирует контейнер с заданным координатором.
    /// - Parameter coordinator: Координатор, который будет управлять этим контейнером.
    public init(coordinator: Coordinator<SwitchContainer>) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.start(with: self)
    }

    // MARK: - Private members
    private let coordinator: Coordinator<SwitchContainer>
    private var pendingAnimated: Bool = false
    private var pendingCompletion: (() -> Void)?

    // MARK: - Switch Logic

    public func setRoot(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // Сохраняем флаги во временное состояние, так как setContent не принимает их.
        pendingAnimated = animated
        pendingCompletion = completion

        // Этот вызов триггерит метод transition(from:to:)
        setContent(viewController)
    }

    // MARK: - Transition Logic

    public override func transition(from oldViewController: UIViewController?, to newViewController: UIViewController) {
        let animated = pendingAnimated
        let completion = pendingCompletion

        pendingAnimated = false
        pendingCompletion = nil

        // Первичная установка (нет старого экрана). Анимация не требуется.
        guard let oldViewController = oldViewController else {
            setupChildViewController(newViewController)
            completion?()
            return
        }

        if !animated {
            oldViewController.willMove(toParent: nil)
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()

            setupChildViewController(newViewController)
            completion?()
            return
        }

        addChild(newViewController)
        newViewController.view.alpha = 0
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newViewController.view)

        NSLayoutConstraint.activate([
            newViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            newViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            newViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.layoutIfNeeded()

        oldViewController.willMove(toParent: nil)

        UIView.animate(withDuration: 0.3, animations: {
            newViewController.view.alpha = 1
        }, completion: { _ in
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()

            newViewController.didMove(toParent: self)
            completion?()
        })
    }
}
