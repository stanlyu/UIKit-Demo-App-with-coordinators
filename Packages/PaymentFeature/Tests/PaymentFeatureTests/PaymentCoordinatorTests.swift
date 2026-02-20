import UIKit
import Testing
@testable import Core
@testable import PaymentFeature

@MainActor
struct PaymentCoordinatorTests {
    @Test
    func start_pushesPaymentScreenWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].viewController === sut.composer.paymentViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func backTap_forwardsCancelledEventToModuleOutput() {
        var receivedEvents: [PaymentEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)

        sut.composer.paymentEventHandler?(.onBackTap)

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .cancelled")
            return
        }
        guard case .cancelled = event else {
            Issue.record("Ожидалось событие .cancelled")
            return
        }
    }

    @Test
    func paymentCompleted_forwardsCompletedResultToModuleOutput() {
        var receivedEvents: [PaymentEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        let result = PaymentResult.failure(amount: 2500, error: .processingTimeout)

        sut.coordinator.start(with: sut.router)
        sut.composer.paymentEventHandler?(.onPaymentCompleted(result))

        guard let event = receivedEvents.last else {
            Issue.record("Не получено событие .completed")
            return
        }
        guard case let .completed(receivedResult) = event else {
            Issue.record("Ожидалось событие .completed")
            return
        }
        guard case let .failure(amount, error) = receivedResult else {
            Issue.record("Ожидался failure результат")
            return
        }
        #expect(amount == 2500)
        #expect(error == .processingTimeout)
    }
}

@MainActor
private extension PaymentCoordinatorTests {
    struct SUT {
        let coordinator: PaymentCoordinatingLogic<MockStackRouter>
        let composer: MockPaymentComposer
        let router: MockStackRouter
    }

    func makeSUT(eventHandler: @escaping (PaymentEvent) -> Void = { _ in }) -> SUT {
        let composer = MockPaymentComposer()
        let router = MockStackRouter()
        let coordinator = PaymentCoordinatingLogic<MockStackRouter>(composer: composer, eventHandler: eventHandler)
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockPaymentComposer: PaymentComposing {
    let paymentViewController = UIViewController()
    var paymentEventHandler: PaymentEventHandler?

    func makePaymentViewController(with eventHandler: @escaping PaymentEventHandler) -> UIViewController {
        paymentEventHandler = eventHandler
        return paymentViewController
    }
}

@MainActor
private final class MockStackRouter: UIViewController, StackRouting {
    struct PushCall {
        let viewController: UIViewController
        let animated: Bool
    }

    var viewControllers: [UIViewController] = []
    private(set) var pushCalls: [PushCall] = []

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(viewController: viewController, animated: animated))
        viewControllers.append(viewController)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popTo(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func setStack(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }
}
