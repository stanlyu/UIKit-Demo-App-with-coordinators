//
//  HomePresenter.swift
//  HomeFeature
//
//  Created by Любченко Станислав Валерьевич on 19.12.2025.
//

@MainActor
protocol HomeViewOutput: AnyObject {
    func viewDidLoad()
    func orderButtonTapped()
}

final class HomePresenter {
    weak var view: HomeView?

    init(interactor: HomeInteracting, onEvent: @escaping (HomeScreenEvent) -> Void) {
        self.interactor = interactor
        self.onEvent = onEvent
    }

    // MARK: - Private properties

    private let interactor: HomeInteracting
    private let onEvent: (HomeScreenEvent) -> Void
}

extension HomePresenter: HomeViewOutput {
    func viewDidLoad() {
        view?.startLoading()
        
        interactor.fetchData { [unowned self] in
            self.view?.stopLoading()
        }
    }

    func orderButtonTapped() {
        onEvent(.placeOrder(Int.random(in: 1...1000000)))
    }
}
