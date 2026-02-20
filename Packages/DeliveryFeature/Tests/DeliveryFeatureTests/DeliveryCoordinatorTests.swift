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
        #expect(sut.router.pushCalls[0].viewController === sut.composer.pickupPointsViewController)
        #expect(sut.router.pushCalls[0].animated == false)
    }

    @Test
    func addPickupPointEvent_pushesAddScreenAnimated() {
        let sut = makeSUT()
        sut.coordinator.start(with: sut.router)

        sut.composer.pickupPointsEventHandler?(.onAddPickupPoint)

        #expect(sut.router.pushCalls.count == 2)
        #expect(sut.router.pushCalls[1].viewController === sut.composer.addPickupPointViewController)
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

        #expect(sut.router.presentedController === sut.composer.deleteConfirmationViewController)
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
        let coordinator = DeliveryCoordinatingLogic<MockStackRouter>(composer: composer)
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

    func makePickupPointsViewController(with eventHandler: @escaping PickupPointsEventHandler) -> UIViewController {
        pickupPointsEventHandler = eventHandler
        return pickupPointsViewController
    }

    func makePickupPointsNavigationController(with eventHandler: @escaping PickupPointsEventHandler) -> UINavigationController {
        pickupPointsEventHandler = eventHandler
        return UINavigationController(rootViewController: pickupPointsViewController)
    }

    func makeAddPickupPointViewController(with eventHandler: @escaping AddPickupPointEventHandler) -> UIViewController {
        addPickupPointEventHandler = eventHandler
        return addPickupPointViewController
    }

    func makeFavoritePickupPointDeleteConfirmationViewController(
        pickupPoint: PickupPoint,
        onConfirm: @escaping () -> Void
    ) -> UIViewController {
        deleteConfirmationRequestedPickupPoint = pickupPoint
        deleteConfirmationOnConfirm = onConfirm
        return deleteConfirmationViewController
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
private final class MockStackRouter: UIViewController, StackRouting {
    struct PushCall {
        let viewController: UIViewController
        let animated: Bool
    }

    var viewControllers: [UIViewController] = []

    private(set) var pushCalls: [PushCall] = []
    private(set) var popCalls: [Bool] = []

    private(set) var presentedController: UIViewController?
    private(set) var presentedAnimated: Bool = false

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCalls.append(PushCall(viewController: viewController, animated: animated))
        viewControllers.append(viewController)
        completion?()
    }

    func pop(animated: Bool, completion: (() -> Void)?) {
        popCalls.append(animated)
        if viewControllers.isEmpty == false {
            _ = viewControllers.removeLast()
        }
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

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedController = viewControllerToPresent
        presentedAnimated = flag
        completion?()
    }
}
