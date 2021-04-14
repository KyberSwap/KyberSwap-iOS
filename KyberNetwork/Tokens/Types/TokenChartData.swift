//
//  TokenChartData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/25/21.
//

import Foundation

struct ChartData: Codable {
    let prices, marketCaps, totalVolumes: [[Double]]

    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
}

struct TokenDetailData: Codable {
  let tokenDetailDataDescription: Description
  let icoData: IcoData?
  let marketData: MarketData
  let links: TokenDetailDataLinks
  
  enum CodingKeys: String, CodingKey {
    case tokenDetailDataDescription = "description"
    case icoData = "ico_data"
    case marketData = "market_data"
    case links
  }
}

struct IcoData: Codable {
  let icoDataDescription: String?
}

struct MarketData: Codable {
  let currentPrice: [String: Double]?
  let ath, athChangePercentage: [String: Double]?
  let atl, atlChangePercentage: [String: Double]?
  let marketCap: [String: Double]?
  
}

struct Description: Codable {
  let en: String
}

struct TokenDetailDataLinks: Codable {
  let homepage: [String]
  let twitterScreenName: String
  
  enum CodingKeys: String, CodingKey {
    case homepage
    case twitterScreenName = "twitter_screen_name"
  }
}
