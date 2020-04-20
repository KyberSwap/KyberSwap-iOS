// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNEnterWalletNameViewControllerDelegate: class {
  func enterWalletNameDidNext(sender: KNEnterWalletNameViewController, walletObject: KNWalletObject)
}

class KNEnterWalletNameViewModel {
  let walletObject: KNWalletObject

  init(walletObject: KNWalletObject, isEditing: Bool = false) {
    if isEditing {
      self.walletObject = walletObject
    } else {
      self.walletObject = walletObject.copy(withNewName: "")
    }
  }

  var name: String { return self.walletObject.name }

  func walletObject(with newName: String) -> KNWalletObject {
    return self.walletObject.copy(withNewName: newName.isEmpty ? "Untitled" : newName)
  }
}

class KNEnterWalletNameViewController: KNBaseViewController {

  weak var delegate: KNEnterWalletNameViewControllerDelegate?
  fileprivate let viewModel: KNEnterWalletNameViewModel

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var nameLabel: UILabel!

  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var nextButton: UIButton!

  init(viewModel: KNEnterWalletNameViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNEnterWalletNameViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    self.containerView.rounded(radius: 4.0)
    self.nameLabel.text = NSLocalizedString("give.your.wallet.a.name", value: "Give your wallet a name (optional)", comment: "")
    self.nameTextField.rounded(radius: 4.0)
    let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.nameTextField.leftView = paddingView
    self.nameTextField.leftViewMode = .always
    self.nameTextField.rightView = paddingView
    self.nameTextField.rightViewMode = .always
    self.nextButton.rounded(radius: KNAppStyleType.current.buttonRadius())
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.nameTextField.text = self.viewModel.name
    self.nameTextField.becomeFirstResponder()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    self.nameTextField.resignFirstResponder()
    let walletObject = self.viewModel.walletObject(with: self.nameTextField.text ?? "")
    self.dismiss(animated: false) {
      self.delegate?.enterWalletNameDidNext(sender: self, walletObject: walletObject)
    }
  }
}
