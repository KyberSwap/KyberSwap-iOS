// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

class KNTransactionDetailsCoordinator: Coordinator {

  let navigationController: UINavigationController
  let etherScanURL: String = KNGeneralProvider.shared.customRPC.etherScanEndpoint
  
  var coordinators: [Coordinator] = []

  var rootViewController: KNTransactionDetailsViewController

  init(
    navigationController: UINavigationController,
    transaction: InternalHistoryTransaction
    ) {
    self.navigationController = navigationController
    let viewModel = InternalTransactionDetailViewModel(transaction: transaction)
    let controller = KNTransactionDetailsViewController(viewModel: viewModel)
    self.rootViewController = controller
    controller.loadViewIfNeeded()
    controller.delegate = self
  }
  
  init(
    navigationController: UINavigationController,
    data: CompletedHistoryTransactonViewModel
    ) {
    self.navigationController = navigationController
    let viewModel = EtherscanTransactionDetailViewModel(data: data)
    let controller = KNTransactionDetailsViewController(viewModel: viewModel)
    self.rootViewController = controller
    controller.loadViewIfNeeded()
    controller.delegate = self
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func update(transaction: Transaction, currentWallet: KNWalletObject) {
//    self.transaction = transaction
//    self.rootViewController.coordinator(update: transaction, currentWallet: currentWallet)
  }
//
  func updatePendingTransactions(_ transactions: [KNTransaction], currentWallet: KNWalletObject) {
//    guard let tran = transactions.map({ $0.toTransaction() }).first(where: { $0.compoundKey == (self.transaction?.compoundKey ?? "") }) else {
//      return
//    }
//    self.rootViewController.coordinator(update: tran, currentWallet: currentWallet)
  }
}

extension KNTransactionDetailsCoordinator: KNTransactionDetailsViewControllerDelegate {
  func transactionDetailsViewController(_ controller: KNTransactionDetailsViewController, run event: KNTransactionDetailsViewEvent) {
    switch event {
    case .back: self.stop()
    case .openEtherScan(let hash):
      let urlString = "\(self.etherScanURL)tx/\(hash)"
      self.rootViewController.openSafari(with: urlString)
    case .openEtherScanAddress(let hash):
      let urlString = "\(self.etherScanURL)address/\(hash)"
      self.rootViewController.openSafari(with: urlString)
    case .openEnjinXScan:
      break
    }
  }
}
