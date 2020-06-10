// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportWalletCoordinatorDelegate: class {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?)
  func importWalletCoordinatorDidClose()
}

class KNImportWalletCoordinator: Coordinator {

  weak var delegate: KNImportWalletCoordinatorDelegate?
  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  init(
    navigationController: UINavigationController,
    keystore: Keystore
  ) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: nil)
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
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "import_JSON"])
      self.importWallet(with: .keystore(string: json, password: password), name: name)
    case .importPrivateKey(let privateKey, let name):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "import_PrivateKey"])
      self.importWallet(with: .privateKey(privateKey: privateKey), name: name)
    case .importSeeds(let seeds, let name):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_import_wallet", customAttributes: ["action": "import_Seeds"])
      self.importWallet(with: .mnemonic(words: seeds, password: ""), name: name)
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
        KNCrashlyticsUtil.logCustomEvent(withName: "wallet_import_success", customAttributes: ["wallet_type": type.displayString()])
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
      case .failure(let error):
        self.navigationController.topViewController?.displayError(error: error)
      }
    }
  }
}
