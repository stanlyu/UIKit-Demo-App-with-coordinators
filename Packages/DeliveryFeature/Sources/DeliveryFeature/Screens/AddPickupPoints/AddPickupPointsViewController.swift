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
        navigationItem.backBarButtonItem = UIBarButtonItem(primaryAction: UIAction(handler: { [unowned self] _ in
            self.viewOutput.backButtonDidTap()
        }))
    }
}
