//
//  LaunchInteractor.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import Foundation

@MainActor
protocol LaunchInteracting: AnyObject {
    func fetchData(completion: @escaping () -> Void)
}

final class LaunchInteractor {
    init(service: LaunchServicing) {
        self.service = service
    }

    // MARK: - Private properties

    private let service: LaunchServicing
}

extension LaunchInteractor: LaunchInteracting {
    func fetchData(completion: @escaping () -> Void) {
        Task {
            await service.fetchData()
            completion()
        }
    }
}
