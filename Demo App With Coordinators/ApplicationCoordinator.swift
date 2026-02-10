//
//  ApplicationCoordinator.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import UIKit
import Core

final class ApplicationCoordinator: ProxyViewController {

    init(composer: ApplicationComposing = ApplicationComposer()) {
        self.composer = composer
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Запускаем первый экран (Launch)
        let launchVC = composer.makeLaunchViewController { [unowned self] event in
            self.handleLaunchEvent(event)
        }
        setContent(launchVC)
    }

    // MARK: - Transition Logic override

    override func transition(from oldViewController: UIViewController?, to newViewController: UIViewController) {
        // Если старого нет (первый запуск), просто показываем новый
        guard let oldViewController = oldViewController else {
            setupChildViewController(newViewController)
            return
        }

        // 1. Подготовка нового
        addChild(newViewController)
        setupChildView(newViewController.view)
        newViewController.view.alpha = 0
        view.layoutIfNeeded()

        // 2. Сообщаем старому, что он уйдет
        oldViewController.willMove(toParent: nil)

        // 3. Анимация
        UIView.animate(withDuration: 0.3, animations: {
            newViewController.view.alpha = 1
        }, completion: { finished in
            // 4. Зачистка старого
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()

            // 5. Финализация нового
            newViewController.didMove(toParent: self)
        })
    }

    // MARK: - Private members

    private let composer: ApplicationComposing

    private func setupChildView(_ childView: UIView) {
        view.addSubview(childView)

        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func handleLaunchEvent(_ event: LaunchScreenEvent) {
        switch event {
        case .mainFlowStarted:
            setContent(composer.makeMainTabsViewController())
        }
    }
}
