// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import BigInt
import TrustKeystore
import TrustCore

class TokenObject: Object {
    @objc dynamic var contract: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimals: Int = 0
    @objc dynamic var value: String = ""
    @objc dynamic var icon: String = ""
    @objc dynamic var isCustom: Bool = false
    @objc dynamic var isSupported: Bool = false
    @objc dynamic var isDisabled: Bool = false

    convenience init(
        contract: String = "",
        name: String = "",
        symbol: String = "",
        decimals: Int = 0,
        value: String,
        isCustom: Bool = false,
        isSupported: Bool = false,
        isDisabled: Bool = false
    ) {
        self.init()
        self.contract = contract
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.value = value
        self.icon = symbol.lowercased()
        self.isCustom = isCustom
        self.isSupported = isSupported
        self.isDisabled = isDisabled
    }

    // init from local json
    convenience init(localDict: JSONDictionary) {
      self.init()
      self.name = localDict["name"] as? String ?? ""
      self.symbol = localDict["symbol"] as? String ?? ""
      self.icon = self.symbol.lowercased()
      self.contract = (localDict["address"] as? String ?? "").lowercased()
      self.decimals = localDict["decimals"] as? Int ?? 0
      self.isSupported = true
      self.addExtraData(json: localDict)
    }

    // init from public API
    convenience init(apiDict: JSONDictionary) {
      self.init()
      self.name = apiDict["name"] as? String ?? ""
      self.symbol = apiDict["symbol"] as? String ?? ""
      self.icon = self.symbol.lowercased()
      self.contract = (apiDict["address"] as? String ?? "").lowercased()
      self.decimals = apiDict["decimals"] as? Int ?? 0
      self.isSupported = true
      self.addExtraData(json: apiDict)
    }

    var isETH: Bool {
      return self.symbol == "ETH" && self.name.lowercased() == "ethereum"
    }

    var isWETH: Bool {
      return self.symbol == "WETH"
    }

    var symbolLODisplay: String {
      if self.isETH || self.isWETH { return "ETH*" }
      return self.symbol
    }

    var isPromoToken: Bool {
      let promoTokenSymbol: String = {
//        if KNEnvironment.default == .production || KNEnvironment.default == .mainnetTest || KNEnvironment.default == .staging { return "PT" }
        if KNEnvironment.default == .production || KNEnvironment.default == .mainnetTest { return "PT" }
        return "OMG" // set OMG as PT token for other networks
      }()
      return promoTokenSymbol == self.symbol
    }

    var isDGX: Bool { return self.symbol == "DGX" }
    var isDAI: Bool { return self.symbol == "DAI" || self.symbol == "SAI" }
    var isMKR: Bool { return self.symbol == "MKR" }
    var isPRO: Bool { return self.symbol == "PRO" }
    var isPT: Bool { return self.symbol == "PT" }
    var isTUSD: Bool { return self.symbol == "TUSD" && self.name.lowercased() == "trueusd" }

    var isKNC: Bool {
      return self.symbol == "KNC" && self.name.replacingOccurrences(of: " ", with: "").lowercased() == "kybernetwork"
    }

    var display: String {
      return "\(self.symbol) - \(self.name)"
    }

    var address: Address {
        return Address(string: contract)!
    }

    var valueBigInt: BigInt {
        return BigInt(value) ?? BigInt()
    }

    override static func primaryKey() -> String? {
        return "contract"
    }

    override static func ignoredProperties() -> [String] {
        return ["type"]
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TokenObject else { return false }
        return object.contract == self.contract
    }

    var title: String {
        return name.isEmpty ? symbol : (name + " (" + symbol + ")")
    }

    var symbolAndNameID: String {
      return self.symbol + " " + self.name.replacingOccurrences(of: " ", with: "").lowercased()
    }

  /**
   Clone object to use in another realm
  */
  func clone() -> TokenObject {
    return TokenObject(
      contract: self.contract,
      name: self.name,
      symbol: self.symbol,
      decimals: self.decimals,
      value: self.value,
      isCustom: self.isCustom,
      isSupported: self.isSupported,
      isDisabled: self.isDisabled
    )
  }

  func addExtraData(json: JSONDictionary) {
    let extraData = TokenExtraData(dict: json)
    let key = "\(KNEnvironment.default.displayName)_\(self.contract)"
    UserDefaults.standard.set(extraData.json, forKey: key)
    UserDefaults.standard.synchronize()
  }
}

extension TokenObject {
  func identifier() -> String {
    if KNEnvironment.default == .kovan || KNEnvironment.default == .ropsten || KNEnvironment.default == .rinkeby {
      return self.symbol
    }
    return self.contract.lowercased()
  }

  var iconURL: String {
    return "https://raw.githubusercontent.com/KyberNetwork/KyberNetwork.github.io/master/DesignAssets/tokens/iOS/\(self.icon).png"
  }

  func contains(_ text: String) -> Bool {
    if text.isEmpty { return true }
    let desc = "\(symbol)\(name)".replacingOccurrences(of: " ", with: "").lowercased()
    return desc.contains(text.lowercased())
  }

  var extraData: TokenExtraData? {
    let key = "\(KNEnvironment.default.displayName)_\(self.contract)"
    if let object = UserDefaults.standard.object(forKey: key) as? JSONDictionary {
      return TokenExtraData(dict: object)
    }
    return nil
  }
}

class TokenExtraData: NSObject {
  let address: String
  let gasLimit: String
  let gasApprove: Double
  let listingTime: TimeInterval
  let limitOrderEnabled: Bool
  let isQuote: Bool
  let isGasFixed: Bool
  let quotePriority: Int

  init(address: String, gasLimit: String, gasApprove: Double, listingTime: TimeInterval, limitOrderEnabled: Bool, isQuote: Bool, isGasFixed: Bool, quotePriority: Int) {
    self.address = address
    self.gasLimit = gasLimit
    self.gasApprove = gasApprove
    self.listingTime = listingTime
    self.limitOrderEnabled = limitOrderEnabled
    self.isQuote = isQuote
    self.isGasFixed = isGasFixed
    self.quotePriority = quotePriority
  }

  init(dict: JSONDictionary) {
    self.address = dict["address"] as? String ?? ""
    self.gasLimit = dict["gasLimit"] as? String ?? ""
    self.gasApprove = dict["gasApprove"] as? Double ?? 0.0
    self.listingTime = dict["listing_time"] as? TimeInterval ?? 0.0
    self.limitOrderEnabled = dict["sp_limit_order"] as? Bool ?? false
    self.isQuote = dict["is_quote"] as? Bool ?? false
    self.isGasFixed = dict["is_gas_fixed"] as? Bool ?? false
    self.quotePriority = dict["quote_priority"] as? Int ?? 0
  }

  var json: JSONDictionary {
    return [
      "address": address,
      "gasLimit": gasLimit,
      "gasApprove": gasApprove,
      "listing_time": listingTime,
      "sp_limit_order": self.limitOrderEnabled,
      "is_quote": self.isQuote,
      "is_gas_fixed": self.isGasFixed,
      "quote_priority": self.quotePriority
    ]
  }

  var gasLimitDefault: BigInt? {
    guard !self.gasLimit.isEmpty else { return nil }
    guard let value = self.gasLimit.shortBigInt(units: .wei), !value.isZero else { return nil }
    return value
  }

  var gasApproveDefault: BigInt? {
    guard self.gasApprove != 0.0 else { return nil }
    return BigInt(self.gasApprove)
  }

  var shouldShowAsNew: Bool {
    // less than 7 days
    let date = Date(timeIntervalSince1970: self.listingTime)
    return Date().timeIntervalSince(date) <= 7.0 * 24.0 * 60.0 * 60.0
  }

  var isListed: Bool {
    let date = Date(timeIntervalSince1970: self.listingTime)
    return Date().timeIntervalSince(date) >= 0
  }
}
