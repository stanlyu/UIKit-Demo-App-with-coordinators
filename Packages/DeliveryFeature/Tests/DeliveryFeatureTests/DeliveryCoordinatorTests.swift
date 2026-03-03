import UIKit
import Testing
@testable import Core
@testable import DeliveryFeature

@MainActor
struct DeliveryCoordinatorTests {
    @Test
    func start_pushesPickupPointsRootWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(with: sut.router)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].item.viewController === sut.composer.pickupPointsViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func addPickupPointEvent_pushesAddScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.pickupPointsEventHandler?(.onAddPickupPoint)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].item.viewController === sut.composer.addPickupPointViewController)
        #expect(sut.router.pushCalls[1].animated == true)
    }

    @Test
    func addPickupPointBackEvent_popsCurrentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)
        sut.composer.pickupPointsEventHandler?(.onAddPickupPoint)

        sut.composer.addPickupPointEventHandler?(.onBackTap)

        #expect(sut.router.popCalls == [true])
    }

    @Test
    func favoriteDeleteRequest_presentsConfirmationAnimated() {
        let sut = makeSUT()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")
        let input = MockPickupPointsInput()

        sut.coordinator.start(with: sut.router)
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        #expect(sut.router.presentedItem?.viewController === sut.composer.deleteConfirmationViewController)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func favoriteDeleteRequest_passesRequestedPickupPointToComposer() {
        let sut = makeSUT()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")
        let input = MockPickupPointsInput()

        sut.coordinator.start(with: sut.router)
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        #expect(sut.composer.deleteConfirmationRequestedPickupPoint == pickupPoint)
    }

    @Test
    func favoriteDeleteConfirmation_callsInputConfirmDelete() {
        let sut = makeSUT()
        let input = MockPickupPointsInput()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")

        sut.coordinator.start(with: sut.router)
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        sut.composer.deleteConfirmationOnConfirm?()
        #expect(input.confirmedPickupPoint == pickupPoint)
    }
}

@MainActor
private extension DeliveryCoordinatorTests {
    struct SUT {
        let coordinator: DeliveryCoordinatingLogic<MockStackRouter>
        let composer: MockDeliveryComposer
        let router: MockStackRouter
    }

    func makeSUT() -> SUT {
        let composer = MockDeliveryComposer()
        let router = MockStackRouter()
        let coordinator = DeliveryCoordinatingLogic<MockStackRouter>(
            composer: composer
        )
        return SUT(coordinator: coordinator, composer: composer, router: router)
    }
}

@MainActor
private final class MockDeliveryComposer: DeliveryComposing {
    let pickupPointsViewController = UIViewController()
    let addPickupPointViewController = UIViewController()
    let deleteConfirmationViewController = UIViewController()

    var pickupPointsEventHandler: PickupPointsEventHandler?
    var addPickupPointEventHandler: AddPickupPointEventHandler?

    private(set) var deleteConfirmationRequestedPickupPoint: PickupPoint?
    var deleteConfirmationOnConfirm: (() -> Void)?

    func makeViewController(for route: DeliveryRoute, capability: ComposeCapability) -> UIViewController {
        switch route {
        case .pickupPoints(let eventHandler):
            pickupPointsEventHandler = eventHandler
            return pickupPointsViewController
        case .addPickupPoint(let eventHandler):
            addPickupPointEventHandler = eventHandler
            return addPickupPointViewController
        case .deleteConfirmation(let pickupPoint, let onConfirm):
            deleteConfirmationRequestedPickupPoint = pickupPoint
            deleteConfirmationOnConfirm = onConfirm
            return deleteConfirmationViewController
        }
    }
}

@MainActor
private final class MockPickupPointsInput: PickupPointsInput {
    private(set) var confirmedPickupPoint: PickupPoint?

    func confirmDeleteFavoritePickupPoint(_ pickupPoint: PickupPoint) {
        confirmedPickupPoint = pickupPoint
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
    private(set) var popCalls: [Bool] = []

    private(set) var presentedItem: RouterItem?
    private(set) var presentedAnimated: Bool = false

    func push(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(item: item, animated: animated))
        items.append(item)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        popCalls.append(animated)
        if items.isEmpty == false {
            _ = items.removeLast()
        }
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

    func present(_ item: RouterItem, animated: Bool, completion: (() -> Void)?) {
        presentedItem = item
        presentedAnimated = animated
        completion?()
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
}
