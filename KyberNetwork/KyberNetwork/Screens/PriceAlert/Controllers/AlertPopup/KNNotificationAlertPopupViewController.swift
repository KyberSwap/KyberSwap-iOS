// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import OneSignal
import BigInt

class KNNotificationAlertPopupViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!

  @IBOutlet weak var tokenImageView: UIImageView!
  @IBOutlet weak var pairTextLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var descTextLabel: UILabel!
  @IBOutlet weak var actionButton: UIButton!

  fileprivate let alert: KNAlertObject
  fileprivate let actionButtonTitle: String
  fileprivate let descriptionText: String

  init(
    alert: KNAlertObject,
    actionButtonTitle: String,
    descriptionText: String
    ) {
    self.alert = alert
    self.actionButtonTitle = actionButtonTitle
    self.descriptionText = descriptionText
    super.init(nibName: "KNNotificationAlertPopupViewController", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 4.0)
    tokenImageView.setTokenImage(with: alert, size: CGSize(width: 36.0, height: 36.0))
    self.pairTextLabel.text = "\(self.alert.token)/\(self.alert.currency)"
    self.priceLabel.text = {
      let number = BigInt(self.alert.price * pow(10.0, 18.0))
      let string = number.displayRate(decimals: 18)
      if self.alert.isAbove { return ">= \(string)" }
      return "<= \(string)"
    }()
    self.priceLabel.textColor = self.alert.isAbove ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
    self.descTextLabel.text = self.descriptionText
    self.actionButton.setTitle(
      self.actionButtonTitle,
      for: .normal
    )
    self.actionButton.rounded(radius: 4.0)
    self.actionButton.applyGradient()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.userDidTapOutSide(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.actionButton.removeSublayer(at: 0)
    self.actionButton.applyGradient()
  }

  @IBAction func actionButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @objc func userDidTapOutSide(_ sender: UITapGestureRecognizer) {
    let touchPoint = sender.location(in: self.view)
    if touchPoint.x < self.containerView.frame.minX
      || touchPoint.x > self.containerView.frame.maxX
      || touchPoint.y < self.containerView.frame.minY
      || touchPoint.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
