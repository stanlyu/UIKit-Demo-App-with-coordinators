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
        #expect(sut.router.pushCalls[0].item.viewController === sut.paymentViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func backTap_forwardsCancelledEventToModuleOutput() {
        var receivedEvents: [PaymentEvent] = []
        let sut = makeSUT(eventHandler: { receivedEvents.append($0) })
        sut.coordinator.start(with: sut.router)

        sut.paymentEventHandler(.onBackTap)

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
        sut.paymentEventHandler(.onPaymentCompleted(result))

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
        let router: MockStackRouter
        let paymentViewController: UIViewController
        let paymentEventHandler: @escaping (PaymentEventHandler)
    }

    func makeSUT(eventHandler: @escaping (PaymentEvent) -> Void = { _ in }) -> SUT {
        let router = MockStackRouter()
        let vc = UIViewController()
        var extractedEventHandler: PaymentEventHandler?
        
        let coordinator = PaymentCoordinatingLogic<MockStackRouter>(
            eventHandler: eventHandler,
            buildBlock: { @MainActor route in
                if case .payment(let handler) = route {
                    extractedEventHandler = handler
                }
                return vc
            }
        )
        return SUT(
            coordinator: coordinator,
            router: router,
            paymentViewController: vc,
            paymentEventHandler: { extractedEventHandler?($0) }
        )
    }
}

@MainActor
private final class MockStackRouter: StackRouting {
    var root: RouterRoot { RouterRoot(UIViewController()) }
    func extractRootUI() -> UIViewController { return UIViewController() }

    struct PushCall {
        let item: RouterItem
        let animated: Bool
    }

    var items: [RouterItem] = []
    private(set) var pushCalls: [PushCall] = []

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(item: item, animated: animated))
        items.append(item)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popToRoot(animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        completion?()
    }

    func setStack(_ items: [RouterItem], animated: Bool) {
        self.items = items
    }
    
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
