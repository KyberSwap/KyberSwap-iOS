// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import BigInt
import TrustCore
import Moya
import MBProgressHUD
import QRCodeReaderViewController
import WalletConnect

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet)
  func historyCoordinatorDidSelectManageWallet()
  func historyCoordinatorDidSelectAddWallet()
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class KNHistoryCoordinator: NSObject, Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject
  var sendCoordinator: KNSendTokenViewCoordinator?

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?
  fileprivate weak var transactionStatusVC: KNTransactionStatusPopUp?
  var etherScanURL: String {
    return KNGeneralProvider.shared.customRPC.etherScanEndpoint
  }

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel(
      currentWallet: self.currentWallet
    )
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  var txDetailsCoordinator: KNTransactionDetailsCoordinator?
//  lazy var txDetailsCoordinator: KNTransactionDetailsCoordinator = {
//    return KNTransactionDetailsCoordinator(
//      navigationController: self.navigationController,
//      transaction: nil,
//      currentWallet: self.currentWallet
//    )
//  }()

  var speedUpViewController: SpeedUpCustomGasSelectViewController?

  init(
    navigationController: UINavigationController,
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  func start() {
    if EtherscanTransactionStorage.shared.getHistoryTransactionModel().isEmpty {
      DispatchQueue.global(qos: .background).async {
        EtherscanTransactionStorage.shared.generateKrytalTransactionModel()
      }
    }
    
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      self.appCoordinatorTokensTransactionsDidUpdate(showLoading: true)
      self.appCoordinatorPendingTransactionDidUpdate()
      self.rootViewController.coordinatorUpdateTokens()
      self.session.transacionCoordinator?.loadEtherscanTransactions()
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.historyCoordinatorDidClose()
    }
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.session = session
    let address = self.session.wallet.address.description
    self.currentWallet = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
    self.appCoordinatorTokensTransactionsDidUpdate()
    self.rootViewController.coordinatorUpdateTokens()
    self.appCoordinatorPendingTransactionDidUpdate()
    self.rootViewController.coordinatorUpdateNewSession(wallet: self.currentWallet)
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
  }

  func appCoordinatorTokensTransactionsDidUpdate(showLoading: Bool = false) {
    if showLoading { self.navigationController.displayLoading() }
    DispatchQueue.global(qos: .background).async {
      let dates: [String] = {
        let dates = EtherscanTransactionStorage.shared.getHistoryTransactionModel().map { return self.dateFormatter.string(from: $0.date) }
        var uniqueDates = [String]()
        dates.forEach({
          if !uniqueDates.contains($0) { uniqueDates.append($0) }
        })
        return uniqueDates
      }()

      let sectionData: [String: [HistoryTransaction]] = {
        var data: [String: [HistoryTransaction]] = [:]
        EtherscanTransactionStorage.shared.getHistoryTransactionModel().forEach { tx in
          var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
          trans.append(tx)
          data[self.dateFormatter.string(from: tx.date)] = trans
        }
        return data
      }()
      DispatchQueue.main.async {
        if showLoading { self.navigationController.hideLoading() }
        self.rootViewController.coordinatorDidUpdateCompletedTransaction(sections: dates, data: sectionData)
      }
    }
  }

  func appCoordinatorPendingTransactionDidUpdate() {
    let dates: [String] = {
      let dates = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().map { return self.dateFormatter.string(from: $0.time) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [InternalHistoryTransaction]] = {
      var data: [String: [InternalHistoryTransaction]] = [:]
      EtherscanTransactionStorage.shared.getInternalHistoryTransaction().forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.time)] ?? []
        trans.append(tx)
        data[self.dateFormatter.string(from: tx.time)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
          data: sectionData,
          dates: dates,
          currentWallet: self.currentWallet
        )
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }

  func coordinatorGasPriceCachedDidUpdate() {
    speedUpViewController?.updateGasPriceUIs()
  }

  func coordinatorDidUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.hash, txHash == tx.hash {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: InternalHistoryTransaction) {
    let viewModel = KNConfirmCancelTransactionViewModel(transaction: transaction)
    let confirmPopup = KNConfirmCancelTransactionPopUp(viewModel: viewModel)
    confirmPopup.delegate = self
    self.navigationController.present(confirmPopup, animated: true, completion: nil)
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: InternalHistoryTransaction) {
    let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
    let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    navigationController.present(controller, animated: true, completion: nil)
    speedUpViewController = controller
  }

  fileprivate func openTransactionStatusPopUp(transaction: InternalHistoryTransaction) {
    let controller = KNTransactionStatusPopUp(transaction: transaction)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.transactionStatusVC = controller
  }

//  fileprivate func sendUserTxHashIfNeeded(_ txHash: String) {
//    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
//    let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])
//    provider.request(.sendTxHash(authToken: accessToken, txHash: txHash)) { result in
//      switch result {
//      case .success(let resp):
//        do {
//          _ = try resp.filterSuccessfulStatusCodes()
//          let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
//          let success = json["success"] as? Bool ?? false
//          let message = json["message"] as? String ?? "Unknown"
//          if success {
//            KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_success", customAttributes: nil)
//          } else {
//            KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: ["error": message])
//          }
//        } catch {
//          KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: nil)
//        }
//      case .failure:
//        KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: nil)
//      }
//    }
//  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .dismiss:
      self.stop()
    case .cancelTransaction(let transaction):
      self.openTransactionCancelConfirmPopUpFor(transaction: transaction)
      
    case .speedUpTransaction(let transaction):
      self.openTransactionSpeedUpViewController(transaction: transaction)
    case .quickTutorial(let pointsAndRadius):
      break
    case .openEtherScanWalletPage:
      let urlString = "\(self.etherScanURL)address/\(self.session.wallet.address.description)"
      self.rootViewController.openSafari(with: urlString)
    case .openKyberWalletPage:
//      let urlString = "\(self.enjinScanURL)eth/address/\(self.session.wallet.address.description)"
//      self.rootViewController.openSafari(with: urlString)
    break
    case .openWalletsListPopup:
      let viewModel = WalletsListViewModel(
        walletObjects: KNWalletStorage.shared.wallets,
        currentWallet: self.currentWallet
      )
      let walletsList = WalletsListViewController(viewModel: viewModel)
      walletsList.delegate = self
      self.navigationController.present(walletsList, animated: true, completion: nil)
    case .selectPendingTransaction(transaction: let transaction):
      let coordinator = KNTransactionDetailsCoordinator(navigationController: self.navigationController, transaction: transaction)
      coordinator.start()
      self.txDetailsCoordinator = coordinator
    case .selectCompletedTransaction(data: let data):
      let coordinator = KNTransactionDetailsCoordinator(navigationController: self.navigationController, data: data)
      coordinator.start()
      self.txDetailsCoordinator = coordinator
    case .swap:
      if self.navigationController.tabBarController?.selectedIndex == 1 {
        self.navigationController.popToRootViewController(animated: true)
      } else {
        self.navigationController.tabBarController?.selectedIndex = 1
      }
    }
  }

  fileprivate func openQuickTutorial(_ controller: KNHistoryViewController, pointsAndRadius: [(CGPoint, CGFloat)]) {
    let attributedString = NSMutableAttributedString(string: "Speed Up or Cancel transaction.".toBeLocalised(), attributes: [
      .font: UIFont.Kyber.regular(with: 18),
      .foregroundColor: UIColor(white: 1.0, alpha: 1.0),
      .kern: 0.0,
    ])
    let contentTopOffset: CGFloat = 496.0
    let overlayer = controller.createOverlay(
      frame: controller.tabBarController!.view.frame,
      contentText: attributedString,
      contentTopOffset: contentTopOffset,
      pointsAndRadius: pointsAndRadius,
      nextButtonTitle: "Got it".toBeLocalised()
    )
    controller.tabBarController!.view.addSubview(overlayer)
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    
    if let etherScanEndpoint = self.session.externalProvider?.customRPC.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }
  
  fileprivate func openSendTokenView() {
    let from: TokenObject = {
      if KNGeneralProvider.shared.isEthereum {
        return KNSupportedTokenStorage.shared.ethToken
      } else {
        return KNSupportedTokenStorage.shared.bnbToken
      }
    }()
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: [:],
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
}

extension KNHistoryCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let cancelTx = transaction.transactionObject.toCancelTransaction(account: account)
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      saved?.state = .cancel
      saved?.type = .transferETH
      saved?.transactionSuccessDescription = "-0 ETH"
      cancelTx.send(provider: provider) { (result) in
        switch result {
        case .success(let hash):
          saved?.hash = hash
          if let unwrapped = saved {
            self.openTransactionStatusPopUp(transaction: unwrapped)
            KNNotificationUtil.postNotification(
              for: kTransactionDidUpdateNotificationKey,
              object: unwrapped,
              userInfo: nil
            )
          }
        case .failure(let error):
          self.navigationController.showTopBannerView(message: error.description)
        }
      }
    } else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
    }
  }
}

extension KNHistoryCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .done(let transaction, let newValue):
      if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
        let savedTx = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
        savedTx?.state = .speedup
        let speedupTx = transaction.transactionObject.toSpeedupTransaction(account: account, gasPrice: newValue)
        speedupTx.send(provider: provider) { (result) in
          switch result {
          case .success(let hash):
            savedTx?.hash = hash
            if let unwrapped = savedTx {
              self.openTransactionStatusPopUp(transaction: unwrapped)
              KNNotificationUtil.postNotification(
                for: kTransactionDidUpdateNotificationKey,
                object: unwrapped,
                userInfo: nil
              )
            }
            
          case .failure(let error):
            self.navigationController.showTopBannerView(message: error.description)
          }
        }
      } else {
        self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      }
    case .invaild:
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "your.gas.must.be.10.percent.higher".toBeLocalised(),
        time: 1.5
      )
    }
    speedUpViewController = nil
  }
}

extension KNHistoryCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    switch action {
    case .swap:
      if self.navigationController.tabBarController?.selectedIndex == 1 {
        self.navigationController.popToRootViewController(animated: true)
      } else {
        self.navigationController.tabBarController?.selectedIndex = 1
      }
    case .speedUp(tx: let tx):
      self.openTransactionSpeedUpViewController(transaction: tx)
    case .cancel(tx: let tx):
      self.openTransactionCancelConfirmPopUpFor(transaction: tx)
    case .openLink(url: let url):
      self.navigationController.openSafari(with: url)
    case .transfer:
      self.openSendTokenView()
    case .goToSupport:
      self.navigationController.openSafari(with: "https://support.krystal.app")
    default:
      break
    }
    self.transactionStatusVC = nil
  }
}

extension KNHistoryCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.historyCoordinatorDidSelectManageWallet()
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
      self.delegate?.historyCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.historyCoordinatorDidSelectAddWallet()
    }
  }
}

extension KNHistoryCoordinator: QRCodeReaderDelegate {
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

extension KNHistoryCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.historyCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.historyCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.navigationController.popViewController(animated: true)
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.historyCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.historyCoordinatorDidSelectAddWallet()
  }
}
