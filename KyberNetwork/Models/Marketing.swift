//
//  Marketing.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation

// MARK: - MarketingAssetsResponse
struct MarketingAssetsResponse: Codable {
    let timestamp: Int
    let assets: [Asset]
}

// MARK: - Asset
struct Asset: Codable {
    let id: Int
    let url: String
    let imageURL: String
    let type: TypeEnum

    enum CodingKeys: String, CodingKey {
        case id, url
        case imageURL = "imageUrl"
        case type
    }
}

enum TypeEnum: String, Codable {
    case banner = "banner"
    case partner = "partner"
}
