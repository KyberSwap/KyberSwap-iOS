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
  
  fileprivate var currentWallet: KNWalletObject {
    let address = self.session.wallet.address.description
    return KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)
  }
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
    self.loadReferralOverview()
  }

  func stop() {
    
  }

  fileprivate func loadReferralOverview() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getReferralOverview(address: self.session.wallet.address.description)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ReferralOverviewResponse.self, from: resp.data)
          self.rootViewController.coordinatorDidUpdateOverviewReferral(data.overview)
          Storage.store(data.overview, as: Constants.referralOverviewStoreFileName)
        } catch let error {
          print("[Invest] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Invest] \(error.localizedDescription)")
      }
    }
  }
  
  fileprivate func loadCachedReferralOverview() {
    guard let overview = Storage.retrieve(Constants.referralOverviewStoreFileName, as: Overview.self) else { return }
    self.rootViewController.coordinatorDidUpdateOverviewReferral(overview)
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
    self.rootViewController.coordinatorDidUpdateWallet(self.session.wallet)
    self.loadCachedReferralOverview()
    self.loadReferralOverview()
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
      break
    case .openWalletList:
      self.openWalletListView()
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
