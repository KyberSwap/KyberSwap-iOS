//
//  OverviewDepositTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt

protocol OverviewDepositCellViewModel {
  var symbol: String { get }
  var displayBalance: NSAttributedString { get }
  var displayValue: String { get }
  var balanceBigInt: BigInt { get }
  var valueBigInt: BigInt { get }
  var currencyType: CurrencyType { get set }
  func updateCurrencyType(_ type: CurrencyType)
  var hideBalanceStatus: Bool { get set }
}

class OverviewDepositLendingBalanceCellViewModel: OverviewDepositCellViewModel {
  var hideBalanceStatus: Bool = true
  func updateCurrencyType(_ type: CurrencyType) {
    self.currencyType = type
  }
  
  var currencyType: CurrencyType = .usd
  
  var symbol: String {
    return self.balance.symbol
  }
  
  var displayBalance: NSAttributedString {
    guard !self.hideBalanceStatus else {
      return NSAttributedString(string: "********")
    }
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    let rateString = String(format: "%.2f", self.balance.supplyRate * 100)
    let amountAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let apyAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: "\(balanceString) \(self.balance.symbol) ", attributes: amountAttributes))
    attributedText.append(NSAttributedString(string: "\(rateString)% APY", attributes: apyAttributes))
    return attributedText
  }
  
  var displayValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let string = self.valueBigInt.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
    switch self.currencyType {
    case .usd:
      return "$" + string
    case .eth:
      return string + " ETH"
    case .btc:
      return string + " BTC"
    }
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.supplyBalance) ?? BigInt(0)
  }

  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    var price = 0.0
    switch self.currencyType {
    case .usd:
      price = tokenPrice.usd
    case .eth:
      price = tokenPrice.eth
    case .btc:
      price = tokenPrice.btc
    }
    return self.balanceBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(self.balance.decimals)
  }
  
  let balance: LendingBalance
  
  init(balance: LendingBalance) {
    self.balance = balance
  }
}

class OverviewDepositDistributionBalanceCellViewModel: OverviewDepositCellViewModel {
  var hideBalanceStatus: Bool = true
  func updateCurrencyType(_ type: CurrencyType) {
    self.currencyType = type
  }
  
  var symbol: String {
    return self.balance.symbol
  }

  var displayBalance: NSAttributedString {
    guard !self.hideBalanceStatus else {
      return NSAttributedString(string: "********")
    }
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimal, minFractionDigits: 0, maxFractionDigits: 6)
    let text = "\(balanceString) \(self.balance.symbol)"
    let amountAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    return NSAttributedString(string: text, attributes: amountAttributes)
  }

  var displayValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let string = self.valueBigInt.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
    switch self.currencyType {
    case .usd:
      return "$" + string
    case .eth:
      return string + " ETH"
    case .btc:
      return string + " BTC"
    }
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.unclaimed) ?? BigInt(0)
  }
  
  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    var price = 0.0
    switch self.currencyType {
    case .usd:
      price = tokenPrice.usd
    case .eth:
      price = tokenPrice.eth
    case .btc:
      price = tokenPrice.btc
    
    }
    return self.balanceBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(self.balance.decimal)
  }
  
  var currencyType: CurrencyType = .usd
  
  let balance: LendingDistributionBalance
  
  init(balance: LendingDistributionBalance) {
    self.balance = balance
  }
}

class OverviewDepositTableViewCell: UITableViewCell {
  static let kCellID: String = "OverviewDepositTableViewCell"
  static let kCellHeight: CGFloat = 48
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var tokenBalanceInfoLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!

  func updateCell(viewModel: OverviewDepositCellViewModel) {
    self.iconImageView.setSymbolImage(symbol: viewModel.symbol)
    self.tokenBalanceInfoLabel.attributedText = viewModel.displayBalance
    self.valueLabel.text = viewModel.displayValue
  }
}
