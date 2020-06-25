// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import QRCodeReaderViewController
import WalletConnect
import Moya

protocol KNBalanceTabCoordinatorDelegate: class {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject, isReceived: Bool)
  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject)
  func balanceTabCoordinatorDidSelectAddWallet()
  func balanceTabCoordinatorDidSelectPromoCode()
  func balanceTabCoordinatorOpenManageOrder()
  func balanceTabCoordinatorOpenSwap(from: String, to: String)
}

class KNBalanceTabCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  fileprivate var balances: [String: Balance] = [:]

  weak var delegate: KNBalanceTabCoordinatorDelegate?

  lazy var newRootViewController: KWalletBalanceViewController = {
    let address: String = self.session.wallet.address.description
    let wallet: KNWalletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    let viewModel: KWalletBalanceViewModel = KWalletBalanceViewModel(wallet: wallet)
    let controller: KWalletBalanceViewController = KWalletBalanceViewController(viewModel: viewModel)
    controller.delegate = self
    controller.loadViewIfNeeded()
    return controller
  }()

  fileprivate var promoCodeCoordinator: KNPromoCodeCoordinator?

  fileprivate var newAlertController: KNNewAlertViewController?

  fileprivate var qrcodeCoordinator: KNWalletQRCodeCoordinator? {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description) else { return nil }
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController,
      walletObject: walletObject
    )
    return qrcodeCoordinator
  }

  fileprivate var historyCoordinator: KNHistoryCoordinator?

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var tokenChartCoordinator: KNTokenChartCoordinator?

  deinit {
    self.stop()
  }

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.newRootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.navigationController.viewControllers = [self.newRootViewController]
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
    self.sendTokenCoordinator = nil
    self.promoCodeCoordinator = nil
    self.historyCoordinator = nil
  }
}

// Update from appcoordinator
extension KNBalanceTabCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    if resetRoot {
      self.navigationController.popToRootViewController(animated: true)
    }

    let viewModel: KWalletBalanceViewModel = {
      let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
      let address: String = session.wallet.address.description
      let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
      let viewModel = KWalletBalanceViewModel(wallet: walletObject)
      _ = viewModel.updateTokenObjects(tokenObjects)
      return viewModel
    }()
    self.balances = [:]
    self.newRootViewController.coordinatorUpdateSessionWithNewViewModel(viewModel)
    let pendingObjects = self.session.transactionStorage.kyberPendingTransactions
    self.newRootViewController.coordinatorUpdatePendingTransactions(pendingObjects)
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

  func appCoordinatorDidUpdateWalletObjects() {
    self.newRootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorTokenBalancesDidUpdate(
    totalBalanceInUSD: BigInt,
    totalBalanceInETH: BigInt,
    otherTokensBalance: [String: Balance]
    ) {
    self.newRootViewController.coordinatorUpdateTokenBalances(otherTokensBalance)
    self.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.tokenChartCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func appCoordinatorExchangeRateDidUpdate(
    totalBalanceInUSD: BigInt,
    totalBalanceInETH: BigInt
    ) {
    self.tokenChartCoordinator?.coordinatorExchangeRateDidUpdate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
    self.newRootViewController.coordinatorUpdateBalanceInETHAndUSD(
      ethBalance: totalBalanceInETH,
      usdBalance: totalBalanceInUSD
    )
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.newRootViewController.coordinatorUpdateTokenObjects(tokenObjects)
    self.tokenChartCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorSupportedTokensDidUpdate(tokenObjects: [TokenObject]) {
    let tokens = self.session.tokenStorage.tokens
    self.newRootViewController.coordinatorUpdateTokenObjects(tokens)
    self.tokenChartCoordinator?.coordinatorTokenObjectListDidUpdate(tokens)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
    self.newRootViewController.coordinatorUpdatePendingTransactions(transactions)
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.tokenChartCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.historyCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorOpenTokenChart(for token: String) {
    guard let token = self.session.tokenStorage.tokens.first(where: { return $0.symbol == token }) else { return }
    self.navigationController.popToRootViewController(animated: false)
    self.openTokenChartView(for: token)
  }

  func appCoordinatorBalanceSorted(with currencyType: KWalletCurrencyType) {
    self.navigationController.popToRootViewController(animated: false)
    self.newRootViewController.coordinatorSortedChange24h(with: currencyType)
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    if self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    return self.tokenChartCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) ?? false
  }

  func appCoordinatorWillTerminate() {
    if let topVC = self.navigationController.topViewController?.presentedViewController as? KNWalletConnectViewController {
      topVC.applicationWillTerminate()
    }
  }

  func appCoordinatorWillEnterForeground() {
    if let topVC = self.navigationController.topViewController?.presentedViewController as? KNWalletConnectViewController {
      topVC.applicationWillEnterForeground()
    }
  }

  func appCoordinatorDidEnterBackground() {
    if let topVC = self.navigationController.topViewController?.presentedViewController as? KNWalletConnectViewController {
      topVC.applicationDidEnterBackground()
    }
  }
}

// MARK: New Design K Wallet Balance delegation
extension KNBalanceTabCoordinator: KWalletBalanceViewControllerDelegate {
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run event: KWalletBalanceViewEvent) {
    switch event {
    case .openQRCode:
      self.qrcodeCoordinator?.start()
    case .selectToken(let token):
      self.openTokenChartView(for: token)
    case .send(let token):
      self.openSendTokenView(with: token)
    case .sell(let token):
      self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: false)
    case .buy(let token):
      self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: true)
    case .receiveToken:
      self.qrcodeCoordinator?.start()
    case .alert(let token):
      self.openAddNewAlert(token)
    case .refreshData:
      // refresh rates
      KNRateCoordinator.shared.refreshData()
      KNNotificationUtil.postNotification(for: kRefreshBalanceNotificationKey)
    case .buyETH:
      self.openBuyETHAlert()
    case .copyAddress:
      UIPasteboard.general.string = self.session.wallet.address.description
      self.navigationController.showMessageWithInterval(
        message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
      )
    case .quickTutorial(let step, let pointsAndRadius):
      self.openQuickTutorial(controller, step: step, pointsAndRadius: pointsAndRadius)
    }
  }

  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run menuEvent: KNBalanceTabHamburgerMenuViewEvent) {
    switch menuEvent {
    case .select(let wallet):
      self.hamburgerMenu(select: wallet)
    case .selectAddWallet:
      self.hamburgerMenuSelectAddWallet()
    case .selectPromoCode:
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_kybercode", customAttributes: nil)
      self.hamburgerMenuSelectPromoCode()
    case .selectSendToken:
      let from: TokenObject = {
        guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description), let token = self.session.tokenStorage.tokens.first(where: { return $0.symbol == destToken }) else {
          return self.session.tokenStorage.ethToken
        }
        return token
      }()
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_transfer", customAttributes: nil)
      self.openSendTokenView(with: from)
    case .selectAllTransactions:
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_tnx", customAttributes: nil)
      self.openHistoryTransactionView()
    case .selectWalletConnect:
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_walletconnect", customAttributes: nil)
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .selectNotifications:
      let viewController = KNListNotificationViewController()
      viewController.loadViewIfNeeded()
      viewController.delegate = self
      self.navigationController.pushViewController(viewController, animated: true)
    }
  }

  fileprivate func openQuickTutorial(_ controller: KWalletBalanceViewController, step: Int, pointsAndRadius: [(CGPoint, CGFloat)]) {
    var attributedString = NSMutableAttributedString()
    var contentTopOffset: CGFloat = 0.0
    var nextButtonText = "next".toBeLocalised()
    switch step {
    case 1:
      attributedString = NSMutableAttributedString(string: "Total balance in your wallet\nYou can buy ETH here".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      attributedString.string.enumerateSubstrings(in: attributedString.string.startIndex..<attributedString.string.endIndex, options: .byWords) { (substring, substringRange, _, _) in
        if substring == "here" {
          attributedString.addAttribute(.foregroundColor, value: UIColor.Kyber.orange, range: NSRange(substringRange, in: attributedString.string))
        }
      }
      contentTopOffset = 302
    case 2:
      attributedString = NSMutableAttributedString(string: "Token balance in your wallet".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 452
    case 3:
      attributedString = NSMutableAttributedString(string: "Live token price along with 24h change.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 464
    case 4:
      attributedString = NSMutableAttributedString(string: "Swipe right to set price alert.\nSwipe left to buy, sell or send tokens.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 476
      nextButtonText = "Got it".toBeLocalised()
    default:
      break
    }
    let overlayer = controller.createOverlay(
      frame: controller.tabBarController!.view.frame,
      contentText: attributedString,
      contentTopOffset: contentTopOffset,
      pointsAndRadius: pointsAndRadius,
      nextButtonTitle: nextButtonText
    )
    controller.tabBarController!.view.addSubview(overlayer)
  }

  fileprivate func openTokenChartView(for tokenObject: TokenObject) {
    if let topVC = self.navigationController.topViewController, topVC is KNTokenChartViewController { return }
    self.tokenChartCoordinator = KNTokenChartCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      token: tokenObject
    )
    self.tokenChartCoordinator?.delegate = self
    self.tokenChartCoordinator?.start()
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

  func hamburgerMenu(select walletObject: KNWalletObject) {
    self.delegate?.balanceTabCoordinatorDidSelect(walletObject: walletObject)
  }

  func hamburgerMenuSelectAddWallet() {
    self.delegate?.balanceTabCoordinatorDidSelectAddWallet()
  }

  func hamburgerMenuSelectPromoCode() {
    self.delegate?.balanceTabCoordinatorDidSelectPromoCode()
  }

  func openSendTokenView(with token: TokenObject) {
    if let topVC = self.navigationController.topViewController, topVC is KSendTokenViewController { return }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_balance", customAttributes: ["action": "send_\(token.symbol)"])
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      self.sendTokenCoordinator = KNSendTokenViewCoordinator(
        navigationController: self.navigationController,
        session: self.session,
        balances: self.balances,
        from: token
      )
      self.sendTokenCoordinator?.start()
    } else {
      let message = NSLocalizedString("Please wait for other transactions to be mined before making a transfer", comment: "")
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: message,
        time: 2.0
      )
    }
  }

  func openHistoryTransactionView() {
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

  func openAddNewAlert(_ token: TokenObject) {
    if let topVC = self.navigationController.topViewController, topVC is KNNewAlertViewController { return }
    if KNAlertStorage.shared.isMaximumAlertsReached {
      let alertController = KNPrettyAlertController(
        title: "Alert limit exceeded".toBeLocalised(),
        message: "You already have 10 (maximum) alerts in your inbox. Please delete an existing alert to add a new one".toBeLocalised(),
        secondButtonTitle: nil,
        firstButtonTitle: "OK".toBeLocalised(),
        secondButtonAction: nil,
        firstButtonAction: nil
      )
      self.navigationController.present(alertController, animated: true, completion: nil)
      return
    }
    if IEOUserStorage.shared.user == nil {
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
        time: 1.5
      )
      return
    }
    self.newAlertController = KNNewAlertViewController()
    self.newAlertController?.loadViewIfNeeded()
    self.navigationController.pushViewController(self.newAlertController!, animated: true) {
      self.newAlertController?.updatePair(token: token, currencyType: KNAppTracker.getCurrencyType())
    }
  }

  fileprivate func openBuyETHAlert() {
    let alertController = KNPrettyAlertController(
      title: nil,
      message: "KyberSwap.is.only.support.buying.ETH.with.fiat.on.web".toBeLocalised(),
      secondButtonTitle: "yes".toBeLocalised(),
      firstButtonTitle: "cancel".toBeLocalised(),
      secondButtonAction: {
        let ksURL = URL(string: "https://kyberswap.com/swap/knc-eth")!
        if UIApplication.shared.canOpenURL(ksURL) {
          UIApplication.shared.open(ksURL)
        }
        KNCrashlyticsUtil.logCustomEvent(withName: "balance_buyeth_yes", customAttributes: nil)
      },
      firstButtonAction: {
        KNCrashlyticsUtil.logCustomEvent(withName: "balance_buyeth_cancel", customAttributes: nil)
      }
    )

    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Token Chart Coordinator Delegate
extension KNBalanceTabCoordinator: KNTokenChartCoordinatorDelegate {
  func tokenChartCoordinator(sell token: TokenObject) {
    self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: false)
  }

  func tokenChartCoordinator(buy token: TokenObject) {
    self.delegate?.balanceTabCoordinatorShouldOpenExchange(for: token, isReceived: true)
  }

  func tokenChartCoordinatorShouldBack() {
    self.navigationController.popToRootViewController(animated: true)
  }
}

extension KNBalanceTabCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidClose() {
//    self.historyCoordinator = nil
  }
}

extension KNBalanceTabCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let session = WCSession.from(string: result) else {
        self.navigationController.showTopBannerView(
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }
      let controller = KNWalletConnectViewController(
        wcSession: session,
        knSession: self.session
      )
      self.navigationController.present(controller, animated: true, completion: nil)
    }
  }
}

extension KNBalanceTabCoordinator: KNListNotificationViewControllerDelegate {
  func listNotificationViewController(_ controller: KNListNotificationViewController, run event: KNListNotificationViewEvent) {
    switch event {
    case .openSwap(let from, let to):
      self.delegate?.balanceTabCoordinatorOpenSwap(from: from, to: to)
    case .openManageOrder:
      if IEOUserStorage.shared.user == nil { return }
      self.delegate?.balanceTabCoordinatorOpenManageOrder()
    case .openSetting:
      self.openNotificationSettingScreen()
    }
  }
}

extension KNBalanceTabCoordinator: KNNotificationSettingViewControllerDelegate {
  func notificationSettingViewControllerDidApply(_ controller: KNNotificationSettingViewController) {
    self.navigationController.popViewController(animated: true) {
      self.showSuccessTopBannerMessage(message: "Updated subscription tokens".toBeLocalised())
    }
  }
}
