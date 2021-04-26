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

  fileprivate(set) var amount: String = ""
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.transferETHGasLimitDefault

  fileprivate(set) var addressString: String = ""
  fileprivate(set) var isUsingEns: Bool = false
  var isSendAllBalanace: Bool = false

  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var allTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.from.getBalanceBigInt()
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
//    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.from) {
//      return usdRate.rate * self.amountBigInt / BigInt(10).power(self.from.decimals)
//    }
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.from.address) else { return nil }
    
    return self.amountBigInt * BigInt(tokenPrice.usd * pow(10.0, 18.0)) / BigInt(10).power(self.from.decimals)
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var amountTextColor: UIColor {
    return isAmountValid ? UIColor.white : UIColor.red
  }

  var address: Address?

  var currentWalletAddress: String

  init(from: TokenObject, balances: [String: Balance], currentAddress: String) {
    self.from = from.clone()
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: from)
    self.currentWalletAddress = currentAddress
  }

  var navTitle: String {
    return "transfer".toBeLocalised().uppercased()
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

  var tokenButtonText: String {
    return String(self.from.symbol.prefix(8))
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    var typeString = ""
    switch self.selectedGasPriceType {
    case .superFast:
      typeString = "super.fast".toBeLocalised().uppercased()
    case .fast:
      typeString = "fast".toBeLocalised().uppercased()
    case .medium:
      typeString = "regular".toBeLocalised().uppercased()
    case .slow:
      typeString = "slow".toBeLocalised().uppercased()
    default:
      break
    }
    return "Gas fee: \(feeString) ETH (\(typeString))"
  }

  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }

  var balanceText: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol.prefix(8)) \(balanceText)".uppercased()
  }

  var displayBalance: String {
    let string = self.from.getBalanceBigInt().string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(15))"
  }

  var totalBalanceText: String {
    return "\(self.displayBalance) \(self.from.symbol)"
  }

  var placeHolderEnterAddress: NSAttributedString {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 66, green: 87, blue: 95),
    ]
    return NSAttributedString(string: "Recipient Address/ENS", attributes: attributes)
  }

  var placeHolderAmount: NSAttributedString {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 66, green: 87, blue: 95),
    ]
    return NSAttributedString(string: "0", attributes: attributes)
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
    let balanceVal = self.from.getBalanceBigInt()
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
    let ethBal = BalanceStorage.shared.getBalanceETHBigInt()
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
        let balance = self.from.getBalanceBigInt()
        return max(BigInt(0), balance - self.allETHBalanceFee)
      }
      return self.isSendAllBalanace ? self.from.getBalanceBigInt() : self.amountBigInt
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
    self.amount = ""
    self.isSendAllBalanace = false
    self.gasLimit = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: self.from)
  }

  func updateBalance(_ balances: [String: Balance]) {
  }

  func updateAmount(_ amount: String, forSendAllETH: Bool = false) {
    self.amount = amount
    guard !forSendAllETH else {
      return
    }
    self.isSendAllBalanace = false
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
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
