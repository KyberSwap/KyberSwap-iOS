// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt

class SpeedUpCustomGasSelectViewModel {
  fileprivate(set) var selectedType: KNSelectedGasPriceType = .superFast
  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var superFast: BigInt = KNGasCoordinator.shared.superFastKNGas
  let transaction: Transaction
  init(transaction: Transaction) {
      self.transaction = transaction
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    let extraGas = KNGasConfiguration.extraGasPromoWallet //TODO: max with current * 1.2
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

  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: "\n\(text)", attributes: feeAttributes))
    return attributedString
  }

  var currentTransactionFeeETHString: String {
    let fee: BigInt? = {
      guard let gasPrice = EtherNumberFormatter.full.number(from: transaction.gasPrice, decimals: 0),
        let gasLimit = EtherNumberFormatter.full.number(from: transaction.gasUsed, decimals: 0)
        else { return nil }
      return gasPrice * gasLimit
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) ETH"
  }

  func getNewTransactionFeeETHString() -> String {
    let fee = getNewTransactionFeeETH()
    let feeString: String = fee.displayRate(decimals: 18)
    return "\(feeString) ETH"
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
      guard let gasLimit = EtherNumberFormatter.full.number(from: transaction.gasUsed, decimals: 0) else { return nil }
      return gasPrice * gasLimit
    }()
    return fee ?? BigInt(0)
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func isNewGasPriceValid() -> Bool {
    let newValue = getNewTransactionGasPriceETH()
    let oldValue = EtherNumberFormatter.full.number(from: transaction.gasPrice, decimals: 0) ?? BigInt(0)
    return newValue > ( oldValue * (BigInt(120) / BigInt (100)) )
  }
}
