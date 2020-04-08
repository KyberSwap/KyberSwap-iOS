//
//  KNSelectMarketViewModel.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/8/20.
//

import Foundation

class KNSelectMarketViewModel {
  fileprivate var markets: [KNMarket]
  var cellViewModels: [KNMarketCellViewModel]

  init() {
    self.markets = KNRateCoordinator.shared.cachedMarket
    self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
  }

  func updateMarketFromCoordinator() {
    self.markets = KNRateCoordinator.shared.cachedMarket
    self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
  }
}
