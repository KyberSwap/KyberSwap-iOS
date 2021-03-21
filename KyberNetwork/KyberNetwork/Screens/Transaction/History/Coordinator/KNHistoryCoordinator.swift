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
  func historyCoordinatorDidUpdateWalletObjects()
  func historyCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet)
  func historyCoordinatorDidSelectManageWallet()
  func historyCoordinatorDidSelectAddWallet()
}

class KNHistoryCoordinator: NSObject, Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?
  fileprivate var transactionStatusVC: KNTransactionStatusPopUp?
  let etherScanURL: String = KNEnvironment.default.etherScanIOURLString
  let enjinScanURL: String = KNEnvironment.default.enjinXScanIOURLString

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
    self.navigationController.pushViewController(self.rootViewController, animated: true) {
      let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
      self.appCoordinatorTokensTransactionsDidUpdate(showLoading: true)
      self.appCoordinatorPendingTransactionDidUpdate()
      self.rootViewController.coordinatorUpdateTokens(self.session.tokenStorage.tokens)
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
    self.rootViewController.coordinatorUpdateTokens(self.session.tokenStorage.tokens)
    let pendingTrans = self.session.transactionStorage.kyberPendingTransactions
    self.appCoordinatorPendingTransactionDidUpdate()
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
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        if showLoading { self.navigationController.hideLoading() }
        self.rootViewController.coordinatorDidUpdateCompletedTransaction(sections: dates, data: sectionData)
      })
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
    //    self.txDetailsCoordinator.updatePendingTransactions(transactions, currentWallet: self.currentWallet)
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
    self.transactionStatusVC = KNTransactionStatusPopUp(transaction: transaction)
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
            KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_success", customAttributes: nil)
          } else {
            KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: ["error": message])
          }
        } catch {
          KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: nil)
        }
      case .failure:
        KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_tx_hash_sent_failure", customAttributes: nil)
      }
    }
  }
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
      let urlString = "\(self.enjinScanURL)eth/address/\(self.session.wallet.address.description)"
      self.rootViewController.openSafari(with: urlString)
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
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }
}

extension KNHistoryCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction) {
    if case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider {
      let cancelTx = transaction.transactionObject.toCancelTransaction(account: account)
      let saved = EtherscanTransactionStorage.shared.getInternalHistoryTransactionWithHash(transaction.hash)
      saved?.state = .cancel
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
      self.navigationController.showTopBannerView(message: "Watch wallet can not do this operation".toBeLocalised())
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
        self.navigationController.showTopBannerView(message: "Watch wallet can not do this operation".toBeLocalised())
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
    self.transactionStatusVC = nil
    switch action {
    case .swap:
      KNNotificationUtil.postNotification(for: kOpenExchangeTokenViewKey)
    default:
      break
    }
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
