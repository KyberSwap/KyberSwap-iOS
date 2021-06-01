//
//  OverviewCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import Foundation
import Moya
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnect

protocol OverviewCoordinatorDelegate: class {
  func overviewCoordinatorDidSelectAddWallet()
  func overviewCoordinatorDidSelectWallet(_ wallet: Wallet)
  func overviewCoordinatorDidSelectManageWallet()
  func overviewCoordinatorDidSelectSwapToken(token: Token, isBuy: Bool)
  func overviewCoordinatorDidSelectDepositMore(tokenAddress: String)
  func overviewCoordinatorDidSelectAddToken(_ token: TokenObject)
}

class OverviewCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  var balances: [String: Balance] = [:]
  var sendCoordinator: KNSendTokenViewCoordinator?
  var qrCodeCoordinator: KNWalletQRCodeCoordinator?
  var addTokenCoordinator: AddTokenCoordinator?
  var historyCoordinator: KNHistoryCoordinator?
  var withdrawCoordinator: WithdrawCoordinator?
  var krytalCoordinator: KrytalCoordinator?
  var notificationsCoordinator: NotificationCoordinator?
  var currentCurrencyType: CurrencyType = .usd

  lazy var rootViewController: OverviewContainerViewController = {
    print("[Balance][Overview][\(session.wallet.address.description)] \(KNSupportedTokenStorage.shared.ethToken.getBalanceBigInt().description)")
    let viewModel = OverviewContainerViewModel(session: self.session, marketViewModel: self.marketViewController.viewModel, assetsViewModel: self.assetsViewController.viewModel, depositViewModel: self.depositViewController.viewModel)
    let controller = OverviewContainerViewController(viewModel: viewModel, marketViewController: self.marketViewController, assetsViewController: self.assetsViewController, depositViewController: self.depositViewController)
    self.assetsViewController.container = controller
    self.marketViewController.container = controller
    self.depositViewController.container = controller
    controller.delegate = self
    controller.navigationDelegate = self
    return controller
  }()
  
  lazy var marketViewController: OverviewMarketViewController = {
    let controller = OverviewMarketViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var assetsViewController: OverviewAssetsViewController = {
    let controller = OverviewAssetsViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var depositViewController: OverviewDepositViewController = {
    let controller = OverviewDepositViewController()
    controller.delegate = self
    return controller
  }()
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }

  weak var delegate: OverviewCoordinatorDelegate?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }
  
  func stop() {
  }
  
  fileprivate func openChartView(token: Token) {
    let viewModel = ChartViewModel(token: token, currency: self.currentCurrencyType.toString())
    let controller = ChartViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  fileprivate func openKrytalView() {
    let coordinator = KrytalCoordinator(navigationController: self.navigationController, session: self.session)
    coordinator.delegate = self
    coordinator.start()
    self.krytalCoordinator = coordinator
  }
  
  //TODO: coordinator update balance, coordinator change wallet
  func appCoordinatorDidUpdateTokenList() {
    self.rootViewController.coordinatorDidUpdateDidUpdateTokenList()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.rootViewController.coordinatorDidUpdateNewSession(session)
    self.sendCoordinator?.appCoordinatorDidUpdateNewSession(session)
    self.historyCoordinator?.appCoordinatorDidUpdateNewSession(session)
    self.krytalCoordinator?.appCoordinatorDidUpdateNewSession(session)
  }
  
  func appCoordinatorPendingTransactionsDidUpdate() {
//    self.rootViewController.coordinatorUpdatePendingTransactions(transactions)
    self.historyCoordinator?.appCoordinatorPendingTransactionDidUpdate()
    self.rootViewController.coordinatorDidUpdatePendingTx()
    self.sendCoordinator?.coordinatorDidUpdatePendingTx()
    self.withdrawCoordinator?.coordinatorDidUpdatePendingTx()
    self.sendCoordinator?.coordinatorTokenBalancesDidUpdate(balances: [:])
  }
  
  func appCoordinatorUpdateTransaction(_ tx: InternalHistoryTransaction) -> Bool {
    if self.sendCoordinator?.coordinatorDidUpdateTransaction(tx) == true { return true }
    return self.withdrawCoordinator?.appCoordinatorUpdateTransaction(tx) ?? false
  }
  
  func appCoordinatorDidUpdateChain() {
    self.rootViewController.coordinatorDidUpdateChain()
  }
  
}

extension OverviewCoordinator: OverviewTokenListViewDelegate {
  func overviewTokenListView(_ controller: OverviewViewController, run event: OverviewTokenListViewEvent) {
    switch event {
    case .select(token: let token):
      self.openChartView(token: token)
    case .buy(token: let token):
      self.openSwapView(token: token, isBuy: true)
    case .sell(token: let token):
      self.openSwapView(token: token, isBuy: false)
    case .transfer(token: let token):
      self.openSendTokenView(token)
    }
  }
  
  func overviewMarketViewController(_ controller: OverviewMarketViewController, didSelect token: Token) {
    self.openChartView(token: token)
  }
}

extension OverviewCoordinator: ChartViewControllerDelegate {
  func chartViewController(_ controller: ChartViewController, run event: ChartViewEvent) {
    switch event {
    case .getChartData(let address, let from, let to, let currency):
      let provider = MoyaProvider<CoinGeckoService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getChartData(address: address, from: from, to: to, currency: currency)) { result in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(ChartData.self, from: resp.data)
            controller.coordinatorDidUpdateChartData(data)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .getTokenDetailInfo(address: let address):
      let provider = MoyaProvider<CoinGeckoService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getTokenDetailInfo(address: address)) { (result) in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(TokenDetailData.self, from: resp.data)
            controller.coordinatorDidUpdateTokenDetailInfo(data)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .transfer(token: let token):
      self.openSendTokenView(token)
    case .swap(token: let token):
      self.openSwapView(token: token, isBuy: true)
    case .invest(token: let token):
      break
    case .openEtherscan(address: let address):
      self.openCommunityURL("\(KNGeneralProvider.shared.customRPC.etherScanEndpoint)address/\(address)")
    case .openWebsite(url: let url):
      self.openCommunityURL(url)
    case .openTwitter(name: let name):
      self.openCommunityURL("https://twitter.com/\(name)/")
    }
  }
  
  fileprivate func openCommunityURL(_ url: String) {
    self.navigationController.openSafari(with: url)
  }

  fileprivate func openSendTokenView(_ token: Token?) {
    let from: TokenObject = {
      if let fromToken = token {
        return fromToken.toObject()
      }
      if KNGeneralProvider.shared.isEthereum {
        return KNSupportedTokenStorage.shared.ethToken
      } else {
        return KNSupportedTokenStorage.shared.bnbToken
      }
    }()
    self.sendCoordinator = nil
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
  
  fileprivate func openSwapView(token: Token, isBuy: Bool) {
    self.delegate?.overviewCoordinatorDidSelectSwapToken(token: token, isBuy: isBuy)
  }
}

extension OverviewCoordinator: OverviewContainerViewControllerDelegate {
  func overviewContainerViewController(_ controller: OverviewContainerViewController, run event: OverviewContainerViewEvent) {
    switch event {
    case .send:
      self.openSendTokenView(nil)
    case .receive:
      self.openQRCodeScreen()
    case .addCustomToken:
      self.openAddTokenScreen()
    case .krytal:
      self.openKrytalView()
    case .notifications:
      let coordinator = NotificationCoordinator(navigationController: self.navigationController)
      coordinator.start()
      self.notificationsCoordinator = coordinator
    case .selectedCurrency(type: let type):
      self.currentCurrencyType = type
    }
  }
  
  func openQRCodeScreen() {
    guard let walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.session.wallet.address.description) else { return }
    let qrcodeCoordinator = KNWalletQRCodeCoordinator(
      navigationController: self.navigationController,
      walletObject: walletObject
    )
    qrcodeCoordinator.start()
    self.qrCodeCoordinator = qrcodeCoordinator
  }
  
  func openAddTokenScreen() {
    let tokenCoordinator = AddTokenCoordinator(navigationController: self.navigationController, session: self.session)
    tokenCoordinator.start()
    self.addTokenCoordinator = tokenCoordinator
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
}

extension OverviewCoordinator: NavigationBarDelegate {
  func viewControllerDidSelectHistory(_ controller: KNBaseViewController) {
    self.openHistoryScreen()
  }

  func viewControllerDidSelectWallets(_ controller: KNBaseViewController) {
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }
}

extension OverviewCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.overviewCoordinatorDidSelectManageWallet()
    case .copy(let wallet):
      UIPasteboard.general.string = wallet.address
      let hud = MBProgressHUD.showAdded(to: controller.view, animated: true)
      hud.mode = .text
      hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
      hud.hide(animated: true, afterDelay: 1.5)
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.delegate?.overviewCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.overviewCoordinatorDidSelectAddWallet()
    }
  }
}

extension OverviewCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let session = WCSession.from(string: result) else {
        self.navigationController.showTopBannerView(
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }
      let controller = KNWalletConnectViewController(
        wcSession: session,
        knSession: self.session
      )
      self.navigationController.present(controller, animated: true, completion: nil)
    }
  }
}

extension OverviewCoordinator: KNHistoryCoordinatorDelegate {
  func historyCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func historyCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }

  func historyCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }

  func historyCoordinatorDidClose() {
  }

  func historyCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.overviewCoordinatorDidSelectWallet(wallet)
  }
}

extension OverviewCoordinator: OverviewDepositViewControllerDelegate {
  func overviewDepositViewController(_ controller: OverviewDepositViewController, run event: OverviewDepositViewEvent) {
    switch event {
    case .withdrawBalance(platform: let platform, balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController, session: self.session)
      coordinator.platform = platform
      coordinator.balance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .claim(balance: let balance):
      let coordinator = WithdrawCoordinator(navigationController: self.navigationController, session: self.session)
      coordinator.claimBalance = balance
      coordinator.start()
      coordinator.delegate = self
      self.withdrawCoordinator = coordinator
    case .depositMore:
      self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: "")
    }
  }
}

extension OverviewCoordinator: KNSendTokenViewCoordinatorDelegate {
  func sendTokenCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func sendTokenViewCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.overviewCoordinatorDidSelectWallet(wallet)
  }
  
  func sendTokenViewCoordinatorSelectOpenHistoryList() {
    self.openHistoryScreen()
  }

  func sendTokenCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
  
  func sendTokenCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
}

extension OverviewCoordinator: WithdrawCoordinatorDelegate {
  func withdrawCoordinatorDidSelectAddToken(_ token: TokenObject) {
    self.delegate?.overviewCoordinatorDidSelectAddToken(token)
  }
  
  func withdrawCoordinatorDidSelectEarnMore(balance: LendingBalance) {
    self.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: balance.address)
  }
  
  func withdrawCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
  
  func withdrawCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.overviewCoordinatorDidSelectWallet(wallet)
  }
  
  func withdrawCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
  
  func withdrawCoordinatorDidSelectHistory() {
    self.openHistoryScreen()
  }
}

extension OverviewCoordinator: KrytalCoordinatorDelegate {
  func krytalCoordinatorDidSelectAddWallet() {
    self.delegate?.overviewCoordinatorDidSelectAddWallet()
  }
  
  func krytalCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.overviewCoordinatorDidSelectWallet(wallet)
  }
  
  func krytalCoordinatorDidSelectManageWallet() {
    self.delegate?.overviewCoordinatorDidSelectManageWallet()
  }
}
