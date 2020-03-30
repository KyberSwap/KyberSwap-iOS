// Copyright SIX DAY LLC. All rights reserved.

import Foundation

struct KNMarket {
  let pair: String
  let volume: Double
  let change: Double
  let sellPrice: Double
  let buyPrice: Double
  
  init(dict: [String: String]) {
    self.pair = dict["pair"] ?? ""
    self.volume = dict["volume"]?.doubleValue ?? 0.0
    self.change = dict["change"]?.doubleValue ?? 0.0
    self.sellPrice = dict["sell_price"]?.doubleValue ?? 0.0
    self.buyPrice = dict["buy_price"]?.doubleValue ?? 0.0
  }
}
