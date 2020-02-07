// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNLimitOrderTokenTableViewCell: UITableViewCell {

  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenNameLabel.text = ""
    self.tokenSymbolLabel.text = ""
    self.tokenBalanceLabel.text = ""
  }

  func updateCell(with token: TokenObject, balance: BigInt?) {
//    if !token.isSupported {
//      // always use default icon for un supported tokens for less confusing
//      self.tokenIconImageView.image = UIImage(named: "default_token")
//    } else if let image = UIImage(named: token.icon.lowercased()) {
//      self.tokenIconImageView.image = image
//    } else {
//      self.tokenIconImageView.setImage(
//        with: token.iconURL,
//        placeholder: UIImage(named: "default_token"))
//    }
    tokenIconImageView.setTokenImage(token: token, size: tokenIconImageView.frame.size)
    let isETHStar = (token.isWETH || token.isETH)
    self.tokenSymbolLabel.text = isETHStar ? "ETH*" : "\(token.symbol.prefix(8))"
    self.tokenSymbolLabel.font = isETHStar ? UIFont.Kyber.semiBold(with: 14) : UIFont.Kyber.medium(with: 14)
    self.tokenSymbolLabel.addLetterSpacing()
    self.tokenNameLabel.text = isETHStar ? NSLocalizedString("ETH* represents the sum of ETH & WETH for easy reference", value: "ETH* represents the sum of ETH & WETH for easy reference", comment: "") : token.name
    self.tokenNameLabel.textColor = isETHStar ? UIColor(red: 20, green: 25, blue: 39) : UIColor(red: 158, green: 161, blue: 170)
    self.tokenNameLabel.font = UIFont.Kyber.medium(with: 12, italic: isETHStar)
    self.tokenNameLabel.addLetterSpacing()
    let balText: String = {
      let value = balance?.string(
        decimals: token.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(token.decimals, 6)
      )
      if let val = value, let double = Double(val), double == 0 { return "0" }
      return value ?? ""
    }()
    self.tokenBalanceLabel.text = "\(balText.prefix(12))"
    self.tokenBalanceLabel.addLetterSpacing()
    self.layoutIfNeeded()
  }
}
