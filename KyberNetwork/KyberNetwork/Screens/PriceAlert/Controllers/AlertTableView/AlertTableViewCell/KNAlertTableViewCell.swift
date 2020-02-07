// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNAlertTableViewCell: UITableViewCell {

  static let height: CGFloat = 56.0
  @IBOutlet weak var tokenIcon: UIImageView!
  @IBOutlet weak var pairLabel: UILabel!
  @IBOutlet weak var alertPriceLabel: UILabel!
  @IBOutlet weak var changeButton: UIButton!

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateCell(with alert: KNAlertObject, index: Int) {
    tokenIcon.setTokenImage(with: alert, size: CGSize(width: 36.0, height: 36.0), applyNoir: alert.state != .active)
    self.pairLabel.attributedText = {
      let attributedString = NSMutableAttributedString()
      let pair = "\(alert.token)/\(alert.currency)"
      let pairAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
      ]
      attributedString.append(NSAttributedString(string: pair, attributes: pairAttributes))
      if alert.state == .triggered {
        let triggerAttributes: [NSAttributedStringKey: Any] = [
          NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
          NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
        ]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm dd/MM/yyyy"
        let triggerString = String(
          format: NSLocalizedString("Triggered: \n%@", comment: ""),
          dateFormatter.string(from: Date(timeIntervalSince1970: alert.triggeredDate))
        )
        attributedString.append(NSAttributedString(string: "\n\(triggerString)", attributes: triggerAttributes))
      }
      return attributedString
    }()
    self.pairLabel.numberOfLines = 0

    let percentageChange = alert.currentPrice == 0.0 ? 0.0 : 100.0 * fabs(alert.price - alert.currentPrice) / alert.currentPrice
    let percentageString = NumberFormatterUtil.shared.displayPercentage(from: percentageChange)
    self.changeButton.setTitle("\(percentageString)%", for: .normal)
    self.changeButton.setTitleColor(
      alert.state == .triggered ? UIColor.Kyber.grayChateau : UIColor(red: 90, green: 94, blue: 103),
      for: .normal
    )
    let dirImageActive = alert.isAbove ? UIImage(named: "change_up") : UIImage(named: "change_down")
    let dirImageTrigger = alert.isAbove ? UIImage(named: "change_up_grey") : UIImage(named: "change_down_grey")
    self.changeButton.setImage(
      alert.state == .triggered ? dirImageTrigger : dirImageActive,
      for: .normal
    )
    self.changeButton.alpha = alert.state == .triggered ? 0.5 : 1.0

    self.alertPriceLabel.text = {
      let string = NumberFormatterUtil.shared.displayAlertPrice(from: alert.price)
      if alert.isAbove { return ">= \(string)" }
      return "<= \(string)"
    }()
    self.alertPriceLabel.textColor = {
      if alert.state != .active {
        return UIColor.Kyber.grayChateau
      }
      return alert.isAbove ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
    }()
    self.backgroundColor = index % 2 == 0 ? UIColor(red: 242, green: 243, blue: 246) : UIColor.clear
    self.tokenIcon.alpha = alert.state == .active ? 1.0 : 0.5
    self.layoutIfNeeded()
  }
}
