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
    
    let newRecevieName = Notification.Name(kNewReceivedTransactionKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.handleNewReceiveTx(_:)),
      name: newRecevieName,
      object: nil
    )
    
  }

  func addInternalObserveNotification() {
    let changeChain = Notification.Name(kChangeChainNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.chainDidUpdateNotification(_:)),
      name: changeChain,
      object: nil
    )
    
    let rateTokensName = Notification.Name(kExchangeTokenRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateTokenDidUpdateNotification(_:)),
      name: rateTokensName,
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

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userRestoreIdReceived),
      name: NSNotification.Name(rawValue: FRESHCHAT_USER_RESTORE_ID_GENERATED),
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
//    NotificationCenter.default.removeObserver(
//      self,
//      name: Notification.Name(kProdCachedRateSuccessToLoadNotiKey),
//      object: nil
//    )
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
    let marketDataName = Notification.Name(kMarketSuccessToLoadNotiKey)
    NotificationCenter.default.removeObserver(
      self,
      name: marketDataName,
      object: nil
    )

    let liveChatName = Notification.Name(FRESHCHAT_USER_RESTORE_ID_GENERATED)
    NotificationCenter.default.removeObserver(
      self,
      name: liveChatName,
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }

//    self.balanceTabCoordinator?.appCoordinatorExchangeRateDidUpdate(
//      totalBalanceInUSD: loadBalanceCoordinator.totalBalanceInUSD,
//      totalBalanceInETH: loadBalanceCoordinator.totalBalanceInETH
//    )
  }

//  @objc func prodCachedRateTokenDidUpdateNotification(_ sender: Any?) {
//    if self.session == nil { return }
//    self.exchangeCoordinator?.appCoordinatorUpdateExchangeTokenRates()
//    self.limitOrderCoordinator?.appCoordinatorUpdateExchangeTokenRates()
//  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = BigInt(0)
    let totalETH: BigInt = BigInt(0)

    self.exchangeCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )

    self.settingsCoordinator?.appCoordinatorUSDRateUpdate()
  }
  
  @objc func chainDidUpdateNotification(_ sender: Notification) {
    if let address = sender.object as? String, let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == address.lowercased() }) {
      self.restartNewSession(wal)
    }

    KNSupportedTokenCoordinator.shared.pause()
    KNSupportedTokenCoordinator.shared.resume()
    KNSupportedTokenStorage.shared.reloadData()
    
    KNRateCoordinator.shared.pause()
    KNRateCoordinator.shared.resume()
    KNTrackerRateStorage.shared.reloadData()
    
    KNGasCoordinator.shared.pause()
    KNGasCoordinator.shared.resume()
    
    self.exchangeCoordinator?.appCoordinatorDidUpdateChain()
    self.overviewTabCoordinator?.appCoordinatorDidUpdateChain()
    self.investCoordinator?.appCoordinatorDidUpdateChain()
    self.earnCoordinator?.appCoordinatorDidUpdateChain()
    self.settingsCoordinator?.appCoordinatorDidUpdateChain()
    self.session.externalProvider?.minTxCount = 0
    
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = BigInt(0)
    let totalETH: BigInt = BigInt(0)
    let otherTokensBalance: [String: Balance] = loadBalanceCoordinator.otherTokensBalance

    self.exchangeCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )

    self.settingsCoordinator?.appCoordinatorTokenBalancesDidUpdate(balances: otherTokensBalance)
    
    self.earnCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.investCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.overviewTabCoordinator?.appCoordinatorDidUpdateTokenList()
  }

  //swiftlint:disable function_body_length
  @objc func transactionStateDidUpdate(_ sender: Notification) {
    guard self.session != nil, let transaction = sender.object as? InternalHistoryTransaction else { return }
    
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.earnCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.investCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.settingsCoordinator?.appCoordinatorPendingTransactionsDidUpdate()

    let updateOverview = self.overviewTabCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateEarn = self.earnCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateInvest = self.investCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    if !(updateOverview || updateExchange || updateEarn || updateInvest) {
      guard transaction.isEth == KNGeneralProvider.shared.isEthereum else {
        return
      }
      if transaction.state == .done {
        self.loadBalanceCoordinator?.loadAllBalances()
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: "Transaction is successful",
          time: 3
        )
      } else if transaction.state == .drop || transaction.state == .error {
        self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("failed", value: "Failed", comment: ""),
        message: "Transaction is failure",
        time: 3
        )
      }
    }

    if transaction.state == .done || transaction.state == .drop || transaction.state == .error {
      self.loadBalanceCoordinator?.loadAllBalances()
      self.session.transacionCoordinator?.loadEtherscanTransactions()
    }
   
    
    //TODO: update status view
    
//    let transaction: KNTransaction? = {
//      if let txHash = sender.object as? String {
//        return self.session.transactionStorage.getKyberTransaction(forPrimaryKey: txHash)
//      }
//      return nil
//    }()
//    if let error = sender.object as? AnyError {
//      self.navigationController.showErrorTopBannerMessage(
//        with: NSLocalizedString("failed", value: "Failed", comment: ""),
//        message: error.prettyError,
//        time: -1
//      )
//      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_update_failed", customAttributes: ["info": "no_details"])
//      let transactions = self.session.transactionStorage.kyberPendingTransactions
//      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
////      self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
//      return
//    }
//    guard let trans = transaction else {
//      if let info = sender.userInfo as? JSONDictionary {
//        let txHash = sender.object as? String ?? ""
//        let updateOverview = self.overviewTabCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
//        let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
//        let updateLO = self.limitOrderCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
//        let updateSettings = self.settingsCoordinator?.appCoordinatorUpdateTransaction(nil, txID: txHash) ?? false
//        if !( updateExchange || updateLO || updateSettings || updateOverview ) {
//          var popupMessage = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
//          if let isLost = info["is_lost"] as? TransactionType {
//            switch isLost {
//            case .cancel:
//              popupMessage = "Your cancel transaction might be lost".toBeLocalised()
//              if self.session.updateFailureTransaction(type: .cancel) { return }
//            case .speedup:
//              popupMessage = "Your speedup transaction might be lost".toBeLocalised()
//              if self.session.updateFailureTransaction(type: .speedup) { return }
//            default:
//              popupMessage = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
//            }
//          } else if let isCancel = info["is_cancel"] as? TransactionType {
//            switch isCancel {
//            case .cancel:
//              popupMessage = "Can not cancel the transaction".toBeLocalised()
//            case .speedup:
//              popupMessage = "Can not speed up the transaction".toBeLocalised()
//            default:
//              popupMessage = ""
//            }
//          }
//
//          self.navigationController.showErrorTopBannerMessage(
//            with: NSLocalizedString("failed", value: "Failed", comment: ""),
//            message: popupMessage,
//            time: -1
//          )
//        }
//      }
//
//      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
////      self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
//      return
//    }
//
//    let updateOverview = self.overviewTabCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
//    let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
//    let updateLO = self.limitOrderCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
//    let updateSettings = self.settingsCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
//    let updateEarn = self.earnCoordinator?.appCoordinatorUpdateTransaction(trans, txID: trans.id) ?? false
//
//    if trans.state == .pending {
//      // just sent
//    } else if trans.state == .completed {
//      if !(  updateExchange || updateLO || updateSettings || updateEarn || updateOverview) {
//        let message = trans.type == .cancel ? "Your transaction has been cancelled successfully".toBeLocalised() : trans.getDetails()
//        self.navigationController.showSuccessTopBannerMessage(
//          with: NSLocalizedString("success", value: "Success", comment: ""),
//          message: message,
//          time: -1
//        )
//      }
//      if self.session != nil {
//        self.session.transacionCoordinator?.forceUpdateNewTransactionsWhenPendingTxCompleted()
//        if trans.isTransfer, let tokenAddr = trans.getTokenObject()?.contract {
//          self.loadBalanceCoordinator?.fetchTokenAddressAfterTx(token1: tokenAddr, token2: tokenAddr)
//        } else if let objc = trans.localizedOperations.first {
//          self.loadBalanceCoordinator?.fetchTokenAddressAfterTx(token1: objc.from, token2: objc.to)
//        }
//      }
//      if let type = trans.localizedOperations.first?.type {
//        if type == "transfer" {
//          KNCrashlyticsUtil.logCustomEvent(withName: "tx_mined_transfer_success",
//                                           customAttributes: [
//                                            "token": trans.from,
//                                            "src_amount": trans.value,
//            ]
//          )
//        } else if type == "exchange" {
//          KNCrashlyticsUtil.logCustomEvent(withName: "tx_mined_swap_success",
//                                           customAttributes: [
//                                            "src_token": trans.from,
//                                            "des_token": trans.to,
//                                            "src_amount": trans.getSourceAmount(),
//                                            "des_amount": trans.getDestinationAmount(),
//            ]
//          )
//        }
//      }
//    } else if trans.state == .failed || trans.state == .error {
//      if !( updateExchange || updateLO || updateSettings) {
//        self.navigationController.showSuccessTopBannerMessage(
//          with: NSLocalizedString("failed", value: "Failed", comment: ""),
//          message: trans.getDetails(),
//          time: -1
//        )
//      }
//      if let type = trans.localizedOperations.first?.type {
//        if type == "transfer" {
//          KNCrashlyticsUtil.logCustomEvent(withName: "tx_mined_transfer_fail",
//                                           customAttributes: [
//                                            "token": trans.from,
//                                            "src_amount": trans.value,
//                                            "error": trans.getDetails(),
//            ]
//          )
//        } else if type == "exchange" {
//          KNCrashlyticsUtil.logCustomEvent(withName: "tx_mined_swap_fail",
//                                           customAttributes: [
//                                            "src_token": trans.from,
//                                            "des_token": trans.to,
//                                            "src_amount": trans.getSourceAmount(),
//                                            "des_amount": trans.getDestinationAmount(),
//                                            "error": trans.getDetails(),
//            ]
//          )
//        }
//      }
//    }
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.overviewTabCoordinator?.appCoordinatorDidUpdateTokenList()
    self.earnCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.session.tokenStorage.addKyberSupportedTokens()
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
//    self.balanceTabCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.exchangeCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.settingsCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  @objc func gasPriceCachedDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
//    self.balanceTabCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
  }

  @objc func openExchangeTokenView(_ sender: Any?) {
    if self.session == nil { return }
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.navigationController.popToRootViewController(animated: true)
  }

  @objc func userRestoreIdReceived() {
    guard let restoreId = FreshchatUser.sharedInstance().restoreID, let externalID = FreshchatUser.sharedInstance().externalID  else {
      return
    }
    if var saved = UserDefaults.standard.object(forKey: KNAppTracker.kSavedRestoreIDForLiveChat) as? [String: String] {
      saved[externalID] = restoreId
      UserDefaults.standard.set(saved, forKey: KNAppTracker.kSavedRestoreIDForLiveChat)
    } else {
      let dict = [externalID: restoreId]
      UserDefaults.standard.set(dict, forKey: KNAppTracker.kSavedRestoreIDForLiveChat)
    }
    Freshchat.sharedInstance().identifyUser(withExternalID: externalID, restoreID: restoreId)
  }
  
  @objc func handleNewReceiveTx(_ sender: Notification) {
    guard let transaction = sender.object as? HistoryTransaction else { return }
    
    if transaction.type == .receiveETH {
      if let internalTx = transaction.transacton.first, let amount = BigInt(internalTx.value) {
        let message = "You have received \(amount.shortString(decimals: 18)) ETH from \(internalTx.from)"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
    
    if transaction.type == .receiveToken {
      if let tokenTx = transaction.tokenTransactions.first, let amount = BigInt(tokenTx.value), let decimals = Int(tokenTx.tokenDecimal) {
        let message = "You have received \(amount.shortString(decimals: decimals)) \(tokenTx.tokenSymbol) from \(tokenTx.from)"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
    
    if transaction.type == .earn {
      let tokenTx = transaction.tokenTransactions.first { (tx) -> Bool in
        let address = self.session.wallet.address
        return tx.to.lowercased() == address.description.lowercased()
      }

      if let unwrapped = tokenTx, let amount = BigInt(unwrapped.value), let decimals = Int(unwrapped.tokenDecimal) {
        let message = "You have received \(amount.shortString(decimals: decimals)) \(unwrapped.tokenSymbol) from Suppying"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
  }
}
