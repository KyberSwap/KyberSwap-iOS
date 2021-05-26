// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import JdenticonSwift

struct KConfirmSendViewModel {

  let transaction: UnconfirmedTransaction
  let ens: String?

  init(transaction: UnconfirmedTransaction, ens: String?) {
    self.transaction = transaction
    self.ens = ens
  }

  var token: TokenObject { return transaction.transferType.tokenObject() }

  var addressToIcon: UIImage? {
    guard let data = self.transaction.to?.data else { return nil }
    return UIImage.generateImage(with: 75, hash: data)
  }

  var titleString: String {
    return "Sending confirm".toBeLocalised().uppercased()
  }

  var contactName: String {
    let address = transaction.to?.description ?? NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
    guard let contact = KNContactStorage.shared.contacts.first(where: { address.lowercased() == $0.address.lowercased() }) else {
      let text = NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
      if let ens = self.ens { return "\(ens) - \(text)" }
      return text
    }
    if let ens = self.ens { return "\(ens) - \(contact.name)" }
    return contact.name
  }

  var address: String {
    let address = transaction.to?.description ?? ""
    return "\(address.prefix(20))...\(address.suffix(8))"
  }
  
  var shortAddress: String {
    let address = transaction.to?.description ?? ""
    return "\(address.prefix(6))...\(address.suffix(6))"
  }
  

  var totalAmountString: String {
    let string = self.transaction.value.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    )
    return "\(string.prefix(15)) \(self.token.symbol)"
  }

  var usdValueString: String {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address) else { return "" }
//    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let displayString: String = {
    let usd = self.transaction.value * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.token.decimals)
    return usd.string(
      units: EthereumUnit.ether,
      minFractionDigits: 0,
      maxFractionDigits: 4
    )
    }()
    return "~ \(displayString) USD"
  }

  var transactionFeeText: String { return "\(NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")): " }
  var transactionFeeETHString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt? = {
      guard let gasPrice = self.transaction.gasPrice, let gasLimit = self.transaction.gasLimit else { return nil }
      return gasPrice * gasLimit
    }()
    guard let feeBigInt = fee else { return "" }
//    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
//    let feeUSD: String = {
//      let fee = feeBigInt * trackerRate.rateUSDBigInt / BigInt(EthereumUnit.ether.rawValue)
//      return fee.displayRate(decimals: 18)
//    }()
//    return "~ \(feeUSD) USD"
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = feeBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
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
