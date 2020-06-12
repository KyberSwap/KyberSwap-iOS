// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNPromoCodeViewControllerDelegate: class {
  func promoCodeViewControllerDidClose()
  func promoCodeViewController(_ controller: KNPromoCodeViewController, promoCode: String, name: String)
}

class KNPromoCodeViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var yourPromoCodeTextLabel: UILabel!
  @IBOutlet weak var enterPromoCodeTextField: UITextField!
  @IBOutlet weak var applyButton: UIButton!

  weak var delegate: KNPromoCodeViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = NSLocalizedString("kybercode", value: "KyberCode", comment: "")

    self.yourPromoCodeTextLabel.text = NSLocalizedString("your.kybercode", value: "Your KyberCode", comment: "")
    self.enterPromoCodeTextField.placeholder = "Both capital or small letters work fine".toBeLocalised()

    self.applyButton.setTitle(NSLocalizedString("apply", value: "Apply", comment: ""), for: .normal)
    self.applyButton.rounded(radius: KNAppStyleType.current.buttonRadius())
    self.applyButton.applyGradient()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.enterPromoCodeTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.applyButton.removeSublayer(at: 0)
    self.applyButton.applyGradient()
  }

  func resetUI() {
    self.enterPromoCodeTextField.text = ""
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.promoCodeViewControllerDidClose()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNCrashlyticsUtil.logCustomEvent(withName: "kybercode_apply", customAttributes: nil)
    let promoCode = self.enterPromoCodeTextField.text ?? ""
    guard !promoCode.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("kybercode.is.empty", value: "KyberCode is empty", comment: ""),
        time: 1.5
      )
      return
    }
    guard promoCode.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "KyberCode is invalid format".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let name: String = "PromoCode Wallet"
    self.delegate?.promoCodeViewController(self, promoCode: promoCode, name: name)
  }
}
