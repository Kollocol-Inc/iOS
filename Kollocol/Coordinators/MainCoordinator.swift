//
//  MainCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import Mantis
import PhotosUI
import ObjectiveC

@MainActor
final class MainCoordinator {
    // MARK: - Constants
    private enum AssociatedKeys {
        static var avatarCropHandlerKey: UInt8 = 0
    }

    private enum Tab {
        case main
        case groups
        case myQuizzes
        case profile

        var title: String {
            switch self {
            case .main: return "Главная"
            case .groups: return "Группы"
            case .myQuizzes: return "Мои квизы"
            case .profile: return "Профиль"
            }
        }

        var imageName: String {
            switch self {
            case .main: return "house"
            case .groups: return "person.2"
            case .myQuizzes: return "gamecontroller"
            case .profile: return "person"
            }
        }

        var selectedImageName: String {
            switch self {
            case .main: return "house.fill"
            case .groups: return "person.2.fill"
            case .myQuizzes: return "gamecontroller.fill"
            case .profile: return "person.fill"
            }
        }
    }

    // MARK: - Properties
    private let tabBarController = UITabBarController()
    private let tabBarDelegateProxy = TabBarSlideDelegateProxy()
    private let navigationController: UINavigationController
    private let services: Services
    private let onFinish: () -> Void

    private var mainNavController: UINavigationController?
    private var groupsNavController: UINavigationController?
    private var myQuizzesNavController: UINavigationController?
    private var profileNavController: UINavigationController?
    private var quizWaitingRoomCoordinator: QuizWaitingRoomCoordinator?

    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        services: Services,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.services = services
        self.onFinish = onFinish
    }
    
    // MARK: - Methods
    func start() {
        navigationController.setNavigationBarHidden(true, animated: false)

        tabBarController.delegate = tabBarDelegateProxy

        let tabs = makeTabs()
        tabBarController.setViewControllers(tabs, animated: false)

        navigationController.setViewControllers([tabBarController], animated: true)
    }

    // MARK: - Private Methods
    private func finish() {
        onFinish()
    }

    private func makeTabs() -> [UIViewController] {
        let mainVC = MainAssembly.build(
            router: self,
            userService: services.userService,
            quizService: services.quizService,
            quizParticipationService: services.quizParticipationService
        )
        let mainNav = makeTabNavigationController(
            root: mainVC,
            tab: .main
        )
        mainNavController = mainNav

        let groupsVC = GroupsAssembly.build(router: self)
        let groupsNav = makeTabNavigationController(
            root: groupsVC,
            tab: .groups
        )
        groupsNavController = groupsNav

        let myQuizzesVC = MyQuizzesAssembly.build(
            router: self,
            quizService: services.quizService,
            mlService: services.mlService,
            quizParticipationService: services.quizParticipationService
        )
        let myQuizzesNav = makeTabNavigationController(
            root: myQuizzesVC,
            tab: .myQuizzes
        )
        myQuizzesNavController = myQuizzesNav

        let profileVC = ProfileAssembly.build(
            router: self,
            userService: services.userService,
            sessionManager: services.sessionManager,
            udService: services.udService
        )
        let profileNav = makeTabNavigationController(
            root: profileVC,
            tab: .profile
        )
        profileNavController = profileNav

        return [mainNav, groupsNav, myQuizzesNav, profileNav]
    }

    private func makeTabNavigationController(root: UIViewController, tab: Tab) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)

        let normalImage = UIImage(systemName: tab.imageName)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)

        let selectedImage = UIImage(systemName: tab.selectedImageName)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        let item = UITabBarItem(
            title: nil,
            image: normalImage,
            selectedImage: selectedImage
        )

        item.setTitleTextAttributes([.foregroundColor: UIColor.textSecondary], for: .normal)
        item.setTitleTextAttributes([.foregroundColor: UIColor.accentPrimary], for: .selected)

        nav.tabBarItem = item
        return nav
    }

    private func topMostViewController() -> UIViewController? {
        func resolve(from vc: UIViewController?) -> UIViewController? {
            if let presented = vc?.presentedViewController {
                return resolve(from: presented)
            }
            if let nav = vc as? UINavigationController {
                return resolve(from: nav.visibleViewController)
            }
            if let tab = vc as? UITabBarController {
                return resolve(from: tab.selectedViewController)
            }
            return vc
        }

        return resolve(from: navigationController)
    }

    private func myQuizzesViewController() -> MyQuizzesViewController? {
        guard let myQuizzesNavController else { return nil }
        return myQuizzesNavController.viewControllers.first { $0 is MyQuizzesViewController } as? MyQuizzesViewController
    }

    private func prepareMainLeftBarButtonForPushTransition() {
        guard let mainNavController else { return }
        guard let mainViewController = mainNavController.topViewController as? MainViewController else { return }
        mainViewController.prepareForForwardNavigationTransition()
    }

    private func pushQuizParticipantsOverviewScreen(
        on navigationController: UINavigationController,
        initialData: QuizParticipantsOverviewModels.InitialData
    ) {
        let viewController = QuizParticipantsOverviewAssembly.build(
            router: self,
            initialData: initialData,
            quizService: services.quizService
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    private func pushQuizParticipantReviewScreen(
        on navigationController: UINavigationController,
        initialData: QuizParticipantReviewModels.InitialData
    ) {
        let viewController = QuizParticipantReviewAssembly.build(
            router: self,
            initialData: initialData,
            quizService: services.quizService
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    private func startQuizWaitingRoom(
        on navigationController: UINavigationController,
        accessCode: String,
        startDestination: QuizWaitingRoomCoordinator.StartDestination = .waitingRoom
    ) {
        logQuizFlow(
            "startQuizWaitingRoom requested. accessCode=\(accessCode), " +
            "destination=\(startDestinationDescription(startDestination)), " +
            "navigation=\(String(describing: type(of: navigationController)))"
        )

        let coordinator = QuizWaitingRoomCoordinator(
            navigationController: navigationController,
            quizParticipationService: services.quizParticipationService,
            initialData: .init(accessCode: accessCode),
            startDestination: startDestination,
            onFinish: { [weak self] in
                self?.quizWaitingRoomCoordinator = nil
            }
        )

        quizWaitingRoomCoordinator = coordinator
        coordinator.start()
        logQuizFlow(
            "quiz waiting room coordinator started. destination=\(startDestinationDescription(startDestination))"
        )
    }

    private func logQuizFlow(_ message: String) {
        #if DEBUG
        let timestamp = Self.logDateFormatter.string(from: Date())
        print("[QuizFlow][MainCoordinator][\(timestamp)] \(message)")
        #endif
    }

    private func startDestinationDescription(_ destination: QuizWaitingRoomCoordinator.StartDestination) -> String {
        switch destination {
        case .waitingRoom:
            return "waitingRoom"
        case .participating:
            return "participating"
        }
    }

    private func presentSafely(_ viewController: UIViewController) {
        if let presented = navigationController.presentedViewController {
            let shouldDismissFirst =
                presented is PHPickerViewController ||
                presented is UIImagePickerController ||
                presented.isBeingDismissed ||
                presented.view.window == nil

            if shouldDismissFirst {
                navigationController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    self.navigationController.present(viewController, animated: true)
                }
                return
            }
        }

        if let host = topMostViewController() {
            host.present(viewController, animated: true)
        } else {
            navigationController.present(viewController, animated: true)
        }
    }
}

// MARK: - AlertPresenting
extension MainCoordinator: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        topMostViewController()?.present(alert, animated: true)
    }
}

// MARK: - InfoBottomSheetPresenting
extension MainCoordinator: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        topMostViewController()
    }
}

// MARK: - AuthRouting
extension MainCoordinator: MainRouting {
    func routeToProfileScreen() {
        tabBarController.selectedIndex = 3
    }

    func routeToQuizWaitingRoom(accessCode: String) async {
        guard let mainNavController else { return }
        prepareMainLeftBarButtonForPushTransition()
        logQuizFlow("routeToQuizWaitingRoom called from Main. accessCode=\(accessCode)")

        let connectedPayload = await services.quizParticipationService.currentConnectedPayload()
        let shouldRouteToParticipating = connectedPayload?.quizStatus == .active
            || (connectedPayload?.quizType == .async && connectedPayload?.isCreator == false)
        let startDestination: QuizWaitingRoomCoordinator.StartDestination = shouldRouteToParticipating
            ? .participating
            : .waitingRoom

        logQuizFlow(
            "entry decision: status=\(connectedPayload?.quizStatus?.rawValue ?? "nil"), " +
            "isCreator=\(connectedPayload?.isCreator.description ?? "nil"), " +
            "destination=\(startDestinationDescription(startDestination))"
        )

        startQuizWaitingRoom(
            on: mainNavController,
            accessCode: accessCode,
            startDestination: startDestination
        )
    }

    func routeToQuizParticipantsOverviewFromMain(initialData: QuizParticipantsOverviewModels.InitialData) {
        guard let mainNavController else { return }
        prepareMainLeftBarButtonForPushTransition()
        pushQuizParticipantsOverviewScreen(on: mainNavController, initialData: initialData)
    }

    func showError(title: String, message: String) {
        showAlert(title: title, message: message)
    }

    func showQuizTypeInfoBottomSheet(title: String, description: String) {
        showInfoBottomSheet(title: title, description: description)
    }

    func showQuizJoinConfirmationBottomSheet(
        quizTitle: String,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        showQuizJoinConfirmationSheet(quizTitle: quizTitle, onConfirm: onConfirm)
    }

    func showAsyncQuizStartConfirmationBottomSheet(
        quizTitle: String?,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        showAsyncQuizStartConfirmationSheet(quizTitle: quizTitle, onConfirm: onConfirm)
    }

    func showQuizConnectionUnavailableBottomSheet(description: String) {
        showInfoBottomSheet(
            title: "С прискорбием сообщаем...",
            description: description,
            buttonTitle: "ОК"
        )
    }

    func showQuizJoinConnectionErrorBottomSheet() {
        showInfoBottomSheet(
            title: "Ошибка подключения",
            description: "Не удалось подключиться к квизу. Убедитесь, что у вас стабильное интернет-соединение и код введен верно",
            buttonTitle: "ОК"
        )
    }
}

// MARK: - MyQuizzesRouting
extension MainCoordinator: GroupsRouting {

}

// MARK: - MyQuizzesRouting
extension MainCoordinator: MyQuizzesRouting {
    func routeToCreateTemplateScreen() {
        guard let myQuizzesNavController else { return }

        let viewController = TemplateCreatingAssembly.build(
            router: self,
            quizService: services.quizService,
            mlService: services.mlService
        )
        viewController.hidesBottomBarWhenPushed = true
        myQuizzesNavController.pushViewController(viewController, animated: true)
    }

    func routeToCreateTemplateScreen(
        prefilledTitle: String?,
        questions: [Question]
    ) {
        guard let myQuizzesNavController else { return }

        let viewController = TemplateCreatingAssembly.build(
            router: self,
            quizService: services.quizService,
            mlService: services.mlService,
            prefilledTitle: prefilledTitle,
            questions: questions
        )
        viewController.hidesBottomBarWhenPushed = true
        myQuizzesNavController.pushViewController(viewController, animated: true)
    }

    func routeToEditTemplateScreen(template: QuizTemplate) {
        guard let myQuizzesNavController else { return }

        let viewController = TemplateCreatingAssembly.build(
            router: self,
            quizService: services.quizService,
            mlService: services.mlService,
            template: template
        )
        viewController.hidesBottomBarWhenPushed = true
        myQuizzesNavController.pushViewController(viewController, animated: true)
    }

    func routeToStartQuizScreen(template: QuizTemplate) {
        guard let myQuizzesNavController else { return }

        let viewController = StartQuizAssembly.build(
            router: self,
            template: template,
            quizService: services.quizService,
            quizParticipationService: services.quizParticipationService
        )
        viewController.hidesBottomBarWhenPushed = true
        myQuizzesNavController.pushViewController(viewController, animated: true)
    }

    func routeToQuizWaitingRoomFromMyQuizzes(accessCode: String) async {
        guard let myQuizzesNavController else { return }
        logQuizFlow("routeToQuizWaitingRoom called from MyQuizzes. accessCode=\(accessCode)")

        let connectedPayload = await services.quizParticipationService.currentConnectedPayload()
        let shouldRouteToParticipating = connectedPayload?.quizStatus == .active
            || (connectedPayload?.quizType == .async && connectedPayload?.isCreator == false)
        let startDestination: QuizWaitingRoomCoordinator.StartDestination = shouldRouteToParticipating
            ? .participating
            : .waitingRoom

        logQuizFlow(
            "entry decision: status=\(connectedPayload?.quizStatus?.rawValue ?? "nil"), " +
            "isCreator=\(connectedPayload?.isCreator.description ?? "nil"), " +
            "destination=\(startDestinationDescription(startDestination))"
        )

        startQuizWaitingRoom(
            on: myQuizzesNavController,
            accessCode: accessCode,
            startDestination: startDestination
        )
    }

    func routeToQuizParticipantsOverviewFromMyQuizzes(initialData: QuizParticipantsOverviewModels.InitialData) {
        guard let myQuizzesNavController else { return }
        pushQuizParticipantsOverviewScreen(on: myQuizzesNavController, initialData: initialData)
    }

}

// MARK: - ProfileRouting
extension MainCoordinator: ProfileRouting {
    func showLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) {
        showConfirmationAlert(
            title: "Выход из аккаунта",
            message: "Вы уверены, что хотите выйти из аккаунта?",
            cancelTitle: "Отмена",
            confirmTitle: "Выход",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }

    func showAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        config.cropViewConfig.cropShapeType = .circle(maskOnly: true)
        config.cropViewConfig.showAttachedRotationControlView = false

        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen

        let handler = AvatarCropHandler(onFinish: onFinish)
        cropViewController.delegate = handler

        objc_setAssociatedObject(
            cropViewController,
            &AssociatedKeys.avatarCropHandlerKey,
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        presentSafely(cropViewController)
    }
}

// MARK: - TemplateCreatingRouting
extension MainCoordinator: TemplateCreatingRouting {
    func dismissTemplateCreatingScreen(shouldRefreshTemplates: Bool) {
        if shouldRefreshTemplates {
            myQuizzesViewController()?.scheduleTemplatesRefreshOnAppear()
        }

        myQuizzesNavController?.popViewController(animated: true)
    }
}

// MARK: - StartQuizRouting
extension MainCoordinator: StartQuizRouting {
    func dismissStartQuizScreen() {
        myQuizzesNavController?.popViewController(animated: true)
    }

    func routeToQuizWaitingRoomFromStartQuiz(accessCode: String) {
        guard let myQuizzesNavController else { return }
        logQuizFlow("routeToQuizWaitingRoomFromStartQuiz called. accessCode=\(accessCode), destination=waitingRoom")

        myQuizzesNavController.popViewController(animated: false)
        startQuizWaitingRoom(
            on: myQuizzesNavController,
            accessCode: accessCode,
            startDestination: .waitingRoom
        )
    }
}

@MainActor
protocol MainRouting: ErrorMessageDisplaying {
    func routeToProfileScreen()
    func routeToQuizWaitingRoom(accessCode: String) async
    func routeToQuizParticipantsOverviewFromMain(initialData: QuizParticipantsOverviewModels.InitialData)
    func showQuizTypeInfoBottomSheet(title: String, description: String)
    func showQuizConnectionUnavailableBottomSheet(description: String)
    func showQuizJoinConnectionErrorBottomSheet()
    func showAsyncQuizStartConfirmationBottomSheet(
        quizTitle: String?,
        onConfirm: @escaping @MainActor () -> Void
    )
    func showQuizJoinConfirmationBottomSheet(
        quizTitle: String,
        onConfirm: @escaping @MainActor () -> Void
    )
}

@MainActor
protocol GroupsRouting: AnyObject {

}

@MainActor
protocol MyQuizzesRouting: ErrorMessageDisplaying {
    func routeToCreateTemplateScreen()
    func routeToCreateTemplateScreen(prefilledTitle: String?, questions: [Question])
    func routeToEditTemplateScreen(template: QuizTemplate)
    func routeToStartQuizScreen(template: QuizTemplate)
    func routeToQuizWaitingRoomFromMyQuizzes(accessCode: String) async
    func routeToQuizParticipantsOverviewFromMyQuizzes(initialData: QuizParticipantsOverviewModels.InitialData)
    func showQuizTypeInfoBottomSheet(title: String, description: String)
    func showQuizConnectionUnavailableBottomSheet(description: String)
    func showQuizJoinConfirmationBottomSheet(
        quizTitle: String,
        onConfirm: @escaping @MainActor () -> Void
    )
}

@MainActor
protocol TemplateCreatingRouting: ErrorMessageDisplaying {
    func dismissTemplateCreatingScreen(shouldRefreshTemplates: Bool)
    func showQuizTypeInfoBottomSheet(title: String, description: String)
}

@MainActor
protocol StartQuizRouting: ErrorMessageDisplaying {
    func dismissStartQuizScreen()
    func routeToQuizWaitingRoomFromStartQuiz(accessCode: String)
}

@MainActor
protocol ProfileRouting: ErrorMessageDisplaying {
    func showLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void)
    func showAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void)
}

@MainActor
protocol QuizParticipantsOverviewRouting: ErrorMessageDisplaying {
    func routeToQuizParticipantReview(initialData: QuizParticipantReviewModels.InitialData)
}

extension MainCoordinator: QuizParticipantsOverviewRouting {
    func routeToQuizParticipantReview(initialData: QuizParticipantReviewModels.InitialData) {
        guard let navigationController = topMostViewController()?.navigationController else {
            return
        }

        pushQuizParticipantReviewScreen(on: navigationController, initialData: initialData)
    }
}

@MainActor
protocol QuizParticipantReviewRouting: ErrorMessageDisplaying {}

extension MainCoordinator: QuizParticipantReviewRouting {}
