//
//  ParentViewController.swift
//  Core
//
//  Created by Любченко Станислав Валерьевич on 22.01.2026.
//

import UIKit

open class ParentViewController: UIViewController {

    public override var navigationItem: UINavigationItem {
        childVC?.navigationItem ?? super.navigationItem
    }

    public override var childForStatusBarStyle: UIViewController? {
        return childVC
    }

    public override var childForStatusBarHidden: UIViewController? {
        return childVC
    }

    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        return childVC
    }

    public override var hidesBottomBarWhenPushed: Bool {
        get { childVC?.hidesBottomBarWhenPushed ?? super.hidesBottomBarWhenPushed }
        set {
            guard let childVC else {
                super.hidesBottomBarWhenPushed = newValue
                return
            }

            childVC.hidesBottomBarWhenPushed = newValue
        }
    }

    public func putChildViewController(_ viewController: UIViewController) {
        childVC = viewController
        setupChildViewController(viewController)
        setupBindings()
    }

    // MARK: - Private members

    private var childVC: UIViewController?
    private var observations: [NSKeyValueObservation] = []

    private func setupBindings() {
        guard let childVC else { return }

        observations.removeAll()

        let titleObs = childVC.observe(\.title, options: [.new]) { [weak self] _, change in
            self?.title = change.newValue as? String
            // Иногда нужно принудительно пнуть навигейшн, если он не подхватил
            self?.navigationController?.navigationBar.setNeedsLayout()
        }

        // Следим за элементами тулбара (внизу)
        let toolbarObs = childVC.observe(\.toolbarItems, options: [.new]) { [weak self] _, change in
            self?.setToolbarItems(change.newValue as? [UIBarButtonItem], animated: true)
        }

        // Следим за размером (важно для popover / bottom sheet)
        let sizeObs = childVC.observe(\.preferredContentSize, options: [.new]) { [weak self] _, change in
            guard let newSize = change.newValue else { return }
            self?.preferredContentSize = newSize
        }

        // Сохраняем подписки, чтобы они жили, пока живет контроллер
        observations = [titleObs, toolbarObs, sizeObs]
    }
}
