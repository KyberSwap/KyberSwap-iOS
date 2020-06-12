// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNListWalletsCoordinatorDelegate: class {
  func listWalletsCoordinatorDidClickBack()
  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet)
  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet)
  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KNWalletObject)
  func listWalletsCoordinatorDidUpdateWalletObjects()
  func listWalletsCoordinatorDidSelectAddWallet()
}

class KNListWalletsCoordinator: Coordinator {

  let navigationController: UINavigationController
  private(set) var session: KNSession
  var coordinators: [Coordinator] = []

  weak var delegate: KNListWalletsCoordinatorDelegate?

  fileprivate var selectedWallet: KNWalletObject!

  lazy var rootViewController: KNListWalletsViewController = {
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    let viewModel = KNListWalletsViewModel(listWallets: listWallets, curWallet: curWallet)
    let controller = KNListWalletsViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(
    navigationController: UINavigationController,
    session: KNSession,
    delegate: KNListWalletsCoordinatorDelegate?
    ) {
    self.navigationController = navigationController
    self.session = session
    self.delegate = delegate
  }

  func start() {
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    if let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() }) {
      self.rootViewController.updateView(
        with: listWallets,
        currentWallet: curWallet
      )
      self.navigationController.pushViewController(self.rootViewController, animated: true)
    }
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }

  func updateNewSession(_ session: KNSession) {
    self.session = session
    let listWallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    if let curWallet: KNWalletObject = listWallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() }) {
      self.rootViewController.updateView(
        with: listWallets,
        currentWallet: curWallet
      )
    }
  }
}

extension KNListWalletsCoordinator: KNListWalletsViewControllerDelegate {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent) {
    switch event {
    case .close:
      self.listWalletsViewControllerDidClickBackButton()
    case .select(let wallet):
      guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
        return
      }
      self.listWalletsViewControllerDidSelectWallet(wal)
    case .remove(let wallet):
      self.showDeleteWallet(wallet)
    case .edit(let wallet):
      self.selectedWallet = wallet
      let viewModel = KNEditWalletViewModel(wallet: wallet)
      let controller = KNEditWalletViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true)
    case .addWallet:
      self.delegate?.listWalletsCoordinatorDidSelectAddWallet()
    }
  }

  fileprivate func listWalletsViewControllerDidClickBackButton() {
    self.delegate?.listWalletsCoordinatorDidClickBack()
  }

  fileprivate func listWalletsViewControllerDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.listWalletsCoordinatorDidSelectWallet(wallet)
  }

  fileprivate func listWalletsViewControllerDidSelectRemoveWallet(_ wallet: Wallet) {
    let alert = UIAlertController(title: "", message: NSLocalizedString("do.you.want.to.remove.this.wallet", value: "Do you want to remove this wallet?", comment: ""), preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cacnel", comment: ""), style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: NSLocalizedString("remove", value: "Remove", comment: ""), style: .destructive, handler: { _ in
      if self.navigationController.topViewController is KNEditWalletViewController {
        self.navigationController.popViewController(animated: true, completion: {
          self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
        })
      } else {
        self.delegate?.listWalletsCoordinatorDidSelectRemoveWallet(wallet)
      }
    }))
    self.navigationController.topViewController?.present(alert, animated: true, completion: nil)
  }
}

extension KNListWalletsCoordinator: KNEditWalletViewControllerDelegate {
  func editWalletViewController(_ controller: KNEditWalletViewController, run event: KNEditWalletViewEvent) {
    switch event {
    case .back: self.navigationController.popViewController(animated: true)
    case .update(let newWallet):
      self.navigationController.popViewController(animated: true) {
        self.shouldUpdateWallet(newWallet)
      }
    case .backup(let wallet):
      self.showBackUpWallet(wallet)
    case .delete(let wallet):
      self.showDeleteWallet(wallet)
    }
  }

  fileprivate func shouldUpdateWallet(_ walletObject: KNWalletObject) {
    let contact = KNContact(
      address: walletObject.address,
      name: walletObject.name
    )
    KNContactStorage.shared.update(contacts: [contact])
    KNWalletStorage.shared.update(wallets: [walletObject])
    let wallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = wallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    self.rootViewController.updateView(
      with: KNWalletStorage.shared.wallets,
      currentWallet: curWallet
    )
    self.delegate?.listWalletsCoordinatorDidUpdateWalletObjects()
  }

  fileprivate func showBackUpWallet(_ wallet: KNWalletObject) {
    self.delegate?.listWalletsCoordinatorShouldBackUpWallet(wallet)
  }

  fileprivate func showDeleteWallet(_ wallet: KNWalletObject) {
    guard let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else {
      return
    }
    self.listWalletsViewControllerDidSelectRemoveWallet(wal)
  }
}

extension KNListWalletsCoordinator: KNEnterWalletNameViewControllerDelegate {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject) {
    KNWalletStorage.shared.update(wallets: [walletObject])
    let wallets: [KNWalletObject] = KNWalletStorage.shared.wallets
    let curWallet: KNWalletObject = wallets.first(where: { $0.address.lowercased() == self.session.wallet.address.description.lowercased() })!
    self.rootViewController.updateView(
      with: KNWalletStorage.shared.wallets,
      currentWallet: curWallet
    )
    self.delegate?.listWalletsCoordinatorDidUpdateWalletObjects()
  }
}
