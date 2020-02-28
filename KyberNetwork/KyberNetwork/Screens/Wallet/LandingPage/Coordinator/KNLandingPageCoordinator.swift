// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import TrustKeystore
import TrustCore

protocol KNLandingPageCoordinatorDelegate: class {
  func landingPageCoordinator(import wallet: Wallet)
  func landingPageCoordinator(remove wallet: Wallet)
}

/**
 Flow:
 1. Create Wallet:
  - Enter password
  - Backup 12 words seed for new wallet
  - Testing backup
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 2. Import Wallet:
  - JSON/Private Key/Seeds
  - Enter wallet name
  - Enter passcode (if it is the first wallet)
 */
class KNLandingPageCoordinator: Coordinator {

  weak var delegate: KNLandingPageCoordinatorDelegate?
  let navigationController: UINavigationController
  var keystore: Keystore
  var coordinators: [Coordinator] = []

  fileprivate var newWallet: Wallet?
  fileprivate var isCreate: Bool = false

  lazy var rootViewController: KNLandingPageViewController = {
    let controller = KNLandingPageViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var promoCodeCoordinator: KNPromoCodeCoordinator = {
    let coordinator = KNPromoCodeCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore,
      newWallet: self.newWallet,
      name: nil
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var importWalletCoordinator: KNImportWalletCoordinator = {
    let coordinator = KNImportWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore
    )
    coordinator.delegate = self
    return coordinator
  }()

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode(cancellable: false)
    )
    coordinator.delegate = self
    return coordinator
  }()

  init(
    navigationController: UINavigationController = UINavigationController(),
    keystore: Keystore
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.keystore = keystore
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    if self.keystore.wallets.isEmpty && KNPasscodeUtil.shared.currentPasscode() != nil {
      // In case user delete the app, wallets are removed but passcode is still save in keychain
      KNPasscodeUtil.shared.deletePasscode()
    }
    if let wallet = self.keystore.recentlyUsedWallet ?? self.keystore.wallets.first {
      if case .real(let account) = wallet.type {
         //In case backup with icloud/local backup there is no keychain so delete all keystore in keystore directory
         guard let _ =  keystore.getPassword(for: account) else {
            KNPasscodeUtil.shared.deletePasscode()
            let fileManager = FileManager.default
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: keystore.keysDirectory.path)
                for filePath in filePaths {
                    let keyPath = URL(fileURLWithPath: keystore.keysDirectory.path).appendingPathComponent(filePath).absoluteURL
                    try fileManager.removeItem(at: keyPath)
                }
            } catch {
                print("Could not clear keystore folder: \(error)")
            }
            KNWalletStorage.shared.deleteAll()
            return
         }
      }
      if KNPasscodeUtil.shared.currentPasscode() == nil {
        // In case user imported a wallet and kill the app during settings passcode
        self.newWallet = wallet
        self.passcodeCoordinator.start()
      }
    }
  }

  func update(keystore: Keystore) {
    self.keystore = keystore
  }

  fileprivate func addNewWallet(_ wallet: Wallet, isCreate: Bool, name: String?, addToContact: Bool = true) {
    // add new wallet into database in case user exits app
    let walletObject = KNWalletObject(address: wallet.address.description, name: name ?? "Untitled")
    KNWalletStorage.shared.add(wallets: [walletObject])
    if addToContact {
      let contact = KNContact(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNContactStorage.shared.update(contacts: [contact])
    }
    self.newWallet = wallet
    self.isCreate = isCreate
    self.keystore.recentlyUsedWallet = wallet

    if self.keystore.wallets.count == 1 {
      KNPasscodeUtil.shared.deletePasscode()
      self.passcodeCoordinator.start()
    } else {
      self.delegate?.landingPageCoordinator(import: wallet)
    }
  }
}

extension KNLandingPageCoordinator: KNLandingPageViewControllerDelegate {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent) {
    switch event {
    case .openPromoCode:
      self.promoCodeCoordinator.start()
    case .openCreateWallet:
      self.createWalletCoordinator.updateNewWallet(nil, name: nil)
      self.createWalletCoordinator.start()
    case .openImportWallet:
      self.importWalletCoordinator.start()
    case .openTermAndCondition:
      let url: String = "https://files.kyberswap.com/tac.pdf"
      self.navigationController.topViewController?.openSafari(with: url)
    }
  }
}

extension KNLandingPageCoordinator: KNImportWalletCoordinatorDelegate {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?) {
    self.addNewWallet(wallet, isCreate: false, name: name)
  }

  func importWalletCoordinatorDidClose() {
  }
}

extension KNLandingPageCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    self.passcodeCoordinator.stop { }
  }

  func passcodeCoordinatorDidCreatePasscode() {
    guard let wallet = self.newWallet else { return }
    self.navigationController.topViewController?.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
      self.navigationController.topViewController?.hideLoading()
      self.delegate?.landingPageCoordinator(import: wallet)
    }
  }
}

extension KNLandingPageCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidClose() {
  }

  func createWalletCoordinatorCancelCreateWallet(_ wallet: Wallet) {
    self.navigationController.popViewController(animated: true) {
      self.delegate?.landingPageCoordinator(remove: wallet)
    }
  }

  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?) {
    guard let wallet = wallet else { return }
    self.addNewWallet(wallet, isCreate: true, name: name)
  }
}

extension KNLandingPageCoordinator: KNPromoCodeCoordinatorDelegate {
  func promoCodeCoordinatorDidCreate(_ wallet: Wallet, expiredDate: TimeInterval, destinationToken: String?, destAddress: String?, name: String?) {
    KNWalletPromoInfoStorage.shared.addWalletPromoInfo(
      address: wallet.address.description,
      destinationToken: destinationToken ?? "",
      destAddress: destAddress,
      expiredTime: expiredDate
    )
    self.addNewWallet(wallet, isCreate: false, name: name, addToContact: false)
  }
}
