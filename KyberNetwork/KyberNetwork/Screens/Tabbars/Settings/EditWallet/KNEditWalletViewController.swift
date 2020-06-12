// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEditWalletViewEvent {
  case back
  case update(newWallet: KNWalletObject)
  case backup(wallet: KNWalletObject)
  case delete(wallet: KNWalletObject)
}

protocol KNEditWalletViewControllerDelegate: class {
  func editWalletViewController(_ controller: KNEditWalletViewController, run event: KNEditWalletViewEvent)
}

struct KNEditWalletViewModel {
  let wallet: KNWalletObject

  init(wallet: KNWalletObject) {
    self.wallet = wallet
  }
}

class KNEditWalletViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var nameWalletTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!

  @IBOutlet weak var showBackupPhraseButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!

  fileprivate let viewModel: KNEditWalletViewModel
  weak var delegate: KNEditWalletViewControllerDelegate?

  init(viewModel: KNEditWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNEditWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = NSLocalizedString("edit.wallet", value: "Edit Wallet", comment: "")
    self.nameWalletTextLabel.text = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.placeholder = NSLocalizedString("give.your.wallet.a.name", value: "Give your wallet a name", comment: "")
    self.walletNameTextField.text = self.viewModel.wallet.name
    self.showBackupPhraseButton.setTitle(NSLocalizedString("show.backup.phrase", value: "Show Backup Phrase", comment: ""), for: .normal)
    self.deleteButton.setTitle(NSLocalizedString("delete.wallet", value: "Delete Wallet", comment: ""), for: .normal)
    self.view.layoutIfNeeded()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.walletNameTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.delegate?.editWalletViewController(self, run: .back)
  }

  @IBAction func showBackUpPhraseButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNCrashlyticsUtil.logCustomEvent(withName: "edit_wallet_show_back_up", customAttributes: nil)
    self.delegate?.editWalletViewController(self, run: .backup(wallet: self.viewModel.wallet))
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNCrashlyticsUtil.logCustomEvent(withName: "edit_wallet_delete_wallet", customAttributes: ["action": "delete_wallet"])
    self.delegate?.editWalletViewController(self, run: .delete(wallet: self.viewModel.wallet))
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNCrashlyticsUtil.logCustomEvent(withName: "edit_wallet_save_wallet", customAttributes: ["action": "save_wallet"])
    let wallet = self.viewModel.wallet.copy(withNewName: self.walletNameTextField.text ?? "")
    self.delegate?.editWalletViewController(self, run: .update(newWallet: wallet))
  }

  @IBAction func edgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.editWalletViewController(self, run: .back)
    }
  }
}
