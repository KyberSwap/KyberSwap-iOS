// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import Result
import Moya
import APIKit

class KNSendTokenViewCoordinator: Coordinator {

  let navigationController: UINavigationController
  fileprivate var session: KNSession
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]
  fileprivate var from: TokenObject

  lazy var rootViewController: KSendTokenViewController = {
    let viewModel = KNSendTokenViewModel(
      from: self.from,
      balances: self.balances
    )
    let controller = KSendTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  fileprivate(set) var confirmVC: KConfirmSendViewController?
  fileprivate var transactionStatusVC: KNTransactionStatusPopUp?

  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  deinit {
    self.rootViewController.removeObserveNotification()
  }

  init(
    navigationController: UINavigationController,
    session: KNSession,
    balances: [String: Balance],
    from: TokenObject = KNSupportedTokenStorage.shared.ethToken
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balances = balances
    self.from = from
    if self.from.isPromoToken {
      self.from = KNSupportedTokenStorage.shared.ethToken
    }
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorUpdateBalances(self.balances)

    let isPromo = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description) != nil
    self.rootViewController.coordinatorUpdateIsPromoWallet(isPromo)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

// MARK: Update from coordinator
extension KNSendTokenViewCoordinator {
  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.rootViewController.coordinatorUpdateBalances(self.balances)
    self.searchTokensVC?.updateBalances(self.balances)
  }

  func coordinatorETHBalanceDidUpdate(ethBalance: Balance) {
    let eth = KNSupportedTokenStorage.shared.ethToken
    self.balances[eth.contract] = ethBalance
    self.rootViewController.coordinatorUpdateBalances(self.balances)
    self.searchTokensVC?.updateBalances(self.balances)
  }

  func coordinatorShouldOpenSend(from token: TokenObject) {
    self.rootViewController.coordinatorDidUpdateSendToken(token, balance: self.balances[token.contract])
  }

  func coordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.searchTokensVC?.updateListSupportedTokens(tokenObjects)
  }

  func coordinatorGasPriceCachedDidUpdate() {
    self.rootViewController.coordinatorUpdateGasPriceCached()
  }

  func coordinatorOpenSendView(to address: String) {
    self.rootViewController.coordinatorSend(to: address)
  }

  func coordinatorDidUpdateTrackerRate() {
    self.rootViewController.coordinatorUpdateTrackerRate()
  }

  func coordinatorDidUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    if let txHash = self.transactionStatusVC?.transaction.id, txHash == txID {
      self.transactionStatusVC?.updateView(with: tx)
      return true
    }
    return false
  }
}

// MARK: Send Token View Controller Delegate
extension KNSendTokenViewCoordinator: KSendTokenViewControllerDelegate {
  func kSendTokenViewController(_ controller: KSendTokenViewController, run event: KSendTokenViewEvent) {
    switch event {
    case .back: self.stop()
    case .setGasPrice:
      break
    case .estimateGas(let transaction):
      self.estimateGasLimit(for: transaction)
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken)
    case .send(let transaction, let ens):
      self.send(transaction: transaction, ens: ens)
    case .addContact(let address, let ens):
      self.openNewContact(address: address, ens: ens)
    case .contactSelectMore:
      self.openListContactsView()
    }
  }

  fileprivate func estimateGasLimit(for transaction: UnconfirmedTransaction) {
    self.session.externalProvider.getEstimateGasLimit(
    for: transaction) { [weak self] result in
      if case .success(let gasLimit) = result {
        self?.rootViewController.coordinatorUpdateEstimatedGasLimit(
          gasLimit,
          from: transaction.transferType.tokenObject(),
          amount: transaction.value
        )
      }
    }
  }

  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = self.session.tokenStorage.tokens
    self.searchTokensVC = {
      let viewModel = KNSearchTokenViewModel(
        headerColor: KNAppStyleType.current.walletFlowHeaderColor,
        supportedTokens: tokens
      )
      let controller = KNSearchTokenViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.searchTokensVC!, animated: true)
    self.searchTokensVC?.updateBalances(self.balances)
  }

  fileprivate func send(transaction: UnconfirmedTransaction, ens: String?) {
    if ens != nil {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_using_ens"])
    }
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      self.confirmVC = {
        let viewModel = KConfirmSendViewModel(transaction: transaction, ens: ens)
        let controller = KConfirmSendViewController(viewModel: viewModel)
        controller.delegate = self
        controller.loadViewIfNeeded()
        return controller
      }()
      self.navigationController.pushViewController(self.confirmVC!, animated: true)
    } else {
      let message = NSLocalizedString("Please wait for other transactions to be mined before making a transfer", comment: "")
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: message,
        time: 2.0
      )
    }
  }

  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address, ens: ens)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
  }

  fileprivate func openListContactsView() {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
}

// MARK: Search Token Delegate
extension KNSendTokenViewCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.navigationController.popViewController(animated: true) {
      self.searchTokensVC = nil
      if case .select(let token) = event {
        let balance = self.balances[token.contract]
        self.rootViewController.coordinatorDidUpdateSendToken(token, balance: balance)
      }
    }
  }
}

// MARK: Confirm Transaction Delegate
extension KNSendTokenViewCoordinator: KConfirmSendViewControllerDelegate {
  func kConfirmSendViewController(_ controller: KConfirmSendViewController, run event: KConfirmViewEvent) {
    if case .confirm(let type) = event, case .transfer(let transaction) = type {
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
        if let errorMessage = message {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: errorMessage,
            time: 2.0
          )
        } else {
          self.didConfirmTransfer(transaction)
        }
      }
    } else {
      self.navigationController.popViewController(animated: true) {
        self.confirmVC = nil
      }
    }
  }
}

// MARK: Network requests
extension KNSendTokenViewCoordinator {
  fileprivate func didConfirmTransfer(_ transaction: UnconfirmedTransaction) {
    self.rootViewController.coordinatorSendTokenUserDidConfirmTransaction()
    // send transaction request
    self.session.externalProvider.transfer(transaction: transaction, completion: { [weak self] sendResult in
      guard let `self` = self else { return }
      switch sendResult {
      case .success(let txHash):
        let tx: Transaction = transaction.toTransaction(
          wallet: self.session.wallet,
          hash: txHash,
          nounce: self.session.externalProvider.minTxCount - 1
        )
        self.session.addNewPendingTransaction(tx)
        if self.confirmVC != nil {
          self.navigationController.popViewController(animated: true, completion: {
            self.confirmVC = nil
            self.openTransactionStatusPopUp(transaction: tx)
          })
        }
      case .failure(let error):
        self.confirmVC?.resetActionButtons()
        KNNotificationUtil.postNotification(
          for: kTransactionDidUpdateNotificationKey,
          object: error,
          userInfo: nil
        )
      }
    })
  }

  fileprivate func openTransactionStatusPopUp(transaction: Transaction) {
    let trans = KNTransaction.from(transaction: transaction)
    self.transactionStatusVC = KNTransactionStatusPopUp(transaction: trans)
    self.transactionStatusVC?.modalPresentationStyle = .overFullScreen
    self.transactionStatusVC?.modalTransitionStyle = .crossDissolve
    self.transactionStatusVC?.delegate = self
    self.navigationController.present(self.transactionStatusVC!, animated: true, completion: nil)
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

extension KNSendTokenViewCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension KNSendTokenViewCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let contact) = event {
        self.rootViewController.coordinatorDidSelectContact(contact)
      } else if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension KNSendTokenViewCoordinator: KNTransactionStatusPopUpDelegate {
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
