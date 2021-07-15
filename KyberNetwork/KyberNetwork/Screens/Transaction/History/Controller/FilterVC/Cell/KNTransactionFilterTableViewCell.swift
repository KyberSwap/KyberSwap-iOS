// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTransactionFilterTableViewCellDelegate: class {
  func transactionFilterTableViewCell(_ cell: KNTransactionFilterTableViewCell, select token: String)
}

class KNTransactionFilterTableViewCell: UITableViewCell {

  @IBOutlet var tokenButtons: [UIButton]!
  fileprivate var tokens: [String] = []

  weak var delegate: KNTransactionFilterTableViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.tokenButtons.forEach({ $0.setTitle("", for: .normal) })
    self.tokenButtons.forEach({ $0.backgroundColor = .clear })
    self.tokenButtons.forEach({ $0.setImage(nil, for: .normal) })
  }

  func updateCell(with symbols: [String], selectedTokens: [String]) {
    self.tokens = symbols
    self.tokenButtons.forEach({
      if $0.tag >= symbols.count {
        $0.setTitle("", for: .normal)
        $0.backgroundColor = .clear
        $0.setImage(nil, for: .normal)
        $0.isHidden = true
      } else {
        $0.isHidden = false
        $0.setTitle(symbols[$0.tag], for: .normal)
        if selectedTokens.contains(symbols[$0.tag]) {
          $0.backgroundColor = UIColor(named: "buttonBackgroundColor")
          $0.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
          $0.rounded(radius: 16.0)
        } else {
          $0.backgroundColor = UIColor(named: "navButtonBgColor")
          $0.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
          $0.rounded(radius: 16.0)
        }
      }
    })
    self.layoutIfNeeded()
  }

  @IBAction func tokenButtonPressed(_ sender: UIButton) {
    if sender.tag < self.tokens.count {
      self.delegate?.transactionFilterTableViewCell(self, select: self.tokens[sender.tag])
    }
  }
}
