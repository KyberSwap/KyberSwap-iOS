// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KConfirmSwapViewModel {

  let transaction: KNDraftExchangeTransaction
  let ethBalance: BigInt
  let signTransaction: SignTransaction
  let hasRateWarning: Bool
  let platform: String
  let rawTransaction: TxObject
  let minDestAmount: BigInt

  init(transaction: KNDraftExchangeTransaction, ethBalance: BigInt, signTransaction: SignTransaction, hasRateWarning: Bool, platform: String, rawTransaction: TxObject, minDestAmount: BigInt) {
    self.transaction = transaction
    self.ethBalance = ethBalance
    self.signTransaction = signTransaction
    self.hasRateWarning = hasRateWarning
    self.platform = platform
    self.rawTransaction = rawTransaction
    self.minDestAmount = minDestAmount
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) ➞ \(self.transaction.to.symbol)"
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.displayRate(decimals: transaction.from.decimals)
    return "\(amountString.prefix(15)) \(self.transaction.from.symbol)"
  }

  var equivalentUSDAmount: BigInt? {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.transaction.to.address) else { return nil }
//    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.transaction.to) {
//      let expectedReceive = self.transaction.expectedReceive
//      return usdRate.rate * expectedReceive / BigInt(10).power(self.transaction.to.decimals)
//    }
//    return nil
    let usd = self.transaction.expectedReceive * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.transaction.to.decimals)
    return usd
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: false)
    return "\(receivedAmount.prefix(15)) \(self.transaction.to.symbol)"
  }

  var displayEstimatedRate: String {
    let rateString = self.transaction.expectedRate.displayRate(decimals: 18)
    let usdPriceDouble = KNTrackerRateStorage.shared.getPriceWithAddress(self.transaction.to.address)?.usd ?? 0.0
    let usdPrice = BigInt(usdPriceDouble * pow(10.0, 18.0))
    let usdValue = self.transaction.expectedRate * usdPrice / BigInt(10).power(18)
    return "1 \(self.transaction.from.symbol) = \(rateString) \(self.transaction.to.symbol) = \(usdValue.displayRate(decimals: 18)) USD"
  }

  var warningMinAcceptableRateMessage: String? {
    guard let minRate = self.transaction.minRate, minRate >= self.transaction.expectedRate else { return nil }
    // min rate is zero
    return "Your configured minimal rate is higher than what is recommended by KyberNetwork. Your swap has high chance to fail.".toBeLocalised()
  }

  var minRateString: String {
    let minRate = self.transaction.minRate ?? BigInt(0)
    return minRate.displayRate(decimals: 18)
  }
  
  var displayMinDestAmount: String {
    return self.minDestAmount.string(decimals: self.transaction.to.decimals, minFractionDigits: 4, maxFractionDigits: 4) + " " + self.transaction.to.symbol
  }
  

  var transactionFee: BigInt {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    return gasPrice * gasLimit
  }

  var feeETHString: String {
    let quoteToken = KNGeneralProvider.shared.isEthereum ? "ETH" : "BNB"
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) \(quoteToken)"
  }

  var feeUSDString: String {
//    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
//    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
//    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
//    let valueString: String = value.displayRate(decimals: 18)
//    return "~ \(valueString) USD"
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.transactionFee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var warningETHBalanceShown: Bool {
    if !self.transaction.from.isETH { return false }
    let totalAmount = self.transactionFee + self.transaction.amount
    return self.self.transaction.from.getBalanceBigInt() - totalAmount <= BigInt(0.01 * pow(10.0, 18.0))
  }

  var transactionGasPriceString: String {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }

  var hint: String {
    return self.transaction.hint ?? ""
  }
  
  var reverseRoutingText: String {
    return String(format: "Your transaction will be routed to %@ for better rate.".toBeLocalised(), self.platform.capitalized)
  }
}
