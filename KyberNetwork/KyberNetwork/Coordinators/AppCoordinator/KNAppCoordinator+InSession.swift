// Copyright SIX DAY LLC. All rights reserved.

import UIKit

// MARK: This file for handling in session
extension KNAppCoordinator {
  //swiftlint:disable function_body_length
  func startNewSession(with wallet: Wallet) {
    self.keystore.recentlyUsedWallet = wallet
    self.currentWallet = wallet
    self.session = KNSession(keystore: self.keystore, wallet: wallet)
    self.session.startSession()
    self.loadBalanceCoordinator?.exit()
    self.loadBalanceCoordinator = nil
    self.loadBalanceCoordinator = KNLoadBalanceCoordinator(session: self.session)
    self.loadBalanceCoordinator?.resume()

    self.tabbarController = KNTabBarController()
    self.tabbarController.tabBar.barTintColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7)
    // Balance Tab
    self.balanceTabCoordinator = {
      let coordinator = KNBalanceTabCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.balanceTabCoordinator!)
    self.balanceTabCoordinator?.start()

    // KyberSwap Tab
    self.exchangeCoordinator = {
      let coordinator = KNExchangeTokenCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.exchangeCoordinator!)
    self.exchangeCoordinator?.start()

    self.limitOrderCoordinator = {
      let coordinator = KNLimitOrderTabCoordinatorV2(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    self.addCoordinator(self.limitOrderCoordinator!)
    self.limitOrderCoordinator?.start()

    // Settings tab
    self.settingsCoordinator = {
      let coordinator = KNSettingsCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()

    self.exploreCoordinator = {
      let coordinator = KNExploreCoordinator(session: self.session)
      coordinator.delegate = self
      return coordinator
    }()
    self.exploreCoordinator?.start()

    self.addCoordinator(self.settingsCoordinator!)
    self.settingsCoordinator?.start()

    self.tabbarController.viewControllers = [
      self.balanceTabCoordinator!.navigationController,
      self.exchangeCoordinator!.navigationController,
      self.limitOrderCoordinator!.navigationController,
      self.exploreCoordinator!.navigationController,
      self.settingsCoordinator!.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor.Kyber.tabbarActive
    self.balanceTabCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: NSLocalizedString("balance", value: "Balance", comment: ""),
      image: UIImage(named: "tabbar_balance_icon_normal"),
      selectedImage: UIImage(named: "tabbar_balance_icon_active")
    )
    self.balanceTabCoordinator?.navigationController.tabBarItem.tag = 0

    self.exchangeCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: NSLocalizedString("kyberswap", value: "KyberSwap", comment: ""),
      image: UIImage(named: "tabbar_kyberswap_icon_normal"),
      selectedImage: UIImage(named: "tabbar_kyberswap_icon_active")
    )
    self.exchangeCoordinator?.navigationController.tabBarItem.tag = 1

    self.limitOrderCoordinator?.navigationController.tabBarItem.tag = 2
    self.limitOrderCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: NSLocalizedString("Limit Order", value: "Limit Order", comment: ""),
      image: UIImage(named: "tabbar_limit_order_icon_normal"),
      selectedImage: UIImage(named: "tabbar_limit_order_icon_active")
    )

    self.exploreCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: NSLocalizedString("Explore", value: "Explore", comment: ""),
      image: UIImage(named: "tabbar_explore_normal_icon"),
      selectedImage: UIImage(named: "tabbar_explore_active_icon")
    )
    self.exploreCoordinator?.navigationController.tabBarItem.tag = 3

    self.settingsCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: NSLocalizedString("settings", value: "Settings", comment: ""),
      image: UIImage(named: "tabbar_settings_icon_normal"),
      selectedImage: UIImage(named: "tabbar_settings_icon_active")
    )
    self.settingsCoordinator?.navigationController.tabBarItem.tag = 4

    self.navigationController.pushViewController(self.tabbarController, animated: true) {
      // default balance tab
      self.tabbarController.tabBar.tintColor = UIColor.Kyber.tabbarActive
    }

    self.addObserveNotificationFromSession()
    self.updateLocalData()

    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)

    let transactions = self.session.transactionStorage.kyberPendingTransactions
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.limitOrderCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
  }

  func stopAllSessions() {
    KNPasscodeUtil.shared.deletePasscode()
    self.landingPageCoordinator.navigationController.popToRootViewController(animated: false)
    self.removeObserveNotificationFromSession()

    self.loadBalanceCoordinator?.exit()
    self.loadBalanceCoordinator = nil

    if self.session == nil, let wallet = self.keystore.wallets.first {
      self.session = KNSession(keystore: self.keystore, wallet: wallet)
    }
    if self.session != nil { self.session.stopSession() }
    KNWalletStorage.shared.deleteAll()

    self.currentWallet = nil
    self.keystore.recentlyUsedWallet = nil
    self.session = nil

    self.navigationController.popToRootViewController(animated: true)

    // Stop all coordinators in tabs and re-assign to nil
    self.exchangeCoordinator?.stop()
    self.exchangeCoordinator = nil
    self.balanceTabCoordinator?.stop()
    self.balanceTabCoordinator = nil
    self.limitOrderCoordinator?.stop()
    self.limitOrderCoordinator = nil
    self.exploreCoordinator?.stop()
    self.exploreCoordinator = nil
    self.settingsCoordinator?.stop()
    self.settingsCoordinator = nil
    IEOUserStorage.shared.signedOut()
    self.tabbarController = nil
  }

  // Switching account, restart a new session
  func restartNewSession(_ wallet: Wallet, isLoading: Bool = true) {
    if isLoading { self.navigationController.displayLoading() }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.removeObserveNotificationFromSession()

      self.loadBalanceCoordinator?.exit()
      self.session.switchSession(wallet)
      self.loadBalanceCoordinator?.restartNewSession(self.session)

      let isPromo = KNWalletPromoInfoStorage.shared.getDestinationToken(from: wallet.address.description) != nil
      if isPromo {
        // default select swap for PT wallet
        self.tabbarController.selectedIndex = 1
      }

      self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      self.exploreCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      self.balanceTabCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      self.limitOrderCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      self.exploreCoordinator?.updateSession(self.session)
      self.settingsCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
      self.addObserveNotificationFromSession()
      self.updateLocalData()
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      let transactions = self.session.transactionStorage.kyberPendingTransactions
      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
        transactions: transactions
      )
      self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
        transactions: transactions
      )
      self.limitOrderCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
        transactions: transactions
      )
      self.exploreCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
        transactions: transactions
      )
      if isLoading { self.navigationController.hideLoading() }
    }
  }

  // Remove a wallet
  func removeWallet(_ wallet: Wallet) {
    self.navigationController.displayLoading(text: NSLocalizedString("removing", value: "Removing", comment: ""), animated: true)
    if self.keystore.wallets.count == 1 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        self.stopAllSessions()
        self.navigationController.hideLoading()
      }
      return
    }
    // User remove current wallet, switch to another wallet first
    if self.session == nil {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        self.stopAllSessions()
        self.navigationController.hideLoading()
      }
      return
    }
    let isRemovingCurrentWallet: Bool = self.session.wallet == wallet
    var delayTime: Double = 0.0
    if isRemovingCurrentWallet {
      guard let newWallet = self.keystore.wallets.last(where: { $0 != wallet }) else { return }
      self.restartNewSession(newWallet, isLoading: false)
      delayTime = 0.25
    }
    self.loadBalanceCoordinator?.exit()
    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
      if self.session.removeWallet(wallet) {
        self.loadBalanceCoordinator?.restartNewSession(self.session)
        self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(
          self.session,
          resetRoot: isRemovingCurrentWallet
        )
        self.balanceTabCoordinator?.appCoordinatorDidUpdateNewSession(
          self.session,
          resetRoot: isRemovingCurrentWallet
        )
        self.limitOrderCoordinator?.appCoordinatorDidUpdateNewSession(
          self.session,
          resetRoot: isRemovingCurrentWallet
        )
        self.settingsCoordinator?.appCoordinatorDidUpdateNewSession(
          self.session,
          resetRoot: isRemovingCurrentWallet
        )
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      } else {
        self.loadBalanceCoordinator?.restartNewSession(self.session)
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("something.went.wrong.can.not.remove.wallet", value: "Something went wrong. Can not remove wallet.", comment: "")
        )
      }
      self.navigationController.hideLoading()
    }
  }

  func addNewWallet() {
    let addWalletCoordinator = KNAddNewWalletCoordinator(keystore: self.session.keystore)
    addWalletCoordinator.delegate = self
    self.navigationController.present(
      addWalletCoordinator.navigationController,
      animated: false) {
      addWalletCoordinator.start()
    }
  }

  func addPromoCode() {
    self.promoCodeCoordinator = nil
    self.promoCodeCoordinator = KNPromoCodeCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    self.promoCodeCoordinator?.delegate = self
    self.promoCodeCoordinator?.start()
  }

  fileprivate func updateLocalData() {
    self.tokenBalancesDidUpdateNotification(nil)
    self.exchangeRateTokenDidUpdateNotification(nil)
    self.tokenObjectListDidUpdate(nil)
    self.tokenTransactionListDidUpdate(nil)
  }
}
