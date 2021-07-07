//
//  EarnSelectTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/29/21.
//

import UIKit

class EarnSelectTableViewCellViewModel {
  var isSelected: Bool
  let platform: String
  let distributionSupplyRate: Double
  let supplyRate: Double

  init(platform: LendingPlatformData, isSelected: Bool = false) {
    self.isSelected = isSelected
    self.platform = platform.name
    self.distributionSupplyRate = platform.distributionSupplyRate
    self.supplyRate = platform.supplyRate
  }
  
  func distributionSupplyRateDiplayString() -> String {
    if self.distributionSupplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.distributionSupplyRate * 100.0) + "%"
    }
  }

  func stableBorrowRateDiplayString() -> String {
    if self.supplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.supplyRate * 100.0) + "%"
    }
  }
}

class EarnSelectTableViewCell: UITableViewCell {
  @IBOutlet weak var checkStatusIndicator: UIView!
  @IBOutlet weak var platformIconImageView: UIImageView!
  @IBOutlet weak var platformNameLabel: UILabel!
  @IBOutlet weak var distributionSupplyRateContainerView: UIView!
  @IBOutlet weak var distributionSupplyRateLabel: UILabel!
  @IBOutlet weak var stableBorrowRateLabel: UILabel!
  
  static let kCellID: String = "EarnSelectTableViewCell"
  static let kCellHeight: CGFloat = 54

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCellViewViewModel(_ viewModel: EarnSelectTableViewCellViewModel) {
    let selectColor = viewModel.isSelected ? UIColor(named: "buttonBackgroundColor")! : UIColor(named: "investButtonBgColor")!
    let selectedBorder = viewModel.isSelected ? 5 : 1
    self.checkStatusIndicator.rounded(color: selectColor, width: CGFloat(selectedBorder), radius: 8)
    //TODO: temp soluton with only 2 platform and aave ropten is not correct name
    let iconImage = viewModel.platform == "Compound" ? UIImage(named: "comp_icon") : UIImage(named: "aave_icon")
    self.platformIconImageView.image = iconImage
    self.platformNameLabel.text = viewModel.platform
    self.distributionSupplyRateContainerView.isHidden = viewModel.distributionSupplyRateDiplayString().isEmpty
    self.distributionSupplyRateLabel.text = viewModel.distributionSupplyRateDiplayString()
    self.stableBorrowRateLabel.text = viewModel.stableBorrowRateDiplayString()
  }
}
