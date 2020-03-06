// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import TrustCore

struct KNDraftExchangeTransaction {
  let from: TokenObject
  let to: TokenObject
  let amount: BigInt
  let maxDestAmount: BigInt
  let expectedRate: BigInt
  let minRate: BigInt?
  let gasPrice: BigInt?
  let gasLimit: BigInt?
  let expectedReceivedString: String?
}

extension KNDraftExchangeTransaction {
  func displayAmount(short: Bool = true) -> String {
    return short ? amount.shortString(decimals: from.decimals) : amount.fullString(decimals: from.decimals)
  }

  var expectedReceive: BigInt {
    return amount * expectedRate / BigInt(10).power(from.decimals)
  }

  func displayExpectedReceive(short: Bool = true) -> String {
    if let string = self.expectedReceivedString {
      return "\(string.prefix(12))"
    }
    return short ? expectedReceive.shortString(decimals: to.decimals) : expectedReceive.fullString(decimals: to.decimals)
  }

  func displayExpectedRate(short: Bool = true) -> String {
    return short ? expectedRate.shortString(decimals: to.decimals) : expectedRate.fullString(decimals: to.decimals)
  }

  func displayMinRate(short: Bool = true) -> String? {
    return short ? minRate?.shortString(decimals: to.decimals) : minRate?.fullString(decimals: to.decimals)
  }

  var displayGasPrice: String? {
    return gasPrice?.shortString(units: UnitConfiguration.gasPriceUnit)
  }

  var fee: BigInt {
    return (gasPrice ?? BigInt(0)) * (gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault)
  }

  func displayFeeString(short: Bool = true) -> String {
    return short ? fee.shortString(units: UnitConfiguration.gasFeeUnit) : fee.fullString(units: UnitConfiguration.gasFeeUnit)
  }

  var usdValueStringForFee: String {
    let eth = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.isETH })!
    let rate = KNRateCoordinator.shared.usdRate(for: eth)?.rate ?? BigInt(0)
    return (rate * fee / BigInt(EthereumUnit.ether.rawValue)).shortString(units: .ether)
  }

  var usdRateForFromToken: KNRate? {
    return KNRateCoordinator.shared.usdRate(for: from)
  }

  var usdValueStringForFromToken: String {
    let rate = usdRateForFromToken?.rate ?? BigInt(0)
    return (rate * amount / BigInt(EthereumUnit.ether.rawValue)).shortString(units: .ether)
  }

  var usdRateForToToken: KNRate? {
    return KNRateCoordinator.shared.usdRate(for: to)
  }
}

extension KNDraftExchangeTransaction {

  func copy(expectedRate: BigInt, gasLimit: BigInt? = nil) -> KNDraftExchangeTransaction {
    return KNDraftExchangeTransaction(
      from: self.from,
      to: self.to,
      amount: self.amount,
      maxDestAmount: self.maxDestAmount,
      expectedRate: expectedRate,
      minRate: self.minRate,
      gasPrice: self.gasPrice,
      gasLimit: gasLimit ?? self.gasLimit,
      expectedReceivedString: (expectedRate * amount / BigInt(10).power(self.from.decimals)).fullString(decimals: self.to.decimals)
    )
  }

  func toTransaction(hash: String, fromAddr: Address, toAddr: Address, nounce: Int, type: TransactionType = .normal) -> Transaction {
    // temporary: local object contains from and to tokens + expected rate
    let expectedAmount: String = {
      return self.expectedReceive.fullString(decimals: self.to.decimals)
    }()
    let localObject = LocalizedOperationObject(
      from: self.from.contract,
      to: self.to.contract,
      contract: nil,
      type: "exchange",
      value: expectedAmount,
      symbol: self.from.symbol,
      name: self.to.symbol,
      decimals: self.to.decimals
    )
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: fromAddr.description,
      to: toAddr.description,
      value: self.amount.fullString(decimals: self.from.decimals),
      gas: self.gasLimit?.fullString(units: .wei).removeGroupSeparator() ?? "",
      gasPrice: self.gasPrice?.fullString(units: .wei).removeGroupSeparator() ?? "",
      gasUsed: self.gasLimit?.fullString(units: .wei).removeGroupSeparator() ?? "",
      nonce: "\(nounce)",
      date: Date(),
      localizedOperations: [localObject],
      state: .pending,
      type: type
    )
  }
}
