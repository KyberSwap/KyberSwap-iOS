// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNSearchTokenTableViewCellDelegate: class {
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didSelect token: TokenObject)
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didAdd token: TokenObject)
}

class KNSearchTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var addButton: UIButton!
  weak var delegate: KNSearchTokenTableViewCellDelegate?
  var token: TokenObject?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenSymbolLabel.text = ""
    self.addButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.addButton.frame.size.height / 2)
  }

  func updateCell(with token: TokenObject, isExistToken: Bool) {
    self.token = token
    self.iconImageView.setSymbolImage(symbol: token.symbol, size: iconImageView.frame.size)
    self.tokenSymbolLabel.text = "\(token.symbol.prefix(8))"
    let balText: String = {
      let value = token.getBalanceBigInt().string(
        decimals: token.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(token.decimals, 6)
      )
      if let double = Double(value.removeGroupSeparator()), double == 0 { return "0" }
      return value ?? ""
    }()
    self.balanceLabel.text = "\(balText.prefix(15))"
    self.balanceLabel.addLetterSpacing()
    self.balanceLabel.isHidden = !isExistToken
    self.addButton.isHidden = isExistToken
    self.layoutIfNeeded()
  }
  
  @IBAction func tapCell(_ sender: UIButton) {
    if let notNilToken = self.token {
      self.delegate?.searchTokenTableCell(self, didSelect: notNilToken)
    }
  }
  
  @IBAction func tapAddButton(_ sender: UIButton) {
    if let notNilToken = self.token {
      self.delegate?.searchTokenTableCell(self, didAdd: notNilToken)
    }
  }
  
}
