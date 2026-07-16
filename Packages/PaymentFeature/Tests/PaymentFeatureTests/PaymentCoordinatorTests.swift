import UIKit
import Testing
@testable import Core
@testable import PaymentFeature

@MainActor
struct PaymentCoordinatorTests {
    @Test
    func start_setsPaymentScreenWithoutAnimation() {
        // arrange
        let sut = makeSUT()

        // act
        sut.coordinator.start(CoordinatorStartContext())

        // assert
        #expect(sut.router.setRootCalls.count == 1)
        #expect(sut.router.setRootCalls[0].item.isWrapping(sut.paymentViewController))
        #expect(sut.router.setRootCalls[0].animated == false)
    }

    @Test
    func backTap_forwardsCancelledEventToModuleOutput() {
        // arrange
        var receivedEvents: [PaymentNavigationOutputEvent] = []
        let sut = makeSUT(onEvent: { receivedEvents.append($0) })

        // act
        sut.coordinator.start(CoordinatorStartContext())
        sut.paymentEventHandler(.onBackTap)

        // assert
        if case .cancelled = receivedEvents.last {
            #expect(true)
        } else {
            #expect(false, "Ожидалось событие .cancelled")
        }
    }

    @Test
    func paymentCompleted_forwardsCompletedResultToModuleOutput() {
        // arrange
        var receivedEvents: [PaymentNavigationOutputEvent] = []
        let sut = makeSUT(onEvent: { receivedEvents.append($0) })
        let result = PaymentResult.failure(amount: 2500, error: .processingTimeout)

        // act
        sut.coordinator.start(CoordinatorStartContext())
        sut.paymentEventHandler(.onPaymentCompleted(result))

        // assert
        if case let .completed(receivedResult) = receivedEvents.last,
           case let .failure(amount, error) = receivedResult {
            #expect(amount == 2500)
            #expect(error == .processingTimeout)
        } else {
            #expect(false, "Ожидалось событие .completed(.failure)")
        }
    }
}

@MainActor
private extension PaymentCoordinatorTests {
    struct SUT {
        let coordinator: PaymentCoordinatingLogic
        let router: MockStackRouter
        let paymentViewController: UIViewController
        let paymentEventHandler: PaymentPresenterEventHandler
    }

    func makeSUT(onEvent: @escaping (PaymentNavigationOutputEvent) -> Void = { _ in }) -> SUT {
        let router = MockStackRouter()
        let vc = UIViewController()
        var extractedEventHandler: PaymentPresenterEventHandler?

        let composer = InlineComposer<PaymentRoute> { @MainActor route in
            if case .payment(let handler) = route {
                extractedEventHandler = handler
            }
            return vc
        }
        let coordinator = PaymentCoordinatingLogic(
            router: router,
            composer: composer,
            onEvent: onEvent
        )
        return SUT(
            coordinator: coordinator,
            router: router,
            paymentViewController: vc,
            paymentEventHandler: { extractedEventHandler?($0) }
        )
    }
}

// Записывающий роутер для `StackNavigation`. В тестах payment проверяется
// только `setRootCalls`; остальные команды стека — no-op заглушки.
@MainActor
private final class MockStackRouter: StackNavigation {
    struct PushCall {
        let item: RouterItem
        let animated: Bool
    }

    struct SetRootCall {
        let item: RouterItem
        let animated: Bool
    }

    private(set) var setRootCalls: [SetRootCall] = []
    private(set) var pushCalls: [PushCall] = []

    var items: [RouterItem] = []

    func setRoot(_ item: RouterItem, animated: Bool) {
        setRootCalls.append(SetRootCall(item: item, animated: animated))
    }

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(item: item, animated: animated))
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) { completion?() }
    func popToRoot(animated: Bool, completion: (() -> Void)?) { completion?() }
    func popTo(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) { completion?() }
    func setStack(_ items: [RouterItem], animated: Bool) {}
    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {}
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
