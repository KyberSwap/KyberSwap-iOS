//
//  OverviewMainViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/10/21.
//

import UIKit
import BigInt

enum OverviewMainCellMode {
  case market(token: Token)
  case asset(token: Token)
  case supply(balance: Any)
}

class OverviewMainCellViewModel {
  let mode: OverviewMainCellMode
  var hideBalanceStatus: Bool = true
  init(mode: OverviewMainCellMode) {
    self.mode = mode
  }
  
  var displayTitle: String {
    switch self.mode {
    case .market(token: let token):
      return token.symbol
    case .asset(token: let token):
      return token.symbol
    case .supply(balance: let balance):
      return ""
    }
    
  }
  
  var displaySubTitleDetail: String {
    switch self.mode {
    case .market(token: let token):
      let price = token.getTokenPrice().usd
      return "$" + String(format: "%.6f", price)
    case .asset(token: let token):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      return token.getBalanceBigInt().string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 6))
    default:
      return ""
    }
  }
  
  var displayAccessoryTitle: String {
    switch self.mode {
    case .market(token: let token):
      let change24 = token.getTokenPrice().usd24hChange
      return String(format: "%.2f", change24) + "%"
    case .asset(token: let token):
      let rateBigInt = BigInt(token.getTokenPrice().usd * pow(10.0, 18.0))
      let valueBigInt = token.getBalanceBigInt() * rateBigInt / BigInt(10).power(token.decimals)
      let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 6))
      return "$" + valueString
    default:
      return ""
    }
  }

  var displayAccessoryColor: UIColor? {
    switch self.mode {
    case .market(token: let token):
      let change24 = token.getTokenPrice().usd24hChange
      return change24 > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    case .asset(token: let token):
      let change24 = token.getTokenPrice().usd24hChange
      return change24 > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    default:
      return nil
    }
  }
  
}

class OverviewMainViewCell: UITableViewCell {
  
  static let kCellID: String = "OverviewMainViewCell"
  static let kCellHeight: CGFloat = 60
  
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var tokenValueLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateCell(_ viewModel: OverviewMainCellViewModel) {
    self.iconImageView.setSymbolImage(symbol: viewModel.displayTitle)
    self.tokenLabel.text = viewModel.displayTitle
    self.tokenBalanceLabel.text = viewModel.displaySubTitleDetail
    self.tokenValueLabel.text = viewModel.displayAccessoryTitle
    self.tokenValueLabel.textColor = viewModel.displayAccessoryColor
  }
  
}
