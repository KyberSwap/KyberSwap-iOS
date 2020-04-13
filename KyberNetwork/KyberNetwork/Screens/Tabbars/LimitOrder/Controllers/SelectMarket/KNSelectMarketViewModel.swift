//
//  KNSelectMarketViewModel.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/8/20.
//

import Foundation

enum MarketSortType {
  case pair(asc: Bool)
  case price(asc: Bool)
  case volume(asc: Bool)
  case change(asc: Bool)
}

class KNSelectMarketViewModel {
  fileprivate var markets: [KNMarket]
  fileprivate var cellViewModels: [KNMarketCellViewModel]
  var marketType: String = "ETH" {
    didSet {
      self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
      self.updateDisplayDataSource()
    }
  }
  var sortType: MarketSortType = .price(asc: true) {
    didSet {
      self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
      self.updateDisplayDataSource()
    }
  }
  var displayCellViewModels: [KNMarketCellViewModel]
  var pickerViewSelectedValue: String?
  var isFav: Bool = false {
    didSet {
      self.updateDisplayDataSource()
    }
  }
  var searchText: String = "" {
    didSet {
      self.updateDisplayDataSource()
    }
  }

  var showNoDataView: Bool {
    return self.displayCellViewModels.isEmpty
  }

  var pickerViewData: [String]

  init() {
    self.markets = KNRateCoordinator.shared.cachedMarket
    self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
    let filterd = self.cellViewModels.filter { $0.pairName.contains("ETH") }
    let sorted = filterd.sorted { (left, right) -> Bool in
      return KNMarketCellViewModel.compareViewModel(left: left, right: right, type: .price(asc: true))
    }
    self.displayCellViewModels = sorted
    let quoteTokens = KNSupportedTokenStorage.shared.supportedTokens.filter { $0.extraData?.isQuote == true && !$0.isETH && !$0.isWETH }
    self.pickerViewData = quoteTokens.map { $0.symbol }.sorted()
  }

  fileprivate func updateDisplayDataSource() {
    var filterd: [KNMarketCellViewModel] = []
    if self.isFav {
      filterd = self.cellViewModels.filter { $0.isFav == true }
    } else {
      filterd = self.cellViewModels.filter { $0.pairName.contains(self.marketType) }
    }
    if !self.searchText.isEmpty {
      filterd = filterd.filter { $0.pairName.contains(self.searchText.uppercased()) }
    }
    let sorted = filterd.sorted { (left, right) -> Bool in
      return KNMarketCellViewModel.compareViewModel(left: left, right: right, type: self.sortType)
    }
    self.displayCellViewModels = sorted
  }

  func updateMarketFromCoordinator() {
    self.markets = KNRateCoordinator.shared.cachedMarket
    self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
    self.updateDisplayDataSource()
  }

  func getMarketObject(viewModel: KNMarketCellViewModel) -> KNMarket? {
    let searchKey = viewModel.pairName.replacingOccurrences(of: "/", with: "_")
    let market = self.markets.first { (item) -> Bool in
      return item.pair == searchKey
    }
    return market
  }
}
