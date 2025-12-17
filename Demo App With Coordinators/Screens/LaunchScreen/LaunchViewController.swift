//
//  LaunchViewController.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 16.12.2025.
//

import UIKit

protocol LaunchViewInput: AnyObject {
    func startAnimation()
    func stopAnimation()
}

class LaunchViewController: UIViewController {

    var output: LaunchViewOutput?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        let label = UILabel()
        view.addSubview(label)
        label.text = "Demo Application"
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        output?.viewDidLoad()
    }
}

extension LaunchViewController: LaunchViewInput {
    func startAnimation() {
        #warning("TODO: Implement startAnimation")
    }

    func stopAnimation() {
        #warning("TODO: Implement stopAnimation")
    }
}
