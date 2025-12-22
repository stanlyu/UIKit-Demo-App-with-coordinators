//
//  LaunchInteractor.swift
//  Demo App With Coordinators
//
//  Created by Любченко Станислав Валерьевич on 17.12.2025.
//

import Foundation

enum LaunchInteractingState {
    case loading
    case loaded
}

protocol LaunchInteracting: AnyObject {
    func start(handler: @escaping (LaunchInteractingState) -> Void)
}

final class LaunchInteractor {
    init() {
        let (stream, continuation) = AsyncStream<LaunchInteractingState>.makeStream()
        stateStream = stream
        self.continuation = continuation
    }

    // MARK: - Private properties

    private let stateStream: AsyncStream<LaunchInteractingState>
    private let continuation: AsyncStream<LaunchInteractingState>.Continuation
}

extension LaunchInteractor: LaunchInteracting {
    func start(handler: @escaping (LaunchInteractingState) -> Void) {
        Task {
            for await state in self.stateStream {
                handler(state)
            }
        }
        Task {
            continuation.yield(.loading)
            // Эмитируем загрузку необходимых данных для того, чтобы можно было обновить UI
            try? await Task.sleep(for: .seconds(5))
            continuation.yield(.loaded)
            continuation.finish()
        }
    }
}
