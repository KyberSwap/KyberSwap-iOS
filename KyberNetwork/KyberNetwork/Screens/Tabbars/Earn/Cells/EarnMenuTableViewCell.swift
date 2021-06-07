//
//  EarnMenuTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/26/21.
//

import UIKit

struct EarnMenuTableViewCellViewModel {
  let name: String
  let sym: String
  let borrowRateAPY: String
  let token: TokenData
  let supplyRate: Double
  init(token: TokenData) {
    self.name = token.name
    self.sym = token.symbol.uppercased()
    let optimizeValue = token.lendingPlatforms.max { (left, right) -> Bool in
      return left.supplyRate < right.supplyRate
    }

    if let notNilValue = optimizeValue {
      self.borrowRateAPY = String(format: "%.6f", notNilValue.supplyRate * 100.0) + "%"
      self.supplyRate = notNilValue.supplyRate
    } else {
      self.borrowRateAPY = ""
      self.supplyRate = 0
    }
    self.token = token
  }
}

class EarnMenuTableViewCell: UITableViewCell {
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenNameLabel: UILabel!
  @IBOutlet weak var apyValueLabel: UILabel!
  
  static let kCellID: String = "EarnMenuTableViewCell"
  static let kCellHeight: CGFloat = 52
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateCellWithViewModel(_ viewModel: EarnMenuTableViewCellViewModel) {
    self.tokenIconImageView.setTokenImage(tokenData: viewModel.token, size: CGSize(width: 12, height: 12))
    self.tokenNameLabel.text = viewModel.sym
    self.apyValueLabel.text = viewModel.borrowRateAPY
  }
}
