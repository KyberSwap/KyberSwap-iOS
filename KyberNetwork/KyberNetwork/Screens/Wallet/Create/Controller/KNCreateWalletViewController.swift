// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNCreateWalletViewEvent {
  case back
  case next(name: String)
}

protocol KNCreateWalletViewControllerDelegate: class {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent)
}

class KNCreateWalletViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var confirmLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!

  weak var delegate: KNCreateWalletViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    self.containerView.rounded(radius: 5.0)
    self.confirmLabel.text = NSLocalizedString("confirm", value: "Confirm", comment: "")
    self.descLabel.text = "This creates a new Ethereum wallet for you to receive and send tokens".toBeLocalised()
    let style = KNAppStyleType.current
    self.confirmButton.rounded(radius: style.buttonRadius())
    self.confirmButton.applyGradient()
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let touchedPoint = sender.location(in: self.view)
    if touchedPoint.x < self.containerView.frame.minX
      || touchedPoint.x > self.containerView.frame.maxX
      || touchedPoint.y < self.containerView.frame.minY
      || touchedPoint.y > self.containerView.frame.maxY {
      KNCrashlyticsUtil.logCustomEvent(withName: "create_wallet_dismiss", customAttributes: nil)
      self.delegate?.createWalletViewController(self, run: .back)
    }
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "create_wallet_confirm", customAttributes: nil)
    self.delegate?.createWalletViewController(self, run: .next(name: "New Wallet"))
  }
}
