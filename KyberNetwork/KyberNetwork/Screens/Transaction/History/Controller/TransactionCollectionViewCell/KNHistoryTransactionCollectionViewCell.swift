// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import BigInt


protocol AbstractHistoryTransactionViewModel: class {
  var index: Int { get }
  var fromIconSymbol: String { get }
  var toIconSymbol: String { get }
  var backgroundColor: UIColor { get }
  var displayedAmountString: String { get }
  var transactionDetailsString: String { get }
  var transactionTypeString: String { get }
  var isError: Bool { get }
  var transactionTypeImage: UIImage { get }
  var displayTime: String { get }
}

class CompletedHistoryTransactonViewModel: AbstractHistoryTransactionViewModel {
  let index: Int
  
  var fromIconSymbol: String {
    guard self.data.type == .swap || self.data.type == .earn || self.data.type == .withdraw else {
      return ""
    }
    
    if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
      return transaction.from.lowercased() == self.data.wallet
    } {
      return outTx.tokenSymbol
    }
     
    return KNGeneralProvider.shared.quoteToken
  }
  
  var toIconSymbol: String {
    guard self.data.type == .swap || self.data.type == .earn || self.data.type == .withdraw else {
      return ""
    }
    
    if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      return KNGeneralProvider.shared.quoteToken
    }
    
    if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      return inTx.tokenSymbol
    }
    return ""
  }
  
  var backgroundColor: UIColor {
//    return self.index % 2 == 0 ? UIColor(red: 0, green: 50, blue: 67) : UIColor(red: 1, green: 40, blue: 53)
    return UIColor(named: "mainViewBgColor")!
  }
  
  func generateSwapAmountString() -> String {
    var result = ""
    if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
      return transaction.from.lowercased() == self.data.wallet
    } {
      let valueBigInt = BigInt(outTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: Int(outTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: Int(outTx.tokenDecimal) ?? 6)
      result += "\(valueString) \(outTx.tokenSymbol) -> "
    } else if let sendEthTx = self.data.transacton.first {
      let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(KNGeneralProvider.shared.quoteToken) -> "
    }
    
    if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: Int(inTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: Int(inTx.tokenDecimal) ?? 6)
      result += "\(valueString) \(inTx.tokenSymbol)"
    }
    
    if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
      return transaction.to.lowercased() == self.data.wallet
    }) {
      let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
      let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
      result += "\(valueString) \(KNGeneralProvider.shared.quoteToken)"
    }

    return result
  }

  var displayedAmountString: String {
    switch self.data.type {
    case .swap:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .withdraw:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .transferETH:
      if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    case .receiveETH:
      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "+ \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      } else if let receiveEthTx = self.data.transacton.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "+ \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    case .transferToken:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        let valueBigInt = BigInt(outTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: Int(outTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: Int(outTx.tokenDecimal) ?? 6)
        return "- \(valueString) \(outTx.tokenSymbol)"
      }
      return ""
    case .receiveToken:
      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: Int(inTx.tokenDecimal) ?? 18, minFractionDigits: 0, maxFractionDigits: Int(inTx.tokenDecimal) ?? 6)
        return "+ \(valueString) \(inTx.tokenSymbol)"
      }
      return ""
    case .allowance:
      if let tx = self.data.transacton.first  {
        let address = tx.to
        if address == Constants.gasTokenAddress {
          return "CHI"
        } else if let token = KNSupportedTokenStorage.shared.getTokenWith(address: address) {
          return token.name
        }
      }
      return "Token"
    case .earn:
      if self.isError {
        return "--/--"
      }
      return self.generateSwapAmountString()
    case .contractInteraction:
      return "--/--"
    case .selfTransfer:
      if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        let valueString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
        return "- \(valueString) \(KNGeneralProvider.shared.quoteToken)"
      }
      return ""
    }
  }
  
  var transactionDetailsString: String {
    switch self.data.type {
    case .swap:
      guard self.data.transacton.first?.isError != "1" else {
        return ""
      }
      var fromValue = BigInt.zero
      var toValue = BigInt.zero
      var fromSymbol = ""
      var toSymbol = ""
      var fromDecimal = 0
      var toDecimal = 0
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        let valueBigInt = BigInt(outTx.value) ?? BigInt(0)
        fromValue = valueBigInt
        fromSymbol = outTx.tokenSymbol
        fromDecimal = Int(outTx.tokenDecimal) ?? 0
        
      } else if let sendEthTx = self.data.transacton.first {
        let valueBigInt = BigInt(sendEthTx.value) ?? BigInt(0)
        fromValue = valueBigInt
        fromSymbol = KNGeneralProvider.shared.quoteToken
        fromDecimal = 18
      }
      
      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(inTx.value) ?? BigInt(0)
        toValue = valueBigInt
        toSymbol = inTx.tokenSymbol
        toDecimal = Int(inTx.tokenDecimal) ?? 0
      }
      
      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        let valueBigInt = BigInt(receiveEthTx.value) ?? BigInt(0)
        toValue = valueBigInt
        toSymbol = KNGeneralProvider.shared.quoteToken
        toDecimal = 18
      }
      guard !toSymbol.isEmpty, !fromSymbol.isEmpty else {
        return ""
      }
      let amountFrom = fromValue * BigInt(10).power(18) / BigInt(10).power(fromDecimal)
      let amountTo = toValue * BigInt(10).power(18) / BigInt(10).power(toDecimal)
      let rate = amountTo * BigInt(10).power(18) / amountFrom
      let rateString = rate.displayRate(decimals: 18)
      return "1 \(fromSymbol) = \(rateString) \(toSymbol)"
    case .withdraw:
      return ""
    case .transferETH:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        return "To: \(outTx.to)"
      }
      return ""
    case .receiveETH:
      if let receiveEthTx = self.data.internalTransactions.first(where: { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      }) {
        return "From: \(receiveEthTx.from)"
      }
      return ""
    case .transferToken:
      if let outTx = self.data.tokenTransactions.first { (transaction) -> Bool in
        return transaction.from.lowercased() == self.data.wallet
      } {
        return "To: \(outTx.to)"
      }
      return ""
    case .receiveToken:
      if let inTx = self.data.tokenTransactions.first(where: { (transaction) -> Bool in
        return transaction.to.lowercased() == self.data.wallet
      }) {
        return "From: \(inTx.from)"
      }
      return ""
    case .allowance:
      return self.data.transacton.first?.to ?? ""
    case .earn:
      return ""
    case .contractInteraction:
      return self.data.transacton.first?.to ?? ""
    case .selfTransfer:
      return ""
    }
  }
  
  var transactionTypeString: String {
    switch self.data.type {
    case .swap:
      return "SWAP"
    case .withdraw:
      return "WITHDRAWAL"
    case .transferETH:
      return "TRANSFER"
    case .receiveETH:
      return "RECEIVED"
    case .transferToken:
      return "TRANSFER"
    case .receiveToken:
      return "RECEIVED"
    case .allowance:
      return "APPROVED"
    case .earn:
      return "SUPPLY"
    case .contractInteraction:
      return "CONTRACT INTERACT"
    case .selfTransfer:
      return "SELF"
    }
  }

  var isError: Bool {
    if let transaction = self.data.transacton.first {
      return transaction.isError != "0"
    } else if let internalTx = self.data.internalTransactions.first {
      return internalTx.isError != "0"
    } else {
      return false
    }
  }

  var transactionTypeImage: UIImage {
    switch self.data.type {
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

  var displayTime: String {
    return self.dateStringFromTimeStamp(self.data.timestamp)
  }

  func dateStringFromTimeStamp(_ ts: String) -> String {
    let date = Date(timeIntervalSince1970: Double(ts) ?? 0)
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: date)
  }
  
  let data: HistoryTransaction
  
  init(data: HistoryTransaction, index: Int) {
    self.data = data
    self.index = index
  }
}

class PendingInternalHistoryTransactonViewModel: AbstractHistoryTransactionViewModel {
  var index: Int
  
  let internalTransaction: InternalHistoryTransaction
  
  var fromIconSymbol: String {
    return self.internalTransaction.fromSymbol ?? ""
  }
  
  var toIconSymbol: String {
    return self.internalTransaction.toSymbol ?? ""
  }
  
  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? UIColor(red: 0, green: 50, blue: 67) : UIColor(red: 1, green: 40, blue: 53)
  }
  
  var displayedAmountString: String {
    return self.internalTransaction.transactionDescription
  }
  
  var transactionDetailsString: String {
    return self.internalTransaction.transactionDetailDescription
  }
  
  var transactionTypeString: String {
    guard self.internalTransaction.state == .pending else {
      switch self.internalTransaction.state {
      case .speedup:
        return "SPEED UP"
      case .cancel:
        return "CANCEL"
      default:
        return ""
      }
    }
    
    switch self.internalTransaction.type {
    case .swap:
      return "SWAP"
    case .withdraw:
      return "WITHDRAWAL"
    case .transferETH:
      return "TRANSFER"
    case .receiveETH:
      return "RECEIVE"
    case .transferToken:
      return "TRANSFER"
    case .receiveToken:
      return "RECEIVE"
    case .allowance:
      return "APPROVE"
    case .earn:
      return "SUPPLY"
    case .contractInteraction:
      return "CONTRACT INTERACT"
    case .selfTransfer:
      return "SELF"
    }
  }

  var isError: Bool {
    return false
  }

  var transactionTypeImage: UIImage {
    switch self.internalTransaction.type {
    case .swap:
      return UIImage()
    case .withdraw:
      return UIImage(named: "history_approve_icon")!
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
      return UIImage(named: "history_approve_icon")!
    case .contractInteraction:
      return UIImage(named: "history_contract_interaction_icon")!
    case .selfTransfer:
      return UIImage(named: "history_send_icon")!
    }
  }

  var displayTime: String {
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: self.internalTransaction.time)
  }

  init(index: Int, transaction: InternalHistoryTransaction) {
    self.index = index
    self.internalTransaction = transaction
  }
}

class PendingHistoryTransactonViewModel: AbstractHistoryTransactionViewModel {
  let index: Int
  let transaction: Transaction
  let ownerAddress: String
  let ownerWalletName: String

  init(
    transaction: Transaction,
    ownerAddress: String,
    ownerWalletName: String,
    index: Int
    ) {
    self.transaction = transaction
    self.ownerAddress = ownerAddress
    self.ownerWalletName = ownerWalletName
    self.index = index
  }

  var backgroundColor: UIColor { return self.index % 2 == 0 ? UIColor(red: 0, green: 50, blue: 67) : UIColor(red: 1, green: 40, blue: 53) }

  var isSwap: Bool { return self.transaction.localizedOperations.first?.type == "exchange" }
  var isSent: Bool {
    if self.isSwap { return false }
    return self.transaction.from.lowercased() == self.ownerAddress.lowercased()
  }

  var isAmountTransactionHidden: Bool {
    return self.transaction.state == .error || self.transaction.state == .failed
  }

  var isError: Bool {
    if self.transaction.state == .error || self.transaction.state == .failed {
      return true
    }
    return false
  }

  var isContractInteraction: Bool {
    if !self.transaction.input.isEmpty && self.transaction.input != "0x" {
      return true
    }
    return false
  }

  var isSelf: Bool {
    return self.transaction.from.lowercased() == self.transaction.to.lowercased()
  }

  var transactionStatusString: String {
    if isError { return NSLocalizedString("failed", value: "Failed", comment: "") }
    return ""
  }

  var transactionTypeString: String {
    let typeString: String = {
      if self.isSelf { return "Self" }
      if self.isContractInteraction && self.isError { return "Contract Interaction".toBeLocalised() }
      if self.isSwap { return NSLocalizedString("swap", value: "Swap", comment: "") }
      return self.isSent ? NSLocalizedString("transfer", value: "Transfer", comment: "") : NSLocalizedString("receive", value: "Receive", comment: "")
    }()
    return typeString
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

  var transactionDetailsString: String {
    if self.isSwap { return self.displayedExchangeRate ?? "" }
    if self.isSent {
      return NSLocalizedString("To", value: "To", comment: "") + ": \(self.transaction.to.prefix(12))...\(self.transaction.to.suffix(8))"
    }
    return NSLocalizedString("From", value: "From", comment: "") + ": \(self.transaction.from.prefix(12))...\(self.transaction.from.suffix(8))"
  }

  let normalTextAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor(red: 182, green: 186, blue: 185),
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.kern: 0.0,
  ]

  let highlightedTextAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.kern: 0.0,
  ]

  var descriptionLabelAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    if self.isSwap {
      let name: String = self.ownerWalletName.formatName(maxLen: 10)
      attributedString.append(NSAttributedString(string: name, attributes: highlightedTextAttributes))
      attributedString.append(NSAttributedString(string: "\n\(self.ownerAddress.prefix(6))....\(self.ownerAddress.suffix(4))", attributes: normalTextAttributes))
      return attributedString
    }

    let fromText: String = {
      if self.isSent { return self.ownerWalletName }
      return "\(self.transaction.from.prefix(8))....\(self.transaction.from.suffix(6))"
    }()
    let toText: String = {
      if self.isSent {
        return "\(self.transaction.to.prefix(8))....\(self.transaction.to.suffix(6))"
      }
      return self.ownerWalletName.formatName(maxLen: 32)
    }()
    attributedString.append(NSAttributedString(string: "\(NSLocalizedString("from", value: "From", comment: "")) ", attributes: normalTextAttributes))
    attributedString.append(NSAttributedString(string: fromText, attributes: highlightedTextAttributes))
    attributedString.append(NSAttributedString(string: "\n\(NSLocalizedString("to", value: "To", comment: "")) ", attributes: normalTextAttributes))
    attributedString.append(NSAttributedString(string: toText, attributes: highlightedTextAttributes))
    return attributedString
  }

  var displayedAmountString: String {
    return self.transaction.displayedAmountString(curWallet: self.ownerAddress)
  }

  var displayedExchangeRate: String? {
    return self.transaction.displayedExchangeRate
  }

  var fromIconSymbol: String {
    guard let from = self.transaction.localizedOperations.first?.from, let fromToken = KNSupportedTokenStorage.shared.getTokenWith(address: from) else {
      return ""
    }
    return fromToken.symbol
  }

  var toIconSymbol: String {
    guard let to = self.transaction.localizedOperations.first?.to, let toToken = KNSupportedTokenStorage.shared.getTokenWith(address: to) else {
      return ""
    }
    return toToken.symbol
  }
  
  var displayTime: String {
    return ""
  }
}

class KNHistoryTransactionCollectionViewCell: SwipeCollectionViewCell {

  static let cellID: String = "kHistoryTransactionCellID"
  static let height: CGFloat = 68.0

  fileprivate var viewModel: AbstractHistoryTransactionViewModel!

  @IBOutlet weak var transactionAmountLabel: UILabel!
  @IBOutlet weak var transactionDetailsLabel: UILabel!
  @IBOutlet weak var transactionTypeLabel: UILabel!
  @IBOutlet weak var transactionStatus: UIButton!
  @IBOutlet weak var historyTypeImage: UIImageView!
  @IBOutlet weak var fromIconImage: UIImageView!
  @IBOutlet weak var toIconImage: UIImageView!
  @IBOutlet weak var dateTimeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // reset data
    self.transactionAmountLabel.text = ""
    self.transactionDetailsLabel.text = ""
    self.transactionTypeLabel.text = ""
    self.transactionStatus.rounded(radius: 10.0)
  }

  func updateCell(with model: AbstractHistoryTransactionViewModel) {
    self.viewModel = model
    let hasFromToIcon = !self.viewModel.fromIconSymbol.isEmpty && !self.viewModel.toIconSymbol.isEmpty
    self.transactionAmountLabel.text = model.displayedAmountString
    self.transactionDetailsLabel.text = model.transactionDetailsString
    self.transactionTypeLabel.text = model.transactionTypeString.uppercased()
    self.transactionStatus.rounded(color: UIColor.Kyber.SWRed, width: 1, radius: 3)
    self.transactionStatus.setTitleColor(UIColor.Kyber.SWRed, for: .normal)
    self.transactionStatus.setTitle(model.isError ? "failed" : "", for: .normal)
    self.transactionStatus.isHidden = !model.isError
    self.hideSwapIcon(!hasFromToIcon)
    self.historyTypeImage.isHidden = hasFromToIcon
    if hasFromToIcon {
      self.fromIconImage.setSymbolImage(symbol: self.viewModel.fromIconSymbol, size: self.toIconImage.frame.size)
      self.toIconImage.setSymbolImage(symbol: self.viewModel.toIconSymbol, size: self.toIconImage.frame.size)
    } else {
      self.historyTypeImage.image = model.transactionTypeImage
    }
    self.dateTimeLabel.text = model.displayTime
    self.layoutIfNeeded()
  }

  fileprivate func hideSwapIcon(_ hidden: Bool) {
    self.fromIconImage.isHidden = hidden
    self.toIconImage.isHidden = hidden
  }
}
