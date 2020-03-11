// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result

/*
 Handling notification from many fetchers, views, ...
 */
extension KNAppCoordinator {
  func addObserveNotificationFromSession() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    let ethBalanceName = Notification.Name(kETHBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.ethBalanceDidUpdateNotification(_:)),
      name: ethBalanceName,
      object: nil
    )
    let tokenBalanceName = Notification.Name(kOtherBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
    let tokenTxListName = Notification.Name(kTokenTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenTransactionListDidUpdate(_:)),
      name: tokenTxListName,
      object: nil
    )
    let tokenObjectListName = Notification.Name(kTokenObjectListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: tokenObjectListName,
      object: nil
    )
    let openExchangeName = Notification.Name(kOpenExchangeTokenViewKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.openExchangeTokenView(_:)),
      name: openExchangeName,
      object: nil
    )
  }

  func addInternalObserveNotification() {
    let rateTokensName = Notification.Name(kExchangeTokenRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateTokenDidUpdateNotification(_:)),
      name: rateTokensName,
      object: nil)
    let prodCachedRateName = Notification.Name(kProdCachedRateSuccessToLoadNotiKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.prodCachedRateTokenDidUpdateNotification(_:)),
      name: prodCachedRateName,
      object: nil)
    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateUSDDidUpdateNotification(_:)),
      name: rateUSDName,
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.gasPriceCachedDidUpdate(_:)),
      name: gasPriceName,
      object: nil
    )
  }

  func removeObserveNotificationFromSession() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kETHBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOtherBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenTransactionListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenObjectListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOpenExchangeTokenViewKey),
      object: nil
    )
  }

  func removeInternalObserveNotification() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeTokenRateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kProdCachedRateSuccessToLoadNotiKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeUSDRateNotificationKey),
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: gasPriceName,
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }

    self.balanceTabCoordinator?.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: loadBalanceCoordinator.totalBalanceInUSD,
      totalBalanceInETH: loadBalanceCoordinator.totalBalanceInETH
    )
  }

  @objc func prodCachedRateTokenDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorUpdateExchangeTokenRates()
    self.limitOrderCoordinator?.appCoordinatorUpdateExchangeTokenRates()
  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = loadBalanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = loadBalanceCoordinator.totalBalanceInETH

    self.exchangeCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
    self.limitOrderCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
    self.balanceTabCoordinator?.appCoordinatorExchangeRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )
    self.settingsCoordinator?.appCoordinatorUSDRateUpdate()
  }

  @objc func ethBalanceDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = loadBalanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = loadBalanceCoordinator.totalBalanceInETH
    let ethBalance: Balance = loadBalanceCoordinator.ethBalance

    self.exchangeCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
    self.balanceTabCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
    self.limitOrderCoordinator?.appCoordinatorETHBalanceDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      ethBalance: ethBalance
    )
    self.settingsCoordinator?.appCoordinatorETHBalanceDidUpdate(ethBalance: ethBalance)
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = loadBalanceCoordinator.totalBalanceInUSD
    let totalETH: BigInt = loadBalanceCoordinator.totalBalanceInETH
    let otherTokensBalance: [String: Balance] = loadBalanceCoordinator.otherTokensBalance

    self.exchangeCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
    self.balanceTabCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
    self.limitOrderCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )
    self.settingsCoordinator?.appCoordinatorTokenBalancesDidUpdate(balances: otherTokensBalance)
  }

  @objc func transactionStateDidUpdate(_ sender: Notification) {
    if self.session == nil { return }
    let transaction: KNTransaction? = {
      if let txHash = sender.object as? String {
        return self.session.transactionStorage.getKyberTransaction(forPrimaryKey: txHash)
      }
      return nil
    }()
    if let error = sender.object as? AnyError {
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("failed", value: "Failed", comment: ""),
        message: error.prettyError,
        time: -1
      )
      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_update_failed", customAttributes: ["info": "no_details"])
      let transactions = self.session.transactionStorage.kyberPendingTransactions
      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
      self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
      return
    }
    guard let trans = transaction else {
      if let info = sender.userInfo as? JSONDictionary {
        let txHash = sender.object as? String ?? ""
        let updateBalance = self.balanceTabCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
        let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
        let updateLO = self.limitOrderCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
        let updateSettings = self.settingsCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
        if !(updateBalance || updateExchange || updateLO || updateSettings) {
          var popupMessage = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
          if let isLost = info["is_lost"] as? TransactionType {
            switch isLost {
            case .cancel:
              popupMessage = "Your cancel transaction might be lost".toBeLocalised()
              if self.session.updateFailureTransaction(type: .cancel) { return }
            case .speedup:
              popupMessage = "Your speedup transaction might be lost".toBeLocalised()
              if self.session.updateFailureTransaction(type: .speedup) { return }
            default:
              popupMessage = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
            }
          } else if let isCancel = info["is_cancel"] as? TransactionType {
            switch isCancel {
            case .cancel:
              popupMessage = "Can not cancel the transaction".toBeLocalised()
            case .speedup:
              popupMessage = "Can not speed up the transaction".toBeLocalised()
            default:
              popupMessage = ""
            }
          }

          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("failed", value: "Failed", comment: ""),
            message: popupMessage,
            time: -1
          )
        }
        KNCrashlyticsUtil.logCustomEvent(withName: "transaction_update_failed", customAttributes: ["info": "lost_dropped_replaced"])
      }

      let transactions = self.session.transactionStorage.kyberPendingTransactions
      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
      self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
      return
    }
    let updateBalance = self.balanceTabCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
    let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
    let updateLO = self.limitOrderCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
    let updateSettings = self.settingsCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false

    if trans.state == .pending {
      // just sent
    } else if trans.state == .completed {
      if !(updateBalance || updateExchange || updateLO || updateSettings) {
        let message = trans.type == .cancel ? "Your transaction has been cancelled successfully".toBeLocalised() : trans.getDetails()
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: message,
          time: -1
        )
      }
      if self.session != nil {
        self.session.transacionCoordinator?.forceUpdateNewTransactionsWhenPendingTxCompleted()
        if trans.isTransfer, let tokenAddr = trans.getTokenObject()?.contract {
          self.loadBalanceCoordinator?.fetchTokenAddressAfterTx(token1: tokenAddr, token2: tokenAddr)
        } else if let objc = trans.localizedOperations.first {
          self.loadBalanceCoordinator?.fetchTokenAddressAfterTx(token1: objc.from, token2: objc.to)
        }
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_update_success", customAttributes: ["info": trans.shortDesc])
    } else if trans.state == .failed || trans.state == .error {
      if !(updateBalance || updateExchange || updateLO || updateSettings) {
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("failed", value: "Failed", comment: ""),
          message: trans.getDetails(),
          time: -1
        )
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_update_failed", customAttributes: ["info": trans.shortDesc])
    }
    let transactions = self.session.transactionStorage.kyberPendingTransactions
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.limitOrderCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.limitOrderCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.balanceTabCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.loadBalanceCoordinator?.forceUpdateBalanceTransactionsCompleted()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.session.tokenStorage.addKyberSupportedTokens()
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.balanceTabCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.limitOrderCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.exchangeCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.settingsCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  @objc func gasPriceCachedDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
    self.limitOrderCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
    self.balanceTabCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
  }

  @objc func openExchangeTokenView(_ sender: Any?) {
    if self.session == nil { return }
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.navigationController.popToRootViewController(animated: true)
  }
}
