//
//  OverviewMainViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/10/21.
//

import UIKit
import BigInt

enum OverviewMainCellMode {
  case market(token: Token, rightMode: RightMode)
  case asset(token: Token, rightMode: RightMode)
  case supply(balance: Any)
  case search(token: Token)
}

class OverviewMainCellViewModel {
  let mode: OverviewMainCellMode
  let currency: CurrencyMode
  var hideBalanceStatus: Bool = true
  init(mode: OverviewMainCellMode, currency: CurrencyMode) {
    self.mode = mode
    self.currency = currency
  }
  
  var tokenSymbol: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      return token.symbol
    case .asset(token: let token, rightMode: let mode):
      return token.symbol
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        return lendingBalance.symbol
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        return distributionBalance.symbol
      } else {
        return ""
      }
    case .search(token: let token):
      return token.symbol
    }
  }
  
  var displayTitle: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      return token.symbol
    case .asset(token: let token, rightMode: let mode):
      return token.symbol
    case .supply(balance: let balance):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      if let lendingBalance = balance as? LendingBalance {
        let balanceBigInt = BigInt(lendingBalance.supplyBalance) ?? BigInt(0)
        let balanceString = balanceBigInt.string(decimals: lendingBalance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
        return "\(balanceString) \(lendingBalance.symbol)"
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        let balanceBigInt = BigInt(distributionBalance.unclaimed) ?? BigInt(0)
        let balanceString = balanceBigInt.string(decimals: distributionBalance.decimal, minFractionDigits: 0, maxFractionDigits: 6)
        return "\(balanceString) \(distributionBalance.symbol)"
      } else {
        return ""
      }
    case .search(token: let token):
      return token.symbol
    }
  }

  var displaySubTitleDetail: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      let price = token.getTokenLastPrice(self.currency)
      return self.currency.symbol() + String(format: "%.6f", price)
    case .asset(token: let token, rightMode: let mode):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      return token.getBalanceBigInt().string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 6))
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        let rateString = String(format: "%.2f", lendingBalance.supplyRate * 100)
        return "\(rateString)%".paddingString()
      } else {
        return ""
      }
    case .search(token: let token):
      return token.name
    }
  }

  var displayAccessoryTitle: String {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      switch mode {
      case .ch24:
        let change24 = token.getTokenChange24(self.currency)
        return String(format: "%.2f", change24) + "%"
      case .lastPrice:
        let price = token.getTokenLastPrice(self.currency)
        return self.currency.symbol() + String(format: "%.2f", price)
      default:
        return ""
      }
      
    case .asset(token: let token, rightMode: let mode):
      guard !self.hideBalanceStatus else {
        return "********"
      }
      switch mode {
      case .value:
        let rateBigInt = BigInt(token.getTokenLastPrice(self.currency) * pow(10.0, 18.0))
        let valueBigInt = token.getBalanceBigInt() * rateBigInt / BigInt(10).power(token.decimals)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 6))
        return self.currency.symbol() + valueString
      case .ch24:
        let change24 = token.getTokenChange24(self.currency)
        return String(format: "%.2f", change24) + "%"
      case .lastPrice:
        let price = token.getTokenLastPrice(self.currency)
        return self.currency.symbol() + String(format: "%.2f", price)
      }
    case .supply(balance: let balance):
      if let lendingBalance = balance as? LendingBalance {
        guard !self.hideBalanceStatus else {
          return "********"
        }
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: lendingBalance.address, currency: self.currency)
        let balanceBigInt = BigInt(lendingBalance.supplyBalance) ?? BigInt(0)
        let valueBigInt = balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(lendingBalance.decimals)
        return self.currency.symbol() + valueBigInt.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
      } else if let distributionBalance = balance as? LendingDistributionBalance {
        guard !self.hideBalanceStatus else {
          return "********"
        }
        let tokenPrice = KNTrackerRateStorage.shared.getLastPriceWith(address: distributionBalance.address, currency: self.currency)
        let balanceBigInt = BigInt(distributionBalance.unclaimed) ?? BigInt(0)
        let valueBigInt = balanceBigInt * BigInt(tokenPrice * pow(10.0, 18.0)) / BigInt(10).power(distributionBalance.decimal)
        return self.currency.symbol() + valueBigInt.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
      } else {
        return ""
      }
    case .search(token: let token):
      let price = token.getTokenLastPrice(self.currency)
      return self.currency.symbol() + String(format: "%.2f", price)
    }
  }

  var displayAccessoryColor: UIColor? {
    switch self.mode {
    case .market(token: let token, rightMode: let mode):
      let change24 = token.getTokenChange24(self.currency)
      return change24 > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    case .asset(token: let token, rightMode: let mode):
      let change24 = token.getTokenChange24(self.currency)
      return change24 > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    case .search(token: let token):
      let change24 = token.getTokenChange24(self.currency)
      return change24 > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
    default:
      return UIColor(named: "buttonBackgroundColor")
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
  var action: (() -> ())?
  
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
  
  @IBAction func tapOnRightSide(_ sender: Any) {
    (self.action ?? {})()
  }
  
}
