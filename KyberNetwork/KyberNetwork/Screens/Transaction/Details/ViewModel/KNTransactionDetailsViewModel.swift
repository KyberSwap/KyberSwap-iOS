// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

struct KNTransactionDetailsViewModel {

  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM dd yyyy, HH:mm:ss ZZZZ"
    return formatter
  }()

  fileprivate(set) var transaction: Transaction?
  fileprivate(set) var currentWallet: KNWalletObject

  init(
    transaction: Transaction?,
    currentWallet: KNWalletObject
    ) {
    self.transaction = transaction
    self.currentWallet = currentWallet
  }

  var isSwap: Bool {
    return self.transaction?.localizedOperations.first?.type == "exchange"
  }

  var isSent: Bool {
    guard let transaction = self.transaction, !self.isSwap else { return false }
    return transaction.from.lowercased() == self.currentWallet.address.lowercased()
  }

  var displayTxTypeString: String {
    if self.isSwap {
      return NSLocalizedString("swap", value: "Swap", comment: "").uppercased()
    }
    if self.isSent {
      return NSLocalizedString("transfer", value: "Transfer", comment: "").uppercased()
    }
    return NSLocalizedString("receive", value: "Receive", comment: "").uppercased()
  }

  var displayedAmountString: String {
    return self.transaction?.displayedAmountStringDetailsView(curWallet: self.currentWallet.address) ?? ""
  }

  var displayFee: String? {
    if let fee = self.transaction?.feeBigInt {
      return "\(fee.displayRate(decimals: 18)) ETH"
    }
    return nil
  }

  var displayNonce: String? {
    return self.transaction?.nonce
  }

  var displayTxStatus: String {
    guard let state = self.transaction?.state else { return "  ---  " }
    var statusString = ""
    switch state {
    case .completed:
      statusString = "mined".toBeLocalised().uppercased()
    case .pending:
      statusString = "pending".toBeLocalised().uppercased()
    case .failed, .error:
      statusString = "failed".toBeLocalised().uppercased()
    default:
      statusString = "---"
    }
    return "  \(statusString)  "
  }

  var displayTxStatusColor: (UIColor, UIColor) {
    guard let state = self.transaction?.state else {
      return (UIColor(red: 236, green: 235, blue: 235), UIColor(red: 20, green: 25, blue: 39))
    }
    switch state {
    case .completed:
      return (UIColor(red: 212, green: 254, blue: 229), UIColor(red: 0, green: 102, blue: 68))
    case .pending:
      return (UIColor(red: 255, green: 236, blue: 213), UIColor(red: 255, green: 144, blue: 8))
    case .failed, .error:
      return (UIColor(red: 255, green: 234, blue: 234), UIColor(red: 250, green: 101, blue: 102))
    default:
      return (UIColor(red: 236, green: 235, blue: 235), UIColor(red: 20, green: 25, blue: 39))
    }
  }

  var displayGasPrice: String {
    guard let gasPriceString = self.transaction?.gasPrice, let gasPriceBigNo = EtherNumberFormatter.full.number(from: gasPriceString, units: .wei) else {
      return "---"
    }

    let displayETH = gasPriceBigNo.fullString(decimals: 18)
    let displayGWei = gasPriceBigNo.fullString(units: .gwei)

    return "\(displayETH) ETH (\(displayGWei) Gwei)"
  }

  var displayRateTextString: String {
    if let symbols = self.transaction?.getTokenPair() {
      if symbols.0.isEmpty || symbols.1.isEmpty { return "" }
      return NSLocalizedString("rate", value: "Rate", comment: "") + " \(symbols.0)/\(symbols.1)"
    }
    return ""
  }

  var displayExchangeRate: String? { return self.transaction?.exchangeRateDisplay }

  lazy var textAttachment: NSTextAttachment = {
    let attachment = NSTextAttachment()
    attachment.image = UIImage(named: "copy_icon")
    return attachment
  }()

  lazy var textAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.kern: 0.0,
  ]

  var addressTextDisplay: String? {
    if self.isSwap { return nil }
    if self.isSent { return NSLocalizedString("to", value: "To", comment: "") }
    return NSLocalizedString("from", value: "From", comment: "")
  }

  mutating func addressAttributedString() -> NSAttributedString {
    if self.isSwap { return NSMutableAttributedString() }
    if self.isSent { return self.toAttributedString() }
    return self.fromAttributedString()
  }

  mutating func fromAttributedString() -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(transaction?.from ?? "")  ", attributes: textAttributes))
    attributedString.append(NSAttributedString(attachment: textAttachment))
    return attributedString
  }

  mutating func toAttributedString() -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(transaction?.to ?? "")  ", attributes: textAttributes))
    attributedString.append(NSAttributedString(attachment: textAttachment))
    return attributedString
  }

  mutating func txHashAttributedString() -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(transaction?.id ?? "")  ", attributes: textAttributes))
    attributedString.append(NSAttributedString(attachment: textAttachment))
    return attributedString
  }

  mutating func dateString() -> String {
    guard let date = self.transaction?.date else { return "" }
    return self.dateFormatter.string(from: date)
  }

  mutating func update(transaction: Transaction, currentWallet: KNWalletObject) {
    self.transaction = transaction
    self.currentWallet = currentWallet
  }
}
