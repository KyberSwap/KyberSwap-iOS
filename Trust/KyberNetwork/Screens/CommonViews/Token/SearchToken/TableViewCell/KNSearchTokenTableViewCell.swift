// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenSymbolLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
    self.textLabel?.textColor = UIColor(hex: "5A5E67")
    self.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
  }

  func updateCell(with token: TokenObject) {
    //TODO: remove default value
    if let image = UIImage(named: token.icon) {
      self.iconImageView.image = image
    } else {
      self.iconImageView.setImage(
        with: token.iconURL,
        placeholder: UIImage(named: "default_token"))
    }
    self.tokenSymbolLabel.text = token.symbol
    self.tokenNameLabel.text = token.name
    self.layoutIfNeeded()
  }
}
