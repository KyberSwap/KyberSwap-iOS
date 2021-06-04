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

  var isContractInteraction: Bool {
    guard let notNilTransaction = self.transaction else {
      return false
    }
    if !notNilTransaction.input.isEmpty && notNilTransaction.input != "0x" {
      return true
    }
    return false
  }

  var isError: Bool {
    guard let notNilTransaction = self.transaction else {
      return false
    }
    if notNilTransaction.state == .error || notNilTransaction.state == .failed {
      return true
    }
    return false
  }

  var isSelf: Bool {
    guard let notNilTransaction = self.transaction else {
      return false
    }
    return notNilTransaction.from.lowercased() == notNilTransaction.to.lowercased()
  }

  var displayTxTypeString: String {
    if self.isSelf { return "Self" }
    if self.isContractInteraction && self.isError {
      return "Contract Interaction".toBeLocalised()
    }
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
      return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
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

  var displayTxStatusColor: UIColor {
    guard let state = self.transaction?.state else {
      return UIColor(red: 20, green: 25, blue: 39)
    }
    switch state {
    case .completed:
      return UIColor(red: 0, green: 102, blue: 68)
    case .pending:
      return  UIColor(red: 255, green: 144, blue: 8)
    case .failed, .error:
      return UIColor(red: 250, green: 101, blue: 102)
    default:
      return UIColor(red: 20, green: 25, blue: 39)
    }
  }

  var displayGasPrice: String {
    guard let gasPriceString = self.transaction?.gasPrice, let gasPriceBigNo = EtherNumberFormatter.full.number(from: gasPriceString, units: .wei) else {
      return "---"
    }

    let displayETH = gasPriceBigNo.fullString(decimals: 18)
    let displayGWei = gasPriceBigNo.fullString(units: .gwei)

    return "\(displayETH) \(KNGeneralProvider.shared.quoteToken) (\(displayGWei) Gwei)"
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

  var transactionTypeImage: UIImage {
    let typeImage: UIImage = {
      if self.isSelf { return UIImage(named: "history_send_icon")! }
      if self.isContractInteraction && self.isError { return UIImage(named: "history_contract_interaction_icon")! }
      if self.isSwap { return UIImage() }
      return self.isSent ? UIImage(named: "history_send_icon")! : UIImage(named: "history_receive_icon")!
    }()
    return typeImage
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

protocol TransactionDetailsViewModel {
  var displayTxStatus: String { get }
  var displayTxStatusColor: UIColor { get }
  var displayTxTypeString: String { get }
  var displayDateString: String { get }
  var displayAmountString: String { get }
  var displayFromAddress: String { get }
  var displayToAddress: String { get }
  var displayGasFee: String { get }
  var displayHash: String { get }
  var fromIconSymbol: String { get }
  var toIconSymbol: String { get }
  var fromFieldTitle: String { get }
  var toFieldTitle: String { get }
  var transactionTypeImage: UIImage { get }
}

struct InternalTransactionDetailViewModel: TransactionDetailsViewModel {
  var transactionTypeImage: UIImage {
    switch self.transaction.type {
    case .swap:
      return UIImage()
    case .withdraw:
      return UIImage()
    case .transferETH:
      return UIImage(named: "history_send_icon")!
    case .receiveETH:
      return UIImage(named: "history_receive_icon")!
    case .transferToken:
      return UIImage(named: "history_send_icon")!
    case .receiveToken:
      return UIImage(named: "history_receive_icon")!
    case .allowance:
      return UIImage(named: "history_approve_icon")!
    case .earn:
      return UIImage()
    case .contractInteraction:
      return UIImage(named: "history_contract_interaction_icon")!
    case .selfTransfer:
      return UIImage(named: "history_send_icon")!
    }
  }
  
  var fromIconSymbol: String {
    
    return self.transaction.fromSymbol ?? ""
  }
  
  var toIconSymbol: String {
    return self.transaction.toSymbol ?? ""
  }
  
  var fromFieldTitle: String {
    switch self.transaction.type {
    case .swap:
      return "Wallet".toBeLocalised()
    case .withdraw:
      return "Wallet".toBeLocalised()
    case .transferETH:
      return "Wallet".toBeLocalised()
    case .receiveETH:
      return "From Wallet".toBeLocalised()
    case .transferToken:
      return "Wallet".toBeLocalised()
    case .receiveToken:
      return "From Wallet".toBeLocalised()
    case .allowance:
      return "Wallet".toBeLocalised()
    case .earn:
      return "Wallet".toBeLocalised()
    case .contractInteraction:
      return "Wallet".toBeLocalised()
    case .selfTransfer:
      return "Wallet".toBeLocalised()
    }
  }
  
  var toFieldTitle: String {
    switch self.transaction.type {
    case .swap:
      return "Application".toBeLocalised()
    case .withdraw:
      return "Application".toBeLocalised()
    case .transferETH:
      return "To Wallet".toBeLocalised()
    case .receiveETH:
      return "To Wallet".toBeLocalised()
    case .transferToken:
      return "To Wallet".toBeLocalised()
    case .receiveToken:
      return "To Wallet".toBeLocalised()
    case .allowance:
      return "Application".toBeLocalised()
    case .earn:
      return "Application".toBeLocalised()
    case .contractInteraction:
      return "Application".toBeLocalised()
    case .selfTransfer:
      return "Wallet".toBeLocalised()
    }
  }
  
  let transaction: InternalHistoryTransaction
  let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM dd yyyy, HH:mm:ss ZZZZ"
    return formatter
  }()
  
  var displayTxStatus: String {
    switch self.transaction.state {
    case .pending:
      return "pending".toBeLocalised().uppercased().paddingString()
    case .error, .drop:
      return "failed".toBeLocalised().uppercased().paddingString()
    case .cancel:
      return "cancel".toBeLocalised().uppercased().paddingString()
    case .speedup:
      return "speedup".toBeLocalised().uppercased().paddingString()
    case .done:
      return "mined".toBeLocalised().uppercased().paddingString()
    }
  }
  
  var displayTxStatusColor: UIColor {
    switch self.transaction.state {
    case .pending, .cancel, .speedup:
      return UIColor(red: 255, green: 144, blue: 8)
    case .error, .drop:
      return UIColor.Kyber.SWRed
    case .done:
      return UIColor.Kyber.SWGreen
    }
  }
  
  var displayTxTypeString: String {
    switch self.transaction.type {
    case .swap:
      return "swap".toBeLocalised().uppercased()
    case .withdraw:
      return "withdraw".toBeLocalised().uppercased()
    case .transferETH, .transferToken:
      return "transfer".toBeLocalised().uppercased()
    case .receiveETH, .receiveToken:
      return "receive".toBeLocalised().uppercased()
    case .allowance:
      return "allowance".toBeLocalised().uppercased()
    case .earn:
      return "trade".toBeLocalised().uppercased()
    case .contractInteraction:
      return ""
    case .selfTransfer:
      return "self".toBeLocalised().uppercased()
    }
  }
  
  var displayDateString: String {
    return self.dateFormatter.string(from: self.transaction.time)
  }
  
  var displayAmountString: String {
    return self.transaction.transactionDescription
  }
  
  var displayFromAddress: String {
    return self.transaction.transactionObject.from
  }
  
  var displayToAddress: String {
    return self.transaction.transactionObject.to ?? ""
  }
  
  var displayGasFee: String {
    guard let gasPrice = BigInt(self.transaction.transactionObject.gasPrice), let gasLimit = BigInt(self.transaction.transactionObject.gasLimit) else {
      return ""
    }
    let fee = gasPrice * gasLimit
    return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
  }
  
  var displayHash: String {
    return self.transaction.hash
  }
}

struct EtherscanTransactionDetailViewModel: TransactionDetailsViewModel {

  let data: CompletedHistoryTransactonViewModel

  let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM dd yyyy, HH:mm:ss ZZZZ"
    return formatter
  }()

  var fromIconSymbol: String {
    return self.data.fromIconSymbol
  }

  var toIconSymbol: String {
    return self.data.toIconSymbol
  }
  
  var fromFieldTitle: String {
    switch self.data.data.type {
    case .swap:
      return "Wallet".toBeLocalised()
    case .withdraw:
      return "Wallet".toBeLocalised()
    case .transferETH:
      return "Wallet".toBeLocalised()
    case .receiveETH:
      return "From Wallet".toBeLocalised()
    case .transferToken:
      return "Wallet".toBeLocalised()
    case .receiveToken:
      return "From Wallet".toBeLocalised()
    case .allowance:
      return "Wallet".toBeLocalised()
    case .earn:
      return "Wallet".toBeLocalised()
    case .contractInteraction:
      return "Wallet".toBeLocalised()
    case .selfTransfer:
      return "Wallet".toBeLocalised()
    }
  }
  
  var toFieldTitle: String {
    switch self.data.data.type {
    case .swap:
      return "Application".toBeLocalised()
    case .withdraw:
      return "Application".toBeLocalised()
    case .transferETH:
      return "To Wallet".toBeLocalised()
    case .receiveETH:
      return "To Wallet".toBeLocalised()
    case .transferToken:
      return "To Wallet".toBeLocalised()
    case .receiveToken:
      return "To Wallet".toBeLocalised()
    case .allowance:
      return "Application".toBeLocalised()
    case .earn:
      return "Application".toBeLocalised()
    case .contractInteraction:
      return "Application".toBeLocalised()
    case .selfTransfer:
      return "Wallet".toBeLocalised()
    }
  }
  
  var transactionTypeImage: UIImage {
    return self.data.transactionTypeImage
  }

  var displayTxStatus: String {
    return self.data.isError ? "Failed".toBeLocalised().paddingString() : "Success".toBeLocalised().paddingString()
  }

  var displayTxStatusColor: UIColor {
    return self.data.isError ? UIColor.Kyber.SWRed : UIColor.Kyber.SWGreen
  }

  var displayTxTypeString: String {
    return self.data.transactionTypeString
  }

  var displayDateString: String {
    let date = Date(timeIntervalSince1970: Double(self.data.data.timestamp) ?? 0)
    return self.dateFormatter.string(from: date)
  }

  var displayAmountString: String {
    return self.data.displayedAmountString
  }
  
  var displayFromAddress: String {
    if let transaction = self.data.data.transacton.first {
      return transaction.from
    } else if let internalTx = self.data.data.internalTransactions.first {
      return internalTx.from
    } else if let tokenTx = self.data.data.tokenTransactions.first {
      return tokenTx.from
    }
    return "---"
  }
  
  var displayToAddress: String {
    if let transaction = self.data.data.transacton.first {
      return transaction.to
    } else if let internalTx = self.data.data.internalTransactions.first {
      return internalTx.to
    } else if let tokenTx = self.data.data.tokenTransactions.first {
      return tokenTx.to
    }
    return "---"
  }

  var displayGasFee: String {
    if let transaction = self.data.data.transacton.first {
      let gasPrice = BigInt(transaction.gasPrice) ?? BigInt(0)
      let gasLimit = BigInt(transaction.gasUsed) ?? BigInt(0)
      let fee = gasPrice * gasLimit
      return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
    } else if let tokenTx = self.data.data.tokenTransactions.first {
      let gasPrice = BigInt(tokenTx.gasPrice) ?? BigInt(0)
      let gasLimit = BigInt(tokenTx.gasUsed) ?? BigInt(0)
      let fee = gasPrice * gasLimit
      return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken)"
    } else {
      return "---"
    }
  }

  var displayHash: String {
    if let transaction = self.data.data.transacton.first {
      return transaction.hash
    } else if let internalTx = self.data.data.internalTransactions.first {
      return internalTx.hash
    } else if let tokenTx = self.data.data.tokenTransactions.first {
      return tokenTx.hash
    }
    return "---"
  }
}
