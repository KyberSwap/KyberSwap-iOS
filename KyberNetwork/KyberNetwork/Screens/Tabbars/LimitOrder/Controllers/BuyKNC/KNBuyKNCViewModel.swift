// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

class KNBuyKNCViewModel {
  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate(set) var market: KNMarket?
  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?
  var isUseAllBalance: Bool = false
  let supportedTokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken
  let weth = KNSupportedTokenStorage.shared.wethToken
  fileprivate(set) var pendingBalances: JSONDictionary = [:]
  fileprivate(set) var targetPrice: String = ""
  
  init(wallet: Wallet) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr) ?? KNWalletObject(address: addr)
    self.from = KNSupportedTokenStorage.shared.wethToken ?? KNSupportedTokenStorage.shared.ethToken
    self.to = KNSupportedTokenStorage.shared.kncToken
  }
  
  var walletNameString: String {
    let addr = self.walletObject.address.lowercased()
    return "|  \(addr.prefix(10))...\(addr.suffix(8))"
  }
  
  var targetPriceFromMarket: String {
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    return formatter.string(from: NSNumber(value: self.market?.buyPrice ?? 0)) ?? ""
  }
  
  func updateMarket(name: String = "ETH_KNC") {
    self.market = KNRateCoordinator.shared.getMarketWith(name: name)
  }
  
  func updateBalance(_ balances: [String: Balance])  {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      if let oldBal = self.balance, oldBal.value != bal.value {
        self.isUseAllBalance = false
      }
      self.balance = bal
    }
  }
  
  func updateTargetPrice(_ price: String) {
    self.targetPrice = price
  }
  
  var availableBalance: BigInt {
    let balance: BigInt = {
      if self.from.isWETH {
        let wethBalance = self.balance?.value ?? BigInt(0)
        let ethBalance = self.balances[self.eth.contract]?.value ?? BigInt(0)
        return wethBalance + ethBalance
      }
      return self.balance?.value ?? BigInt(0)
    }()
    var availableAmount = balance
    if let pendingAmount = self.pendingBalances[self.from.symbol] as? Double {
      availableAmount -= BigInt(pendingAmount * pow(10.0, Double(self.from.decimals)))
    }
    availableAmount = max(availableAmount, BigInt(0))
    return availableAmount
  }
  
  var balanceText: String {
    let bal: BigInt = self.availableBalance
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string), double == 0 { return "0" }
    return "\(string.prefix(12))"
  }

  var percentageRateDiff: Double {
    guard let marketPrice = self.market?.buyPrice else { return 0.0 }
    let currentPrice = self.targetPrice.doubleValue
    return (currentPrice - marketPrice) / marketPrice * 100.0
  }

  var differentRatePercentageDisplay: String? {
    let change = self.percentageRateDiff
    let display = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
    return "\(display)%"
  }

  var displayRateCompareAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let rateChange = self.percentageRateDiff
    if fabs(rateChange) < 0.1 { return attributedString }
    guard let rate = self.differentRatePercentageDisplay else { return attributedString }
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    ]
    let higherAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.shamrock,
    ]
    let lowerAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.strawberry,
    ]
    attributedString.append(NSAttributedString(string: "Your target rate is".toBeLocalised(), attributes: normalAttributes))
    if rateChange > 0 {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: higherAttributes))
      attributedString.append(NSAttributedString(string: "higher than current Market rate".toBeLocalised(), attributes: normalAttributes))
    } else {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: lowerAttributes))
      attributedString.append(NSAttributedString(string: "lower than current rate".toBeLocalised(), attributes: normalAttributes))
    }
    return attributedString
  }
}
