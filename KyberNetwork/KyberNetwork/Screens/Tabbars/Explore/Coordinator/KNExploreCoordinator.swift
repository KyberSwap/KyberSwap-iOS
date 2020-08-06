// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Moya

protocol KNExploreCoordinatorDelegate: class {
  func exploreCoordinatorOpenManageOrder()
  func exploreCoordinatorOpenSwap(from: String, to: String)
}

class KNExploreCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  fileprivate var historyCoordinator: KNHistoryCoordinator?
  weak var delegate: KNExploreCoordinatorDelegate?

  lazy var rootViewController: KNExploreViewController = {
    let viewModel = KNExploreViewModel()
    let controller = KNExploreViewController(viewModel: viewModel)
    controller.delegate = self
    return controller
  }()

  lazy var profileCoordinator: KNProfileHomeCoordinator = {
    let coordinator = KNProfileHomeCoordinator(navigationController: self.navigationController, session: self.session)
    return coordinator
  }()

  fileprivate var manageAlertCoordinator: KNManageAlertCoordinator?

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.profileCoordinator.startUserTrackingTimer()
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
    self.profileCoordinator.stop()
  }

  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
    self.profileCoordinator.updateSession(session)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
    self.rootViewController.update(transactions: transactions)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    if self.navigationController.viewControllers.first(where: { $0 is KNHistoryViewController }) == nil {
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController,
        session: self.session
      )
    }
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(session)
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.historyCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    return false
  }
}

extension KNExploreCoordinator: KNExploreViewControllerDelegate {
  func kExploreViewController(_ controller: KNExploreViewController, run event: KNExploreViewEvent) {
    switch event {
    case .getListMobileBanner:
      self.fetchBannerImages()
    case .openNotification:
      self.openListNotifications()
    case .openAlert:
      guard IEOUserStorage.shared.user != nil else {
        self.navigationController.showWarningTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
          time: 1.5
        )
        return
      }
      self.openManageAlert()
    case .openHistory:
      self.openHistoryTransactionView()
    case .openLogin:
      self.profileCoordinator.start()
    case .openBannerLink(let link):
      self.rootViewController.openSafari(with: link)
    case .navigateSwap:
      self.rootViewController.tabBarController?.selectedIndex = 1
    case .navigateLO:
      self.rootViewController.tabBarController?.selectedIndex = 2
    }
  }

  fileprivate func fetchBannerImages() {
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<UserInfoService>()
      provider.request(.getMobileBanner) { (result) in
        self.rootViewController.hideLoading()
        switch result {
        case .success(let resp):
          do {
            _ = try resp.filterSuccessfulStatusCodes()
            let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
            let success = json["success"] as? Bool ?? false
            let data = json["data"] as? [[String: String]] ?? []
            if success {
              self.rootViewController.coordinatorUpdateBannerImages(items: data)
            }
          } catch {
            self.rootViewController.coordinatorUpdateBannerImages(items: [])
            self.showRetryAlert()
          }
        case .failure:
          self.rootViewController.coordinatorUpdateBannerImages(items: [])
          self.showRetryAlert()
        }
      }
    }
  }

  fileprivate func showRetryAlert() {
    let alert = KNPrettyAlertController(
      title: nil,
      message: "something.went.wrong.please.try.again".toBeLocalised(),
      secondButtonTitle: "try.again".toBeLocalised(),
      firstButtonTitle: "cancel".toBeLocalised(),
      secondButtonAction: {
        self.fetchBannerImages()
        KNCrashlyticsUtil.logCustomEvent(withName: "explore_retry_alert_retry_tapped", customAttributes: nil)
      },
      firstButtonAction: {
        KNCrashlyticsUtil.logCustomEvent(withName: "explore_retry_alert_cancel_tapped", customAttributes: nil)
      }
    )
    self.rootViewController.present(alert, animated: true, completion: nil)
  }

  fileprivate func openListNotifications() {
    let viewController = KNListNotificationViewController()
    viewController.loadViewIfNeeded()
    viewController.delegate = self
    self.navigationController.pushViewController(viewController, animated: true)
  }

  fileprivate func openNotificationSettingScreen() {
    self.navigationController.displayLoading()
    KNNotificationCoordinator.shared.getListSubcriptionTokens { (message, result) in
      self.navigationController.hideLoading()
      if let errorMessage = message {
        self.navigationController.showErrorTopBannerMessage(message: errorMessage)
      } else if let symbols = result {
        let viewModel = KNNotificationSettingViewModel(tokens: symbols.0, selected: symbols.1, notiStatus: symbols.2)
        let viewController = KNNotificationSettingViewController(viewModel: viewModel)
        viewController.delegate = self
        self.navigationController.pushViewController(viewController, animated: true)
      }
    }
  }

  fileprivate func openHistoryTransactionView() {
    if let topVC = self.navigationController.topViewController, topVC is KNHistoryViewController { return }
    self.historyCoordinator = nil
    self.historyCoordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session
    )
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator?.start()
  }

  fileprivate func openManageAlert() {
    if let topVC = self.navigationController.topViewController, topVC is KNManageAlertsViewController { return }
    self.manageAlertCoordinator = KNManageAlertCoordinator(navigationController: self.navigationController)
    self.manageAlertCoordinator?.start()
  }
}

extension KNExploreCoordinator: KNNotificationSettingViewControllerDelegate {
  func notificationSettingViewControllerDidApply(_ controller: KNNotificationSettingViewController) {
    self.navigationController.popViewController(animated: true) {
      self.showSuccessTopBannerMessage(message: "Updated subscription tokens".toBeLocalised())
    }
  }
}

extension KNExploreCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidClose() {
  }
}

extension KNExploreCoordinator: KNListNotificationViewControllerDelegate {
  func listNotificationViewController(_ controller: KNListNotificationViewController, run event: KNListNotificationViewEvent) {
    switch event {
    case .openSwap(let from, let to):
      self.delegate?.exploreCoordinatorOpenSwap(from: from, to: to)
    case .openManageOrder:
      if IEOUserStorage.shared.user == nil { return }
      self.delegate?.exploreCoordinatorOpenManageOrder()
    case .openSetting:
      self.openNotificationSettingScreen()
    }
  }
}
