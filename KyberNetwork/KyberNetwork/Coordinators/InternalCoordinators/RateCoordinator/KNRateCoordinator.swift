// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya
import BigInt

/*

 This coordinator controls the fetching exchange token + usd rates,
 running timer interval to frequently fetch data from /getRate and /getRateUSD APIs

*/

class KNRateCoordinator {

  static let shared = KNRateCoordinator()

  fileprivate let provider = MoyaProvider<KNTrackerService>()
  fileprivate let userInfoProvider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])

  fileprivate var cacheTokenETHRates: [String: KNRate] = [:] // Rate token to ETH
  fileprivate var cachedProdTokenRates: [String: KNRate] = [:] // Prod cached rate to compare when swapping
  var cachedMarket: [KNMarket] = []
  var cachedMarketVolume: [String: Double] = [:]
  fileprivate var cacheRateTimer: Timer?

  fileprivate var cachedUSDRates: [String: KNRate] = [:] // Rate token to USD

  fileprivate var exchangeTokenRatesTimer: Timer?
  fileprivate var isLoadingExchangeTokenRates: Bool = false
  fileprivate var platformFeeTimer: Timer?

  fileprivate var lastRefreshTime: Date = Date()
  var currentSymPair: (String, String) = ("KNC", "ETH")

  func getRate(from: TokenObject, to: TokenObject) -> KNRate? {
    if from.isETH {
      if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: to) {
        return KNRate(
          source: from.symbol,
          dest: to.symbol,
          rate: trackerRate.rateETHNow == 0.0 ? 0.0 : 1.0 / trackerRate.rateETHNow,
          decimals: to.decimals
        )
      }
    } else if to.isETH {
      if let rate = self.cacheTokenETHRates[from.symbol] { return rate }
      if let rate = KNTrackerRateStorage.shared.trackerRate(for: from) {
        return KNRate.rateETH(from: rate)
      }
    }
    guard let rateFrom = KNTrackerRateStorage.shared.trackerRate(for: from),
      let rateTo = KNTrackerRateStorage.shared.trackerRate(for: to) else { return nil }
    if rateTo.rateUSDNow == 0.0 { return nil }
    return KNRate(
      source: from.symbol,
      dest: to.symbol,
      rate: rateFrom.rateUSDNow / rateTo.rateUSDNow,
      decimals: to.decimals
    )
  }

  func getCachedProdRate(from: TokenObject, to: TokenObject) -> BigInt? {
    if let rate = self.cachedProdTokenRates["\(from.symbol)_\(to.symbol)"] { return rate.rate }
    if let rateToETH = self.cachedProdTokenRates["\(from.symbol)_ETH"],
      let rateETHTo = self.cachedProdTokenRates["ETH_\(to.symbol)"] {
      let swapRate = rateToETH.rate * rateETHTo.rate / BigInt(10).power(18)
      return swapRate
    }
    return self.getRate(from: from, to: to)?.rate
  }

  func getCacheRate(from: String, to: String) -> KNRate? {
    if to == "ETH" { return self.cacheTokenETHRates[from] }
    if to == "USD" { return self.cachedUSDRates[from] }
    return self.cachedProdTokenRates["\(from)_\(to)"]
  }

  func usdRate(for token: TokenObject) -> KNRate? {
    if let cachedRate = self.cachedUSDRates[token.symbol] { return cachedRate }
    if let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate.rateUSD(from: trackerRate)
    }
    return nil
  }

  func ethRate(for token: TokenObject) -> KNRate? {
    if let rate = self.getCacheRate(from: token.symbol, to: "ETH") { return rate }
    if let rate = KNTrackerRateStorage.shared.trackerRate(for: token) {
      return KNRate(source: "", dest: "", rate: rate.rateETHNow, decimals: 18)
    }
    return nil
  }

  init() {}

  func resume() {
    self.fetchCacheRate(nil)
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] timer in
        self?.fetchCacheRate(timer)
      }
    )
    // Immediate fetch data from server, then run timers with interview 60 seconds
    self.fetchExchangeTokenRate(nil)
    self.exchangeTokenRatesTimer?.invalidate()
    self.platformFeeTimer?.invalidate()

    self.exchangeTokenRatesTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchExchangeTokenRate(timer)
      }
    )

    self.fetchPlatformFee(nil)
    self.platformFeeTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] (timer) in
        self?.fetchPlatformFee(timer)
      }
    )
  }

  func pause() {
    self.cacheRateTimer?.invalidate()
    self.cacheRateTimer = nil
    self.exchangeTokenRatesTimer?.invalidate()
    self.exchangeTokenRatesTimer = nil
    self.platformFeeTimer?.invalidate()
    self.platformFeeTimer = nil
    self.isLoadingExchangeTokenRates = false
  }

  func refreshData() {
    if Date().timeIntervalSince(self.lastRefreshTime) > 15.0 {
      self.lastRefreshTime = Date()
      self.fetchCacheRate(nil)
      self.fetchExchangeTokenRate(nil)
    }
  }

  @objc func fetchExchangeTokenRate(_ sender: Any?) {
    if isLoadingExchangeTokenRates { return }
    isLoadingExchangeTokenRates = true
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KNTrackerService>()
      provider.request(.getRates, completion: { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.isLoadingExchangeTokenRates = false
          if case .success(let resp) = result {
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              guard let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary else { return }
              var rates: [KNTrackerRate] = []
              for value in json.values {
                if let rateJSON = value as? JSONDictionary {
                  rates.append(KNTrackerRate(dict: rateJSON))
                }
              }
              KNTrackerRateStorage.shared.update(rates: rates)
              // cached rate is more updated than exchange token rate API
              self.updateTrackerRateWithCachedRates(isUSD: true, isNotify: false)
              self.updateTrackerRateWithCachedRates(isUSD: false, isNotify: true)

            } catch {}
          }
        }
      })
    }
  }

  @objc func fetchCacheRate(_ sender: Any?) { //Note: fetch cache rate
    let group = DispatchGroup()
    group.enter()
    KNInternalProvider.shared.getKNExchangeTokenRate { [weak self] result in
      guard let `self` = self else {
        group.leave()
        return
      }
      if case .success(let rates) = result {
        rates.forEach({
          if $0.dest == "ETH" { self.cacheTokenETHRates[$0.source] = $0 }
        })
        self.updateTrackerRateWithCachedRates(isUSD: false, isNotify: false)
      }
      group.leave()
    }
    group.enter()
    KNInternalProvider.shared.getKNExchangeRateUSD { [weak self] result in
      guard let `self` = self else {
        group.leave()
        return
      }
      if case .success(let rates) = result {
        rates.forEach({
          if $0.dest == "USD" { self.cachedUSDRates[$0.source] = $0 }
        })
        self.updateTrackerRateWithCachedRates(isUSD: true, isNotify: false)
      }
      group.leave()
    }
    group.notify(queue: .main) {
      KNNotificationUtil.postNotification(for: kExchangeTokenRateNotificationKey)
    }

    self.updateReferencePrice(fromSym: self.currentSymPair.0, toSym: self.currentSymPair.1)

    KNLimitOrderServerCoordinator.shared.getMarket { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let rates) = result {
        self.cachedMarket = rates.map { KNMarket(dict: $0) }
        self.cachedMarket.forEach { market in
          self.cachedMarketVolume[market.pair] = market.volume
        }
        KNNotificationUtil.postNotification(for: kMarketSuccessToLoadNotiKey)
      } else {
        KNNotificationUtil.postNotification(for: kMarketFailedToLoadNotiKey)
      }
    }
  }

  @objc func fetchPlatformFee(_ sender: Any?) {
    self.userInfoProvider.request(.getPlatformFee) { [weak self] (response) in
      guard let _ = self else { return }
      switch response {
      case .success(let resp):
        do {
          let _ = try resp.filterSuccessfulStatusCodes()
          let json = try resp.mapJSON() as? JSONDictionary ?? [:]
          if let isSuccess = json["success"] as? Bool,
            isSuccess == true,
            let fee = json["fee"] as? NSNumber {
            UserDefaults.standard.set(fee.intValue, forKey: KNAppTracker.kPlatformFeeKey)
          }
        } catch {
        }
      case .failure:
        break
      }
    }
  }

  func updateReferencePrice(fromSym: String, toSym: String) {
    if toSym == "ETH" || fromSym == "ETH" {
      var sym = ""
      if toSym == "ETH" {
        sym = fromSym
      } else {
        sym = toSym
      }
      KNInternalProvider.shared.getProductionChainLinkRate(sym: sym) { [weak self] result in
        guard let `self` = self else { return }
        if case .success(let rate) = result, rate.doubleValue > 0 {
          if toSym == "ETH" {
            var decimal = 18
            if let fromToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { (token) -> Bool in
              return token.symbol == fromSym
            }) {
              decimal = fromToken.decimals
            }
            self.cachedProdTokenRates["\(fromSym)_\(toSym)"] = KNRate(source: sym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
            self.cachedProdTokenRates["\(toSym)_\(fromSym)"] = KNRate(source: "ETH", dest: sym, rate: 1 / rate.doubleValue, decimals: decimal)
          } else {
            var decimal = 18
            if let toToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { (token) -> Bool in
              return token.symbol == toSym
            }) {
              decimal = toToken.decimals
            }
            self.cachedProdTokenRates["\(fromSym)_\(toSym)"] = KNRate(source: "ETH", dest: sym, rate: 1 / rate.doubleValue, decimals: decimal)
            self.cachedProdTokenRates["\(toSym)_\(fromSym)"] = KNRate(source: sym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
          }

          KNNotificationUtil.postNotification(for: kProdCachedRateSuccessToLoadNotiKey)
        } else {
          self.updateListCacheRate()
        }
      }
      return
    }

    var rateFrom: KNRate?
    var rateTo: KNRate?
    let group = DispatchGroup()
    group.enter()
    KNInternalProvider.shared.getProductionChainLinkRate(sym: fromSym) { result in
      if case .success(let rate) = result, rate.doubleValue > 0 {
        var decimal = 18
        if let fromToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { (token) -> Bool in
          return token.symbol == fromSym
        }) {
          decimal = fromToken.decimals
        }
        rateFrom = KNRate(source: fromSym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
        self.cachedProdTokenRates["\(fromSym)_ETH"] = KNRate(source: fromSym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
        self.cachedProdTokenRates["ETH_\(fromSym)"] = KNRate(source: "ETH", dest: fromSym, rate: 1 / rate.doubleValue, decimals: decimal)
      }
      group.leave()
    }
    group.enter()
    KNInternalProvider.shared.getProductionChainLinkRate(sym: toSym) { result in
      if case .success(let rate) = result, rate.doubleValue > 0 {
        var decimal = 18
        if let toToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { (token) -> Bool in
          return token.symbol == toSym
        }) {
          decimal = toToken.decimals
        }
        rateTo = KNRate(source: toSym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
        self.cachedProdTokenRates["\(toSym)_ETH"] = KNRate(source: toSym, dest: "ETH", rate: rate.doubleValue, decimals: 18)
        self.cachedProdTokenRates["ETH_\(toSym)"] = KNRate(source: "ETH", dest: toSym, rate: 1 / rate.doubleValue, decimals: decimal)
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let notNilRateFrom = rateFrom, let notNilRateTo = rateTo {
        if notNilRateTo.rate.isZero || notNilRateFrom.rate.isZero {
          self.cachedProdTokenRates["\(fromSym)_\(toSym)"] = KNRate(source: fromSym, dest: toSym, rate: 0.0, decimals: 18)
          KNNotificationUtil.postNotification(for: kProdCachedRateSuccessToLoadNotiKey)
          return
        }
        var decimal = 18
        if let toToken = KNSupportedTokenStorage.shared.supportedTokens.first(where: { (token) -> Bool in
          return token.symbol == toSym
        }) {
          decimal = toToken.decimals
        }
        guard notNilRateTo.rate.description.doubleValue != 0.0 else { return }
        let finalRateValue = notNilRateFrom.rate.description.doubleValue / notNilRateTo.rate.description.doubleValue
        let finalRate = KNRate(source: fromSym, dest: toSym, rate: finalRateValue, decimals: decimal)
        self.cachedProdTokenRates["\(fromSym)_\(toSym)"] = finalRate
        KNNotificationUtil.postNotification(for: kProdCachedRateSuccessToLoadNotiKey)
      } else {
        self.updateListCacheRate()
      }
    }
  }

  fileprivate func updateListCacheRate() {
    KNInternalProvider.shared.getProductionCachedRate { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let rates) = result {
        rates.forEach({
          self.cachedProdTokenRates["\($0.source)_\($0.dest)"] = $0
        })
        KNNotificationUtil.postNotification(for: kProdCachedRateSuccessToLoadNotiKey)
      } else {
        KNNotificationUtil.postNotification(for: kProdCachedRateFailedToLoadNotiKey)
      }
    }
  }

  func getMarketWith(name: String) -> KNMarket? {
    guard !self.cachedMarket.isEmpty else {
      return KNMarket(dict: ["pair": name])
    }
    let market = self.cachedMarket.first { (market) -> Bool in
      return market.pair == name
    }
    return market
  }

  func getMarketVolume(pair: String) -> Double {
    let firstSymbol = pair.components(separatedBy: "_").first ?? ""
    let secondSymbol = pair.components(separatedBy: "_").last ?? ""
    if firstSymbol == "ETH" || firstSymbol == "WETH" {
      return (self.cachedMarketVolume["ETH_\(secondSymbol)"] ?? 0) + (self.cachedMarketVolume["WETH_\(secondSymbol)"] ?? 0)
    }
    if secondSymbol == "ETH" || secondSymbol == "WETH" {
      return (self.cachedMarketVolume["\(firstSymbol)_ETH"] ?? 0) + (self.cachedMarketVolume["\(firstSymbol)_WETH"] ?? 0)
    }
    return self.cachedMarketVolume[pair] ?? 0
  }

  fileprivate func updateTrackerRateWithCachedRates(isUSD: Bool, isNotify: Bool = true) {
    KNTrackerRateStorage.shared.updateCachedRates(
      cachedRates: isUSD ? self.cachedUSDRates.map({ $0.1 }) : self.cacheTokenETHRates.map({ $0.1 })
    )
    if isNotify { KNNotificationUtil.postNotification(for: kExchangeTokenRateNotificationKey) }
  }

  func getCachedSourceAmount(from: TokenObject, to: TokenObject, destAmount: Double, completion: @escaping (Result<BigInt?, AnyError>) -> Void) {
    let fromAddr = from.contract
    let toAddr = to.contract

    DispatchQueue.global().async {
      self.provider.request(.getSourceAmount(src: fromAddr, dest: toAddr, amount: destAmount)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            do {
              let _ = try resp.filterSuccessfulStatusCodes()
              let json = try resp.mapJSON() as? JSONDictionary ?? [:]
              if let err = json["error"] as? Bool, !err, let value = json["data"] as? String, let amount = value.fullBigInt(decimals: from.decimals) {
                // add platform fee
                completion(.success(amount * BigInt(10000 + KNAppTracker.getPlatformFee(source: from.addressObj, dest: to.addressObj)) / BigInt(10000)))
              } else {
                completion(.success(nil))
              }
            } catch let error {
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}

class KNRateHelper {
  static func displayRate(from rate: BigInt, decimals: Int) -> String {
    /*
     Displaying rate with at most 4 digits after leading zeros
     */
    if rate.isZero { return "0.0000" }
    var string = rate.string(decimals: decimals, minFractionDigits: decimals, maxFractionDigits: decimals)
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) {
      string += "0000"
    } else {
      return rate.string(decimals: decimals, minFractionDigits: min(decimals, 4), maxFractionDigits: min(decimals, 4))
    }
    var isZeroNumber = false
    if let range = string.range(of: separator)?.lowerBound {
      let numberString = string[..<range]
      if Int(numberString) == 0 {
        isZeroNumber = true
      }
    }
    var start = false
    var cnt = 0
    var separatorIndex = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        separatorIndex = id
        start = true
      } else if start {
        if !isZeroNumber && (id - separatorIndex) == 6 {
          let fractionDigit = cnt == 0 ? 4 : 6
          return rate.string(
            decimals: decimals,
            minFractionDigits: fractionDigit,
            maxFractionDigits: fractionDigit
          )
        }
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 {
          return rate.string(
            decimals: decimals,
            minFractionDigits: id - separatorIndex,
            maxFractionDigits: id - separatorIndex
          )
        }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }

  static func displayRate(from rate: String) -> String {
    var string = rate
    let separator = EtherNumberFormatter.full.decimalSeparator
    if let _ = string.firstIndex(of: separator[separator.startIndex]) { string = string + "0000" }
    var start = false
    var cnt = 0
    var index = string.startIndex
    for id in 0..<string.count {
      if string[index] == separator[separator.startIndex] {
        start = true
      } else if start {
        if cnt > 0 || string[index] != "0" { cnt += 1 }
        if cnt == 4 { return string.substring(to: id + 1) }
      }
      index = string.index(after: index)
    }
    if cnt == 0, let id = string.firstIndex(of: separator[separator.startIndex]) {
      index = string.index(id, offsetBy: 5)
      return String(string[..<index])
    }
    return string
  }
}
