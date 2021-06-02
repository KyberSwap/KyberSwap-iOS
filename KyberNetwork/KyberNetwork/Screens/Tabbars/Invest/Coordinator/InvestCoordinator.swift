//
//  InvestCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/12/21.
//

import Foundation
import Moya
import BigInt

protocol InvestCoordinatorDelegate: class {
  func investCoordinatorDidSelectWallet(_ wallet: Wallet)
  func investCoordinatorDidSelectManageWallet()
  func investCoordinatorDidSelectAddWallet()
  func investCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class InvestCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  var balances: [String: Balance] = [:]
  var sendCoordinator: KNSendTokenViewCoordinator?
  var krytalCoordinator: KrytalCoordinator?
  fileprivate var loadTimer: Timer?
  weak var delegate: InvestCoordinatorDelegate?
  var historyCoordinator: KNHistoryCoordinator?
  
  lazy var rootViewController: InvestViewController = {
    let controller = InvestViewController()
    controller.delegate = self
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.loadCachedMarketAssets()
    self.startIntervalLoadingAssets()
    self.loadMarketAssets()
  }

  func stop() {
    self.loadTimer?.invalidate()
    self.loadTimer = nil
  }
  
  func appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: BigInt, totalBalanceInETH: BigInt, otherTokensBalance: [String: Balance]) {
    otherTokensBalance.forEach { self.balances[$0.key] = $0.value }
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }
  
  fileprivate func loadMarketAssets() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getMarketingAssets) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(MarketingAssetsResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateMarketingAssets(data.assets)
          Storage.store(data.assets, as: Constants.marketingAssetsStoreFileName)
        } catch let error {
          print("[Krytal] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Krytal] \(error.localizedDescription)")
      }
    }
  }
  
  fileprivate func loadCachedMarketAssets() {
    let assets = Storage.retrieve(Constants.marketingAssetsStoreFileName, as: [Asset].self) ?? []
    self.rootViewController.coordinatorDidUpdateMarketingAssets(assets)
  }
  
  fileprivate func startIntervalLoadingAssets() {
    self.loadTimer?.invalidate()
    self.loadTimer = nil
    self.loadTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.minutes5,
      repeats: true,
      block: { [weak self] timer in
        guard let `self` = self else { return }
        self.loadMarketAssets()
      }
    )
  }
  
  fileprivate func openSendTokenView() {
    let from: TokenObject = {
      if KNGeneralProvider.shared.isEthereum {
        return KNSupportedTokenStorage.shared.ethToken
      } else {
        return KNSupportedTokenStorage.shared.bnbToken
      }
    }()
    let coordinator = KNSendTokenViewCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      balances: self.balances,
      from: from
    )
    coordinator.delegate = self
    coordinator.start()
    self.sendCoordinator = coordinator
  }
  
  fileprivate func openKrytalView() {
    let coordinator = KrytalCoordinator(navigationController: self.navigationController, session: self.session)
    coordinator.delegate = self
    coordinator.start()
    self.krytalCoordinator = coordinator
  }
  
  func openHistoryScreen() {
    self.historyCoordinator = nil
    self.historyCoordinator = KNHistoryCoordinator(
      navigationController: self.navigationController,
      session: self.session
    )
    self.historyCoordinator?.delegate = self
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(self.session)
    self.historyCoordinator?.start()
  }
  
  func appCoordinatorPendingTransactionsDidUpdate() {
    self.sendCoordinator?.coordinatorDidUpdatePendingTx()
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession) {
    self.sendCoordinator?.appCoordinatorDidUpdateNewSession(session)
    self.krytalCoordinator?.appCoordinatorDidUpdateNewSession(session)
  }
  
  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    return false
  }
  
  func appCoordinatorDidUpdateChain() {
    self.rootViewController.coordinatorDidUpdateChain()
    self.loadMarketAssets()
    self.sendCoordinator?.appCoordinatorDidUpdateChain()
  }
}

extension InvestCoordinator: InvestViewControllerDelegate {
  func investViewController(_ controller: InvestViewController, run event: InvestViewEvent) {
    switch event {
    case .openLink(url: let url):
      controller.openSafari(with: url)
    case .swap:
      self.navigationController.tabBarController?.selectedIndex = 1
    case .transfer:
      self.openSendTokenView()
    case .deposit:
      self.navigationController.tabBarController?.selectedIndex = 3
    case .krytal:
      self.openKrytalView()
    }
  }
}

extension InvestCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.investCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }
  
  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
}

extension InvestCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.investCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidClose() {
    
  }
  
  func historyCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.investCoordinatorDidSelectWallet(wallet)
  }
  
  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
}

extension InvestCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.delegate?.investCoordinatorDidSelectAddWallet()
  }
  
  func krytalCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.investCoordinatorDidSelectWallet(wallet)
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.delegate?.investCoordinatorDidSelectManageWallet()
  }
}
