// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KWalletSortType {
  case nameDesc // A -> Z
  case balanceDesc
  case priceAsc
  case priceDesc
  case changeAsc
  case changeDesc
  case `default`
}

extension KWalletSortType {
  func displayString() -> String {
    switch self {
    case .nameDesc:
      return "name"
    case .balanceDesc:
      return "balance"
    case .priceAsc, .priceDesc:
      return "price"
    case .changeAsc, .changeDesc:
      return "24h"
    default:
      return "balance"
    }
  }
}

enum KWalletCurrencyType: String {
  case usd = "USD"
  case eth = "ETH"
}

enum KTokenListType: Int {
  case kyberListed
  case favourite
  case others
}

extension KTokenListType {
  func displayString() -> String {
    switch self {
    case .kyberListed:
      return "kyber listed"
    case .favourite:
      return "favourite"
    case .others:
      return "others"
    }
  }
}

class KWalletBalanceViewModel: NSObject {

  let displayTypeNormalAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.bold(with: 12),
    NSAttributedStringKey.foregroundColor: UIColor(red: 158, green: 161, blue: 170),
  ]

  let displayTypeHighLightedAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.bold(with: 12),
    NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
  ]

  lazy var arrowUpAttributedString: NSAttributedString = {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.regular(with: 15),
      NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
    ]
    return NSAttributedString(string: "↑", attributes: attributes)
  }()

  lazy var arrowDownAttributedString: NSAttributedString = {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.regular(with: 15),
      NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
    ]
    return NSAttributedString(string: "↓", attributes: attributes)
  }()

  private(set) var tabOption: KTokenListType = .kyberListed // 0: Kyber List, 1: Favourite, 2: Other
  private(set) var preExtraTabOption: KTokenListType = .favourite // either 1 or 2, default 1
  private(set) var wallet: KNWalletObject
  private(set) var tokenObjects: [TokenObject] = []
  private(set) var tokensDisplayType: KWalletSortType = .default

  private(set) var trackerRateData: [String: KNTrackerRate] = [:]
  private(set) var displayedTokens: [TokenObject] = []
  private(set) var displayTrackerRates: [KNTrackerRate?] = []

  private(set) var currencyType: KWalletCurrencyType = KNAppTracker.getCurrencyType()

  private(set) var balances: [String: Balance] = [:]
  private(set) var totalETHBalance: BigInt = BigInt(0)
  private(set) var totalUSDBalance: BigInt = BigInt(0)

  private(set) var searchText: String = ""

  private(set) var isBalanceShown: Bool = true

  init(wallet: KNWalletObject) {
    self.wallet = wallet
    super.init()
  }

  // MARK: Check if balance has tokens
  var hasTokens: Bool {
    // As combining market and balance, there is no need to check
    return !self.tokenObjects.isEmpty
  }

  var textNoMatchingTokens: String {
    return NSLocalizedString("no.matching.tokens", value: "No matching tokens", comment: "")
  }

  fileprivate func setupTrackerRateData() {
    KNTrackerRateStorage.shared.rates.forEach { rate in
      self.trackerRateData[rate.identifier] = rate
    }
  }

  // MARK: Wallet data
  var walletNameDisplayedText: String {
    return self.wallet.name
  }

  var headerBackgroundColor: UIColor {
    return KNAppStyleType.current.walletFlowHeaderColor
  }

  // MARK: Balance data

  var displayNameAndBalance: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    if self.tokensDisplayType != .balanceDesc && self.tokensDisplayType != .nameDesc {
      // not highlighted
      let display = "Name | Bal"
      return NSAttributedString(string: display, attributes: displayTypeNormalAttributes)
    }
    if self.tokensDisplayType == .balanceDesc {
      attributedString.append(NSAttributedString(string: "Name | ", attributes: displayTypeNormalAttributes))
      attributedString.append(NSAttributedString(string: "Bal ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowDownAttributedString)
    } else {
      attributedString.append(NSAttributedString(string: "Name ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowDownAttributedString)
      attributedString.append(NSAttributedString(string: " | Bal", attributes: displayTypeNormalAttributes))
    }
    return attributedString
  }

  var nameAndBalanceCenterXConstant: CGFloat {
    return 0.0
  }

  var displayETHCurrency: NSAttributedString {
    if self.currencyType == .usd {
      return NSAttributedString(string: "ETH |", attributes: displayTypeNormalAttributes)
    }
    let attributedString = NSMutableAttributedString()
    if self.tokensDisplayType == .priceDesc {
      attributedString.append(NSAttributedString(string: "ETH ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowDownAttributedString)
      return attributedString
    }
    if self.tokensDisplayType == .priceAsc {
      attributedString.append(NSAttributedString(string: "ETH ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowUpAttributedString)
      return attributedString
    }
    return NSAttributedString(string: "ETH", attributes: displayTypeHighLightedAttributes)
  }

  var currencyETHCenterXConstant: CGFloat {
    return 0.0
  }

  var displayUSDCurrency: NSAttributedString {
    if self.currencyType == .eth {
      return NSAttributedString(string: "| USD", attributes: displayTypeNormalAttributes)
    }
    let attributedString = NSMutableAttributedString()
    if self.tokensDisplayType == .priceDesc {
      attributedString.append(NSAttributedString(string: "USD ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowDownAttributedString)
      return attributedString
    }
    if self.tokensDisplayType == .priceAsc {
      attributedString.append(NSAttributedString(string: "USD ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowUpAttributedString)
      return attributedString
    }
    return NSAttributedString(string: "USD", attributes: displayTypeHighLightedAttributes)
  }

  var currencyUSDCenterXConstant: CGFloat {
    return 0.0
  }

  var displayChange24h: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    if self.tokensDisplayType == .changeDesc {
      attributedString.append(NSAttributedString(string: "24h% ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowDownAttributedString)
      return attributedString
    }
    if self.tokensDisplayType == .changeAsc {
      attributedString.append(NSAttributedString(string: "24h% ", attributes: displayTypeHighLightedAttributes))
      attributedString.append(self.arrowUpAttributedString)
      return attributedString
    }
    return NSAttributedString(string: "24h%", attributes: displayTypeNormalAttributes)
  }

  var change24hCenterXConstant: CGFloat {
    return 0.0
  }

  func updateCurrencyType(_ type: KWalletCurrencyType) -> Bool {
    if self.currencyType == type { return false }
    self.currencyType = type
    KNAppTracker.updateCurrencyType(type)
    self.createDisplayedData()
    return true
  }

  var balanceDisplayAttributedString: NSAttributedString {
    let valueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 28),
      NSAttributedStringKey.foregroundColor: UIColor.white,
      NSAttributedStringKey.kern: 0.0,
    ]

    let currencyAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.white,
      NSAttributedStringKey.kern: 0.0,
    ]

    let value: String = {
      if !self.isBalanceShown { return "******" }
      switch self.currencyType {
      case .usd:
        let usdValue = self.totalUSDBalance.shortString(units: .ether, maxFractionDigits: 2).prefix(11)
        return "\(usdValue)"
      case .eth:
        let ethValue = self.totalETHBalance.shortString(units: .ether, maxFractionDigits: 6).prefix(11)
        return "\(ethValue)"
      }
    }()
    let currency: String = "  \(self.currencyType.rawValue)"

    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: value, attributes: valueAttributes))
    attributedString.append(NSAttributedString(string: currency, attributes: currencyAttributes))
    return attributedString
  }

  var colorKyberListedButton: UIColor {
    if self.tabOption == .kyberListed { return UIColor.Kyber.enygold }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  var colorOthersButton: UIColor {
    if self.tabOption != .kyberListed { return UIColor.Kyber.enygold } // Fav or Other
    return UIColor(red: 29, green: 48, blue: 58)
  }

  var otherButtonTitle: String {
    if self.tabOption != .kyberListed {
      return self.tabOption == .favourite ? "Favourite".toBeLocalised() : "Others".toBeLocalised()
    }
    return self.preExtraTabOption == .favourite ? "Favourite".toBeLocalised() : "Others".toBeLocalised()
  }

  // MARK: Update display data
  // 1: Click name
  // 2: Click price
  // 3: Click change 24h
  func updateTokenDisplayType(positionClicked: Int, isSwitched: Bool = true) {
    if positionClicked == 1 {
      if self.tokensDisplayType == .balanceDesc {
        self.tokensDisplayType = .nameDesc
      } else {
        self.tokensDisplayType = .balanceDesc
      }
    } else if positionClicked == 2 {
      self.tokensDisplayType = (isSwitched || self.tokensDisplayType != .priceDesc) ? .priceDesc : .priceAsc
    } else {
      self.tokensDisplayType = self.tokensDisplayType == .changeDesc ? .changeAsc : .changeDesc
    }
    self.createDisplayedData()
  }

  fileprivate func updateTokensDisplayType(_ type: KWalletSortType) -> Bool {
    if self.tokensDisplayType == type { return false }
    self.tokensDisplayType = type
    self.createDisplayedData()
    return true
  }

  func updateTokenSortedChange24h(with currencyType: KWalletCurrencyType) {
    self.currencyType = currencyType
    KNAppTracker.updateCurrencyType(currencyType)
    self.tokensDisplayType = KWalletSortType.changeDesc
    self.tabOption = .kyberListed
    self.preExtraTabOption = .favourite
    self.createDisplayedData()
  }

  func updateSearchText(_ text: String) {
    self.searchText = text
    self.createDisplayedData()
  }

  // MARK: Tokens balance table view
  var numberRows: Int {
    return self.displayedTokens.count
  }

  func tokenObject(for row: Int) -> TokenObject {
    return self.displayedTokens[row]
  }

  func trackerRate(for row: Int) -> KNTrackerRate? {
    return self.displayTrackerRates[row]
  }

  func balance(for token: TokenObject) -> Balance? {
    if token.isInvalidated { return nil }
    if let balance = self.balances[token.contract] { return balance }
    if let amount = token.value.shortBigInt(decimals: 0) {
      return Balance(value: amount)
    }
    return nil
  }

  func iconName(for token: TokenObject) -> String? {
    return token.icon
  }

  // MARK: Update data
  // return true if data is updated and we need to update UIs
  // to reduce number of reloading collection view
  func updateWalletObject(_ walletObject: KNWalletObject) {
    self.wallet = walletObject
  }

  func updateDisplayDataSessonDidSwitch() {
    self.createDisplayedData()
  }

  func updateTokenObjects(_ tokenObjects: [TokenObject]) -> Bool {
    self.tokenObjects = tokenObjects
    self.createDisplayedData()
    return true
  }

  func updateDisplayTabOption(_ option: KTokenListType) -> Bool {
    if self.tabOption == option { return false }
    self.preExtraTabOption = {
      if option == .kyberListed { return self.tabOption }
      if option == .favourite { return .others }
      return .favourite
    }()
    self.tabOption = option
    self.createDisplayedData()
    return true
  }

  func updateIsBalanceShown(_ isShowing: Bool) {
    self.isBalanceShown = isShowing
  }

  func updateTokenBalances(_ balances: [String: Balance]) -> Bool {
    var isDataChanged: Bool = false
    balances.forEach {
      if self.balances[$0.key] == nil || self.balances[$0.key]!.value != $0.value.value {
        isDataChanged = true
      }
      self.balances[$0.key] = $0.value
    }
    if isDataChanged { self.createDisplayedData() }
    return isDataChanged
  }

  func updateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.totalETHBalance = ethBalance
    self.totalUSDBalance = usdBalance
  }

  func exchangeRatesDataUpdated() {
    self.setupTrackerRateData()
    self.createDisplayedData()
  }

  func createDisplayedData() {
    let favouriteTokens = KNAppTracker.getListFavouriteTokens()
    // Compute displayed token objects sorted by displayed type
    let tokenObjects = self.tokenObjects.filter({
      return $0.contains(self.searchText)
    }).filter({
      if self.tabOption == .kyberListed && $0.isSupported { return true }
      if self.tabOption == .others && !$0.isSupported { return true }
      if self.tabOption == .favourite && favouriteTokens.contains($0.contract.lowercased()) { return true }
      return false
    }).filter({
      if $0.extraData?.isListed == false { return false }
      return true
    })
    self.displayedTokens = {
      return tokenObjects.sorted(by: {
        return self.displayedTokenComparator(left: $0, right: $1)
      })
    }()
    self.displayTrackerRates = self.displayedTokens.map({
      if $0.isSupported { return  self.trackerRateData[$0.identifier()] }
      return nil
    })
  }

  fileprivate func displayedTokenComparator(left: TokenObject, right: TokenObject) -> Bool {
    let tracker0Data = self.trackerRateData[left.identifier()]
    let tracker1Data = self.trackerRateData[right.identifier()]

    let isLeftFav = KNAppTracker.isTokenFavourite(left.contract.lowercased())
    let isRightFav = KNAppTracker.isTokenFavourite(right.contract.lowercased())

    if self.tokensDisplayType == .default {
      if left.extraData?.shouldShowAsNew == true { return true }
      if right.extraData?.shouldShowAsNew == true { return false }
      if isLeftFav { return true }
      if isRightFav { return false }
    }

    // sort by name
    if self.tokensDisplayType == .nameDesc { return left.symbol < right.symbol }
    if self.tokensDisplayType == .balanceDesc || self.tokensDisplayType == .default {
      // sort by balance
      guard let balance0 = self.balance(for: left) else { return false }
      guard let balance1 = self.balance(for: right) else { return true }
      let value0 = balance0.value * BigInt(10).power(18 - left.decimals)
      let value1 = balance1.value * BigInt(10).power(18 - right.decimals)
      if value0 == value1 {
        if isLeftFav { return true }
        if isRightFav { return false }
        return (tracker0Data?.rateETHNow ?? 0.0) > (tracker1Data?.rateETHNow ?? 0.0)
      }
      return value0 > value1
    }

    guard let tracker0 = tracker0Data else { return false }
    guard let tracker1 = tracker1Data else { return true }

    // sort by price or change
    if tracker1.rateUSDNow == 0.0 { return true }
    if tracker0.rateUSDNow == 0.0 { return false }

    let change0: Double = {
      return self.currencyType == .eth ? tracker0.changeETH24h : tracker0.changeUSD24h
    }()
    let change1: Double = {
      return self.currencyType == .eth ? tracker1.changeETH24h : tracker1.changeUSD24h
    }()
    // sort by change 24h
    if self.tokensDisplayType == .changeAsc { return change0 < change1 }
    if self.tokensDisplayType == .changeDesc { return change0 > change1 }
    // sort by price, rate ETH or rate USD are the same to compare
    if self.tokensDisplayType == .priceAsc { return tracker0.rateETHNow < tracker1.rateETHNow }
    return tracker0.rateETHNow > tracker1.rateETHNow
  }

  // MARK: TUTORIAL
  var currentTutorialStep: Int = 1
  var isShowingQuickTutorial: Bool = false

  var isNeedShowTutorial: Bool {
    return UserDefaults.standard.object(forKey: Constants.isDoneShowQuickTutorialForBalanceView) == nil || KNEnvironment.default == .ropsten
  }

  func updateDoneTutorial() {
    UserDefaults.standard.set(true, forKey: Constants.isDoneShowQuickTutorialForBalanceView)
  }
}
