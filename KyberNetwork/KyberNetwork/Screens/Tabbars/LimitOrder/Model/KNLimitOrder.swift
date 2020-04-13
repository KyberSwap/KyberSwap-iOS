// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore

struct KNLimitOrder {
  let from: TokenObject
  let to: TokenObject
  let account: Account
  let sender: Address
  let srcAmount: BigInt
  let targetRate: BigInt
  let fee: Int
  let transferFee: Int
  let nonce: String
  let isBuy: Bool?
}

// use this to reduce rounding error
struct KNLimitOrderConfirmData {
  let price: String
  let amount: String
  let totalAmount: String
  let livePrice: String
}
