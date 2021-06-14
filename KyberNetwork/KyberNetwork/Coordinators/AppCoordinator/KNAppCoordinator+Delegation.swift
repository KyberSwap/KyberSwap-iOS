// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: Landing Page Coordinator Delegate
extension KNAppCoordinator: KNLandingPageCoordinatorDelegate {
  func landingPageCoordinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
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
  func exchangeTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func exchangeTokenCoodinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
  func exchangeTokenCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }

  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: KNWalletObject) {
    guard let wallet = self.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet { return }
    self.restartNewSession(wallet)
  }

  func exchangeTokenCoordinatorRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func exchangeTokenCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }

  func exchangeTokenCoordinatorDidSelectPromoCode() {
    self.addPromoCode()
  }

  func exchangeTokenCoordinatorOpenManageOrder() {
//    self.tabbarController.selectedIndex = 2
//    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
  }

  func exchangeTokenCoordinatorDidUpdateWalletObjects() {
//    self.balanceTabCoordinator?.appCoordinatorDidUpdateWalletObjects()
    self.exchangeCoordinator?.appCoordinatorDidUpdateWalletObjects()
    
  }

  func exchangeTokenCoordinatorDidSelectRemoveWallet(_ wallet: Wallet) {
    self.removeWallet(wallet)
  }

  func exchangeTokenCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
}

extension KNAppCoordinator: EarnCoordinatorDelegate {
  func earnCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func earnCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func earnCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
  
  func earnCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
}

extension KNAppCoordinator: OverviewCoordinatorDelegate {
  func overviewCoordinatorDidSelectExportWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectExportWallet()
  }
  
  func overviewCoordinatorDidSelectDeleteWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectDeleteWallet()
  }
  
  func overviewCoordinatorDidSelectRenameWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectRenameWallet()
  }
  
  func overviewCoordinatorDidChangeHideBalanceStatus(_ status: Bool) {
    self.earnCoordinator?.appCoodinatorDidUpdateHideBalanceStatus(status)
  }

  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String) {
    self.tabbarController.selectedIndex = 3
    self.earnCoordinator?.appCoodinatorDidOpenEarnView(tokenAddress: tokenAddress)
  }
  
  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool) {
    //TODO: temp use token realm object for swap atm, support custom token
    let tokenObject = KNSupportedTokenStorage.shared.get(forPrimaryKey: token.address.lowercased()) ?? (KNGeneralProvider.shared.isEthereum ? KNSupportedTokenStorage.shared.ethToken : KNSupportedTokenStorage.shared.bnbToken)
    self.exchangeCoordinator?.appCoordinatorShouldOpenExchangeForToken(tokenObject, isReceived: isBuy)
    self.tabbarController.selectedIndex = 1
    
  }
  
  func overviewCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func overviewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
  
  func overviewCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
}

extension KNAppCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func krytalCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
}

extension KNAppCoordinator: InvestCoordinatorDelegate {
  func investCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.appCoordinatorDidSelectAddToken(token)
  }
  
  func investCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
  
  func investCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func investCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
}

// MARK: Settings Coordinator Delegate
extension KNAppCoordinator: KNSettingsCoordinatorDelegate {
  func settingsCoordinatorDidSelectAddWallet() {
    self.addNewWallet(type: .full)
  }
  
  func settingsCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.restartNewSession(wallet)
  }
  
  func settingsCoordinatorDidSelectManageWallet() {
    self.tabbarController.selectedIndex = 4
    self.settingsCoordinator?.settingsViewControllerWalletsButtonPressed()
  }
  
  func settingsCoordinatorUserDidUpdateWalletObjects() {
    self.exchangeCoordinator?.appCoordinatorDidUpdateWalletObjects()
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

  func settingsCoordinatorUserDidSelectAddWallet(type: AddNewWalletType) {
    self.addNewWallet(type: type)
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
  func addNewWalletCoordinatorDidSendRefCode(_ code: String) {
    self.sendRefCode(code.uppercased())
  }
  
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

//extension KNAppCoordinator: KNExploreCoordinatorDelegate {
//  func exploreCoordinatorOpenManageOrder() {
////    self.tabbarController.selectedIndex = 2
////    self.limitOrderCoordinator?.appCoordinatorOpenManageOrder()
//  }
//
//  func exploreCoordinatorOpenSwap(from: String, to: String) {
//    self.tabbarController.selectedIndex = 1
//    self.exchangeCoordinator?.appCoordinatorPushNotificationOpenSwap(from: from, to: to)
//  }
//}
