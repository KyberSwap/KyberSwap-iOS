// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import BigInt

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(add wallet: Wallet)
  func addNewWalletCoordinator(remove wallet: Wallet)
}

class KNAddNewWalletCoordinator: Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  fileprivate var keystore: Keystore

  fileprivate var newWallet: Wallet?
  fileprivate var isCreate: Bool = false

  weak var delegate: KNAddNewWalletCoordinatorDelegate?

  lazy var createWalletCoordinator: KNCreateWalletCoordinator = {
    let coordinator = KNCreateWalletCoordinator(
      navigationController: self.navigationController,
      keystore: self.keystore,
      newWallet: nil,
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

  init(
    navigationController: UINavigationController = UINavigationController(),
    keystore: Keystore
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    let rootViewController = UIViewController()
    rootViewController.view.backgroundColor = UIColor.clear
    self.navigationController.viewControllers = [rootViewController]
    self.navigationController.modalPresentationStyle = .overCurrentContext
    self.navigationController.modalTransitionStyle = .crossDissolve
    self.keystore = keystore
  }

  lazy var alertController: UIAlertController = {
    let controller = UIAlertController(
      title: nil,
      message: NSLocalizedString("add.new.wallet", value: "Add new wallet?", comment: ""),
      preferredStyle: .actionSheet
    )
    let createWallet = NSLocalizedString("create.a.new.wallet", value: "Create a new wallet", comment: "")
    controller.addAction(UIAlertAction(title: createWallet, style: .default, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_mywallet_create", customAttributes: nil)
      self.createNewWallet()
    }))
    let importWallet = NSLocalizedString("import.a.wallet", value: "Import a wallet", comment: "")
    controller.addAction(UIAlertAction(title: importWallet, style: .default, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_mywallet_import", customAttributes: nil)
      self.importAWallet()
    }))
    controller.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_menu_mywallet_cancel", customAttributes: nil)
      self.navigationController.dismiss(animated: false, completion: nil)
    }))
    return controller
  }()

  func start() {
    self.navigationController.present(self.alertController, animated: true, completion: nil)
  }

  fileprivate func createNewWallet() {
    self.isCreate = true
    self.newWallet = nil
    self.createWalletCoordinator.updateNewWallet(nil, name: nil)
    self.createWalletCoordinator.start()
  }

  fileprivate func importAWallet() {
    self.isCreate = false
    self.newWallet = nil
    self.importWalletCoordinator.start()
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?) {
    guard let wallet = wallet else { return }
    self.navigationController.dismiss(animated: true) {
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNWalletStorage.shared.add(wallets: [walletObject])
      let contact = KNContact(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNContactStorage.shared.update(contacts: [contact])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }

  func createWalletCoordinatorDidClose() {
    self.navigationController.dismiss(animated: false, completion: nil)
  }

  func createWalletCoordinatorCancelCreateWallet(_ wallet: Wallet) {
    self.navigationController.dismiss(animated: true) {
      self.delegate?.addNewWalletCoordinator(remove: wallet)
    }
  }
}

extension KNAddNewWalletCoordinator: KNImportWalletCoordinatorDelegate {
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?) {
    self.navigationController.dismiss(animated: true) {
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNWalletStorage.shared.add(wallets: [walletObject])
      let contact = KNContact(
        address: wallet.address.description,
        name: name ?? "Untitled"
      )
      KNContactStorage.shared.update(contacts: [contact])
      self.delegate?.addNewWalletCoordinator(add: wallet)
    }
  }

  func importWalletCoordinatorDidClose() {
    self.navigationController.dismiss(animated: true, completion: nil)
  }
}
