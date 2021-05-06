// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import TrustCore
import TrustKeystore

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?)
  func importWalletCoordinatorDidClose()
  func importWalletCoordinatorDidSendRefCode(_ code: String)
}

class KNImportWalletCoordinator: Coordinator {

  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []
  var refCode: String = ""

  init(
    navigationController: UINavigationController,
    keystore: Keystore
  ) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    let importVC: KNImportWalletViewController = {
      let controller = KNImportWalletViewController()
      controller.delegate = self
      controller.loadViewIfNeeded()
      return controller
    }()
    self.navigationController.pushViewController(importVC, animated: true)
  }

  func stop(completion: (() -> Void)? = nil) {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.importWalletCoordinatorDidClose()
      completion?()
    }
  }
}

extension KNImportWalletCoordinator: KNImportWalletViewControllerDelegate {
  func importWalletViewController(_ controller: KNImportWalletViewController, run event: KNImportWalletViewEvent) {
    switch event {
    case .back:
      self.stop()
    case .importJSON(let json, let password, let name):
      self.importWallet(with: .keystore(string: json, password: password), name: name)
    case .importPrivateKey(let privateKey, let name):
      self.importWallet(with: .privateKey(privateKey: privateKey), name: name)
    case .importSeeds(let seeds, let name):
      self.importWallet(with: .mnemonic(words: seeds, password: ""), name: name)
    case .sendRefCode(code: let code):
      self.refCode = code
    }
  }

  fileprivate func importWallet(with type: ImportType, name: String?) {
    self.navigationController.topViewController?.displayLoading(text: "\(NSLocalizedString("importing.wallet", value: "Importing wallet", comment: ""))...", animated: true)
    if name == nil || name?.isEmpty == true {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "name_empty"])
    } else {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "name_not_empty"])
    }
    self.keystore.importWallet(type: type) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.topViewController?.hideLoading()
      switch result {
      case .success(let wallet):
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("wallet.imported", value: "Wallet Imported", comment: ""),
          message: NSLocalizedString("you.have.successfully.imported.a.wallet", value: "You have successfully imported a wallet", comment: ""),
          time: 1
        )
        let walletName: String = {
          if name == nil || name?.isEmpty == true { return "Imported" }
          return name ?? "Imported"
        }()
        self.delegate?.importWalletCoordinatorDidImport(wallet: wallet, name: walletName)
        if !self.refCode.isEmpty {
          if case .real(let account) = wallet.type {
            self.sendRefCode(self.refCode, account: account)
          }
        }
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
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
