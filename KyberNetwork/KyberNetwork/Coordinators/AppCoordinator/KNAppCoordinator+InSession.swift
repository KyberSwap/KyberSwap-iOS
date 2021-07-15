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
    
    let overviewCoordinator = OverviewCoordinator(session: self.session)
    self.addCoordinator(overviewCoordinator)
    overviewCoordinator.delegate = self
    overviewCoordinator.start()
    self.overviewTabCoordinator = overviewCoordinator

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

    // Settings tab
    self.settingsCoordinator = {
      let coordinator = KNSettingsCoordinator(
        session: self.session
      )
      coordinator.delegate = self
      return coordinator
    }()
    
    self.investCoordinator = {
      let coordinator = InvestCoordinator(session: self.session)
      coordinator.delegate = self
      return coordinator
    }()
    self.investCoordinator?.start()

    self.earnCoordinator = {
      let coordinator = EarnCoordinator(session: self.session)
      coordinator.delegate = self
      return coordinator
    }()
    self.earnCoordinator?.start()

    self.addCoordinator(self.settingsCoordinator!)
    self.settingsCoordinator?.start()

    self.tabbarController.viewControllers = [
      self.overviewTabCoordinator!.navigationController,
      self.exchangeCoordinator!.navigationController,
      self.investCoordinator!.navigationController,
      self.earnCoordinator!.navigationController,
      self.settingsCoordinator!.navigationController,
    ]
    self.tabbarController.tabBar.tintColor = UIColor(named: "buttonBackgroundColor")
    self.tabbarController.tabBar.barTintColor = UIColor(named: "toolbarBgColor")
    self.overviewTabCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_summary_icon"),
      selectedImage: nil
    )
    self.overviewTabCoordinator?.navigationController.tabBarItem.tag = 0

    self.exchangeCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_swap_icon"),
      selectedImage: nil
    )
    self.exchangeCoordinator?.navigationController.tabBarItem.tag = 1

    self.investCoordinator?.navigationController.tabBarItem.tag = 2
    self.investCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_invest_icon"),
      selectedImage: nil
    )

    self.earnCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_earn_icon"),
      selectedImage: nil
    )
    self.earnCoordinator?.navigationController.tabBarItem.tag = 3

    self.settingsCoordinator?.navigationController.tabBarItem = UITabBarItem(
      title: nil,
      image: UIImage(named: "tabbar_setting_icon"),
      selectedImage: nil
    )
    self.settingsCoordinator?.navigationController.tabBarItem.tag = 4

    self.navigationController.pushViewController(self.tabbarController, animated: true) {
    }

    self.addObserveNotificationFromSession()
    self.updateLocalData()

    KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)

    let transactions = self.session.transactionStorage.kyberPendingTransactions
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    
//    self.balanceTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(transactions: transactions)
    self.doLogin()
  }

  func stopAllSessions() {
    KNPasscodeUtil.shared.deletePasscode()
    self.landingPageCoordinator.navigationController.popToRootViewController(animated: false)

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
//    self.balanceTabCoordinator?.stop()
//    self.balanceTabCoordinator = nil
    self.settingsCoordinator?.stop()
    self.settingsCoordinator = nil
//    IEOUserStorage.shared.signedOut()
    self.tabbarController = nil
  }

  // Switching account, restart a new session
  func restartNewSession(_ wallet: Wallet, isLoading: Bool = true) {
    if isLoading { self.navigationController.displayLoading() }
    DispatchQueue.global(qos: .background).async {
      self.loadBalanceCoordinator?.exit()
      EtherscanTransactionStorage.shared.updateCurrentWallet(wallet)
      BalanceStorage.shared.updateCurrentWallet(wallet)
      
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.session.switchSession(wallet)
      self.loadBalanceCoordinator?.restartNewSession(self.session)
      self.exchangeCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      
      self.earnCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      
      self.overviewTabCoordinator?.appCoordinatorDidUpdateNewSession(
        self.session,
        resetRoot: true
      )
      
      self.settingsCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
      
      self.investCoordinator?.appCoordinatorDidUpdateNewSession(self.session)

      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
      )
      self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate(
      )
      self.doLogin()
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

        self.settingsCoordinator?.appCoordinatorDidUpdateNewSession(
          self.session,
          resetRoot: isRemovingCurrentWallet
        )

        self.earnCoordinator?.appCoordinatorDidUpdateNewSession(
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

  func addNewWallet(type: AddNewWalletType) {
    self.navigationController.present(
      self.addWalletCoordinator.navigationController,
      animated: false) {
      self.addWalletCoordinator.start(type: type)
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
