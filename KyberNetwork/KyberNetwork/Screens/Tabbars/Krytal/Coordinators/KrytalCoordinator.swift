//
//  KrytalCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation
import Moya
import QRCodeReaderViewController
import MBProgressHUD
import WalletConnect

protocol KrytalCoordinatorDelegate: class {
  func krytalCoordinatorDidSelectAddWallet()
  func krytalCoordinatorDidSelectWallet(_ wallet: Wallet)
  func krytalCoordinatorDidSelectManageWallet()
}

class KrytalCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  weak var delegate: KrytalCoordinatorDelegate?
  
  lazy var rootViewController: KrytalViewController = {
    let controller = KrytalViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var historyViewController: KrytalHistoryViewController = {
    let controller = KrytalHistoryViewController()
    controller.delegate = self
    return controller
  }()
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }
  
  fileprivate var historyTxTimer: Timer?
  weak var claimViewController: ClaimRewardViewController?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.historyViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
//    self.loadCachedClaimHistory()
    self.loadReferralOverview()
    self.loadClaimHistory()
    self.historyTxTimer = Timer(timeInterval: KNLoadingInterval.seconds60, repeats: true, block: { (timer) in
//      self.loadClaimHistory()
      self.loadReferralOverview()
    })
    self.checkWallet()
  }

  func stop() {
    
  }

  func loadReferralOverview() {
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
        self.loadReferralOverview()
      }
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getReferralOverview(address: self.session.wallet.address.description, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralOverviewResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateOverviewReferral(data.overview)
          Storage.store(data.overview, as: self.session.wallet.address.description + Constants.referralOverviewStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.loadReferralOverview()
          }
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
          self.loadReferralOverview()
        }
      }
    }
  }

  fileprivate func loadClaimHistory() {
    guard let loginToken = Storage.retrieve(self.session.wallet.address.description + Constants.loginTokenStoreFileName, as: LoginToken.self) else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getClaimHistory(address: self.session.wallet.address.description, accessToken: loginToken.token)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ClaimHistoryResponse.self, from: resp.data)
          self.historyViewController.coordinatorDidUpdateClaimedTransaction(data.claims)
          Storage.store(data.claims, as: self.session.wallet.address.description + Constants.krytalHistoryStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
      }
    }
  }

  fileprivate func loadCachedReferralOverview() {
    let overview = Storage.retrieve(self.session.wallet.address.description + Constants.referralOverviewStoreFileName, as: Overview.self)
    self.rootViewController.coordinatorDidUpdateOverviewReferral(overview)
  }
  
  fileprivate func loadCachedClaimHistory() {
    let history = Storage.retrieve(self.session.wallet.address.description + Constants.krytalHistoryStoreFileName, as: [Claim].self) ?? []
    self.historyViewController.coordinatorDidUpdateClaimedTransaction(history)
  }
  
  fileprivate func openWalletListView() {
    let viewModel = WalletsListViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.currentWallet
    )
    let walletsList = WalletsListViewController(viewModel: viewModel)
    walletsList.delegate = self
    self.navigationController.present(walletsList, animated: true, completion: nil)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    self.checkWallet()
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.historyViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
    self.loadCachedClaimHistory()
    self.loadReferralOverview()
    self.loadClaimHistory()
  }
  
  fileprivate func checkWallet() {
    guard case .real(let account) = self.session.wallet.type else {
      self.navigationController.showTopBannerView(message: "Watched wallet can not do this operation".toBeLocalised())
      return
    }
  }
}

extension KrytalCoordinator: KrytalViewControllerDelegate {
  func krytalViewController(_ controller: KrytalViewController, run event: KrytalViewEvent) {
    switch event {
    case .openShareCode(refCode: let refCode, codeObject: let codeObject):
      let viewModel = ShareReferralLinkViewModel(refCode: refCode, codeObject: codeObject)
      let controller = ShareReferralLinkViewController(viewModel: viewModel)
      self.navigationController.present(controller, animated: true, completion: nil)
    case .openHistory:
      self.navigationController.pushViewController(self.historyViewController, animated: true)
    case .openWalletList:
      self.openWalletListView()
    case .claim(amount: let amount):
//      let controller = ClaimRewardViewController(viewModel: ClaimRewardViewModel(claimablePoint: amount))
    break
    }
  }
}

extension KrytalCoordinator: WalletsListViewControllerDelegate {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent) {
    switch event {
    case .connectWallet:
      let qrcode = QRCodeReaderViewController()
      qrcode.delegate = self
      self.navigationController.present(qrcode, animated: true, completion: nil)
    case .manageWallet:
      self.delegate?.krytalCoordinatorDidSelectManageWallet()
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
      self.delegate?.krytalCoordinatorDidSelectWallet(wal)
    case .addWallet:
      self.delegate?.krytalCoordinatorDidSelectAddWallet()
    }
  }
}

extension KrytalCoordinator: QRCodeReaderDelegate {
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

extension KrytalCoordinator: KrytalHistoryViewControllerDelegate {
  func krytalHistoryViewController(_ controller: KrytalHistoryViewController, run event: KrytalHistoryViewEvent) {
    switch event {
    case .openWalletList:
      self.openWalletListView()
    case .select(hash: let hash):
    self.navigationController.openSafari(with: KNGeneralProvider.shared.customRPC.etherScanEndpoint + "tx/\(hash)")
    }
  }
}
