//
//  AddPickupPointsViewController.swift
//  DeliveryFeature
//
//  Created by Любченко Станислав Валерьевич on 22.12.2025.
//

import UIKit

class AddPickupPointsViewController: UIViewController {

    let viewOutput: AddPickupPointsViewOutput

    init(viewOutput: AddPickupPointsViewOutput) {
        self.viewOutput = viewOutput
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        title = "Добавить ПВЗ"

        if #available(iOS 16.0, *) {
            navigationItem.backAction = UIAction { [weak self] _ in
                self?.viewOutput.backButtonDidTap()
            }
        } else {
            let backButton = UIBarButtonItem(
                    image: UIImage(systemName: "chevron.left"),
                    style: .plain,
                    target: self,
                    action: #selector(handleBackButtonTap)
                )

                navigationItem.leftBarButtonItem = backButton
                navigationController?.interactivePopGestureRecognizer?.delegate = self
        }
    }

    // MARK: - Private members

    @objc private func handleBackButtonTap() {
        viewOutput.backButtonDidTap()
    }
}

extension AddPickupPointsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
