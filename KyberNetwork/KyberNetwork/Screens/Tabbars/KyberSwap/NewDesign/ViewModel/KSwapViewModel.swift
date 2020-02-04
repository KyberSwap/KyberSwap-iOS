// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KSwapViewModel {

  let defaultTokenIconImg = UIImage(named: "default_token")
  let eth = KNSupportedTokenStorage.shared.ethToken
  let knc = KNSupportedTokenStorage.shared.kncToken

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate var supportedTokens: [TokenObject] = []

  fileprivate(set) var from: TokenObject
  fileprivate(set) var to: TokenObject

  fileprivate(set) var balances: [String: Balance] = [:]
  fileprivate(set) var balance: Balance?

  fileprivate(set) var amountFrom: String = ""
  fileprivate(set) var amountTo: String = ""
  fileprivate(set) var isFocusingFromAmount: Bool = true

  fileprivate(set) var userCapInWei: BigInt = BigInt(2).power(255)
  fileprivate(set) var estRate: BigInt?
  fileprivate(set) var slippageRate: BigInt?
  fileprivate(set) var minRatePercent: Double = 3.0

  var isSwapAllBalance: Bool = false

  var isSwapSuggestionShown: Bool {
    if let suggestions = self.swapSuggestion, !suggestions.isEmpty { return true }
    return false
  }
  var swapSuggestion: [JSONDictionary]?

  var estimatedRateDouble: Double {
    guard let rate = self.estRate else { return 0.0 }
    return Double(rate) / pow(10.0, Double(self.to.decimals))
  }

  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.fastKNGas

  fileprivate(set) var estimateGasLimit: BigInt = KNGasConfiguration.exchangeTokensGasLimitDefault

  init(wallet: Wallet,
       from: TokenObject,
       to: TokenObject,
       supportedTokens: [TokenObject]
    ) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr)?.clone() ?? KNWalletObject(address: addr)
    self.from = from.clone()
    self.to = to.clone()
    self.supportedTokens = supportedTokens.map({ return $0.clone() })
    self.updateProdCachedRate()
    self.updateRelatedOrders()
  }

  var headerBackgroundColor: UIColor { return KNAppStyleType.current.swapFlowHeaderColor }
  // MARK: Wallet name
  var walletNameString: String {
    let address = self.walletObject.address.lowercased()
    return "|  \(address.prefix(10))...\(address.suffix(8))"
  }

  // MARK: From Token
  var allETHBalanceFee: BigInt {
    let gasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to) + BigInt(10_000)
    return self.gasPrice * gasLimit
  }

  var allFromTokenBalanceString: String {
    if self.from.isETH {
      let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
      if balance <= self.feeBigInt { return "0" }
      let fee = self.allETHBalanceFee
      let availableToSwap = max(BigInt(0), balance - fee)
      let string = availableToSwap.string(
        decimals: self.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.from.decimals, 6)
      ).removeGroupSeparator()
      return "\(string.prefix(12))"
    }
    return self.balanceText.removeGroupSeparator()
  }

  var amountFromBigInt: BigInt {
    return self.amountFrom.removeGroupSeparator().amountBigInt(decimals: self.from.decimals) ?? BigInt(0)
  }

  var amountToEstimate: BigInt {
    if self.amountFromBigInt.isZero, let smallAmount = EtherNumberFormatter.short.number(from: "0.001", decimals: self.from.decimals) {
      return smallAmount
    }
    return self.amountFromBigInt
  }

  var equivalentUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.to) {
      return usdRate.rate * self.amountToBigInt / BigInt(10).power(self.to.decimals)
    }
    return nil
  }

  var displayEquivalentUSDAmount: String? {
    guard let amount = self.equivalentUSDAmount, !amount.isZero else { return nil }
    let value = amount.displayRate(decimals: 18)
    return "~ $\(value) USD"
  }

  var fromTokenIconName: String {
    return self.from.icon
  }

  var isFromTokenBtnEnabled: Bool {
    guard KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) != nil else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken { return false }
    return true
  }

  var fromTokenBtnTitle: String {
    return self.from.symbol
  }

  // when user wants to fix received amount
  var expectedExchangeAmountText: String {
    guard let rate = self.estRate, !self.amountToBigInt.isZero else {
      return ""
    }
    let expectedExchange: BigInt = {
      let exchangeRate: BigInt = {
        if !rate.isZero { return rate }
        return KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to) ?? BigInt(0)
      }()
      if exchangeRate.isZero { return BigInt(0) }
      let amount = self.amountToBigInt
      return amount * BigInt(10).power(self.from.decimals) / exchangeRate
    }()
    return expectedExchange.string(
      decimals: self.from.decimals,
      minFractionDigits: min(self.from.decimals, 6),
      maxFractionDigits: min(self.from.decimals, 6)
    ).removeGroupSeparator()
  }

  fileprivate var cachedProdRate: BigInt?

  var percentageRateDiff: Double {
    guard let rate = self.cachedProdRate ?? KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to), !rate.isZero else {
      return 0.0
    }
    if self.estimatedRateDouble == 0.0 { return 0.0 }
    let marketRateDouble = Double(rate) / pow(10.0, Double(self.to.decimals))
    let change = (self.estimatedRateDouble - marketRateDouble) / marketRateDouble * 100.0
    if change > -0.1 { return 0.0 }
    return change
  }

  var differentRatePercentageDisplay: String? {
    if self.amountFromBigInt.isZero { return nil }
    let change = self.percentageRateDiff
    if change >= -0.1 { return nil }
    let display = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
    return "\(display)%"
  }

  // MARK: To Token
  var amountToBigInt: BigInt {
    return self.amountTo.removeGroupSeparator().amountBigInt(decimals: self.to.decimals) ?? BigInt(0)
  }

  var isToTokenBtnEnabled: Bool {
    guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.walletObject.address) else {
      // not a promo wallet, always enabled
      return true
    }
    if self.from.isPromoToken && self.to.symbol == destToken { return false }
    return true
  }

  var toTokenBtnTitle: String {
    return self.to.symbol
  }

  var toTokenIconName: String {
    return self.to.icon
  }

  var amountTextFieldColor: UIColor {
    return self.isAmountValid ? UIColor.Kyber.enygold : UIColor.red
  }

  var expectedReceivedAmountText: String {
    guard !self.amountFromBigInt.isZero else {
      return ""
    }
    let rate: BigInt? = {
      if let rate = self.estRate, !rate.isZero { return rate }
      return KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
    }()
    guard let expectedRate = rate else { return "" }
    let expectedAmount: BigInt = {
      let amount = self.amountFromBigInt
      return expectedRate * amount / BigInt(10).power(self.from.decimals)
    }()
    return expectedAmount.string(
      decimals: self.to.decimals,
      minFractionDigits: min(self.to.decimals, 6),
      maxFractionDigits: min(self.to.decimals, 6)
    ).removeGroupSeparator()
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
    let symbol = isSource ? self.from.symbol : self.to.symbol
    let name = isSource ? self.from.name : self.to.name
    attributedString.append(NSAttributedString(string: symbol, attributes: symbolAttributes))
    attributedString.append(NSAttributedString(string: "\n\(name)", attributes: nameAttributes))
    return attributedString
  }

  // MARK: Balance
  var balanceText: String {
    let bal: BigInt = self.balance?.value ?? BigInt(0)
    let string = bal.string(
      decimals: self.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.from.decimals, 6)
    )
    if let double = Double(string.removeGroupSeparator()), double == 0 { return "0" }
    return "\(string.prefix(12))"
  }

  var balanceTextString: String {
    let balanceText = NSLocalizedString("balance", value: "Balance", comment: "")
    return "\(self.from.symbol) \(balanceText)".uppercased()
  }

  // MARK: Rate
  var exchangeRateText: String {
    let rate: BigInt? = {
      if let rate = self.estRate, !rate.isZero { return rate }
      return KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
    }()
    return rate?.displayRate(decimals: self.to.decimals) ?? "---"
  }

  var minRate: BigInt? {
    guard let estRate = self.estRate else { return nil }
    return estRate * BigInt(10000.0 - self.minRatePercent * 100.0) / BigInt(10000.0)
  }

  var slippageRateText: String? {
    return self.slippageRate?.string(decimals: self.to.decimals, minFractionDigits: 0, maxFractionDigits: min(self.to.decimals, 9))
  }

  // MARK: Gas Price
  var gasPriceText: String {
    return "\(self.gasPrice.shortString(units: .gwei, maxFractionDigits: 1)) gwei"
  }

  // MARK: Verify data
  // Amount should > 0 and <= balance
  var isAmountTooSmall: Bool {
    if self.amountFromBigInt <= BigInt(0) { return true }
    if self.from.isETH || self.from.isWETH {
      return self.amountFromBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    if self.to.isETH || self.to.isWETH {
      return self.amountToBigInt < BigInt(0.001 * Double(EthereumUnit.ether.rawValue))
    }
    let ethRate: BigInt = {
      let cacheRate = KNRateCoordinator.shared.ethRate(for: self.from)
      return cacheRate?.rate ?? BigInt(0)
    }()
    if ethRate.isZero && self.estRate != nil && self.estRate?.isZero == false {
      return false
    }
    let valueInETH = ethRate * self.amountFromBigInt
    let valueMin = BigInt(0.001 * Double(EthereumUnit.ether.rawValue)) * BigInt(10).power(self.from.decimals)
    return valueInETH < valueMin
  }

  var isBalanceEnough: Bool {
    if self.amountFromBigInt > self.balance?.value ?? BigInt(0) { return false }
    return true
  }

  var isCapEnough: Bool {
    if self.from.isETH && self.to.isWETH { return true }
    if self.from.isWETH && self.to.isETH { return true }
    let ethAmount: BigInt = {
      if self.from.isETH || self.from.isWETH { return self.amountFromBigInt }
      if self.to.isETH || self.to.isWETH { return self.amountToBigInt }
      let ethRate: BigInt = {
        let cacheRate = KNRateCoordinator.shared.ethRate(for: self.from)
        return cacheRate?.rate ?? BigInt(0)
      }()
      return ethRate * self.amountFromBigInt / BigInt(10).power(self.from.decimals)
    }()
    return self.userCapInWei >= ethAmount
  }

  var isAmountTooBig: Bool {
    if !self.isBalanceEnough { return true }
    if !self.isCapEnough { return true }
    return false
  }

  var isETHSwapAmountAndFeeTooBig: Bool {
    if !self.from.isETH { return false } // not ETH
    let totalValue = self.feeBigInt + self.amountFromBigInt
    let balance = self.balances[self.from.contract]?.value ?? BigInt(0)
    return balance < totalValue
  }

  var isAmountValid: Bool {
    return !self.isAmountTooSmall && !self.isAmountTooBig
  }

  // rate should not be nil and greater than zero
  var isSlippageRateValid: Bool {
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var isRateValid: Bool {
    if self.estRate == nil || self.estRate?.isZero == true { return false }
    if self.slippageRate == nil || self.slippageRate?.isZero == true { return false }
    return true
  }

  var isPairUnderMaintenance: Bool {
    let cachedRate = KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to) ?? BigInt(0)
    let estRate = self.estRate ?? BigInt(0)
    return estRate.isZero && cachedRate.isZero
  }

  var feeBigInt: BigInt {
    return self.gasPrice * self.estimateGasLimit
  }

  var isHavingEnoughETHForFee: Bool {
    var fee = self.gasPrice * self.estimateGasLimit
    if self.from.isETH { fee += self.amountFromBigInt }
    let ethBal = self.balances[self.eth.contract]?.value ?? BigInt(0)
    return ethBal >= fee
  }

  // MARK: Update data
  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
    let address = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: address) ?? KNWalletObject(address: address)

    if let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: address), let ptToken = KNSupportedTokenStorage.shared.ptToken {
      self.from = ptToken.clone()
      self.to = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.symbol == destToken })?.clone() ?? self.eth
    } else {
      // not a promo wallet
      self.from = self.eth
      self.to = self.knc
    }

    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.balances = [:]
    self.balance = nil

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
    self.userCapInWei = BigInt(2).power(255)
    self.updateProdCachedRate()
    self.swapSuggestion = nil
    self.updateRelatedOrders()
  }

  func updateWalletObject() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address)?.clone() ?? self.walletObject
  }

  func updateProdCachedRate(_ rate: BigInt? = nil) {
    self.cachedProdRate = rate ?? KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to)
  }

  func updateRelatedOrders() {
    // TODO
  }

  func swapTokens() {
    swap(&self.from, &self.to)
    self.amountFrom = ""
    self.amountTo = ""
    self.isFocusingFromAmount = true
    self.isSwapAllBalance = false

    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
    self.balance = self.balances[self.from.contract]
    self.updateProdCachedRate()
    self.updateRelatedOrders()
  }

  func updateSelectedToken(_ token: TokenObject, isSource: Bool) {
    if isSource {
      self.from = token.clone()
    } else {
      self.to = token.clone()
    }
    if self.isFocusingFromAmount && isSource {
      // focusing on from amount, and from token is changed, reset amount
      self.amountFrom = ""
      self.isSwapAllBalance = false
    } else if !self.isFocusingFromAmount && !isSource {
      // focusing on to amount, and to token is changed, reset to amount
      self.amountTo = ""
    }
    self.estRate = nil
    self.slippageRate = nil
    self.estimateGasLimit = KNGasConfiguration.calculateDefaultGasLimit(from: self.from, to: self.to)
    self.balance = self.balances[self.from.contract]
    self.updateProdCachedRate()
    self.updateRelatedOrders()
  }

  func updateEstimatedRateFromCachedIfNeeded() {
    guard let rate = KNRateCoordinator.shared.getCachedProdRate(from: self.from, to: self.to), self.estRate == nil, self.slippageRate == nil else { return }
    self.estRate = rate
    self.slippageRate = rate * BigInt(97) / BigInt(100)
  }

  func updateFocusingField(_ isSource: Bool) {
    self.isFocusingFromAmount = isSource
  }

  func updateAmount(_ amount: String, isSource: Bool) {
    if isSource {
      self.amountFrom = amount
      self.isSwapAllBalance = false
    } else {
      self.amountTo = amount
    }
  }

  func updateBalance(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
    if let bal = balances[self.from.contract] {
      if let oldBalance = self.balance, oldBalance.value != bal.value { self.isSwapAllBalance = false }
      self.balance = bal
    }
  }

  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: break
    }
  }

  // update when set gas price
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
    self.selectedGasPriceType = .custom
  }

  @discardableResult
  func updateExchangeRate(for from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) -> Bool {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      self.estRate = rate
      self.slippageRate = slippageRate
      return true
    }
    return false
  }

  func updateExchangeMinRatePercent(_ percent: Double) {
    self.minRatePercent = percent
  }

  func updateEstimateGasLimit(for from: TokenObject, to: TokenObject, amount: BigInt, gasLimit: BigInt) {
    let isAmountChanged: Bool = {
      if self.amountFromBigInt == amount { return false }
      let doubleValue = Double(amount) / pow(10.0, Double(self.from.decimals))
      return !(self.amountFromBigInt.isZero && doubleValue == 0.001)
    }()
    if from == self.from, to == self.to, !isAmountChanged {
      if let specialGasLimit = KNGasConfiguration.specialGasLimitDefault(from: from, to: to) {
        self.estimateGasLimit = max(gasLimit, specialGasLimit)
      } else {
        self.estimateGasLimit = gasLimit
      }
    }
  }

  func updateUserCapInWei(cap: BigInt) {
    self.userCapInWei = cap
  }
}
