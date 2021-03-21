//
//  Krytal.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import Foundation

// MARK: - ReferralOverviewResponse
struct ReferralOverviewResponse: Codable {
    let timestamp: Int
    let overview: Overview
}

// MARK: - Overview
struct Overview: Codable {
    let totalPoint, cashbackPoint: Int
    let codes: [String: Code]
}

// MARK: - Code
struct Code: Codable {
    let totalRefer, totalPoint, ratio: Int
}
