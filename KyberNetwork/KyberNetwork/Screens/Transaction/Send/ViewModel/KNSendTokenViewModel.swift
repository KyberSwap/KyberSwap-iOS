// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore

class KNSendTokenViewModel: NSObject {

  fileprivate let gasPrices: [BigInt] = [
    KNGasConfiguration.gasPriceMin,
    KNGasConfiguration.gasPriceDefault,
    KNGasConfiguration.gasPriceMax,
  ]

  let defaultTokenIconImg = UIImage(named: "default_token")

  fileprivate(set) var from: TokenObject
  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amount: String = ""
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault

  fileprivate(set) var addressString: String = ""
  fileprivate(set) var isUsingEns: Bool = false
  var isSendAllBalanace: Bool = false

  var allETHBalanceFee: BigInt {
    let gasLimit = max(self.gasLimit, KNGasConfiguration.transferETHGasLimitDefault)
    return self.gasPrice * gasLimit
  }

  var allTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
      let availableValue = max(BigInt(0), balance - self.allETHBalanceFee)
      let string = availableValue.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 6)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.displayBalance.removeGroupSeparator()
  }

  var amountBigInt: BigInt {
    return amount.amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.from) {
      return usdRate.rate * self.amountBigInt / BigInt(10).power(self.from.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var amountTextColor: UIColor {
    return isAmountValid ? UIColor.Kyber.enygold : UIColor.red
  }

  var address: Address?

  init(from: TokenObject, balances: [String: Balance]) {
    self.from = from.clone()
    self.balances = balances
    self.balance = balances[from.contract]
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: from)
  }

  var navTitle: String {
    return "\(NSLocalizedString("transfer", value: "Transfer", comment: ""))"
  }

  var tokenButtonAttributedText: NSAttributedString {
    // only have symbol and logo
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedStringKey.kern: 0.0,
    ]
    attributedString.append(NSAttributedString(string: "\(self.from.symbol.prefix(8))", attributes: symbolAttributes))
    return attributedString
  }

  var balanceText: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol.prefix(8)) \(balanceText)".uppercased()
  }

  var displayBalance: String {
    guard let bal = self.balance else { return "0" }
    let string = bal.value.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var placeHolderEnterAddress: String {
    return "Recipient Address/ENS"
  }

  var displayAddress: String? {
    if self.address == nil { return self.addressString }
    if let contact = KNContactStorage.shared.contacts.first(where: { self.addressString.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.addressString)"
    }
    return self.addressString
  }

  var displayEnsMessage: String? {
    if self.addressString.isEmpty { return nil }
    if self.address == nil { return "Invalid address or your ens is not mapped yet" }
    if Address(string: self.addressString) != nil { return nil }
    let address = self.address?.description ?? ""
    return "\(address.prefix(12))...\(address.suffix(10))"
  }

  var displayEnsMessageColor: UIColor {
    if self.address == nil { return UIColor.Kyber.strawberry }
    return UIColor.Kyber.blueGreen
  }

  var newContactTitle: String {
    let addr = self.address?.description.lowercased() ?? ""
    if KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == addr }) != nil {
      return NSLocalizedString("edit.contact", comment: "")
    }
    return NSLocalizedString("add.contact", comment: "")
  }

  var isAmountTooSmall: Bool {
    if self.from.isETH { return false }
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    let balanceVal = balance?.value ?? BigInt(0)
    return amountBigInt > balanceVal
  }

  var isAmountValid: Bool {
    return !isAmountTooBig && !isAmountTooSmall
  }

  var isAddressValid: Bool {
    return self.address != nil
  }

  var ethFeeBigInt: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.ethFeeBigInt
    if self.from.isETH { fee += self.amountBigInt }
    let eth = KNSupportedTokenStorage.shared.ethToken
    let ethBal = self.balances[eth.contract]?.value ?? BigInt(0)
    return ethBal >= fee
  }

  var unconfirmTransaction: UnconfirmedTransaction {
    let transferType: TransferType = {
      if self.from.isETH {
        return TransferType.ether(destination: self.address)
      }
      return TransferType.token(self.from)
    }()
    let amount: BigInt = {
      if self.from.isETH {
        // eth needs to minus some fee
        if !self.isSendAllBalanace { return self.amountBigInt } // not send all balance
        let balance = self.balance?.value ?? BigInt(0)
        return max(BigInt(0), balance - self.allETHBalanceFee)
      }
      return self.isSendAllBalanace ? (self.balance?.value ?? BigInt(0)) : self.amountBigInt
    }()
    return UnconfirmedTransaction(
      transferType: transferType,
      value: amount,
      to: self.address,
      data: nil,
      gasLimit: self.gasLimit,
      gasPrice: self.gasPrice,
      nonce: .none
    )
  }

  var isNeedUpdateEstFeeForTransferingAllBalance: Bool = false

  // MARK: Update
  func updateSendToken(from token: TokenObject, balance: Balance?) {
    self.from = token.clone()
    self.balance = balance
    self.amount = ""
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: self.from)
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      if let oldBal = self.balance, oldBal.value != bal.value {
        self.isSendAllBalanace = false
      }
      self.balance = bal
    }
  }

  func updateAmount(_ amount: String) {
    self.amount = amount
    self.isSendAllBalanace = false
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: return
    }
  }

  @discardableResult
  func updateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, address: String) -> Bool {
    if self.from == from, self.addressString.lowercased() == address.lowercased() {
      self.gasLimit = gasLimit
      return true
    }
    return false
  }

  func updateAddress(_ address: String) {
    self.addressString = address
    self.address = Address(string: address)
    if self.address != nil {
      self.isUsingEns = false
    }
  }

  func updateAddressFromENS(_ ens: String, ensAddr: Address?) {
    if ens == self.addressString {
      self.address = ensAddr
      self.isUsingEns = ensAddr != nil
    }
  }
}
