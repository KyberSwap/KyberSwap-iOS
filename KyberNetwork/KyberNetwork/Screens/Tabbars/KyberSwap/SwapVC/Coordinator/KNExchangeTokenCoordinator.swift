// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result
import Moya
import APIKit
import QRCodeReaderViewController
import WalletConnect
import MBProgressHUD

protocol KNExchangeTokenCoordinatorDelegate: class {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject)
  func exchangeTokenCoordinatorRemoveWallet(_ wallet: Wallet)
  func exchangeTokenCoordinatorDidSelectAddWallet()
  func exchangeTokenCoordinatorDidSelectPromoCode()
  func exchangeTokenCoordinatorOpenManageOrder()
  func exchangeTokenCoordinatorDidUpdateWalletObjects()
  func exchangeTokenCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: Wallet)
}

//swiftlint:disable file_length
class KNExchangeTokenCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  fileprivate(set) var session: KNSession
  var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  var isSelectingSourceToken: Bool = true

  var coordinators: [Coordinator] = []

  fileprivate var balances: [String: Balance] = [:]
  weak var delegate: KNExchangeTokenCoordinatorDelegate?

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var setGasPriceVC: KNSetGasPriceViewController?
  fileprivate var confirmSwapVC: KConfirmSwapViewController?
  fileprivate var promoConfirmSwapVC: KNPromoSwapConfirmViewController?
  fileprivate var transactionStatusVC: KNTransactionStatusPopUp?
  fileprivate var gasFeeSelectorVC: GasFeeSelectorPopupViewController?
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  lazy var rootViewController: KSwapViewController = {
    let (from, to): (TokenObject, TokenObject) = {
      let address = self.session.wallet.address.description
      let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address)
      if let dest = destToken, let from = KNSupportedTokenStorage.shared.ptToken {
        let to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == dest.uppercased() }) ?? KNSupportedTokenStorage.shared.ethToken
        return (from, to)
      }
      return (KNSupportedTokenStorage.shared.ethToken, KNSupportedTokenStorage.shared.kncToken)
    }()
    let viewModel = KSwapViewModel(
      wallet: self.session.wallet,
      from: from,
      to: to,
      supportedTokens: tokens
    )
    let controller = KSwapViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var promoCodeCoordinator: KNPromoCodeCoordinator?

  fileprivate var qrcodeCoordinator: KNWalletQRCodeCoordinator? {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description) else { return nil }
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController,
      walletObject: walletObject
    )
    return qrcodeCoordinator
  }

  fileprivate var historyCoordinator: KNHistoryCoordinator?
  fileprivate var searchTokensViewController: KNSearchTokenViewController?

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
    self.sendTokenCoordinator = nil
    self.confirmSwapVC = nil
    self.promoConfirmSwapVC = nil
    self.promoCodeCoordinator = nil
    self.historyCoordinator = nil
    self.searchTokensViewController = nil
  }
}

// MARK: Update from app coordinator
extension KNExchangeTokenCoordinator {
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorUpdateNewSession(wallet: session.wallet)
    if resetRoot {
      self.navigationController.popToRootViewController(animated: false)
    }
    self.balances = [:]
    
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
    self.rootViewController.coordinatorUpdateWalletObjects()
    self.historyCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    self.rootViewController.coordinatorUpdateTokenBalance(otherTokensBalance)
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
    self.searchTokensViewController?.updateBalances(otherTokensBalance)
  }

  func appCoordinatorUSDRateDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt) {
    self.rootViewController.coordinatorTrackerRateDidUpdate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
//    self.confirmSwapVC?.coordinatorUpdateCurrentMarketRate()
  }

//  func appCoordinatorUpdateExchangeTokenRates() {
////    self.rootViewController.coordinatorUpdateProdCachedRates()
//    self.confirmSwapVC?.coordinatorUpdateCurrentMarketRate()
//  }

  func appCoordinatorShouldOpenExchangeForToken(_ token: TokenObject, isReceived: Bool = false) {
    self.navigationController.popToRootViewController(animated: true)
    if KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description) != nil {
      // promo wallet, keep old behaviour
      self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived)
    } else {
      // normal wallet
      let otherToken: TokenObject = token.isETH ? KNSupportedTokenStorage.shared.kncToken : KNSupportedTokenStorage.shared.ethToken
      self.rootViewController.coordinatorUpdateSelectedToken(token, isSource: !isReceived, isWarningShown: false)
      self.rootViewController.coordinatorUpdateSelectedToken(otherToken, isSource: isReceived, isWarningShown: true)
    }
    self.rootViewController.tabBarController?.selectedIndex = 1
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    let supportedTokens = KNSupportedTokenStorage.shared.supportedTokens
    self.tokens = supportedTokens
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
    self.searchTokensViewController?.updateListSupportedTokens(supportedTokens)
  }

  func appCoordinatorPendingTransactionsDidUpdate(transactions: [KNTransaction]) {
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate(transactions)
  }

  func appCoordinatorGasPriceCachedDidUpdate() {
    self.rootViewController.coordinatorUpdateGasPriceCached()
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.historyCoordinator?.coordinatorGasPriceCachedDidUpdate()
    self.gasFeeSelectorVC?.coordinatorDidUpdateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
  }

  func appCoordinatorTokensTransactionsDidUpdate() {
    self.historyCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  func appCoordinatorPushNotificationOpenSwap(from: String, to: String) {
    guard let from = self.session.tokenStorage.tokens.first(where: { return $0.symbol == from }),
      let to = self.session.tokenStorage.tokens.first(where: { return $0.symbol == to }) else { return }
    self.navigationController.popToRootViewController(animated: false)
    self.rootViewController.coordinatorUpdateSelectedToken(from, isSource: true, isWarningShown: false)
    self.rootViewController.coordinatorUpdateSelectedToken(to, isSource: false)
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if self.historyCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) == true { return true }
    if let trans = self.transactionStatusVC?.transaction, trans.id == txID {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
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
}

// MARK: Network requests
extension KNExchangeTokenCoordinator {
  fileprivate func didConfirmSendExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction) {
    self.rootViewController.coordinatorExchangeTokenUserDidConfirmTransaction()
    KNNotificationUtil.postNotification(for: kTransactionDidUpdateNotificationKey)
    var fee = BigInt(0)
    if let gasPrice = exchangeTransaction.gasPrice, let gasLimit = exchangeTransaction.gasLimit {
      fee = gasPrice * gasLimit
    }
    self.session.externalProvider.getAllowance(token: exchangeTransaction.from) { [weak self] getAllowanceResult in
      guard let `self` = self else { return }
      switch getAllowanceResult {
      case .success(let res):
        if res >= exchangeTransaction.amount {
          self.sendExchangeTransaction(exchangeTransaction)
        } else {
          self.sendApproveForExchangeTransaction(exchangeTransaction, remain: res)
        }
      case .failure(let error):
        self.promoConfirmSwapVC?.resetActionButtons()
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
        KNCrashlyticsUtil.logCustomEvent(withName: "swapconfirm_broadcast_failed",
                                         customAttributes: [
                                          "token_pair": "\(exchangeTransaction.from.name)/\(exchangeTransaction.to.name)",
                                          "amount": exchangeTransaction.amount.displayRate(decimals: exchangeTransaction.from.decimals),
                                          "current_rate": exchangeTransaction.expectedRate.displayRate(decimals: 18),
                                          "min_rate": exchangeTransaction.minRate?.displayRate(decimals: 18) ?? "",
                                          "tx_fee": fee.displayRate(decimals: 18),
                                          "error_text": error.description,
          ]
        )
      }
    }
  }

  fileprivate func sendExchangeTransaction(_ exchage: KNDraftExchangeTransaction) {
    var fee = BigInt(0)
    if let gasPrice = exchage.gasPrice, let gasLimit = exchage.gasLimit {
      fee = gasPrice * gasLimit
    }
    self.session.externalProvider.exchange(exchange: exchage) { [weak self] result in
      guard let `self` = self else { return }
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
        if KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description) == nil {
          if self.confirmSwapVC != nil {
            self.navigationController.popViewController(animated: true, completion: {
              self.confirmSwapVC = nil
              self.openTransactionStatusPopUp(transaction: transaction)
            })
          }
        } else {
          // promo code
          if self.promoConfirmSwapVC != nil {
            self.navigationController.popViewController(animated: true, completion: {
              self.promoConfirmSwapVC = nil
              self.openTransactionStatusPopUp(transaction: transaction)
            })
          }
        }
        KNCrashlyticsUtil.logCustomEvent(withName: "swapconfirm_broadcast_success",
                                         customAttributes: [
                                          "token_pair": "\(exchage.from.name)/\(exchage.to.name)",
                                          "amount": exchage.amount.displayRate(decimals: exchage.from.decimals),
                                          "current_rate": exchage.expectedRate.displayRate(decimals: 18),
                                          "min_rate": exchage.minRate?.displayRate(decimals: 18) ?? "",
                                          "tx_fee": fee.displayRate(decimals: 18),
          ]
        )
      case .failure(let error):
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
        KNCrashlyticsUtil.logCustomEvent(withName: "swapconfirm_broadcast_failed",
                                         customAttributes: [
                                          "token_pair": "\(exchage.from.name)/\(exchage.to.name)",
                                          "amount": exchage.amount.displayRate(decimals: exchage.from.decimals),
                                          "current_rate": exchage.expectedRate.displayRate(decimals: 18),
                                          "min_rate": exchage.minRate?.displayRate(decimals: 18) ?? "",
                                          "tx_fee": fee.displayRate(decimals: 18),
                                          "error_text": error.description,
          ]
        )
      }
    }
  }

  fileprivate func openTransactionStatusPopUp(transaction: Transaction) {
    let trans = KNTransaction.from(transaction: transaction)
    self.transactionStatusVC = KNTransactionStatusPopUp(transaction: trans)
    self.transactionStatusVC?.modalPresentationStyle = .overFullScreen
    self.transactionStatusVC?.modalTransitionStyle = .crossDissolve
    self.transactionStatusVC?.delegate = self
    self.navigationController.present(self.transactionStatusVC!, animated: true, completion: nil)
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
            KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_send_tx_hash_success", customAttributes: nil)
          } else {
            KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_send_tx_hash_failure", customAttributes: ["error": message])
          }
        } catch {
          KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_send_tx_hash_failure", customAttributes: nil)
        }
      case .failure:
        KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_send_tx_hash_failure", customAttributes: nil)
      }
    }
  }

  fileprivate func sendApproveForExchangeTransaction(_ exchangeTransaction: KNDraftExchangeTransaction, remain: BigInt) {
    self.resetAllowanceForExchangeTransactionIfNeeded(exchangeTransaction, remain: remain) { [weak self] resetResult in
      guard let `self` = self else { return }
      switch resetResult {
      case .success:
        self.session.externalProvider.sendApproveERC20Token(exchangeTransaction: exchangeTransaction) { [weak self] result in
          switch result {
          case .success:
            self?.sendExchangeTransaction(exchangeTransaction)
          case .failure(let error):
            KNNotificationUtil.postNotification(
              for: kTransactionDidUpdateNotificationKey,
              object: error,
              userInfo: nil
            )
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

  fileprivate func resetAllowanceForExchangeTransactionIfNeeded(_ exchangeTransaction: KNDraftExchangeTransaction, remain: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    if remain.isZero {
      completion(.success(true))
      return
    }
    let gasPrice = exchangeTransaction.gasPrice ?? KNGasCoordinator.shared.defaultKNGas
    self.session.externalProvider.sendApproveERCToken(
      for: exchangeTransaction.from,
      value: BigInt(0),
      gasPrice: gasPrice
    ) { result in
      switch result {
      case .success:
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

// MARK: Promo Confirm transaction
extension KNExchangeTokenCoordinator: KNPromoSwapConfirmViewControllerDelegate {
  func promoCodeSwapConfirmViewControllerDidBack() {
    self.navigationController.popViewController(animated: true) {
      self.promoConfirmSwapVC = nil
    }
  }

  func promoCodeSwapConfirmViewController(_ controller: KNPromoSwapConfirmViewController, transaction: KNDraftExchangeTransaction, destAddress: String, hint: String) {
    self.didConfirmSendExchangeTransaction(transaction)
  }
}

// MARK: Confirm transaction
extension KNExchangeTokenCoordinator: KConfirmSwapViewControllerDelegate {
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, run event: KConfirmViewEvent) {
    if case .confirm(let type) = event, case .exchange(let exchangeTransaction) = type {
      self.didConfirmSendExchangeTransaction(exchangeTransaction)
    } else {
      self.navigationController.popViewController(animated: true) {
        self.confirmSwapVC = nil
      }
    }
  }
}

// MARK: Swap view delegation
extension KNExchangeTokenCoordinator: KSwapViewControllerDelegate {
  func kSwapViewController(_ controller: KSwapViewController, run event: KSwapViewEvent) {
    switch event {
    case .searchToken(let from, let to, let isSource):
      self.openSearchToken(from: from, to: to, isSource: isSource)
//    case .estimateRate(let from, let to, let amount, let hint, let showError):
//      self.updateExpectedRateWithKyberIfNeeded(from: from, to: to, amount: amount, hint: hint, showError: showError)
    case .estimateGas(let from, let to, let amount, let gasPrice, let hint):
      self.updateEstimatedGasLimit(from: from, to: to, amount: amount, gasPrice: gasPrice, hint: hint)
    case .showQRCode:
      self.showWalletQRCode()
    case .setGasPrice(let gasPrice, let gasLimit):
      self.openSetGasPrice(gasPrice: gasPrice, estGasLimit: gasLimit)
    case .validateRate(let data):
      self.validateRateBeforeSwapping(data: data)
    case .swap(let data):
      self.exchangeButtonPressed(data: data)
    case .quickTutorial(let step, let pointsAndRadius):
      self.openQuickTutorial(controller, step: step, pointsAndRadius: pointsAndRadius)
    case .openGasPriceSelect(let gasLimit, let type, let pair, let percent):
      let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: true, gasLimit: gasLimit, selectType: type, currentRatePercentage: percent)
      viewModel.updateGasPrices(
        fast: KNGasCoordinator.shared.fastKNGas,
        medium: KNGasCoordinator.shared.standardKNGas,
        slow: KNGasCoordinator.shared.lowKNGas,
        superFast: KNGasCoordinator.shared.superFastKNGas
      )
      viewModel.updatePairToken(pair)
      let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
      vc.delegate = self
      self.gasFeeSelectorVC = vc
      self.navigationController.present(vc, animated: true, completion: nil)
    case .updateRate(let rate):
      self.gasFeeSelectorVC?.coordinatorDidUpdateMinRate(rate)
    case .openHistory:
      self.historyCoordinator = nil
      self.historyCoordinator = KNHistoryCoordinator(
        navigationController: self.navigationController,
        session: self.session
      )
      self.historyCoordinator?.delegate = self
      self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
      self.historyCoordinator?.start()
    case .openWalletsList:
      let viewModel = WalletsListViewModel(
        walletObjects: KNWalletStorage.shared.wallets,
        currentWallet: self.currentWallet
      )
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .getAllRates(let from, let to, let srcAmount):
      self.getAllRates(from: from, to: to, srcAmount: srcAmount)
    case .openChooseRate(let from, let to, let rates):
      let viewModel = ChooseRateViewModel(from: from, to: to, data: rates)
      let vc = ChooseRateViewController(viewModel: viewModel)
      vc.delegate = self
      self.navigationController.present(vc, animated: true, completion: nil)
    }
  }

  fileprivate func openQuickTutorial(_ controller: KSwapViewController, step: Int, pointsAndRadius: [(CGPoint, CGFloat)]) {
    var attributedString = NSMutableAttributedString()
    var contentTopOffset: CGFloat = 0.0
    var nextButtonText = "next".toBeLocalised()
    switch step {
    case 1:
      attributedString = NSMutableAttributedString(string: "Step 1\nSelect tokens you want to swap.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 315
    case 2:
      attributedString = NSMutableAttributedString(string: "Step 2\nEnter any amount manually or use quick select.".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 400
    case 3:
      attributedString = NSMutableAttributedString(string: "Step 3 (optional)\nAdjust gas fees and slippage".toBeLocalised(), attributes: [
        .font: UIFont.Kyber.regular(with: 18),
        .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
        .kern: 0.0,
      ])
      contentTopOffset = 166
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
    KNCrashlyticsUtil.logCustomEvent(withName: "tut_swap_show_quick_tutorial", customAttributes: ["step": step])
  }

  fileprivate func openSearchToken(from: TokenObject, to: TokenObject, isSource: Bool) {
    if let topVC = self.navigationController.topViewController, topVC is KNSearchTokenViewController { return }
    self.isSelectingSourceToken = isSource
    self.tokens = KNSupportedTokenStorage.shared.supportedTokens
    self.searchTokensViewController = {
      let viewModel = KNSearchTokenViewModel(
        headerColor: KNAppStyleType.current.swapHeaderBackgroundColor,
        supportedTokens: self.tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.searchTokensViewController!, animated: true)
    self.searchTokensViewController?.updateBalances(self.balances)
  }

  fileprivate func validateRateBeforeSwapping(data: KNDraftExchangeTransaction) {
    self.navigationController.displayLoading(text: NSLocalizedString("checking", value: "Checking", comment: ""), animated: true)
    var errorMessage: String?
    let group = DispatchGroup()
//    group.enter()
//    self.updateEstimatedRate(from: data.from, to: data.to, amount: data.amount, hint: data.hint ?? "", showError: false) { error in
//      if let err = error { errorMessage = err.prettyError }
//      group.leave()
//    }
    if !((data.from.isETH && data.to.isWETH) || (data.from.isWETH && data.to.isETH)) {
      // only need to check cap if not ETH <-> WETH swap
      group.enter()
      sendGetPreScreeningWalletRequest { (result) in
        if case .success(let resp) = result,
          let json = try? resp.mapJSON() as? JSONDictionary ?? [:] {
          if let status = json["eligible"] as? Bool {
            if isDebug { print("eligible status : \(status)") }
            if status == false { errorMessage = json["message"] as? String }
          }
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      self.navigationController.hideLoading()
      if let message = errorMessage {
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: message,
          time: 2.0
        )
      } else {
        self.rootViewController.coordinatorDidValidateRate()
      }
    }
  }

  fileprivate func exchangeButtonPressed(data: KNDraftExchangeTransaction) {
    if KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description) != nil {
      if let topVC = self.navigationController.topViewController, topVC is KNPromoSwapConfirmViewController { return }
      let address = self.session.wallet.address.description
      // promo code wallet
      let destWallet = KNWalletPromoInfoStorage.shared.getDestWallet(from: address) ?? address
      let expiredDate: Date = {
        let time = KNWalletPromoInfoStorage.shared.getExpiredTime(from: address) ?? 0.0
        return Date(timeIntervalSince1970: time)
      }()
      let viewModel = KNPromoSwapConfirmViewModel(
        transaction: data,
        srcWallet: self.session.wallet.address.description,
        destWallet: destWallet,
        expiredDate: expiredDate
      )
      self.promoConfirmSwapVC = KNPromoSwapConfirmViewController(viewModel: viewModel)
      self.promoConfirmSwapVC?.loadViewIfNeeded()
      self.promoConfirmSwapVC?.delegate = self
      self.navigationController.pushViewController(self.promoConfirmSwapVC!, animated: true)
    } else {
      if let topVC = self.navigationController.topViewController, topVC is KConfirmSwapViewController { return }
      self.confirmSwapVC = {
        let ethBal = self.balances[KNSupportedTokenStorage.shared.ethToken.contract]?.value ?? BigInt(0)
        let viewModel = KConfirmSwapViewModel(transaction: data, ethBalance: ethBal)
        let controller = KConfirmSwapViewController(viewModel: viewModel)
        controller.loadViewIfNeeded()
        controller.delegate = self
        return controller
      }()
      self.navigationController.present(self.confirmSwapVC!, animated: true, completion: nil)
    }
  }

  // Update compared rate from node when prod cached failed to load
  // This rate is to compare with current rate to show warning
//  fileprivate func updateComparedEstimateRate(from: TokenObject, to: TokenObject, hint: String) {
//    // Using default amount equivalent to 0.5 ETH
//    let amount: BigInt = {
//      if from.isETH { return BigInt(10).power(from.decimals) / BigInt(2) }
//      if let rate = KNRateCoordinator.shared.ethRate(for: from), !rate.rate.isZero {
//        let ethAmount = BigInt(10).power(from.decimals) / BigInt(2)
//        let amount = ethAmount * BigInt(10).power(to.decimals) / rate.rate
//        return amount
//      }
//      return BigInt(10).power(from.decimals / 2)
//    }()
//    self.getExpectedExchangeRate(from: from, to: to, amount: amount, hint: hint) { [weak self] result in
//      if case .success(let data) = result, !data.0.isZero {
//        self?.rootViewController.coordinatorUpdateComparedRateFromNode(
//          from: from,
//          to: to,
//          rate: data.0
//        )
//      }
//    }
//  }

//  fileprivate func updateReferencePrice(from: TokenObject, to: TokenObject) {
//    KNRateCoordinator.shared.updateReferencePrice(fromSym: from.symbol, toSym: to.symbol)
//  }

  // Call contract to get estimate rate with src, dest, srcAmount
//  fileprivate func updateEstimatedRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", showError: Bool, withKyber: Bool = false, completion: ((Error?) -> Void)? = nil) {
//    self.getExpectedExchangeRate(from: from, to: to, amount: amount, hint: hint, withKyber: withKyber) { [weak self] result in
//      guard let `self` = self else { return }
//      switch result {
//      case .success(let data):
//        self.rootViewController.coordinatorDidUpdateEstimateRate(
//          from: from,
//          to: to,
//          amount: amount,
//          rate: data.0,
//          slippageRate: data.1
//        )
//        completion?(nil)
//      case .failure(let error):
//        if showError && !withKyber {
//          if case let err as APIKit.SessionTaskError = error.error, case .connectionError = err {
//            self.navigationController.showErrorTopBannerMessage(
//              with: NSLocalizedString("error", value: "Error", comment: ""),
//              message: NSLocalizedString("please.check.your.internet.connection", value: "Please check your internet connection", comment: ""),
//              time: 1.5
//            )
//          } else {
//            self.navigationController.showErrorTopBannerMessage(
//              with: NSLocalizedString("error", value: "Error", comment: ""),
//              message: NSLocalizedString("can.not.update.exchange.rate", comment: "Can not update exchange rate"),
//              time: 1.5
//            )
//          }
//          self.rootViewController.coordinatorDidUpdateEstimateRate(
//            from: from,
//            to: to,
//            amount: amount,
//            rate: BigInt(0),
//            slippageRate: BigInt(0)
//          )
//        }
//        if withKyber {
//          self.updateExpectedRateFromAPIIfNeeded(from: from, to: to, amount: amount, showError: showError)
//        }
//        completion?(error)
//      }
//    }
//  }

  fileprivate func getExpectedExchangeRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", withKyber: Bool = false, completion: ((Result<(BigInt, BigInt), AnyError>) -> Void)? = nil) {
    if from == to {
      let rate = BigInt(10).power(from.decimals)
      let slippageRate = rate * BigInt(97) / BigInt(100)
      completion?(.success((rate, slippageRate)))
      return
    }
    self.session.externalProvider.getExpectedRate(
      from: from,
      to: to,
      amount: amount,
      hint: hint,
      withKyber: withKyber
    ) { (result) in
        var estRate: BigInt = BigInt(0)
        var slippageRate: BigInt = BigInt(0)
        switch result {
        case .success(let data):
          estRate = data.0
          slippageRate = data.1
          estRate /= BigInt(10).power(18 - to.decimals)
          slippageRate /= BigInt(10).power(18 - to.decimals)
          completion?(.success((estRate, slippageRate)))
        case .failure(let error):
          completion?(.failure(error))
        }
    }
  }

//  func updateExpectedRateWithKyberIfNeeded(from: TokenObject, to: TokenObject, amount: BigInt, hint: String, showError: Bool) {
//    if hint.isEmpty || hint == "0x" {
//      self.updateExpectedRateFromAPIIfNeeded(from: from, to: to, amount: amount, showError: showError)
//    } else {
//      DispatchQueue.main.async {
//        self.updateEstimatedRate(from: from, to: to, amount: amount, hint: hint, showError: showError, withKyber: true)
//      }
//    }
//  }

//  func updateExpectedRateFromAPIIfNeeded(from: TokenObject, to: TokenObject, amount: BigInt, showError: Bool) {
//    let src = from.contract.lowercased()
//    let dest = to.contract.lowercased()
//    let amt = amount.description
//
//    DispatchQueue.global(qos: .background).async {
//      let provider = MoyaProvider<KNTrackerService>(plugins: [MoyaCacheablePlugin()])
//      provider.request(.getExpectedRate(src: src, dest: dest, amount: amt)) { [weak self] result in
//        guard let `self` = self else { return }
//        if case .success(let resp) = result,
//          let json = try? resp.mapJSON() as? JSONDictionary ?? [:],
//          (json["error"] as? Bool ?? false) == false,
//          let rate = json["expectedRate"] as? String,
//          let rateBigInt = rate.fullBigInt(decimals: 0) {
//          if let timestamp = json["timestamp"] as? NSNumber, Date().timeIntervalSince1970 - timestamp.doubleValue > 60.0 {
//            KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_get_expected_rate_from_node_success", customAttributes: nil)
//            DispatchQueue.main.async {
//              self.updateEstimatedRate(from: from, to: to, amount: amount, showError: showError)
//            }
//            return
//          }
//          var estRate = rateBigInt / BigInt(10).power(18 - to.decimals)
//          // reduce rate amount with platform fee
//          estRate = estRate * BigInt(10000 - KNAppTracker.getPlatformFee(source: from.addressObj, dest: to.addressObj)) / BigInt(10000)
//          DispatchQueue.main.async {
//            self.rootViewController.coordinatorDidUpdateEstimateRate(
//              from: from,
//              to: to,
//              amount: amount,
//              rate: estRate,
//              slippageRate: estRate * BigInt(97) / BigInt(100)
//            )
//          }
//        } else {
//          KNCrashlyticsUtil.logCustomEvent(withName: "kbswap_get_expected_rate_from_node_failure", customAttributes: nil)
//          DispatchQueue.main.async {
//            self.updateEstimatedRate(from: from, to: to, amount: amount, showError: showError)
//          }
//        }
//      }
//    }
//  }
  
  func getAllRates(from: TokenObject, to: TokenObject, srcAmount: BigInt) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let src = from.contract.lowercased()
    let dest = to.contract.lowercased()
    let amt = srcAmount.description

    provider.request(.getAllRates(src: src, dst: dest, srcAmount: amt)) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let rates = json["rates"] as? [JSONDictionary] {
        self.rootViewController.coordinatorDidUpdateRates(from: from, to: to, srcAmount: srcAmount, rates: rates)
      } else {
        self.rootViewController.coordinatorFailUpdateRates()
      }
    }
  }

  func updateEstimatedGasLimit(from: TokenObject, to: TokenObject, amount: BigInt, gasPrice: BigInt, hint: String, completion: @escaping () -> Void = {}) {
    let exchangeTx = KNDraftExchangeTransaction(
      from: from,
      to: to,
      amount: amount,
      maxDestAmount: BigInt(2).power(255),
      expectedRate: BigInt(0),
      minRate: .none,
      gasPrice: gasPrice,
      gasLimit: .none,
      expectedReceivedString: nil,
      hint: hint
    )
    self.session.externalProvider.getEstimateGasLimit(for: exchangeTx) { result in
      if case .success(let estimate) = result {
        self.rootViewController.coordinatorDidUpdateGasLimit(
          from: from,
          to: to,
          amount: amount,
          gasLimit: estimate
        )
        self.gasFeeSelectorVC?.coordinatorDidUpdateGasLimit(estimate)
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

  fileprivate func showWalletQRCode() {
    self.qrcodeCoordinator?.start()
  }

  fileprivate func openSetGasPrice(gasPrice: BigInt, estGasLimit: BigInt) {
    let setGasPriceVC: KNSetGasPriceViewController = {
      let viewModel = KNSetGasPriceViewModel(gasPrice: gasPrice, estGasLimit: estGasLimit)
      let controller = KNSetGasPriceViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.setGasPriceVC = setGasPriceVC
    self.navigationController.pushViewController(setGasPriceVC, animated: true)
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

  fileprivate func openPromoCodeView() {
    self.delegate?.exchangeTokenCoordinatorDidSelectPromoCode()
  }

  fileprivate func openAddWalletView() {
    self.delegate?.exchangeTokenCoordinatorDidSelectAddWallet()
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
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(wallet)
  }
}

// MARK: Search token
extension KNExchangeTokenCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.navigationController.popToRootViewController(animated: true) {
      self.searchTokensViewController = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorUpdateSelectedToken(
          token,
          isSource: self.isSelectingSourceToken
        )
      }
    }
  }
}

// MARK: Set gas price
extension KNExchangeTokenCoordinator: KNSetGasPriceViewControllerDelegate {
  func setGasPriceViewControllerDidReturn(gasPrice: BigInt?) {
    self.navigationController.popViewController(animated: true) {
      self.setGasPriceVC = nil
      self.rootViewController.coordinatorExchangeTokenDidUpdateGasPrice(gasPrice)
    }
  }
}

// MARK: Add new wallet delegate
extension KNExchangeTokenCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    let address = wallet.address.description
    let walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.delegate?.exchangeTokenCoordinatorDidSelectWallet(walletObject)
  }

  func addNewWalletCoordinator(remove wallet: Wallet) {
    self.delegate?.exchangeTokenCoordinatorRemoveWallet(wallet)
  }
}

extension KNExchangeTokenCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidClose() {
//    self.historyCoordinator = nil
  }
  
  func historyCoordinatorDidUpdateWalletObjects() {}
  func historyCoordinatorDidSelectRemoveWallet(_ wallet: Wallet) {}
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet) {}
}

extension KNExchangeTokenCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    self.transactionStatusVC = nil
    if action == .transfer {
      self.openSendTokenView()
    }
    if action == .dismiss {
      if #available(iOS 10.3, *) {
        KNAppstoreRatingManager.requestReviewIfAppropriate()
      }
    }
  }
}

extension KNExchangeTokenCoordinator: QRCodeReaderDelegate {
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

extension KNExchangeTokenCoordinator: KNListNotificationViewControllerDelegate {
  func listNotificationViewController(_ controller: KNListNotificationViewController, run event: KNListNotificationViewEvent) {
    switch event {
    case .openSwap(let from, let to):
      self.navigationController.popViewController(animated: true) {
        self.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
      }
    case .openManageOrder:
      if IEOUserStorage.shared.user == nil { return }
      self.delegate?.exchangeTokenCoordinatorOpenManageOrder()
    case .openSetting:
      self.openNotificationSettingScreen()
    }
  }
}

extension KNExchangeTokenCoordinator: KNNotificationSettingViewControllerDelegate {
  func notificationSettingViewControllerDidApply(_ controller: KNNotificationSettingViewController) {
    self.navigationController.popViewController(animated: true) {
      self.showSuccessTopBannerMessage(message: "Updated subscription tokens".toBeLocalised())
    }
  }
}

extension KNExchangeTokenCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .gasPriceChanged(let type, let value):
      self.rootViewController.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed:
      self.navigationController.showBottomBannerView(
        message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .minRatePercentageChanged(let percent):
      self.rootViewController.coordinatorDidUpdateMinRatePercentage(percent)
    default:
      break
    }
  }
}

extension KNExchangeTokenCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      print("transition")
    case .manageWallet:
      print("transition")
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.delegate?.exchangeTokenCoordinatorDidSelectWallet(wal)
    case .remove(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      let alert = UIAlertController(title: "", message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""), preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cacnel", comment: ""), style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: NSLocalizedString("remove", value: "Remove", comment: ""), style: .destructive, handler: { _ in
        controller.dismiss(animated: true) {
          self.delegate?.exchangeTokenCoordinatorDidSelectRemoveWallet(wal)
        }
      }))
      controller.present(alert, animated: true, completion: nil)
    case .edit(let wallet):
      let viewModel = InputPopUpViewModel(mainTitle: "Edit wallet label", description: wallet.address, doneButtonTitle: "done".toBeLocalised(), value: wallet.name) { (text) in
        let newWallet = wallet.copy(withNewName: text)
        let contact = KNContact(
          address: newWallet.address,
          name: newWallet.name
        )
        KNContactStorage.shared.update(contacts: [contact])
        KNWalletStorage.shared.update(wallets: [newWallet])
        self.delegate?.exchangeTokenCoordinatorDidUpdateWalletObjects()
      }
      let viewController = InputPopUpViewController(viewModel: viewModel)
      self.navigationController.present(viewController, animated: true, completion: nil)
    }
  }
}

extension KNExchangeTokenCoordinator: ChooseRateViewControllerDelegate {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String) {
    self.rootViewController.coordinatorDidUpdatePlatform(rate)
  }
}
