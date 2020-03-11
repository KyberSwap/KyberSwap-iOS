// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import BigInt
import TrustCore

protocol KNHistoryCoordinatorDelegate: class {
  func historyCoordinatorDidClose()
}

class KNHistoryCoordinator: Coordinator {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  let navigationController: UINavigationController
  private(set) var session: KNSession

  var currentWallet: KNWalletObject

  var coordinators: [Coordinator] = []
  weak var delegate: KNHistoryCoordinatorDelegate?
  fileprivate var transactionStatusVC: KNTransactionStatusPopUp?

  lazy var rootViewController: KNHistoryViewController = {
    let viewModel = KNHistoryViewModel(
      completedTxData: [:],
      completedTxHeaders: [],
      pendingTxData: [:],
      pendingTxHeaders: [],
      currentWallet: self.currentWallet
    )
    let controller = KNHistoryViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var txDetailsCoordinator: KNTransactionDetailsCoordinator = {
    return KNTransactionDetailsCoordinator(
      navigationController: self.navigationController,
      transaction: nil,
      currentWallet: self.currentWallet
    )
  }()

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
      self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
      self.rootViewController.coordinatorUpdateTokens(self.session.tokenStorage.tokens)
      self.session.transacionCoordinator?.forceFetchTokenTransactions()
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
    self.appCoordinatorPendingTransactionDidUpdate(pendingTrans)
  }

  func appCoordinatorDidUpdateWalletObjects() {
    self.rootViewController.coordinatorUpdateWalletObjects()
  }

  func appCoordinatorTokensTransactionsDidUpdate(showLoading: Bool = false) {
    var transactions: [Transaction] = Array(self.session.transactionStorage.transferNonePendingObjects.prefix(1000)).map({ return $0.clone() })
    let addressToSymbol: [String: String] = {
      var maps: [String: String] = [:]
      KNSupportedTokenStorage.shared.supportedTokens.forEach({
        maps[$0.contract.lowercased()] = $0.symbol
      })
      return maps
    }()
    let address = self.currentWallet.address
    if showLoading { self.navigationController.displayLoading() }
    DispatchQueue.global(qos: .background).async {
      transactions.sort(by: { return $0.id < $1.id })
      var processedTxs: [Transaction] = []
      var id = 0
      while id < transactions.count {
        if id == transactions.count - 1 {
          processedTxs.append(transactions[id])
          break
        }
        if transactions[id].id == transactions[id + 1].id {
          // count number of txs with same id
          var cnt = 2
          var tempId = id + 2
          while tempId < transactions.count && transactions[tempId].id == transactions[id].id {
            tempId += 1
            cnt += 1
          }
          if cnt > 2 {
            // more than 2 txs shared same hash
            tempId = id
            while id < transactions.count && transactions[id].id == transactions[tempId].id {
              let tx = transactions[id]
              let contract = tx.localizedOperations.first?.contract?.lowercased() ?? ""
              tx.localizedOperations.first?.symbol = addressToSymbol[contract] ?? tx.localizedOperations.first?.symbol
              processedTxs.append(tx)
              id += 1
            }
            continue
          }
          // merge 2 transactions
          if let swap = Transaction.swapTransation(sendTx: transactions[id], receiveTx: transactions[id + 1], curWallet: address, addressToSymbol: addressToSymbol) {
            processedTxs.append(swap)
            id += 2
            continue
          }
        }
        let tx = transactions[id]
        let contract = tx.localizedOperations.first?.contract?.lowercased() ?? ""
        tx.localizedOperations.first?.symbol = addressToSymbol[contract] ?? tx.localizedOperations.first?.symbol
        processedTxs.append(tx)
        id += 1
      }

      transactions = processedTxs.sorted(by: { return $0.date > $1.date })

      let dates: [String] = {
        let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
        var uniqueDates = [String]()
        dates.forEach({
          if !uniqueDates.contains($0) { uniqueDates.append($0) }
        })
        return uniqueDates
      }()

      let sectionData: [String: [Transaction]] = {
        var data: [String: [Transaction]] = [:]
        transactions.forEach { tx in
          var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
          trans.append(tx)
          data[self.dateFormatter.string(from: tx.date)] = trans
        }
        return data
      }()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        if showLoading { self.navigationController.hideLoading() }
        self.rootViewController.coordinatorUpdateCompletedTransactions(
          data: sectionData,
          dates: dates,
          currentWallet: self.currentWallet
        )
      })
    }
  }

  func appCoordinatorPendingTransactionDidUpdate(_ transactions: [KNTransaction]) {
    let dates: [String] = {
      let dates = transactions.map { return self.dateFormatter.string(from: $0.date) }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      return uniqueDates
    }()

    let sectionData: [String: [Transaction]] = {
      var data: [String: [Transaction]] = [:]
      transactions.forEach { tx in
        var trans = data[self.dateFormatter.string(from: tx.date)] ?? []
        trans.append(tx.toTransaction())
        data[self.dateFormatter.string(from: tx.date)] = trans
      }
      return data
    }()

    self.rootViewController.coordinatorUpdatePendingTransaction(
      data: sectionData,
      dates: dates,
      currentWallet: self.currentWallet
    )
    self.txDetailsCoordinator.updatePendingTransactions(transactions, currentWallet: self.currentWallet)
  }

  func coordinatorGasPriceCachedDidUpdate() {
    speedUpViewController?.updateGasPriceUIs()
  }

  func coordinatorDidUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.id, txHash == txID {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }

  fileprivate func openTransactionCancelConfirmPopUpFor(transaction: Transaction) {
    let viewModel = KNConfirmCancelTransactionViewModel(transaction: transaction)
    let confirmPopup = KNConfirmCancelTransactionPopUp(viewModel: viewModel)
    confirmPopup.delegate = self
    confirmPopup.modalPresentationStyle = .overFullScreen
    confirmPopup.modalTransitionStyle = .crossDissolve
    self.navigationController.present(confirmPopup, animated: true, completion: nil)
  }

  fileprivate func openTransactionSpeedUpViewController(transaction: Transaction) {
    let viewModel = SpeedUpCustomGasSelectViewModel(transaction: transaction)
    let controller = SpeedUpCustomGasSelectViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    navigationController.pushViewController(controller, animated: true)
    speedUpViewController = controller
  }

  fileprivate func openTransactionStatusPopUp(transaction: Transaction) {
    let trans = KNTransaction.from(transaction: transaction)
    self.transactionStatusVC = KNTransactionStatusPopUp(transaction: trans)
    self.transactionStatusVC?.modalPresentationStyle = .overFullScreen
    self.transactionStatusVC?.modalTransitionStyle = .crossDissolve
    self.transactionStatusVC?.delegate = self
    self.navigationController.present(self.transactionStatusVC!, animated: true, completion: nil)
  }
}

extension KNHistoryCoordinator: KNHistoryViewControllerDelegate {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent) {
    switch event {
    case .selectTransaction(let transaction):
      self.txDetailsCoordinator.update(
        transaction: transaction,
        currentWallet: self.currentWallet
      )
      self.txDetailsCoordinator.start()
    case .dismiss:
      self.stop()
    case .cancelTransaction(let transaction):
        sendCancelTransactionFor(transaction)
    case .speedUpTransaction(let transaction):
        sendSpeedUpTransactionFor(transaction)
    }
  }

  fileprivate func openEtherScanForTransaction(with hash: String) {
    if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.rootViewController.openSafari(with: url)
    }
  }

  fileprivate func sendCancelTransactionFor(_ transaction: Transaction) {
    self.openTransactionCancelConfirmPopUpFor(transaction: transaction)
  }

  fileprivate func sendSpeedUpTransactionFor(_ transaction: Transaction) {
    self.openTransactionSpeedUpViewController(transaction: transaction)
  }

  fileprivate func didConfirmTransfer(_ transaction: Transaction) {
    guard let unconfirmTx = transaction.makeCancelTransaction() else {
      return
    }
    self.session.externalProvider.speedUpTransferTransaction(transaction: unconfirmTx, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      switch sendResult {
      case .success(let txHash):
        let tx: Transaction = unconfirmTx.toTransaction(
          wallet: self.session.wallet,
          hash: txHash,
          nounce: self.session.externalProvider.minTxCount - 1,
          type: .cancel
        )
        self.session.updatePendingTransactionWithHash(hashTx: transaction.id, ultiTransaction: tx, completion: {
          self.openTransactionStatusPopUp(transaction: tx)
        })
      case .failure:
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: [Constants.transactionIsCancel: TransactionType.cancel],
          userInfo: nil
        )
      }
    })
  }
}

extension KNHistoryCoordinator: KNConfirmCancelTransactionPopUpDelegate {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: Transaction) {
    self.didConfirmTransfer(transaction)
  }
}

extension KNHistoryCoordinator: SpeedUpCustomGasSelectDelegate {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .done(let transaction, let newValue):
      self.didSpeedUpTransactionFor(transaction: transaction, newGasPrice: newValue)
      self.navigationController.popViewController(animated: true)
    case .invaild:
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "your.gas.must.be.10.percent.higher".toBeLocalised(),
        time: 1.5
      )
    }
    speedUpViewController = nil
  }

  func didSpeedUpTransactionFor(transaction: Transaction, newGasPrice: BigInt) {
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens //All available token
    if let localizedOperation = transaction.localizedOperations.first {
      switch localizedOperation.type {
      case "transfer":
        if let speedUpTx = transaction.makeSpeedUpTransaction(availableTokens: tokenObjects, gasPrice: newGasPrice) {
          self.sendSpeedUpForTransferTransaction(transaction: speedUpTx, original: transaction)
        }
      case "exchange":
        self.sendSpeedUpSwapTransactionFor(transaction: transaction, availableTokens: tokenObjects, newPrice: newGasPrice)
      default:
        break
      }
    }
  }

  fileprivate func sendSpeedUpForTransferTransaction(transaction: UnconfirmedTransaction, original: Transaction) {
    self.session.externalProvider.speedUpTransferTransaction(transaction: transaction, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      switch sendResult {
      case .success(let txHash):
        let tx: Transaction = transaction.toTransaction(
          wallet: self.session.wallet,
          hash: txHash,
          nounce: Int(original.nonce)!,
          type: .speedup
        )
        self.session.updatePendingTransactionWithHash(hashTx: original.id, ultiTransaction: tx, state: .speedingUp, completion: {
          self.openTransactionStatusPopUp(transaction: tx)
        })
      case .failure:
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: [Constants.transactionIsCancel: TransactionType.speedup],
          userInfo: nil
        )
      }
    })
  }

  fileprivate func sendSpeedUpSwapTransactionFor(transaction: Transaction, availableTokens: [TokenObject], newPrice: BigInt) {
    guard let nouce = Int(transaction.nonce) else { return }
    guard let localizedOperation = transaction.localizedOperations.first else { return }
    guard let filteredToken = availableTokens.first(where: { (token) -> Bool in
      return token.symbol == localizedOperation.symbol
    }) else { return }
    let amount: BigInt = {
      return transaction.value.amountBigInt(decimals: localizedOperation.decimals) ?? BigInt(0)
    }()
    let gasLimit: BigInt = {
      return transaction.gasUsed.amountBigInt(units: .wei) ?? BigInt(0)
    }()
    session.externalProvider.getTransactionByHash(transaction.id) { [weak self] (pendingTx, _) in
      guard let `self` = self else { return }
      if let fetchedTx = pendingTx {
        if !fetchedTx.input.isEmpty {
          self.session
            .externalProvider
            .speedUpSwapTransaction(
              for: filteredToken,
              amount: amount,
              nonce: nouce,
              data: fetchedTx.input,
              gasPrice: newPrice,
              gasLimit: gasLimit
            ) { sendResult in
              switch sendResult {
              case .success(let txHash):
                let tx = transaction.convertToSpeedUpTransaction(newHash: txHash, newGasPrice: newPrice.displayRate(decimals: 0).removeGroupSeparator())
                self.session.updatePendingTransactionWithHash(hashTx: transaction.id, ultiTransaction: tx, state: .speedingUp, completion: {
                  self.openTransactionStatusPopUp(transaction: tx)
                })
              case .failure:
                KNNotificationUtil.postNotification(
                  for: kTransactionDidUpdateNotificationKey,
                  object: [Constants.transactionIsCancel: TransactionType.speedup],
                  userInfo: nil
                )
              }
          }
        }
      }
    }
  }
}

extension KNHistoryCoordinator: KNTransactionStatusPopUpDelegate {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent) {
    self.transactionStatusVC = nil
    if action == .swap {
      KNNotificationUtil.postNotification(for: kOpenExchangeTokenViewKey)
    }
    if action == .dismiss {
      if #available(iOS 10.3, *) {
        KNAppstoreRatingManager.requestReviewIfAppropriate()
      }
    }
  }
}
