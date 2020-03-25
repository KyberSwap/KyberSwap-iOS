// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNForgotPasswordViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!

  @IBOutlet weak var resetPasswordTextLabel: UILabel!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var subtitleTextLabel: UILabel!

  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 5.0)
    self.resetPasswordTextLabel.text = "Reset Password".toBeLocalised()
    self.subtitleTextLabel.text = "Enter your email address below and we'll get you on track".toBeLocalised()
    self.emailTextField.placeholder = "Email Address".toBeLocalised()
    self.sendButton.rounded(radius: KNAppStyleType.current.buttonRadius())
    self.sendButton.setTitle(NSLocalizedString("continue", value: "Continue", comment: ""), for: .normal)
    self.cancelButton.setTitle(NSLocalizedString("cancel", comment: ""), for: .normal)
    self.sendButton.applyGradient()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.emailTextField.becomeFirstResponder()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.sendButton.removeSublayer(at: 0)
    self.sendButton.applyGradient()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let position = sender.location(in: self.view)
    if position.x < self.containerView.frame.minX || position.x > self.containerView.frame.maxX
      || position.y < self.containerView.frame.minY || position.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    let email = self.emailTextField.text ?? ""
    guard email.isValidEmail() else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Please enter a valid email address to continue".toBeLocalised(),
        time: 1.0
      )
      return
    }
    self.sendResetPasswordRequest(email)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  fileprivate func sendResetPasswordRequest(_ email: String) {
    self.displayLoading()
    KNSocialAccountsCoordinator.shared.resetPassword(email) { [weak self] result in
      guard let `self` = self else { return }
      self.hideLoading()
      switch result {
      case .success(let data):
        if data.0 {
          // success
          self.showSuccessTopBannerMessage(
            with: NSLocalizedString("success", comment: ""),
            message: data.1,
            time: 1.0
          )
          self.dismiss(animated: true, completion: nil)
        } else {
          self.showErrorTopBannerMessage(
            with: NSLocalizedString("error", comment: ""),
            message: data.1,
            time: 1.0
          )
        }
      case .failure:
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: "Can not send your request, please try again".toBeLocalised(),
          time: 1.0
        )
      }
    }
  }
}
