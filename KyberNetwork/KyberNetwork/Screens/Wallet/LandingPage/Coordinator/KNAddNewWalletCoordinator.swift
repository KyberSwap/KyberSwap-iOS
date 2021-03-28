// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import BigInt

protocol KNAddNewWalletCoordinatorDelegate: class {
  func addNewWalletCoordinator(add wallet: Wallet)
  func addNewWalletCoordinator(remove wallet: Wallet)
  func addNewWalletCoordinatorDidSendRefCode(_ code: String)
}

enum AddNewWalletType {
  case full
  case onlyReal
  case watch
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

  func start(type: AddNewWalletType, wallet: KNWalletObject? = nil) {
    self.navigationController.popToRootViewController(animated: false)
    switch type {
    case .full, .onlyReal:
      let popup = CreateWalletMenuViewController(isFull: type == .full)
      popup.delegate = self
      self.navigationController.present(popup, animated: true, completion: {})
    case .watch:
      self.createWatchWallet(wallet)
    }
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

  fileprivate func createWatchWallet(_ wallet: KNWalletObject? = nil) {
    self.isCreate = false
    self.newWallet = nil
    let viewModel = AddWatchWalletViewModel()
    viewModel.wallet = wallet
    let controller = AddWatchWalletViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
  }
}

extension KNAddNewWalletCoordinator: KNCreateWalletCoordinatorDelegate {
  func createWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
  }
  
  func createWalletCoordinatorDidCreateWallet(_ wallet: Wallet?, name: String?) {
    guard let wallet = wallet else { return }
    self.navigationController.dismiss(animated: true) {
      var isWatchWallet = false
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled",
        isWatchWallet: isWatchWallet
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
  func importWalletCoordinatorDidSendRefCode(_ code: String) {
    self.delegate?.addNewWalletCoordinatorDidSendRefCode(code)
  }
  
  func importWalletCoordinatorDidImport(wallet: Wallet, name: String?) {
    self.navigationController.dismiss(animated: true) {
      //TODO: add type to wallet firebase obj
      var isWatchWallet = false
      if case WalletType.watch(_) = wallet.type {
        isWatchWallet = true
      }
      let walletObject = KNWalletObject(
        address: wallet.address.description,
        name: name ?? "Untitled",
        isWatchWallet: isWatchWallet
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

extension KNAddNewWalletCoordinator: CreateWalletMenuViewControllerDelegate {
  func createWalletMenuViewController(_ controller: CreateWalletMenuViewController, run event: CreateWalletMenuViewControllerEvent) {
    switch event {
    case .createRealWallet:
      self.createNewWallet()
    case .importWallet:
      self.importAWallet()
    case .createWatchWallet:
      self.createWatchWallet()
    case .close:
      self.navigationController.dismiss(animated: true, completion: nil)
    }
  }
}

extension KNAddNewWalletCoordinator: AddWatchWalletViewControllerDelegate {
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, wallet: KNWalletObject, address: Address, name: String?) {
    if wallet.address.lowercased() == address.description.lowercased() {
      wallet.name = name ?? "Imported"
      KNWalletStorage.shared.add(wallets: [wallet])
      if let contact = KNContactStorage.shared.get(forPrimaryKey: address.description) {
        let newContact = contact.clone()
        newContact.name = name ?? "Imported"
        KNContactStorage.shared.update(contacts: [newContact])
        self.navigationController.showSuccessTopBannerMessage(
          with: "",
          message: "Edit wallet successful".toBeLocalised(),
          time: 1
        )
      }
      self.navigationController.dismiss(animated: true, completion: nil)
      self.delegate?.addNewWalletCoordinator(add: Wallet(type: .watch(address)))
    } else {
      guard let walletAddress = Address(string: wallet.address) else {
        return
      }
      let aWallet = Wallet(type: .watch(walletAddress))
      self.keystore.delete(wallet: aWallet)
      KNWalletStorage.shared.delete(wallet: wallet)

      self.importNewWatchWallet(address: address, name: name, isAdd: false)
    }
  }
  
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: Address, name: String?) {
    self.importNewWatchWallet(address: address, name: name)
  }

  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController) {
    self.navigationController.dismiss(animated: true, completion: nil)
  }

  fileprivate func importNewWatchWallet(address: Address, name: String?, isAdd: Bool = true) {
    self.keystore.importWallet(type: .watch(address: address)) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let wallet):
        if isAdd {
          self.navigationController.showSuccessTopBannerMessage(
            with: NSLocalizedString("wallet.imported", value: "Wallet Imported", comment: ""),
            message: NSLocalizedString("you.have.successfully.imported.a.wallet", value: "You have successfully imported a wallet", comment: ""),
            time: 1
          )
        } else {
          self.navigationController.showSuccessTopBannerMessage(
            with: "",
            message: "Edit wallet successful".toBeLocalised(),
            time: 1
          )
        }

        let walletName: String = {
          if name == nil || name?.isEmpty == true { return "Imported" }
          return name ?? "Imported"
        }()
        let walletObject = KNWalletObject(
          address: wallet.address.description,
          name: walletName,
          isWatchWallet: true
        )
        KNWalletStorage.shared.add(wallets: [walletObject])
        let contact = KNContact(
          address: wallet.address.description,
          name: name ?? "Untitled"
        )
        KNContactStorage.shared.update(contacts: [contact])
        self.navigationController.dismiss(animated: true, completion: nil)
        self.delegate?.addNewWalletCoordinator(add: wallet)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.localizedDescription)
      }
    }
  }
}
