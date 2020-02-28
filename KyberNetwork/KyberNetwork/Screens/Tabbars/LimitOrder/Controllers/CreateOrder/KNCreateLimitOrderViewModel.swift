// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

// swiftlint:disable file_length
class KNCreateLimitOrderViewModel {

  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken
  let weth = KNSupportedTokenStorage.shared.wethToken

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject
  fileprivate(set) var nonce: String?

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?
  fileprivate(set) var pendingBalances: JSONDictionary = [:]

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var targetRate: String = ""

  fileprivate(set) var rateFromNode: BigInt?
  fileprivate(set) var cachedProdRate: BigInt?

  fileprivate(set) var prevFocusTextFieldTag: Int = 2
  fileprivate(set) var focusTextFieldTag: Int = 2

  fileprivate(set) var relatedOrders: [KNOrderObject] = []
  fileprivate(set) var cancelSuggestOrders: [KNOrderObject] = []
  fileprivate(set) var relatedHeaders: [String] = []
  fileprivate(set) var relatedSections: [String: [KNOrderObject]] = [:]
  fileprivate(set) var cancelSuggestHeaders: [String] = []
  fileprivate(set) var cancelSuggestSections: [String: [KNOrderObject]] = [:]

  var isUseAllBalance: Bool = false

  var cancelOrder: KNOrderObject?

  init(wallet: Wallet,
       from: TokenObject,
       to: TokenObject,
       supportedTokens: [TokenObject]
    ) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr) ?? KNWalletObject(address: addr)
    self.from = from
    self.to = to
    self.feePercentage = 0
    self.discountPercentage = 0
    self.transferFeePercent = 0
    self.nonce = nil
    self.supportedTokens = supportedTokens
    self.pendingBalances = [:]
    self.relatedOrders = []
    self.relatedHeaders = []
    self.relatedSections = [:]
    self.updateProdCachedRate()
  }

  // MARK: Wallet name
  var walletNameString: String {
    let addr = self.walletObject.address.lowercased()
    return "|  \(addr.prefix(10))...\(addr.suffix(8))"
  }

  // MARK: From Token
  var fromSymbol: String {
    return self.from.isETH || self.from.isWETH ? "ETH*" : self.from.symbol
  }

  var toSymbol: String {
    return self.to.isETH || self.to.isWETH ? "ETH*" : self.to.symbol
  }

  var allFromTokenBalanceString: String {
    if !(self.from.isETH || self.from.isWETH) { return self.balanceText.removeGroupSeparator() }
    let fee: BigInt = {
      if let bal = self.balances[self.eth.contract]?.value, !bal.isZero {
        return KNGasCoordinator.shared.fastKNGas * BigInt(600_000) // approve + convet if needed
      }
      return BigInt(0)
    }()
    let bal: BigInt = max(BigInt(0), self.availableBalance - fee)
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    ).removeGroupSeparator()
    if let value = Double(string), value == 0 { return "0" }
    return "\(string.prefix(12))"
  }

  var amountFromBigInt: BigInt {
    return EtherNumberFormatter.full.number(from: self.amountFrom.removeGroupSeparator(), decimals: self.from.decimals) ?? BigInt(0)
  }

  func amountFromWithPercentage(_ percentage: Int) -> BigInt {
    let amount = self.availableBalance * BigInt(percentage) / BigInt(100)
    if !(self.from.isETH || self.from.isWETH) { return amount }
    let fee: BigInt = {
      if let bal = self.balances[self.eth.contract]?.value, !bal.isZero {
        return KNGasCoordinator.shared.fastKNGas * BigInt(600_000) // approve + convet if needed
      }
      return BigInt(0)
    }()
    return min(amount, max(0, self.availableBalance - fee))
  }

  var amountToBigInt: BigInt {
    return self.amountTo.removeGroupSeparator().amountBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var estimateAmountFromBigInt: BigInt {
    let rate = self.targetRateBigInt
    if rate.isZero { return BigInt(0) }
    let amountTo = self.amountToBigInt
    return amountTo * BigInt(10).power(self.from.decimals) / rate
  }

  var shouldAmountFromChange: Bool {
    return self.prevFocusTextFieldTag != 0 && self.focusTextFieldTag != 0
  }

  var estimateAmountToBigInt: BigInt {
    let rate = self.targetRateBigInt
    if rate.isZero { return BigInt(0) }
    return self.amountFromBigInt * rate / BigInt(10).power(self.from.decimals)
  }

  var shouldAmountToChange: Bool {
    return self.prevFocusTextFieldTag != 1 && self.focusTextFieldTag != 1
  }

  func tokenButtonAttributedText(isSource: Bool) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedStringKey.kern: 0.0,
    ]
    let nameAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 13),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
      NSAttributedStringKey.kern: 0.0,
    ]
    let symbol: String = isSource ? self.fromSymbol : self.toSymbol
    let name = isSource ? self.from.name : self.to.name
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }

  // MARK: Balance
  var availableBalance: BigInt {
    let balance: BigInt = {
      if self.from.isWETH {
        let wethBalance = self.balance?.value ?? BigInt(0)
        let ethBalance = self.balances[self.eth.contract]?.value ?? BigInt(0)
        return wethBalance + ethBalance
      }
      return self.balance?.value ?? BigInt(0)
    }()
    var availableAmount = balance
    if let pendingAmount = self.pendingBalances[self.from.symbol] as? Double {
      availableAmount -= BigInt(pendingAmount * pow(10.0, Double(self.from.decimals)))
    }
    availableAmount = max(availableAmount, BigInt(0))

    return availableAmount
  }

  var balanceText: String {
    let bal: BigInt = self.availableBalance
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string), double == 0 { return "0" }
    return "\(string.prefix(12))"
  }

  var balanceTextString: String {
    return "\(self.fromSymbol) Available".toBeLocalised().uppercased()
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.availableBalance { return false }
    return true
  }

  var equivalentETHAmount: BigInt {
    if self.amountFromBigInt <= BigInt(0) { return BigInt(0) }
    if self.from.isETH || self.from.isWETH {
      return self.amountFromBigInt
    }
    if self.to.isETH || self.to.isWETH {
      return self.amountToBigInt
    }
    let ethRate: BigInt = {
      let cacheRate = KNTrackerRateStorage.shared.trackerRate(for: self.from)
      return BigInt((cacheRate?.rateETHNow ?? 0.0) * pow(10.0, 18.0))
    }()
    let valueInETH = ethRate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    return valueInETH
  }

  var isConvertingETHToWETHNeeded: Bool {
    if !self.from.isWETH { return false }
    let balance = self.balance?.value ?? BigInt(0)

    var availableAmount = balance
    if let pendingAmount = self.pendingBalances[self.from.symbol] as? Double {
      availableAmount -= BigInt(pendingAmount * pow(10.0, Double(self.from.decimals)))
    }
    availableAmount = max(availableAmount, BigInt(0))

    return availableAmount < self.amountFromBigInt
  }

  var minAmountToConvert: BigInt {
    if !self.from.isWETH { return BigInt(0) }
    let balance = self.balance?.value ?? BigInt(0)

    var availableAmount = balance
    if let pendingAmount = self.pendingBalances[self.from.symbol] as? Double {
      availableAmount -= BigInt(pendingAmount * pow(10.0, Double(self.from.decimals)))
    }
    availableAmount = max(availableAmount, BigInt(0))

    if availableAmount < self.amountFromBigInt { return self.amountFromBigInt - availableAmount }
    return BigInt(0)
  }

  var isAmountTooBig: Bool {
    return !self.isBalanceEnough
  }

  var isAmountTooSmall: Bool {
    let amount: Double = {
      if KNEnvironment.default == .production { return 0.1 }
      return 0.001
    }()
    let minValueInETH = BigInt(amount * Double(EthereumUnit.ether.rawValue))
    return minValueInETH > self.equivalentETHAmount
  }

  // MARK: Rate
  var targetRateBigInt: BigInt {
    return self.targetRate.removeGroupSeparator().amountBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var targetRateDouble: Double {
    return Double(targetRateBigInt) / pow(10.0, Double(self.to.decimals))
  }

  var estimateTargetRateBigInt: BigInt {
    let amountFrom = self.amountFromBigInt
    if amountFrom.isZero { return BigInt(0) }
    let amountTo = self.amountToBigInt
    return amountTo * BigInt(10).power(self.from.decimals) / amountFrom
  }

  var shouldTargetRateChange: Bool {
    return self.prevFocusTextFieldTag != 2 && self.focusTextFieldTag != 2
  }

  var exchangeRateText: String {
    let rate: BigInt? = self.rateFromNode ?? self.cachedProdRate
    if let rateText = rate?.displayRate(decimals: self.to.decimals) {
      return "1 \(self.fromSymbol) = \(rateText) \(self.toSymbol)"
    }
    return "---"
  }

  var isShowingRevertRate: Bool {
    return self.from.extraData?.isQuote == true
  }

  var revertCurrentExchangeRateString: String? {
    guard let rate = self.rateFromNode ?? self.cachedProdRate, !rate.isZero else {
      return nil
    }
    let revertRate = BigInt(10).power(self.from.decimals) * BigInt(10).power(self.to.decimals) / rate
    let rateText = revertRate.displayRate(decimals: self.from.decimals)
    return "1 \(self.toSymbol) = \(rateText) \(self.fromSymbol)"
  }

  var revertTargetExchangeRateString: String? {
    guard !targetRateBigInt.isZero else {
      return nil
    }
    let revertRate = BigInt(10).power(self.from.decimals) * BigInt(10).power(self.to.decimals) / targetRateBigInt
    let rateText = revertRate.displayRate(decimals: self.from.decimals)
    return "1 \(self.toSymbol) = \(rateText) \(self.fromSymbol)"
  }

  var displayCurrentExchangeRate: String {
    if self.isShowingRevertRate, let revertRateString = self.revertCurrentExchangeRateString {
      return "\(self.exchangeRateText)\n\(revertRateString)"
    }
    return self.exchangeRateText
  }

  var displayTargetExchangeRate: String {
    if self.isShowingRevertRate, let revertRateString = revertTargetExchangeRateString {
      return revertRateString
    }
    return ""
  }

  var estimatedRateDouble: Double {
    guard let rate = self.rateFromNode else { return 0.0 }
    return Double(rate) / pow(10.0, Double(self.to.decimals))
  }

  var isRateTooSmall: Bool {
    return self.targetRateBigInt.isZero
  }

  var isRateTooBig: Bool {
    let curRate = self.rateFromNode ?? self.cachedProdRate ?? BigInt(0)
    return self.targetRateBigInt > curRate * BigInt(10)
  }

  var percentageRateDiff: Double {
    guard let rate = self.targetRate.amountBigInt(decimals: self.to.decimals) else { return 0.0 }
    let marketRate = self.estimatedRateDouble
    if marketRate == 0.0 { return 0.0 }
    let targetRateDouble = Double(rate) / pow(10.0, Double(self.to.decimals))
    return (targetRateDouble - marketRate) / marketRate * 100.0
  }

  var differentRatePercentageDisplay: String? {
    let change = self.percentageRateDiff
    let display = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
    return "\(display)%"
  }

  var displayRateCompareAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let rateChange = self.percentageRateDiff
    if fabs(rateChange) < 0.1 { return attributedString }
    guard let rate = self.differentRatePercentageDisplay else { return attributedString }
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    ]
    let higherAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.shamrock,
    ]
    let lowerAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.strawberry,
    ]
    attributedString.append(NSAttributedString(string: "Your target rate is".toBeLocalised(), attributes: normalAttributes))
    if rateChange > 0 {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: higherAttributes))
      attributedString.append(NSAttributedString(string: "higher than current Market rate".toBeLocalised(), attributes: normalAttributes))
    } else {
      attributedString.append(NSAttributedString(string: " \(rate) ", attributes: lowerAttributes))
      attributedString.append(NSAttributedString(string: "lower than current rate".toBeLocalised(), attributes: normalAttributes))
    }
    return attributedString
  }

  // MARK: Fee
  var feePercentage: Double = 0 // example: 0.005 -> 0.5%
  var discountPercentage: Double = 0 // example: 40 -> 40%
  var feeBeforeDiscount: Double = 0 // same as fee percentage
  var transferFeePercent: Double = 0

  lazy var feeNoteNormalAttributes: [NSAttributedStringKey: Any] = {
    return [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
      NSAttributedStringKey.strikethroughStyle: NSUnderlineStyle.styleSingle.rawValue,
    ]
  }()

  lazy var feeNoteHighlightedAttributes: [NSAttributedStringKey: Any] = {
    return [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    ]
  }()

  var isShowingDiscount: Bool {
    let discountVal = Double(self.amountFromBigInt) * self.feeBeforeDiscount * (self.discountPercentage / 100.0) / pow(10.0, Double(self.from.decimals))
    return discountVal >= 0.000001
  }

  var feeNoteAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()

    if !isShowingDiscount {
      return NSAttributedString(
        string: self.displayFeeString,
        attributes: self.feeNoteHighlightedAttributes
      )
    }

    attributedString.append(NSAttributedString(string: "\(self.displayFeeString)\n", attributes: self.feeNoteHighlightedAttributes))
    attributedString.append(NSAttributedString(string: self.displayFeeBeforeDiscountString, attributes: self.feeNoteNormalAttributes))

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 2
    attributedString.addAttribute(
      NSAttributedString.Key.paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )

    return attributedString
  }

  var displayFeeString: String {
    let feeDouble = Double(self.amountFromBigInt) * (self.feePercentage + transferFeePercent) / pow(10.0, Double(self.from.decimals))
    let feeDisplay = NumberFormatterUtil.shared.displayLimitOrderValue(from: feeDouble)
    let fromSymbol = self.fromSymbol
    let string = "\(feeDisplay.prefix(12)) \(fromSymbol)"
    if self.isShowingDiscount || self.amountFromBigInt.isZero { return string }
    let percentage = NumberFormatterUtil.shared.displayPercentage(from: (self.feePercentage + self.transferFeePercent) * 100.0)
    return "\(string) (\(percentage)%)"
  }

  var displayDiscountPercentageString: String {
    let discount = NumberFormatterUtil.shared.displayPercentage(from: self.discountPercentage)
    return "\(discount)% OFF"
  }

  var displayFeeBeforeDiscountString: String {
    let feeDouble = Double(self.amountFromBigInt) * (self.feeBeforeDiscount + self.transferFeePercent) / pow(10.0, Double(self.from.decimals))
    let feeDisplay = NumberFormatterUtil.shared.displayLimitOrderValue(from: feeDouble)
    let fromSymbol = self.fromSymbol
    return "\(feeDisplay.prefix(12)) \(fromSymbol)"
  }

  var suggestBuyText: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let learnMoreAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 98, green: 107, blue: 134),
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
    ]
    if !isShowingDiscount {
      // only show if there is no discount
      let normalAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 98, green: 107, blue: 134),
        NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      ]
      attributedString.append(NSAttributedString(
        string: "Hold from 2000 KNC to get discount for your orders. ".toBeLocalised(),
        attributes: normalAttributes
        )
      )
    }
    attributedString.append(NSAttributedString(string: "Learn more".toBeLocalised(), attributes: learnMoreAttributes))
    return attributedString
  }

  var suggestBuyTopPadding: CGFloat {
    return !isShowingDiscount ? 10.0 : 4.0
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""
    self.isUseAllBalance = false

    self.feePercentage = 0
    self.transferFeePercent = 0
    self.discountPercentage = 0
    self.nonce = nil

    self.balances = [:]
    self.balance = nil

    self.rateFromNode = nil

    self.pendingBalances = [:]
    self.relatedOrders = []
    self.relatedHeaders = []
    self.relatedSections = [:]

    self.updateProdCachedRate()
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address) ?? self.walletObject
  }

  func updateFocusTextField(_ tag: Int) {
    if self.focusTextFieldTag == tag { return }
    self.prevFocusTextFieldTag = {
      if tag != 2 { return 2 } // rate is the highest priority
      return self.focusTextFieldTag
    }()
    self.focusTextFieldTag = tag
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    if self.from.isETH, let weth = self.weth { self.from = weth } // switch to weth
    if self.to.isETH, let weth = self.weth { self.to = weth }
    self.amountFrom = ""
    self.amountTo = ""
    self.targetRate = ""
    self.isUseAllBalance = false
    self.balance = self.balances[self.from.contract]
    self.feePercentage = 0
    self.transferFeePercent = 0
    self.discountPercentage = 0
    self.nonce = nil

    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
      self.isUseAllBalance = false
    } else {
      self.amountTo = amount
    }
  }

  func updateTargetRate(_ rate: String) {
    self.targetRate = rate
    self.cancelSuggestOrders = self.relatedOrders.filter({ return $0.targetPrice > self.targetRateDouble })
    self.updateRelatedAndCancelSuggestionData()
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token.clone()
      self.feePercentage = 0
      self.transferFeePercent = 0
      self.discountPercentage = 0
      self.isUseAllBalance = false
    } else {
      self.to = token.clone()
    }
    self.nonce = nil
    self.balance = self.balances[self.from.contract]
    self.rateFromNode = nil
    self.updateProdCachedRate()
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      if let oldBal = self.balance, oldBal.value != bal.value {
        self.isUseAllBalance = false
      }
      self.balance = bal
    }
  }

  func updateProdCachedRate(_ rate: BigInt? = nil) {
    self.cachedProdRate = rate ?? KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
  }

  @discardableResult
  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.rateFromNode = rate.isZero ? nil : rate
      return true
    }
    return false
  }

  // Update order with same sender, src and dest address
  func updateRelatedOrders(_ orders: [KNOrderObject]) {
    self.relatedOrders = orders
      .filter({ return $0.state == .open })
      .sorted(by: { return $0.dateToDisplay > $1.dateToDisplay })
    self.cancelSuggestOrders = self.relatedOrders.filter({ return $0.targetPrice > self.targetRateDouble })
    self.updateRelatedAndCancelSuggestionData()
  }

  fileprivate func updateRelatedAndCancelSuggestionData() {
    self.relatedHeaders = []
    self.relatedSections = [:]
    self.relatedOrders.forEach({
      let date = self.displayDate(for: $0)
      if !self.relatedHeaders.contains(date) {
        self.relatedHeaders.append(date)
      }
    })
    self.relatedOrders.forEach { order in
      let date = self.displayDate(for: order)
      var orders: [KNOrderObject] = self.relatedSections[date] ?? []
      orders.append(order)
      orders = orders.sorted(by: { return $0.dateToDisplay > $1.dateToDisplay })
      self.relatedSections[date] = orders
    }

    self.cancelSuggestHeaders = []
    self.cancelSuggestSections = [:]
    self.cancelSuggestOrders.forEach({
      let date = self.displayDate(for: $0)
      if !self.cancelSuggestHeaders.contains(date) {
        self.cancelSuggestHeaders.append(date)
      }
    })
    self.cancelSuggestOrders.forEach { order in
      let date = self.displayDate(for: order)
      var orders: [KNOrderObject] = self.cancelSuggestSections[date] ?? []
      orders.append(order)
      orders = orders.sorted(by: { return $0.dateToDisplay > $1.dateToDisplay })
      self.cancelSuggestSections[date] = orders
    }
  }

  func updatePendingBalances(_ balances: JSONDictionary, address: String) {
    if address.lowercased() == self.walletObject.address.lowercased() {
      self.pendingBalances = balances
    }
  }

  func displayDate(for order: KNOrderObject) -> String {
    return dateFormatter.string(from: order.dateToDisplay)
  }
}
