// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

class SpeedUpCustomGasSelectViewModel {
  fileprivate(set) var selectedType: KNSelectedGasPriceType = .superFast
  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var superFast: BigInt = KNGasCoordinator.shared.superFastKNGas
  let transaction: InternalHistoryTransaction
  init(transaction: InternalHistoryTransaction) {
      self.transaction = transaction
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    let extraGas = KNGasConfiguration.extraGasPromoWallet
    self.fast = fast + extraGas
    self.medium = medium
    self.slow = slow
    self.superFast = superFast
  }

  var fastGasString: NSAttributedString {
    return self.attributedString(
      for: self.fast,
      text: NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    )
  }

  var mediumGasString: NSAttributedString {
    return self.attributedString(
      for: self.medium,
      text: NSLocalizedString("regular", value: "Regular", comment: "").uppercased()
    )
  }

  var slowGasString: NSAttributedString {
    return self.attributedString(
      for: self.slow,
      text: NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
    )
  }

  var superFastGasString: NSAttributedString {
    return self.attributedString(
      for: self.superFast,
      text: NSLocalizedString("super.fast", value: "Super Fast", comment: "").uppercased()
    )
  }

  var estimateFeeSuperFastString: String {
    return self.formatFeeStringFor(gasPrice: self.superFast)
  }

  var estimateFeeFastString: String {
    return self.formatFeeStringFor(gasPrice: self.fast)
  }

  var estimateRegularFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.medium)
  }

  var estimateSlowFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.slow)
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee: BigInt? = {
      guard let gasLimit = BigInt(self.transaction.transactionObject.gasLimit)
        else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "~ \(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      NSAttributedStringKey.font: UIFont.Kyber.latoBold(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 10),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: " \(text)", attributes: feeAttributes))
    return attributedString
  }

  var currentTransactionFeeETHString: String {
    let fee: BigInt? = {
      guard let gasPrice = BigInt(self.transaction.transactionObject.gasPrice),
        let gasLimit = BigInt(self.transaction.transactionObject.gasLimit)
        else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getNewTransactionFeeETHString() -> String {
    let fee = getNewTransactionFeeETH()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }

  func getNewTransactionGasPriceETH() -> BigInt { //TODO: check again formular 1.2 * current
    let gasPrice: BigInt = {
      switch selectedType {
      case .fast: return fast
      case .medium: return medium
      case .slow: return slow
      case .superFast: return superFast
      default: return BigInt(0)
      }
    }()
    return gasPrice
  }

  func getNewTransactionFeeETH() -> BigInt {
    let gasPrice = getNewTransactionGasPriceETH()
    let fee: BigInt? = {
      guard let gasLimit = BigInt(self.transaction.transactionObject.gasLimit) else { return nil }
      return gasPrice * gasLimit
    }()
    return fee ?? BigInt(0)
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func isNewGasPriceValid() -> Bool {
    let newValue = getNewTransactionGasPriceETH()
    let oldValue = BigInt(self.transaction.transactionObject.gasPrice) ?? BigInt(0)
    return newValue > ( oldValue * BigInt(11) / BigInt (10) )
  }
}
