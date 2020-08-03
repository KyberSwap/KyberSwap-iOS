// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  func landingPageCoordinator(import wallet: Wallet) {
    if self.tabbarController == nil {
      self.startNewSession(with: wallet)
    } else {
      self.restartNewSession(wallet)
    }
  }

  func landingPageCoordinator(remove wallet: Wallet) {
    self.removeWallet(wallet)
  }
}

// MARK: Session Delegate
extension KNAppCoordinator: KNSessionDelegate {
  func userDidClickExitSession() {
    let alertController = KNPrettyAlertController(
      title: "exit".toBeLocalised(),
      message: "do.you.want.to.exit.and.remove.all.wallets".toBeLocalised(),
      secondButtonTitle: "OK".toBeLocalised(),
      firstButtonTitle: "cancel".toBeLocalised(),
      secondButtonAction: {
        self.stopAllSessions()
      },
      firstButtonAction: nil
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

// MARK: Exchange Token Coordinator Delegate
extension KNAppCoordinator: KNExchangeTokenCoordinatorDelegate {
  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet { return }
    self.restartNewSession(wallet)
  }

  func exchangeTokenCoordinatorRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func exchangeTokenCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }

  func exchangeTokenCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }

  func exchangeTokenCoordinatorOpenManageOrder() {
    self.tabbarController.selectedIndex = 2
    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
  }
}

// MARK: Limit Order Coordinator Delegate
extension KNAppCoordinator: KNLimitOrderTabCoordinatorV2Delegate {
  func limitOrderTabCoordinatorDidSelectWallet(_ wallet: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet { return }
    self.restartNewSession(wallet)
  }

  func limitOrderTabCoordinatorRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func limitOrderTabCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }

  func limitOrderTabCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }

  func limitOrderTabCoordinatorOpenExchange(from: String, to: String) {
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
  }
}

// MARK: Settings Coordinator Delegate
extension KNAppCoordinator: KNSettingsCoordinatorDelegate {
  func settingsCoordinatorUserDidUpdateWalletObjects() {
    self.balanceTabCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.exchangeCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.limitOrderCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.exploreCoordinator?.appCoordinatorDidUpdateWalletObjects()
  }

  func settingsCoordinatorUserDidSelectExit() {
    self.userDidClickExitSession()
  }

  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }

  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func settingsCoordinatorUserDidSelectAddWallet() {
    self.addNewWallet()
  }
}

// MARK: Balance Tab Coordinator Delegate
extension KNAppCoordinator: KNBalanceTabCoordinatorDelegate {
  func balanceTabCoordinatorShouldOpenExchange(for tokenObject: TokenObject, isReceived: Bool) {
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject, isReceived: isReceived)
    self.tabbarController.selectedIndex = 1
    self.tabbarController.tabBar.tintColor = UIColor.Kyber.tabbarActive
  }

  func balanceTabCoordinatorDidSelect(walletObject: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == walletObject.address.lowercased() }) else { return }
    self.restartNewSession(wallet)
  }

  func balanceTabCoordinatorDidSelectAddWallet() {
    self.addNewWallet()
  }

  func balanceTabCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }

  func balanceTabCoordinatorOpenManageOrder() {
    self.tabbarController.selectedIndex = 2
    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
  }

  func balanceTabCoordinatorOpenSwap(from: String, to: String) {
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
  }
}

// MARK: Transaction Status Delegate
extension KNAppCoordinator: KNTransactionStatusCoordinatorDelegate {
  func transactionStatusCoordinatorDidClose() {
    self.transactionStatusCoordinator = nil
    let trans = self.session.transactionStorage.kyberTransactions.filter({ return $0.state != .pending })
    if !trans.isEmpty { self.session.transactionStorage.delete(trans) }
  }
}

// MARK: Add wallet coordinator delegate
extension KNAppCoordinator: KNAddNewWalletCoordinatorDelegate {
  func addNewWalletCoordinator(add wallet: Wallet) {
    // reset loading state
    KNAppTracker.updateAllTransactionLastBlockLoad(0, for: wallet.address)
    if self.tabbarController == nil {
      self.startNewSession(with: wallet)
    } else {
      self.restartNewSession(wallet)
    }
  }

  func addNewWalletCoordinator(remove wallet: Wallet) {
    self.removeWallet(wallet)
  }
}

extension KNAppCoordinator: KNPromoCodeCoordinatorDelegate {
  func promoCodeCoordinatorDidCreate(_ wallet: Wallet, expiredDate: TimeInterval, destinationToken: String?, destAddress: String?, name: String?) {
    self.navigationController.popViewController(animated: true) {
      let address = wallet.address.description
      KNWalletPromoInfoStorage.shared.addWalletPromoInfo(
        address: address,
        destinationToken: destinationToken ?? "",
        destAddress: destAddress,
        expiredTime: expiredDate
      )
      self.addNewWalletCoordinator(add: wallet)
    }
  }
}

// MARK: Passcode coordinator delegate
extension KNAppCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidEvaluatePIN() {
    self.authenticationCoordinator.stop {}
  }
  func passcodeCoordinatorDidCreatePasscode() {
    self.authenticationCoordinator.stop {}
  }
}

extension KNAppCoordinator: KNExploreCoordinatorDelegate {
  func exploreCoordinatorOpenManageOrder() {
    self.tabbarController.selectedIndex = 2
    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
  }

  func exploreCoordinatorOpenSwap(from: String, to: String) {
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
  }
}
