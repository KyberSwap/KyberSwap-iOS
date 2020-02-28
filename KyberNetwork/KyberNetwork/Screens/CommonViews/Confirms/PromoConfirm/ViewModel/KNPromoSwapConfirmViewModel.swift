// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNPromoSwapConfirmViewModel: NSObject {
  let transaction: KNDraftExchangeTransaction
  let srcWallet: String
  let destWallet: String
  let expiredDate: Date

  init(transaction: KNDraftExchangeTransaction, srcWallet: String, destWallet: String, expiredDate: Date) {
    self.transaction = transaction
    self.srcWallet = srcWallet
    self.destWallet = destWallet
    self.expiredDate = expiredDate
  }

  var titleString: String {
    return "\(self.transaction.from.symbol) -> \(self.transaction.to.symbol)"
  }

  var isPayment: Bool { return self.srcWallet.lowercased() != self.destWallet.lowercased() }

  var walletAddress: String { return self.srcWallet }

  var expireDateDisplay: String {
    return DateFormatterUtil.shared.kycDateFormatter.string(from: self.expiredDate)
  }

  var leftAmountString: String {
    let amountString = self.transaction.amount.displayRate(decimals: transaction.from.decimals)
    return "\(amountString.prefix(12)) \(self.transaction.from.symbol)"
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.transaction.to) {
      let expectedReceive = self.transaction.amount * self.transaction.expectedRate / BigInt(10).power(self.transaction.to.decimals)
      return usdRate.rate * expectedReceive / BigInt(10).power(self.transaction.to.decimals)
    }
    return nil
  }

  var rightAmountString: String {
    let receivedAmount = self.transaction.displayExpectedReceive(short: false)
    return "\(receivedAmount.prefix(12)) \(self.transaction.to.symbol)"
  }

  var transactionFee: BigInt {
    let gasPrice: BigInt = self.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    return gasPrice * gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) ETH"
  }

  var feeUSDString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
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
}
