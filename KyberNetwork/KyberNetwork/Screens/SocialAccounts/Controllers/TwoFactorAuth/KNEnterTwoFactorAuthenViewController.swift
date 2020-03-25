// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNEnterTwoFactorAuthenViewControllerDelegate: class {
  func enterTwoFactorAuthenViewController(_ controller: KNEnterTwoFactorAuthenViewController, token: String)
}

class KNEnterTwoFactorAuthenViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var twoFactorTextLabel: UILabel!

  @IBOutlet weak var tokenTextField: UITextField!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var pasteButton: UIButton!

  weak var delegate: KNEnterTwoFactorAuthenViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    self.containerView.rounded(radius: 5.0)
    self.twoFactorTextLabel.text = "Two Factor Authentication (2FA)".toBeLocalised()

    self.continueButton.rounded()
    self.continueButton.setTitle(NSLocalizedString("continue", value: "Continue", comment: ""), for: .normal)
    self.cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
    self.continueButton.applyGradient()

    self.tokenTextField.placeholder = "Token".toBeLocalised()
    self.tokenTextField.delegate = self

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.tokenTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.continueButton.removeSublayer(at: 0)
    self.continueButton.applyGradient()
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let position = sender.location(in: self.view)
    if position.x < self.containerView.frame.minX || position.x > self.containerView.frame.maxX
      || position.y < self.containerView.frame.minY || position.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func pasteButtonPressed(_ sender: Any) {
    if let string = UIPasteboard.general.string {
      self.tokenTextField.text = string
    }
  }

  @IBAction func continueButtonPressed(_ sender: Any) {
    let token = self.tokenTextField.text ?? ""
    guard token.count == 6 else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Please enter a valid token (6 digits) to continue".toBeLocalised(),
        time: 1.0
      )
      return
    }
    self.dismiss(animated: true) {
      self.delegate?.enterTwoFactorAuthenViewController(self, token: token)
    }
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension KNEnterTwoFactorAuthenViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    self.tokenTextField.text = "\(text.prefix(6))"
    return false
  }
}
