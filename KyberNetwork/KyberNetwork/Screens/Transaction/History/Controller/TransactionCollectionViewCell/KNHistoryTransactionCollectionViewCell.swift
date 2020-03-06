// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit

protocol KNHistoryTransactionCollectionViewCellDelegate: class {
  func historyTransactionCollectionViewCell(_ cell: KNHistoryTransactionCollectionViewCell, openDetails transaction: Transaction)
}

struct KNHistoryTransactionCollectionViewModel {
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

  var backgroundColor: UIColor { return self.index % 2 == 0 ? UIColor.white : UIColor(red: 246, green: 247, blue: 250) }

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

  var transactionStatusString: String {
    if isError { return NSLocalizedString("failed", value: "Failed", comment: "") }
    return ""
  }

  var transactionTypeString: String {
    let typeString: String = {
      if self.isSwap { return NSLocalizedString("swap", value: "Swap", comment: "") }
      return self.isSent ? NSLocalizedString("transfer", value: "Transfer", comment: "") : NSLocalizedString("receive", value: "Receive", comment: "")
    }()
    return typeString
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

  var displayedAmountColorHex: String {
    if self.isSwap { return "F89F50" }
    return self.isSent ? "f87171" : "31cb9e"
  }
}

class KNHistoryTransactionCollectionViewCell: SwipeCollectionViewCell {

  static let cellID: String = "kHistoryTransactionCellID"
  static let height: CGFloat = 60.0

  weak var actionDelegate: KNHistoryTransactionCollectionViewCellDelegate?
  fileprivate var viewModel: KNHistoryTransactionCollectionViewModel!

  @IBOutlet weak var transactionAmountLabel: UILabel!
  @IBOutlet weak var transactionDetailsLabel: UILabel!
  @IBOutlet weak var transactionTypeLabel: UILabel!
  @IBOutlet weak var transactionStatus: UIButton!

  override func awakeFromNib() {
    super.awakeFromNib()
    // reset data
    self.transactionAmountLabel.text = ""
    self.transactionDetailsLabel.text = ""
    self.transactionTypeLabel.text = ""
    self.transactionStatus.rounded(radius: 10.0)
  }

  func updateCell(with model: KNHistoryTransactionCollectionViewModel) {
    self.viewModel = model
    self.backgroundColor = model.backgroundColor
    self.transactionAmountLabel.text = model.displayedAmountString
    self.transactionDetailsLabel.text = model.transactionDetailsString
    self.transactionTypeLabel.text = model.transactionTypeString.uppercased()
    self.transactionStatus.setTitle(model.transactionStatusString, for: .normal)
    self.transactionStatus.isHidden = !model.isError
    self.layoutIfNeeded()
  }
}
