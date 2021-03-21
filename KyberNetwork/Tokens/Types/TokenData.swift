//
//  TokenData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/29/21.
//

import Foundation

class Token: Codable {
  var address: String
  var name: String
  var symbol: String
  var decimals: Int
  var logo: String

  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimals = dictionary["decimals"] as? Int ?? 0
    self.logo = dictionary["logo"] as? String ?? ""
  }
  
  var isETH: Bool {
    return self.symbol == "ETH"
  }
}

struct TokenBalance: Codable {
  let address: String
  let balance: String
}

struct EarnToken: Codable {
  let address: String
  let lendingPlatforms: [LendingPlatformData]
}

struct TokenPrice: Codable {
  let address: String
  let usd: Double
  let usdMarketCap: Double
  let usd24hVol: Double
  let usd24hChange: Double
  let eth: Double
  let ethMarketCap: Double
  let eth24hVol: Double
  let eth24hChange: Double
  let lastUpdateAt: Int

  init(dictionary: JSONDictionary) {
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.usd = dictionary["usd"] as? Double ?? 0.0
    self.usdMarketCap = dictionary["usd_market_cap"] as? Double ?? 0.0
    self.usd24hVol = dictionary["usd_24h_vol"] as? Double ?? 0.0
    self.usd24hChange = dictionary["usd_24h_change"] as? Double ?? 0.0
    self.eth = dictionary["usd"] as? Double ?? 0.0
    self.ethMarketCap = dictionary["usd_market_cap"] as? Double ?? 0.0
    self.eth24hVol = dictionary["usd_24h_vol"] as? Double ?? 0.0
    self.eth24hChange = dictionary["usd_24h_change"] as? Double ?? 0.0
    self.lastUpdateAt = dictionary["last_updated_at"] as? Int ?? 0
  }
}

class FavedToken: Codable {
  let address: String
  var status: Bool
  
  init(address: String, status: Bool) {
    self.address = address
    self.status = status
  }
}

struct LendingBalance: Codable {
  let name: String
  let symbol: String
  let address: String
  let decimals: Int
  let supplyRate: Double
  let stableBorrowRate: Double
  let variableBorrowRate: Double
  let supplyBalance: String
  let stableBorrowBalance: String
  let variableBorrowBalance: String
  let interestBearingTokenSymbol: String
  let interestBearingTokenAddress: String
  let interestBearingTokenDecimal: Int
  let interestBearningTokenBalance: String
  
  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimals = dictionary["decimals"] as? Int ?? 0
    self.supplyRate = dictionary["supplyRate"] as? Double ?? 0.0
    self.stableBorrowRate = dictionary["stableBorrowRate"] as? Double ?? 0.0
    self.variableBorrowRate = dictionary["variableBorrowRate"] as? Double ?? 0.0
    self.supplyBalance = dictionary["supplyBalance"] as? String ?? ""
    self.stableBorrowBalance = dictionary["stableBorrowBalance"] as? String ?? ""
    self.variableBorrowBalance = dictionary["variableBorrowBalance"] as? String ?? ""
    self.interestBearingTokenSymbol = dictionary["interestBearingTokenSymbol"] as? String ?? ""
    self.interestBearingTokenAddress = dictionary["interestBearingTokenAddress"] as? String ?? ""
    self.interestBearingTokenDecimal = dictionary["interestBearingTokenDecimal"] as? Int ?? 0
    self.interestBearningTokenBalance = dictionary["interestBearingTokenBalance"] as? String ?? ""
  }
}

struct LendingPlatformBalance: Codable {
  let name: String
  let balances: [LendingBalance]
}

struct LendingDistributionBalance: Codable {
  let name: String
  let symbol: String
  let address: String
  let decimal: Int
  let current: String
  let unclaimed: String
  
  init(dictionary: JSONDictionary) {
    self.name = dictionary["name"] as? String ?? ""
    self.symbol = dictionary["symbol"] as? String ?? ""
    self.address = (dictionary["address"] as? String ?? "").lowercased()
    self.decimal = dictionary["decimal"] as? Int ?? 0
    self.current = dictionary["current"] as? String ?? ""
    self.unclaimed = dictionary["unclaimed"] as? String ?? ""
  }
}

struct TokenData: Equatable {
  let address: String
  let name: String
  let symbol: String
  let decimals: Int
  let lendingPlatforms: [LendingPlatformData]

  static func == (lhs: TokenData, rhs: TokenData) -> Bool {
    return lhs.address.lowercased() == rhs.address.lowercased()
  }
  
  var isETH: Bool {
    return self.symbol == "ETH"
  }
}

struct LendingPlatformData: Codable {
  let name: String
  let supplyRate: Double
  let stableBorrowRate: Double
  let variableBorrowRate: Double
  let distributionSupplyRate: Double
  let distributionBorrowRate: Double

  var isCompound: Bool {
    return self.name == "Compound"
  }
}
