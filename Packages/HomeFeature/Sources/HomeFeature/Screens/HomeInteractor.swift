//
//  HomeInteractor.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

@MainActor
protocol HomeInteracting: AnyObject {
    var orderID: Int { get }
    func fetchData(completion: @escaping () -> Void)
}

final class HomeInteractor {

    init(service: HomeServicing) {
        self.service = service
    }

    // MARK: - Private properties

    private let service: HomeServicing
}

extension HomeInteractor: HomeInteracting {
    var orderID: Int {
        Int.random(in: 1...1000000)
    }

    func fetchData(completion: @escaping () -> Void) {
        Task {
            await service.fetchHomeData()
            completion()
        }
    }
}
