// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class NumberFormatterUtil {

  static let shared = NumberFormatterUtil()

  lazy var percentageFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter
  }()

  lazy var alertPriceFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 9
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var swapAmountFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 6
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var limitOrderFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 6
    formatter.minimumFractionDigits = 0
    return formatter
  }()

  lazy var doubleFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = NumberFormatter.Style.decimal
    formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
    formatter.maximumFractionDigits = 4
    return formatter
  }()

  func displayPercentage(from number: Double) -> String {
    return self.percentageFormatter.string(from: NSNumber(value: number)) ?? "0.00"
  }

  func displayAlertPrice(from number: Double) -> String {
    let string = self.alertPriceFormatter.string(from: NSNumber(value: number)) ?? "0.00"
    if number < 1 { return string }
    return "\(string.prefix(11))"
  }

  func displayLimitOrderValue(from number: Double) -> String {
    let string = self.limitOrderFormatter.string(from: NSNumber(value: number)) ?? "0.00"
    if number < 1 { return string }
    return "\(string.prefix(10))"
  }
}
