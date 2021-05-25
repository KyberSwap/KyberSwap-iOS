// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices

protocol KNTransactionStatusCoordinatorDelegate: class {
  func transactionStatusCoordinatorDidClose()
}

class KNTransactionStatusCoordinator: Coordinator {

  var transaction: KNTransaction?
  weak var delegate: KNTransactionStatusCoordinatorDelegate?

  var coordinators: [Coordinator] = []

  let navigationController: UINavigationController
  var rootViewController: KNTransactionStatusViewController?

  init(
    navigationController: UINavigationController,
    transaction: KNTransaction?,
    delegate: KNTransactionStatusCoordinatorDelegate?
    ) {
    self.navigationController = navigationController
    self.transaction = transaction
    self.delegate = delegate
  }

  func start() {
    self.rootViewController = KNTransactionStatusViewController(
      delegate: self,
      transaction: self.transaction
    )
    self.rootViewController?.loadViewIfNeeded()
    self.rootViewController?.modalPresentationStyle = .overCurrentContext
    self.rootViewController?.modalTransitionStyle = .crossDissolve
    self.navigationController.present(self.rootViewController!, animated: true, completion: nil)
  }

  func stop(completion: @escaping () -> Void) {
    self.rootViewController?.dismiss(animated: true, completion: completion)
  }

  func updateTransaction(_ transaction: KNTransaction?, error: String?) {
    self.transaction = transaction
    self.rootViewController?.updateViewWithTransaction(self.transaction, error: error)
  }
}

extension KNTransactionStatusCoordinator: KNTransactionStatusViewControllerDelegate {
  func transactionStatusVCUserDidTapToView(transaction: KNTransaction) {
    let urlString = KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(transaction.id)"
    self.rootViewController?.openSafari(with: urlString)
  }

  func transactionStatusVCUserDidClickClose() {
    self.stop {
      self.delegate?.transactionStatusCoordinatorDidClose()
    }
  }
}
