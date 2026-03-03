//
//  SwitchRouter.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 12.02.2026.
//

import UIKit

import ObjectiveC

/// Роутер переключения контента с поддержкой анимированных переходов.
@MainActor
public final class SwitchRouter: SwitchRouting {
    public init<C: Coordinating>(
        coordinator: C,
        lifecycleManager: any LifecycleManaging = AssociatedObjectLifecycleManager()
    ) where C.R == SwitchRouter {
        self.lifecycleManager = lifecycleManager
        self._startCoordinator = { router in
            coordinator.start(with: router)
        }
    }

    /// Возвращает текущий UIViewController, которым управляет роутер.
    ///
    /// - Returns: Корневой `UIViewController` для отображения в окне или иерархии вью.
    /// - Warning: Приводит к fatalError, если контент не был установлен перед вызовом.
    public func extractRootUI() -> UIViewController {
        _startCoordinator?(self)
        _startCoordinator = nil
        
        guard let vc = currentContent ?? unextractedContent else {
            fatalError("SwitchRouter has no content.")
        }
        unextractedContent = nil
        return vc
    }

    /// Переключает на новый корневой контроллер с возможностью анимации.
    ///
    /// - Parameters:
    ///   - item: `RouterItem`, оборачивающий новый `UIViewController`.
    ///   - animated: Использовать ли переходы при замене контента.
    ///   - completion: Замыкание, вызываемое после окончания анимации.
    public func setRoot(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        let newVC = item.viewController
        
        guard let oldVC = currentContent else {
            currentContent = newVC
            unextractedContent = newVC // Сохраняем сильную ссылку до момента вызова extractRootUI
            lifecycleManager.retain(self, to: newVC)
            completion?()
            return
        }
        
        self.oldContentRetainer = oldVC
        lifecycleManager.release(self, from: oldVC)
        
        self.currentContent = newVC
        lifecycleManager.retain(self, to: newVC)
        
        performTransition(from: oldVC, to: newVC, animated: animated) { [weak self] in
            self?.oldContentRetainer = nil
            completion?()
        }
    }

    private func performTransition(from oldVC: UIViewController, to newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        var responderContext: UIResponder? = oldVC.next
        var foundContext: UIResponder? = nil
        
        while let responder = responderContext {
            if responder is UIWindow || responder is UINavigationController || responder is UITabBarController || responder is UIViewController {
                foundContext = responder
                break
            }
            responderContext = responder.next
        }
        
        if let window = foundContext as? UIWindow {
            transitionInWindow(window: window, oldVC: oldVC, newVC: newVC, animated: animated, completion: completion)
        } else if let nav = foundContext as? UINavigationController {
            transitionInNavigationController(nav: nav, oldVC: oldVC, newVC: newVC, animated: animated, completion: completion)
        } else if let tab = foundContext as? UITabBarController {
            transitionInTabBarController(tab: tab, oldVC: oldVC, newVC: newVC, animated: animated, completion: completion)
        } else if let parentVC = foundContext as? UIViewController {
            transitionInParentViewController(parentVC: parentVC, oldVC: oldVC, newVC: newVC, animated: animated, completion: completion)
        } else if let presentingVC = oldVC.presentingViewController {
            transitionInPresentingViewController(presentingVC: presentingVC, oldVC: oldVC, newVC: newVC, animated: animated, completion: completion)
        } else {
            completion()
        }
    }

    private func transitionInWindow(window: UIWindow, oldVC: UIViewController, newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                let oldState = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(false)
                window.rootViewController = newVC
                UIView.setAnimationsEnabled(oldState)
            }, completion: { _ in
                completion()
            })
        } else {
            window.rootViewController = newVC
            completion()
        }
    }

    private func transitionInNavigationController(nav: UINavigationController, oldVC: UIViewController, newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        var viewControllers = nav.viewControllers
        if let index = viewControllers.firstIndex(of: oldVC) {
            viewControllers[index] = newVC
            nav.setViewControllers(viewControllers, animated: animated, completion: completion)
        } else {
            completion()
        }
    }

    private func transitionInTabBarController(tab: UITabBarController, oldVC: UIViewController, newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        var viewControllers = tab.viewControllers ?? []
        if let index = viewControllers.firstIndex(of: oldVC) {
            viewControllers[index] = newVC
            tab.setViewControllers(viewControllers, animated: animated)
            completion()
        } else {
            completion()
        }
    }

    private func transitionInParentViewController(parentVC: UIViewController, oldVC: UIViewController, newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        parentVC.addChild(newVC)
        newVC.view.frame = oldVC.view.frame
        newVC.view.alpha = 0
        parentVC.view.insertSubview(newVC.view, aboveSubview: oldVC.view)
        
        oldVC.willMove(toParent: nil)
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            newVC.view.alpha = 1
        }, completion: { _ in
            oldVC.view.removeFromSuperview()
            oldVC.removeFromParent()
            newVC.didMove(toParent: parentVC)
            completion()
        })
    }

    private func transitionInPresentingViewController(presentingVC: UIViewController, oldVC: UIViewController, newVC: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        oldVC.addChild(newVC)
        newVC.view.frame = oldVC.view.bounds
        newVC.view.alpha = 0
        oldVC.view.addSubview(newVC.view)
        
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            newVC.view.alpha = 1
        }, completion: { _ in
            let window = presentingVC.view.window ?? oldVC.view.window
            let snapshot = window?.snapshotView(afterScreenUpdates: false)
            if let snapshot = snapshot, let window = window {
                snapshot.frame = window.bounds
                window.addSubview(snapshot)
            }
            
            oldVC.dismiss(animated: false) {
                presentingVC.present(newVC, animated: false) {
                    snapshot?.removeFromSuperview()
                    completion()
                }
            }
        })
    }

    // MARK: - Private members

    private weak var currentContent: UIViewController?
    private let lifecycleManager: any LifecycleManaging
    private var oldContentRetainer: UIViewController?
    private var unextractedContent: UIViewController?
    private var _startCoordinator: ((SwitchRouter) -> Void)?
}
