// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length
import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result
import Moya
import APIKit
import QRCodeReaderViewController
import WalletConnect

protocol KNLimitOrderTabCoordinatorV2Delegate: class {
  func limitOrderTabCoordinatorDidSelectWallet(_ wallet: KNWalletObject)
  func limitOrderTabCoordinatorRemoveWallet(_ wallet: Wallet)
  func limitOrderTabCoordinatorDidSelectAddWallet()
  func limitOrderTabCoordinatorDidSelectPromoCode()
  func limitOrderTabCoordinatorOpenExchange(from: String, to: String)
}

class KNLimitOrderTabCoordinatorV2: NSObject, Coordinator {

  let navigationController: UINavigationController
  var session: KNSession
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true
  var coordinators: [Coordinator] = []

  var curOrder: KNLimitOrder?
  var curConfirmData: KNLimitOrderConfirmData?
  var confirmedOrder: KNLimitOrder?
  var signedData: Data?

  weak var delegate: KNLimitOrderTabCoordinatorV2Delegate?

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var pendingBalances: JSONDictionary = [:]
  fileprivate var approveTx: [String: TimeInterval] = [:]

  fileprivate var historyCoordinator: KNHistoryCoordinator?
  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var limitOrderV1Coordinator: KNLimitOrderTabCoordinator?
  fileprivate var tokenChartCoordinator: KNTokenChartCoordinator?

  fileprivate var confirmVC: PreviewLimitOrderV2ViewController?
  fileprivate var manageOrdersVC: KNManageOrdersViewController?
  fileprivate var convertVC: KNConvertSuggestionViewController?

  fileprivate lazy var marketsVC: KNSelectMarketViewController = {
    let viewModel = KNSelectMarketViewModel()
    let viewController = KNSelectMarketViewController(viewModel: viewModel)
    viewController.loadViewIfNeeded()
    viewController.delegate = self
    return viewController
  }()

  lazy var rootViewController: LimitOrderContainerViewController = {
    let controller = LimitOrderContainerViewController(wallet: self.session.wallet)
    controller.delegate = self
    controller.loadViewIfNeeded()
    return controller
  }()

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
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
    self.historyCoordinator = nil
    self.sendTokenCoordinator = nil
    self.confirmVC = nil
    self.manageOrdersVC = nil
    self.convertVC = nil
  }
}

// MARK: Update from app coordinator
extension KNLimitOrderTabCoordinatorV2 {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    self.balances = [:]
    self.self.pendingBalances = [:]
    self.approveTx = [:]
    let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
    self.rootViewController.coordinatorDidUpdatePendingTransactions(pendingTrans)
    if self.navigationController.viewControllers.first(where: { $0 is KNHistoryViewController }) == nil {
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController,
        session: self.session
      )
    }
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)

    self.convertVC?.updateAddress(session.wallet.address.description)
    self.convertVC?.updateETHBalance(BigInt(0))
    self.convertVC?.updateWETHBalance(self.balances)
    self.convertVC?.updatePendingWETHBalance(0)

    self.limitOrderV1Coordinator?.appCoordinatorDidUpdateNewSession(session)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.limitOrderV1Coordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.historyCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.tokenChartCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorMarketCachedDidUpdate() {
    self.rootViewController.coordinatorMarketCachedDidUpdate()
    self.marketsVC.coordinatorMarketCachedDidUpdate()
    self.tokenChartCoordinator?.coordinatorDidUpdateMarketData()
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.convertVC?.updateWETHBalance(otherTokensBalance)
    self.convertVC?.updateETHBalance(otherTokensBalance)
    self.limitOrderV1Coordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH,
      otherTokensBalance: otherTokensBalance
    )
    self.tokenChartCoordinator?.coordinatorTokenBalancesDidUpdate(balances: otherTokensBalance)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
    self.limitOrderV1Coordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalBalanceInUSD,
      totalBalanceInETH: totalBalanceInETH
    )
  }

  func appCoordinatorUpdateExchangeTokenRates() {
    self.limitOrderV1Coordinator?.appCoordinatorUpdateExchangeTokenRates()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    let supportedTokens = KNSupportedTokenStorage.shared.supportedTokens
    self.tokens = supportedTokens
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.limitOrderV1Coordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.tokenChartCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
    self.rootViewController.coordinatorDidUpdatePendingTransactions(transactions)
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    if self.tokenChartCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    return false
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

  func appCoordinatorOpenManageOrder() {
    if IEOUserStorage.shared.user == nil {
      self.rootViewController.tabBarController?.selectedIndex = 3
      self.showWarningTopBannerMessage(
        with: "Sign in required".toBeLocalised(),
        message: "You must sign in to use Limit Order feature".toBeLocalised(),
        time: 1.5
      )
      return
    }
    self.navigationController.popToRootViewController(animated: true) {
      if self.manageOrdersVC == nil {
        self.manageOrdersVC = KNManageOrdersViewController(
          viewModel: KNManageOrdersViewModel(orders: [])
        )
        self.manageOrdersVC?.loadViewIfNeeded()
        self.manageOrdersVC?.delegate = self
      }
      self.navigationController.pushViewController(self.manageOrdersVC!, animated: true, completion: {
        self.manageOrdersVC?.openHistoryOrders()
      })
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: LimitOrderContainerViewControllerDelegate {
  func kCreateLimitOrderViewController(_ controller: KNBaseViewController, run event: KNCreateLimitOrderViewEventV2) {
    switch event {
    case .submitOrder(let order, let confirmData):
      self.checkDataBeforeConfirmOrder(order, confirmData: confirmData)
    case .manageOrders:
      self.appCoordinatorOpenManageOrder()
    case .estimateFee(let address, let src, let dest, let srcAmount, let destAmount):
      self.getExpectedFee(
        accessToken: IEOUserStorage.shared.user?.accessToken,
        address: address,
        src: src,
        dest: dest,
        srcAmount: srcAmount,
        destAmount: destAmount
      )
    case .openConvertWETH(let address, let ethBalance, let amount, let pendingWETH, let order, let confirmData):
      self.curOrder = order
      self.curConfirmData = confirmData
      self.openConvertWETHView(
        address: address,
        ethBalance: ethBalance,
        amount: amount,
        pendingWETH: pendingWETH
      )
    case .getRelatedOrders(let address, let src, let dest, let minRate):
      self.getListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate)
    case .getPendingBalances(let address):
      self.getPendingBalances(address: address)
    case .changeMarket:
      self.openSelectMarketScreen()
    case .openCancelSuggestOrder(let headers, let sections, let cancelOrder, let parent):
      self.openCancelSuggestionOrderScreen(header: headers, sections: sections, cancelOrder: cancelOrder, parent: parent)
    case .openChartView(let market, let isBuy):
      self.openChartView(market: market, isBuy: isBuy)
    case .quickTutorial(let step, let pointsAndRadius):
      self.openQuickTutorial(controller, step: step, pointsAndRadius: pointsAndRadius)
    default: break
    }
  }

  func kCreateLimitOrderViewController(_ controller: KNBaseViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    switch event {
    case .selectSendToken:
      self.openSendTokenView()
    case .selectAddWallet:
      self.openAddWalletView()
    case .select(let wallet):
      self.updateCurrentWallet(wallet)
    case .selectPromoCode:
      self.openPromoCodeView()
    case .selectAllTransactions:
      self.openHistoryTransactionsView()
    case .selectWalletConnect:
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

  fileprivate func openQuickTutorial(_ controller: KNBaseViewController, step: Int, pointsAndRadius: [(CGPoint, CGFloat)]) {
    var attributedString = NSMutableAttributedString()
    var contentTopOffset: CGFloat = 0.0
    var nextButtonText = "next".toBeLocalised()

    switch step {
    case 1:
      attributedString = NSMutableAttributedString(string: "Step 1\nSelect pair you want to trade".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 266
    case 2:
      attributedString = NSMutableAttributedString(string: "Step 2\nSet your desired price. Press Buy/Sell and its done.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 422
    case 3:
      attributedString = NSMutableAttributedString(string: "Zero Fees\nIf you hold 2000 KNC in your wallet, you can make limit order trades with 0 trading fees.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      if let range = attributedString.string.range(of: "Zero Fees".toBeLocalised()) {
        let r = NSRange(range, in: attributedString.string)
        attributedString.addAttribute(.font, value: UIFont.Kyber.medium(with: 18), range: r)
      }
      contentTopOffset = 172
    case 4:
      attributedString = NSMutableAttributedString(string: "Manage Order\nCheck your order history, pending orders etc. You can modify your orders as well.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 330
      nextButtonText = "Got It".toBeLocalised()
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
    KNCrashlyticsUtil.logCustomEvent(withName: "tut_lo_show_quick_tutorial", customAttributes: ["step": step])
  }

  fileprivate func openConvertWETHView(address: String, ethBalance: BigInt, amount: BigInt, pendingWETH: Double) {
    if let topVC = self.navigationController.topViewController, topVC is KNConvertSuggestionViewController { return }
    self.convertVC = KNConvertSuggestionViewController()
    self.convertVC?.loadViewIfNeeded()
    self.convertVC?.delegate = self
    self.navigationController.pushViewController(self.convertVC!, animated: true, completion: {
      self.convertVC?.updateAddress(address)
      self.convertVC?.updateETHBalance(ethBalance)
      self.convertVC?.updateWETHBalance(self.balances)
      self.convertVC?.updateAmountToConvert(amount)
      self.convertVC?.updatePendingWETHBalance(pendingWETH)
    })
  }

  fileprivate func openChartView(market: KNMarket, isBuy: Bool) {
    let pairs = market.pair.components(separatedBy: "_")
    var tokenSymbol = pairs.last?.lowercased() ?? ""
    if tokenSymbol == "weth" { tokenSymbol = "eth" } // change to eth if it is weth

    guard let token = self.tokens.first(where: { $0.symbol.lowercased() == tokenSymbol }) else {
      // no token found
      return
    }
    let chartData = KNLimitOrderChartData(market: market, isBuy: isBuy)
    self.tokenChartCoordinator = KNTokenChartCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      token: token,
      chartLOData: chartData
    )
    self.tokenChartCoordinator?.delegate = self
    self.tokenChartCoordinator?.start()
    self.tokenChartCoordinator?.coordinatorUpdatePendingBalances(
      address: self.session.wallet.address.description.lowercased(),
      balances: self.pendingBalances
    )
  }

  fileprivate func checkDataBeforeConfirmOrder(_ order: KNLimitOrder, confirmData: KNLimitOrderConfirmData?) {
    self.navigationController.displayLoading(text: "Checking...".toBeLocalised(), animated: true)
    var feeValue: Int?
    var transferFeeValue: Int?
    var nonceValue: String?
    var errorMessage: String?

    let group = DispatchGroup()

    // Getting fee
    group.enter()
    let destAmount: Double = {
      let amount = order.srcAmount * order.targetRate / BigInt(10).power(order.from.decimals)
      return Double(amount) / pow(10.0, Double(order.to.decimals))
    }()
    self.getExpectedFee(
      accessToken: IEOUserStorage.shared.user?.accessToken,
      address: order.sender.description,
      src: order.from.contract,
      dest: order.to.contract,
      srcAmount: Double(order.srcAmount) / pow(10.0, Double(order.from.decimals)),
      destAmount: destAmount) { (fee, _, _, transferFee, error) in
        if let err = error { errorMessage = err } else {
          feeValue = Int(round((fee ?? 0.0) * 1000000.0))
          transferFeeValue = Int(round((transferFee ?? 0.0) * 1000000.0))
        }
        group.leave()
    }

    // Getting nonce
    group.enter()
    self.getCurrentNonce { (nonce, error) in
        if let err = error { errorMessage = err } else { nonceValue = nonce }
        group.leave()
    }

    // check address eligible
    group.enter()
    self.checkWalletEligible { data in
      let isEligible = data.0
      let account = data.1 ?? ""
      if !isEligible {
        let message = "This address has been used by another account. Please place order with other address.".toBeLocalised()
        errorMessage = String(format: message, account)
      }
      group.leave()
    }

    group.notify(queue: .main) {
      self.navigationController.hideLoading()
      if let error = errorMessage {
        KNCrashlyticsUtil.logCustomEvent(withName: "lo_submit_error", customAttributes: ["error": error])
        if self.navigationController.viewControllers.count > 1 {
          self.navigationController.popToRootViewController(animated: true, completion: {
            self.navigationController.showWarningTopBannerMessage(with: "", message: error, time: 2.0)
          })
        } else {
          self.navigationController.showWarningTopBannerMessage(with: "", message: error, time: 2.0)
        }
      } else {
        KNCrashlyticsUtil.logCustomEvent(withName: "lo_submit_success", customAttributes: ["pair": "\(order.from.symbol)_\(order.to.symbol)", "src_amount": order.srcAmount.displayRate(decimals: order.from.decimals)])
        let newOrder = KNLimitOrder(
          from: order.from,
          to: order.to,
          account: order.account,
          sender: order.sender,
          srcAmount: order.srcAmount,
          targetRate: order.targetRate,
          fee: feeValue ?? order.fee,
          transferFee: transferFeeValue ?? order.transferFee,
          nonce: nonceValue ?? order.nonce,
          isBuy: order.isBuy
        )
        self.openConfirmOrder(newOrder, confirmData: confirmData)
      }
    }
  }

  fileprivate func openConfirmOrder(_ order: KNLimitOrder, confirmData: KNLimitOrderConfirmData?) {
    if let topVC = self.navigationController.topViewController, topVC is PreviewLimitOrderV2ViewController { return }
    self.signedData = nil

    self.confirmVC = PreviewLimitOrderV2ViewController(order: order, confirmData: confirmData!)
    self.confirmVC?.delegate = self
    self.confirmVC?.loadViewIfNeeded()
    self.navigationController.pushViewController(self.confirmVC!, animated: true)

    self.confirmedOrder = order
    let result = self.session.keystore.signLimitOrder(order)
    if case .success(let data) = result { self.signedData = data }
  }

  // Return (fee, discount, feeBeforeDiscount, Error)
  fileprivate func getExpectedFee(accessToken: String?, address: String, src: String, dest: String, srcAmount: Double, destAmount: Double, completion: ((Double?, Double?, Double?, Double?, String?) -> Void)? = nil) {
    KNLimitOrderServerCoordinator.shared.getFee(
      accessToken: accessToken,
      address: address,
      src: src,
      dest: dest,
      srcAmount: srcAmount,
      destAmount: destAmount) { [weak self] result in
        switch result {
        case .success(let data):
          if data.4 == nil {
            self?.rootViewController.coordinatorUpdateEstimateFee(
              data.0,
              discount: data.1,
              feeBeforeDiscount: data.2,
              transferFee: data.3
            )
            completion?(data.0, data.1, data.2, data.3, nil)
          } else {
            completion?(nil, nil, nil, nil, data.4)
          }
        case .failure(let error):
          completion?(nil, nil, nil, nil, error.prettyError)
        }
    }
  }

  fileprivate func getCurrentNonce(completion: @escaping (String?, String?) -> Void) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion(nil, nil)
      return
    }
    KNLimitOrderServerCoordinator.shared.getNonce(
      accessToken: accessToken) { [weak self] result in
        guard let _ = self else { return }
        switch result {
        case .success(let data):
          if data.1.isEmpty {
            completion(data.0, nil)
          } else {
            completion(nil, data.1)
          }
        case .failure(let error):
          completion(nil, error.prettyError)
        }
    }
  }

  fileprivate func getListRelatedOrders(address: String, src: String, dest: String, minRate: Double) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      self.rootViewController.coordinatorUpdateListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate, orders: [])
      return
    }
    KNLimitOrderServerCoordinator.shared.getRelatedOrders(accessToken: accessToken, address: address, src: src, dest: dest, minRate: minRate) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let orders):
        self.rootViewController.coordinatorUpdateListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate, orders: orders)
      case .failure(let error):
        print("--Get Related Order-- Error: \(error.prettyError)")
      }
    }
  }

  fileprivate func getPendingBalances(address: String) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      // reset pending balance
      self.convertVC?.updatePendingWETHBalance(0.0)
      self.rootViewController.coordinatorUpdatePendingBalances(address: address, balances: [:])
      return
    }
    KNLimitOrderServerCoordinator.shared.getPendingBalances(accessToken: accessToken, address: address) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let balances):
        if self.session.wallet.address.description.lowercased() == address.lowercased() {
          self.pendingBalances = balances
        }
        self.convertVC?.updatePendingWETHBalance(balances["WETH"] as? Double ?? 0.0)
        self.rootViewController.coordinatorUpdatePendingBalances(address: address, balances: balances)
        self.tokenChartCoordinator?.coordinatorUpdatePendingBalances(address: address, balances: balances)
      case .failure(let error):
        print("--Get Pending Balances-- Error: \(error.prettyError)")
      }
    }
  }

  fileprivate func checkWalletEligible(completion: (((Bool, String?)) -> Void)?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion?((true, nil))
      return
    }
    KNLimitOrderServerCoordinator.shared.checkEligibleAddress(
      accessToken: accessToken,
      address: self.session.wallet.address.description) { [weak self] result in
        guard let _ = self else { return }
        switch result {
        case .success(let data):
          completion?(data)
        case .failure:
          completion?((true, nil))
        }
    }
  }

  fileprivate func signAndSendOrder(_ order: KNLimitOrder, completion: ((Bool) -> Void)?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.navigationController.displayLoading(text: "Checking".toBeLocalised(), animated: true)
    self.sendApprovedIfNeeded(order: order) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let isSuccess):
        if !isSuccess {
          self.navigationController.hideLoading()
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", comment: ""),
            message: "Can not send approve token request".toBeLocalised(),
            time: 1.5
          )
          completion?(false)
          return
        }
        self.approveTx[order.from.contract] = Date().timeIntervalSince1970
        self.navigationController.displayLoading(text: "Submitting order".toBeLocalised(), animated: true)
        let result = self.getSignedData(for: order)
        switch result {
        case .success(let data):
          KNLimitOrderServerCoordinator.shared.createNewOrder(accessToken: accessToken, order: order, signature: data, completion: { [weak self] result in
            guard let `self` = self else { return }
            self.navigationController.hideLoading()
            switch result {
            case .success(let resp):
              if let _ = resp.0, self.confirmVC != nil {
                self.rootViewController.coordinatorDoneSubmittingOrder()
                completion?(true)
              } else {
                self.navigationController.showErrorTopBannerMessage(
                  with: NSLocalizedString("error", comment: ""),
                  message: resp.1 ?? "Something went wrong, please try again later".toBeLocalised(),
                  time: 1.5
                )
                completion?(false)
              }
            case .failure(let error):
              self.navigationController.showErrorTopBannerMessage(
                with: NSLocalizedString("error", comment: ""),
                message: "Can not submit your order, error: \(error.prettyError)".toBeLocalised(),
                time: 1.5
              )
              completion?(false)
            }
          })
        case .failure(let error):
          self.navigationController.hideLoading()
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", comment: ""),
            message: "Can not sign your order, error: \(error.prettyError)".toBeLocalised(),
            time: 1.5
          )
          completion?(false)
        }
      case .failure(let error):
        self.navigationController.hideLoading()
        self.navigationController.displayError(error: error)
        completion?(false)
      }
    }
  }

  fileprivate func getSignedData(for order: KNLimitOrder) -> Result<Data, KeystoreError> {
    if let signedData = self.signedData, let confirmedOrder = self.confirmedOrder,
      confirmedOrder.account == order.account, confirmedOrder.nonce == order.nonce,
      confirmedOrder.fee == order.fee, confirmedOrder.sender == order.sender,
      confirmedOrder.from == order.from, confirmedOrder.to == order.to,
      confirmedOrder.targetRate == order.targetRate, confirmedOrder.srcAmount == order.srcAmount {
      return .success(signedData)
    }
    return self.session.keystore.signLimitOrder(order)
  }

  fileprivate func sendApprovedIfNeeded(order: KNLimitOrder, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.session.externalProvider.getAllowanceLimitOrder(token: order.from) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let remain):
        if remain >= BigInt(10).power(28) {
          completion(.success(true))
        } else {
          if let time = self.approveTx[order.from.contract] {
            let preDate = Date(timeIntervalSince1970: time)
            if Date().timeIntervalSince(preDate) <= 5.0 * 60.0 {
              // less than 5 mins ago
              completion(.success(true))
              return
            }
          }
          self.sendApprovedTransaction(order: order, remain: remain, completion: completion)
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func sendApprovedTransaction(order: KNLimitOrder, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendResetAllowanceIfNeeded(order: order, remain: remain) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let isSuccess):
        if isSuccess {
          self.session.externalProvider.sendApproveERCTokenLimitOrder(
            for: order.from,
            value: BigInt(2).power(256) - BigInt(1),
            gasPrice: KNGasCoordinator.shared.fastKNGas,
            completion: completion
          )
        } else {
          completion(.success(false))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func sendResetAllowanceIfNeeded(order: KNLimitOrder, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if remain.isZero {
      completion(.success(true))
      return
    }
    self.session.externalProvider.sendApproveERCTokenLimitOrder(
      for: order.from,
      value: BigInt(0),
      gasPrice: KNGasCoordinator.shared.fastKNGas,
      completion: completion
    )
  }

  fileprivate func openPromoCodeView() {
    self.delegate?.limitOrderTabCoordinatorDidSelectPromoCode()
  }

  fileprivate func openAddWalletView() {
    self.delegate?.limitOrderTabCoordinatorDidSelectAddWallet()
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

  fileprivate func updateCurrentWallet(_ wallet: KNWalletObject) {
    self.delegate?.limitOrderTabCoordinatorDidSelectWallet(wallet)
  }

  fileprivate func openHistoryTransactionsView() {
    self.historyCoordinator = nil
    self.historyCoordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session
    )
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator?.start()
  }

  fileprivate func openSelectMarketScreen() {
    self.navigationController.pushViewController(self.marketsVC, animated: true)
  }

  fileprivate func openCancelSuggestionOrderScreen(header: [String], sections: [String: [KNOrderObject]], cancelOrder: KNOrderObject?, parent: UIViewController) {
    let vc = KNCancelSuggestOrdersViewController(header: header, sections: sections, cancelOrder: cancelOrder, parent: parent)
    vc.delegate = self
    self.navigationController.pushViewController(vc, animated: true)
  }

  fileprivate func openSendTokenView() {
    if let topVC = self.navigationController.topViewController, topVC is KSendTokenViewController { return }
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      let from: TokenObject = {
        guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description), let token = self.session.tokenStorage.tokens.first(where: { return $0.symbol == destToken }) else {
          return self.session.tokenStorage.ethToken
        }
        return token
      }()
      self.sendTokenCoordinator = KNSendTokenViewCoordinator(
        navigationController: self.navigationController,
        session: self.session,
        balances: self.balances,
        from: from
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
}

extension KNLimitOrderTabCoordinatorV2: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidClose() {
    //    self.historyCoordinator = nil
  }
}

extension KNLimitOrderTabCoordinatorV2: KNManageOrdersViewControllerDelegate {
}

extension KNLimitOrderTabCoordinatorV2: PreviewLimitOrderV2ViewControllerDelegate {
  func previewLimitOrderV2ViewControllerDidBack() {
    KNCrashlyticsUtil.logCustomEvent(withName: "loconfirm_cancel", customAttributes: nil)
    self.navigationController.popToRootViewController(animated: true) {
      self.confirmVC = nil
      self.convertVC = nil
    }
  }

  func previewLimitOrderV2ViewController(_ controller: PreviewLimitOrderV2ViewController, order: KNLimitOrder) {
    self.signAndSendOrder(order) { [weak self] isSuccess in
      guard let `self` = self else { return }
      if isSuccess, self.confirmVC != nil {
        KNCrashlyticsUtil.logCustomEvent(withName: "loconfirm_order_success",
                                         customAttributes: [
                                          "token_pair": "\(order.from.symbol)_\(order.to.symbol)",
                                          "current_rate": controller.livePriceValueLabel.text ?? "",
                                          "target_price": controller.yourPriceValueLabel.text ?? "",
                                          "des_amount": controller.quantityValueLabel.text ?? "",
                                          "fee": controller.feeValueLabel.text ?? "",
          ]
        )
        self.navigationController.popToRootViewController(animated: true, completion: {
          self.confirmVC = nil
          self.convertVC = nil
          self.rootViewController.coordinatorFinishConfirmOrder()
        })
      } else {
        KNCrashlyticsUtil.logCustomEvent(withName: "loconfirm_order_failed",
                                         customAttributes: [
                                          "token_pair": "\(order.from.symbol)_\(order.to.symbol)",
                                          "current_rate": controller.livePriceValueLabel.text ?? "",
                                          "target_price": controller.yourPriceValueLabel.text ?? "",
                                          "des_amount": controller.quantityValueLabel.text ?? "",
                                          "fee": controller.feeValueLabel.text ?? "",
          ]
        )
      }
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: KNConvertSuggestionViewControllerDelegate {
  func convertSuggestionViewController(_ controller: KNConvertSuggestionViewController, run event: KNConvertSuggestionViewEvent) {
    switch event {
    case .estimateGasLimit(let from, let to, let amount):
      self.updateEstimatedGasLimit(from: from, to: to, amount: amount)
    case .confirmSwap(let transaction):
      self.navigationController.displayLoading(text: "Sending...".toBeLocalised(), animated: true)
      sendGetPreScreeningWalletRequest { [weak self] (result) in
        guard let `self` = self else { return }
        var message: String?
        if case .success(let resp) = result,
          let json = try? resp.mapJSON() as? JSONDictionary ?? [:] {
          if let status = json["eligible"] as? Bool {
            if isDebug { print("eligible status : \(status)") }
            if status == false { message = json["message"] as? String }
          }
        }
        self.navigationController.hideLoading()
        if let errorMessage = message {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: errorMessage,
            time: 2.0
          )
        } else {
          self.sendExchangeTransaction(transaction)
        }
      }
    }
  }

  fileprivate func updateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt) {
    let exchangeTx = KNDraftExchangeTransaction(
      from: from,
      to: to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(0),
      minRate: .none,
      gasPrice: KNGasConfiguration.exchangeETHTokenGasLimitDefault,
      gasLimit: .none,
      expectedReceivedString: nil
    )
    self.session.externalProvider.getEstimateGasLimit(for: exchangeTx) { [weak self] result in
      if case .success(let estimate) = result {
        self?.convertVC?.updateEstimateGasLimit(estimate)
      }
    }
  }

  fileprivate func sendExchangeTransaction(_ exchage: KNDraftExchangeTransaction) {
    self.session.externalProvider.exchange(exchange: exchage) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let txHash):
        self.sendUserTxHashIfNeeded(txHash)
        let transaction = exchage.toTransaction(
          hash: txHash,
          fromAddr: self.session.wallet.address,
          toAddr: self.session.externalProvider.networkAddress,
          nounce: self.session.externalProvider.minTxCount - 1
        )
        self.session.addNewPendingTransaction(transaction)
        if self.convertVC != nil {
          if let order = self.curOrder {
            self.checkDataBeforeConfirmOrder(order, confirmData: self.curConfirmData)
          } else {
            self.navigationController.popViewController(animated: true, completion: {
              self.convertVC = nil
            })
          }
        }
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    }
  }

  fileprivate func sendUserTxHashIfNeeded(_ txHash: String) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])
    provider.request(.sendTxHash(authToken: accessToken, txHash: txHash)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let success = json["success"] as? Bool ?? false
          let message = json["message"] as? String ?? "Unknown"
          if success {
            KNCrashlyticsUtil.logCustomEvent(withName: "lo_send_tx_hash_success", customAttributes: nil)
          } else {
            KNCrashlyticsUtil.logCustomEvent(withName: "lo_send_tx_hash_failure", customAttributes: ["error": message])
          }
        } catch {
          KNCrashlyticsUtil.logCustomEvent(withName: "lo_send_tx_hash_failure", customAttributes: nil)
        }
      case .failure:
        KNCrashlyticsUtil.logCustomEvent(withName: "lo_send_tx_hash_failure", customAttributes: nil)
      }
    }
  }

  fileprivate func sendGetPreScreeningWalletRequest(completion: @escaping (Result<Moya.Response, MoyaError>) -> Void) {
    let address = self.session.wallet.address.description
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<UserInfoService>()
      provider.request(.getPreScreeningWallet(address: address)) { result in
        DispatchQueue.main.async {
          completion(result)
        }
      }
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: QRCodeReaderDelegate {
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

extension KNLimitOrderTabCoordinatorV2: KNListNotificationViewControllerDelegate {
  func listNotificationViewController(_ controller: KNListNotificationViewController, run event: KNListNotificationViewEvent) {
    switch event {
    case .openSwap(let from, let to):
      self.delegate?.limitOrderTabCoordinatorOpenExchange(from: from, to: to)
    case .openManageOrder:
      if IEOUserStorage.shared.user == nil {
        self.rootViewController.tabBarController?.selectedIndex = 3
        self.showWarningTopBannerMessage(
          with: "Sign in required".toBeLocalised(),
          message: "You must sign in to use Limit Order feature".toBeLocalised(),
          time: 1.5
        )
        return
      }
      self.navigationController.popToRootViewController(animated: true) {
        self.appCoordinatorOpenManageOrder()
      }
    case .openSetting:
      self.openNotificationSettingScreen()
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: KNNotificationSettingViewControllerDelegate {
  func notificationSettingViewControllerDidApply(_ controller: KNNotificationSettingViewController) {
    self.navigationController.popViewController(animated: true) {
      self.showSuccessTopBannerMessage(message: "Updated subscription tokens".toBeLocalised())
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: KNSelectMarketViewControllerDelegate {
  func selectMarketViewControllerDidSelectMarket(_ controller: KNSelectMarketViewController, market: KNMarket) {
    self.navigationController.popViewController(animated: true)
    self.rootViewController.coordinatorUpdateMarket(market: market)
  }

  func selectMarketViewControllerDidSelectLOV1(_ controller: KNSelectMarketViewController) {
    self.limitOrderV1Coordinator = KNLimitOrderTabCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      approveTx: self.approveTx
    )
    self.limitOrderV1Coordinator?.delegate = self
    self.limitOrderV1Coordinator?.start()
  }

  func selectMakertViewController(_ controller: KNSelectMarketViewController, run event: KNSelectMarketEvent) {
    switch event {
    case .getListFavouriteMarket:
      guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
        self.marketsVC.coordinatorUpdatedFavouriteList(true)
        return
      }
      let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])
      provider.request(.getListFavouriteMarket(accessToken: accessToken)) { (result) in
        switch result {
        case .success(let resp):
          do {
            _ = try resp.filterSuccessfulStatusCodes()
            let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
            let success = json["success"] as? Bool ?? false
            let pairs = json["favorite_pairs"] as? [[String: String]]
            if let notNilPairs = pairs, success {
              let markets = notNilPairs.map { "\($0["quote"] ?? "")_\($0["base"] ?? "")" }.map { $0.uppercased() }
              KNAppTracker.setListFavouriteMarkets(pairs: markets)
              self.marketsVC.coordinatorUpdatedFavouriteList(true)
              return
            } else {
              self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
            }
          } catch {
            self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
          }
        case .failure:
          self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
        }
        self.marketsVC.coordinatorUpdatedFavouriteList(false)
      }
    case .updateMarketFavouriteStatus(let base, let quote, let status):
      guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
        self.rootViewController.tabBarController?.selectedIndex = 3
        self.showWarningTopBannerMessage(
          with: "Sign in required".toBeLocalised(),
          message: "You must sign in to use Limit Order feature".toBeLocalised(),
          time: 1.5
        )
        self.marketsVC.coordinatorUpdatedFavouriteList(true)
        return
      }
      let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])
      provider.request(.updateMarketFavouriteStatus(accessToken: accessToken, base: base, quote: quote, status: status)) { (result) in
        switch result {
        case .success(let resp):
          do {
            _ = try resp.filterSuccessfulStatusCodes()
            let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
            let success = json["success"] as? Bool ?? false
            if success {
              let pair = "\(quote)_\(base)"
              KNAppTracker.updateFavouriteMarket(pair, add: status)
              self.marketsVC.coordinatorUpdatedFavouriteList(true)
              let message = status ? NSLocalizedString("Successfully added to your favorites", comment: "") : NSLocalizedString("Removed from your favorites", comment: "")
              self.showSuccessTopBannerMessage(message: message)
              return
            } else {
              self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
            }
          } catch {
            self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
          }
        case .failure:
          self.showErrorTopBannerMessage(message: "Something went wrong, please try again later".toBeLocalised())
        }
        self.marketsVC.coordinatorUpdatedFavouriteList(false)
      }
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: KNLimitOrderTabCoordinatorDelegate {
  func limitOrderTabCoordinatorDidStop(_ coordinator: KNLimitOrderTabCoordinator) {
    self.navigationController.popViewController(animated: true) {
      self.limitOrderV1Coordinator = nil
    }
  }
}

extension KNLimitOrderTabCoordinatorV2: KNCancelSuggestOrdersViewControllerDelegate {
  func cancelSuggestOrdersViewControllerDidCheckUnderstand(_ controller: KNCancelSuggestOrdersViewController) {
    self.navigationController.popToRootViewController(animated: true)
    self.rootViewController.coordinatorUnderstandCheckedInShowCancelSuggestOrder(source: controller.sourceVC)
  }
}

extension KNLimitOrderTabCoordinatorV2: KNTokenChartCoordinatorDelegate {
  func tokenChartCoordinatorShouldBack() {
    self.navigationController.popToRootViewController(animated: true) {
      self.tokenChartCoordinator = nil
    }
  }

  func tokenChartCoordinator(buy token: TokenObject) {
    self.navigationController.popToRootViewController(animated: true) {
      self.rootViewController.coordinatorShouldSelectNewPage(isBuy: true)
    }
  }

  func tokenChartCoordinator(sell token: TokenObject) {
    self.navigationController.popToRootViewController(animated: true) {
      self.rootViewController.coordinatorShouldSelectNewPage(isBuy: false)
    }
  }
}
