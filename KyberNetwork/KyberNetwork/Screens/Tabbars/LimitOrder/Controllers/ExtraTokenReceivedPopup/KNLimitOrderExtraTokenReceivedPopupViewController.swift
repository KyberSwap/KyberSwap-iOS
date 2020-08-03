// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNLimitOrderExtraTokenReceivedPopupViewController: KNBaseViewController {

  let order: KNOrderObject

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var explainTextLabel: UILabel!
  @IBOutlet weak var whyButton: UIButton!

  init(order: KNOrderObject) {
    self.order = order
    super.init(
      nibName: KNLimitOrderExtraTokenReceivedPopupViewController.className,
      bundle: nil
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let symbol = self.order.destTokenSymbol

    self.whyButton.setTitle("Why?".toBeLocalised(), for: .normal)
    let actualReceivedAmount: String = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.actualDestAmount)) \(symbol)"
    let actualSrc = self.order.sourceAmount * (1.0 - self.order.fee)
    let estimatedAmount: String = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: actualSrc * self.order.targetPrice)) \(symbol)"
    let extraAmount: String = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.extraAmount)) \(symbol)"

    let attributedString = NSMutableAttributedString()
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]
    let extraAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 49, green: 203, blue: 158),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]
    attributedString.append(NSAttributedString(string: "Actual received amount: \(actualReceivedAmount)\nEstimated amount: \(estimatedAmount)\nYou got extra: ", attributes: normalAttributes))
    attributedString.append(NSAttributedString(string: "\(extraAmount)", attributes: extraAttributes))

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 5

    let range = NSRange(location: 0, length: attributedString.length)
    attributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: range)

    self.explainTextLabel.attributedText = attributedString

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.isUserInteractionEnabled = true
    self.view.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let loc = sender.location(in: self.view)
    if loc.y < self.containerView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func whyButtonPressed(_ sender: Any) {
    let url = "\(KNEnvironment.default.kyberswapURL)/faq#Why-received-amount-is-higher-than-estimated-amount"
    self.openSafari(with: url)
  }
}
