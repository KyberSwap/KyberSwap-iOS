// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import QRCodeReaderViewController
import WalletConnect
import Moya

protocol KNCreateWalletCoordinatorDelegate: class {
  func createWalletCoordinatorCancelCreateWallet(_ wallet: Wallet)
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?)
  func createWalletCoordinatorDidClose()
  func createWalletCoordinatorDidSendRefCode(_ code: String)
}

class KNCreateWalletCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var name: String?
  fileprivate var refCode: String = ""
  weak var delegate: KNCreateWalletCoordinatorDelegate?
  var createWalletController: KNCreateWalletViewController?

  fileprivate var isCreating: Bool = false

  init(
    navigationController: UINavigationController,
    keystore: Keystore,
    newWallet: Wallet?,
    name: String?
    ) {
    self.navigationController = navigationController
    self.keystore = keystore
    self.newWallet = newWallet
    self.name = name
  }

  func start() {
    if let wallet = self.newWallet {
      self.isCreating = false
      self.openBackUpWallet(wallet, name: self.name)
    } else {
      self.isCreating = true
      let createWalletVC = KNCreateWalletViewController()
      createWalletVC.loadViewIfNeeded()
      createWalletVC.delegate = self
      createWalletVC.modalTransitionStyle = .crossDissolve
      createWalletVC.modalPresentationStyle = .overCurrentContext
      self.navigationController.present(createWalletVC, animated: true, completion: nil)
      self.createWalletController = createWalletVC
    }
  }

  func updateNewWallet(_ wallet: Wallet?, name: String?) {
    self.newWallet = wallet
    self.name = name
  }

  /**
   Open back up wallet view for new wallet created from the app
   Always using 12 words seeds to back up the wallet
   */
  fileprivate func openBackUpWallet(_ wallet: Wallet, name: String?) {
    let walletObject: KNWalletObject = {
      if let walletObject = KNWalletStorage.shared.get(forPrimaryKey: wallet.address.description) {
        return walletObject
      }
      return KNWalletObject(
        address: wallet.address.description,
        isBackedUp: false
      )
    }()

    let account: Account! = {
      if case .real(let acc) = wallet.type { return acc }
      // Failed to get account from wallet, show enter name
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet, name: name)
      fatalError("Wallet type is not real wallet")
    }()

    self.newWallet = wallet
    self.name = name
    self.keystore.recentlyUsedWallet = wallet
    KNWalletStorage.shared.add(wallets: [walletObject])

    let seedResult = self.keystore.exportMnemonics(account: account)
    if case .success(let mnemonics) = seedResult {
      let seeds = mnemonics.split(separator: " ").map({ return String($0) })
      let backUpVC: KNBackUpWalletViewController = {
        let viewModel = KNBackUpWalletViewModel(seeds: seeds)
        let controller = KNBackUpWalletViewController(viewModel: viewModel)
        controller.delegate = self
        return controller
      }()
      self.navigationController.pushViewController(backUpVC, animated: true)
    } else {
      // Failed to get seeds result, temporary open create name for wallet
      self.delegate?.createWalletCoordinatorDidCreateWallet(self.newWallet, name: name)
      fatalError("Can not get seeds from account")
    }
  }
  
  func sendRefCode(_ code: String, account: Account) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let result = self.keystore.signMessage(sendData, for: account)
    switch result {
    case .success(let signedData):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.registerReferrer(address: account.address.description, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            self.navigationController.showTopBannerView(message: "Success register referral code")
          } else if let error = json["error"] as? String {
            self.navigationController.showTopBannerView(message: error)
          } else {
            self.navigationController.showTopBannerView(message: "Fail to register referral code")
          }
        }
      }
    case .failure(let error):
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
}

extension KNCreateWalletCoordinator: KNBackUpWalletViewControllerDelegate {
  func backupWalletViewControllerDidFinish() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: self.name ?? "New Wallet",
      isBackedUp: true
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.delegate?.createWalletCoordinatorDidCreateWallet(wallet, name: self.name)
  }

  func backupWalletViewControllerDidConfirmSkipWallet() {
    guard let wallet = self.newWallet else { return }
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: self.name ?? "New Wallet",
      isBackedUp: false
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    self.delegate?.createWalletCoordinatorDidCreateWallet(wallet, name: self.name)
  }
  
  fileprivate func openQRCode(_ controller: UIViewController) {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    controller.present(qrcode, animated: true, completion: nil)
  }
}

extension KNCreateWalletCoordinator: KNCreateWalletViewControllerDelegate {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent) {
    switch event {
    case .back:
      self.navigationController.dismiss(animated: true) {
        self.delegate?.createWalletCoordinatorDidClose()
      }
    case .next(let name):
      self.navigationController.dismiss(animated: true) {
        self.navigationController.displayLoading(text: "\(NSLocalizedString("creating", value: "Creating", comment: ""))...", animated: true)
        DispatchQueue.global(qos: .userInitiated).async {
          let account = self.keystore.create12wordsAccount(with: "")
          DispatchQueue.main.async {
            self.navigationController.hideLoading()
            self.navigationController.showSuccessTopBannerMessage(
              with: NSLocalizedString("wallet.created", value: "Wallet Created", comment: ""),
              message: NSLocalizedString("you.have.successfully.created.a.new.wallet", value: "You have successfully created a new wallet!", comment: ""),
              time: 1
            )
            let wallet = Wallet(type: WalletType.real(account))
            self.name = name
            self.openBackUpWallet(wallet, name: name)
            if !self.refCode.isEmpty {
              self.sendRefCode(self.refCode.uppercased(), account: account)
            }
          }
        }
      }
    case .openQR:
      self.openQRCode(controller)
    case .sendRefCode(code: let code):
      self.refCode = code
    }
  }
}

extension KNCreateWalletCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.createWalletController?.containerViewDidUpdateRefCode(result)
    }
  }
}
