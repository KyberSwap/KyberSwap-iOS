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

class KNLimitOrderTabCoordinatorV2: NSObject, Coordinator {

  let navigationController: UINavigationController
  var session: KNSession
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true
  var coordinators: [Coordinator] = []

  var curOrder: KNLimitOrder?
  var confirmedOrder: KNLimitOrder?
  var signedData: Data?

  weak var delegate: KNLimitOrderTabCoordinatorDelegate?

  fileprivate var balances: [String: Balance] = [:]
  fileprivate var approveTx: [String: TimeInterval] = [:]

  fileprivate var historyCoordinator: KNHistoryCoordinator?
  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  fileprivate var confirmVC: PreviewLimitOrderV2ViewController?
  fileprivate var manageOrdersVC: KNManageOrdersViewController?
  fileprivate var convertVC: KNConvertSuggestionViewController?
  fileprivate lazy var marketsVC: KNSelectMarketViewController = {
    let viewModel = KNSelectMarketViewModel()
    return KNSelectMarketViewController(viewModel: viewModel)
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
//    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    self.balances = [:]
    self.approveTx = [:]
    let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
//    self.rootViewController.coordinatorDidUpdatePendingTransactions(pendingTrans)
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
  }

  func appCoordinatorDidUpdateWalletObjects() {
//    self.rootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.historyCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func appCoordinatorMarketCachedDidUpdate() {
    self.rootViewController.coordinatorMarketCachedDidUpdate()
    self.marketsVC.coordinatorMarketCachedDidUpdate()
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.convertVC?.updateWETHBalance(otherTokensBalance)
  }

  func appCoordinatorETHBalanceDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, ethBalance: Balance) {
    if let eth = self.tokens.first(where: { $0.isETH }) {
      self.balances[eth.contract] = ethBalance
      self.rootViewController.coordinatorUpdateTokenBalance([eth.contract: ethBalance])
    }
    self.sendTokenCoordinator?.coordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
    self.convertVC?.updateETHBalance(ethBalance.value)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
//    self.rootViewController.coordinatorTrackerRateDidUpdate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }

  func appCoordinatorUpdateExchangeTokenRates() {
//    self.rootViewController.coordinatorUpdateProdCachedRates()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    let supportedTokens = KNSupportedTokenStorage.shared.supportedTokens
    self.tokens = supportedTokens
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
//    self.rootViewController.coordinatorDidUpdatePendingTransactions(transactions)
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    return self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) ?? false
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
    case .openConvertWETH(let address, let ethBalance, let amount, let pendingWETH, let order):
      self.curOrder = order
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
    self.checkWalletEligible { isEligible in
      if !isEligible {
        errorMessage = "This address has been used by another account. Please place order with other address.".toBeLocalised()
      }
      group.leave()
    }

    group.notify(queue: .main) {
      self.navigationController.hideLoading()
      if let error = errorMessage {
        KNCrashlyticsUtil.logCustomEvent(withName: "limit_order_coordinator", customAttributes: ["action": "submit_error_\(error)"])
        if self.navigationController.viewControllers.count > 1 {
          self.navigationController.popToRootViewController(animated: true, completion: {
            self.navigationController.showWarningTopBannerMessage(with: "", message: error, time: 2.0)
          })
        } else {
          self.navigationController.showWarningTopBannerMessage(with: "", message: error, time: 2.0)
        }
      } else {
        let attributes = [
          "action": "submit_\(order.srcAmount.displayRate(decimals: order.from.decimals))_\(order.from.symbol)_\(order.to.symbol)",
        ]
        KNCrashlyticsUtil.logCustomEvent(withName: "limit_order_coordinator", customAttributes: attributes)
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
//      self.rootViewController.coordinatorUpdateListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate, orders: [])
      return
    }
    KNLimitOrderServerCoordinator.shared.getRelatedOrders(accessToken: accessToken, address: address, src: src, dest: dest, minRate: minRate) { [weak self] result in
      guard let `self` = self else { return }
//      switch result {
//      case .success(let orders):
//        self.rootViewController.coordinatorUpdateListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate, orders: orders)
//      case .failure(let error):
//        print("--Get Related Order-- Error: \(error.prettyError)")
//      }
    }
  }

  fileprivate func getPendingBalances(address: String) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      // reset pending balance
      self.convertVC?.updatePendingWETHBalance(0.0)
//      self.rootViewController.coordinatorUpdatePendingBalances(address: address, balances: [:])
      return
    }
    KNLimitOrderServerCoordinator.shared.getPendingBalances(accessToken: accessToken, address: address) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let balances):
        self.convertVC?.updatePendingWETHBalance(balances["WETH"] as? Double ?? 0.0)
//        self.rootViewController.coordinatorUpdatePendingBalances(address: address, balances: balances)
      case .failure(let error):
        print("--Get Pending Balances-- Error: \(error.prettyError)")
      }
    }
  }

  fileprivate func checkWalletEligible(completion: ((Bool) -> Void)?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion?(true)
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
          completion?(true)
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
//                self.rootViewController.coordinatorDoneSubmittingOrder()
                KNAppTracker.logFirstTimeLimitOrderIfNeeded()
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
            value: BigInt(2).power(255),
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

  fileprivate func openSearchToken(from: TokenObject, to: TokenObject, isSource: Bool, pendingBalances: JSONDictionary) {
    // TODO: open select pair
  }

  fileprivate func openSelectMarketScreen() {
    self.navigationController.pushViewController(self.marketsVC, animated: true)
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
    self.navigationController.popToRootViewController(animated: true) {
      self.confirmVC = nil
      self.convertVC = nil
    }
  }

  func previewLimitOrderV2ViewController(_ controller: PreviewLimitOrderV2ViewController, order: KNLimitOrder) {
    self.signAndSendOrder(order) { [weak self] isSuccess in
      guard let `self` = self else { return }
      if isSuccess, self.confirmVC != nil {
        KNCrashlyticsUtil.logCustomEvent(withName: "limit_order_coordinator", customAttributes: ["info": "success_\(order.from.symbol)_\(order.to.symbol)"])
        self.navigationController.popToRootViewController(animated: true, completion: {
          self.confirmVC = nil
          self.convertVC = nil
        })
      } else {
        KNCrashlyticsUtil.logCustomEvent(withName: "limit_order_coordinator", customAttributes: ["info": "failed_\(order.from.symbol)_\(order.to.symbol)"])
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
            self.checkDataBeforeConfirmOrder(order, confirmData: nil)
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
            KNCrashlyticsUtil.logCustomEvent(withName: "swap_coordinator", customAttributes: ["action": "tx_hash_sent"])
          } else {
            KNCrashlyticsUtil.logCustomEvent(withName: "swap_coordinator", customAttributes: ["action": "error_\(message)"])
          }
        } catch {
          KNCrashlyticsUtil.logCustomEvent(withName: "swap_coordinator", customAttributes: ["action": "failed_to_send"])
        }
      case .failure:
        KNCrashlyticsUtil.logCustomEvent(withName: "swap_coordinator", customAttributes: ["action": "failed_to_send"])
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
      if IEOUserStorage.shared.user == nil { return }
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
