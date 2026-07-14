import UIKit
import Testing
@testable import Core
@testable import DeliveryFeature

@MainActor
struct DeliveryCoordinatorTests {
    @Test
    func start_setsPickupPointsRootWithoutAnimation() {
        let sut = makeSUT()

        sut.coordinator.start(CoordinatorStartContext())

        #expect(sut.router.setRootCalls.count == 1)
        #expect(sut.router.setRootCalls[0].item.isWrapping(sut.composer.pickupPointsViewController))
        #expect(sut.router.setRootCalls[0].animated == false)
    }

    @Test
    func addPickupPointEvent_pushesAddScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())

        sut.composer.pickupPointsEventHandler?(.onAddPickupPoint)

        #expect(sut.router.pushCalls.count == 1)
        #expect(sut.router.pushCalls[0].item.isWrapping(sut.composer.addPickupPointViewController))
        #expect(sut.router.pushCalls[0].animated == true)
    }

    @Test
    func addPickupPointBackEvent_popsCurrentScreen() {
        let sut = makeSUT()
        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.pickupPointsEventHandler?(.onAddPickupPoint)

        sut.composer.addPickupPointEventHandler?(.onBackTap)

        #expect(sut.router.popCalls == [true])
    }

    @Test
    func favoriteDeleteRequest_presentsConfirmationAnimated() {
        let sut = makeSUT()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")
        let input = MockPickupPointsInput()

        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        #expect(sut.router.presentedItem?.isWrapping(sut.composer.deleteConfirmationViewController) == true)
        #expect(sut.router.presentedAnimated == true)
    }

    @Test
    func favoriteDeleteRequest_passesRequestedPickupPointToComposer() {
        let sut = makeSUT()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")
        let input = MockPickupPointsInput()

        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        #expect(sut.composer.deleteConfirmationRequestedPickupPoint == pickupPoint)
    }

    @Test
    func favoriteDeleteConfirmation_callsInputConfirmDelete() {
        let sut = makeSUT()
        let input = MockPickupPointsInput()
        let pickupPoint = PickupPoint(id: 7, name: "ПВЗ 7")

        sut.coordinator.start(CoordinatorStartContext())
        sut.composer.pickupPointsEventHandler?(.onFavoriteDeleteRequested(pickupPoint: pickupPoint, input: input))

        sut.composer.deleteConfirmationOnConfirm?()
        #expect(input.confirmedPickupPoint == pickupPoint)
    }
}

@MainActor
private extension DeliveryCoordinatorTests {
    struct SUT {
        let coordinator: DeliveryCoordinatingLogic
        let composer: MockDeliveryComposer
        let router: MockStackRouter
    }

    func makeSUT() -> SUT {
        let composer = MockDeliveryComposer()
        let router = MockStackRouter()
        let coordinator = DeliveryCoordinatingLogic(
            router: router,
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

    func makeViewController(for route: DeliveryRoute) -> UIViewController {
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
private final class MockStackRouter: StackNavigation {
    struct PushCall {
        let item: RouterItem
        let animated: Bool
    }

    var items: [RouterItem] = []

    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []

    private(set) var presentedItem: RouterItem?
    private(set) var presentedAnimated: Bool = false

    struct SetRootCall {
        let item: RouterItem
        let animated: Bool
    }
    private(set) var setRootCalls: [SetRootCall] = []

    func setRoot(_ item: RouterItem, animated: Bool) {
        setRootCalls.append(SetRootCall(item: item, animated: animated))
        items = [item]
    }

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
