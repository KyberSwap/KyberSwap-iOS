// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import Foundation

struct Balance: BalanceProtocol {

    let value: BigInt

    init(value: BigInt) {
        self.value = value
    }

    var isZero: Bool {
        return value.isZero
    }

    var amountShort: String {
        return EtherNumberFormatter.short.string(from: value)
    }

    var amountFull: String {
        return EtherNumberFormatter.full.string(from: value)
    }
}

struct BalancesResponse: Codable {
    let timestamp: Int
    let balances: [BalanceData]
}

struct BalanceData: Codable {
    let token: Token
    let balance: String
    let quote, quoteRate: Double
}
