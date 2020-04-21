// Copyright SIX DAY LLC. All rights reserved.

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
  var marketType: String = "/ETH*" {
    didSet {
      self.updateDisplayDataSource()
    }
  }
  var sortType: MarketSortType = .price(asc: false) {
    didSet {
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
    self.markets = KNRateCoordinator.shared.cachedMarket.filter { $0.pair.components(separatedBy: "_").first != "ETH" && $0.pair.components(separatedBy: "_").last != "ETH" }
    self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
    let filterd = self.cellViewModels.filter { $0.pairName.contains("/ETH*") }
    let sorted = filterd.sorted { (left, right) -> Bool in
      return KNMarketCellViewModel.compareViewModel(left: left, right: right, type: .price(asc: false))
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
    self.markets = KNRateCoordinator.shared.cachedMarket.filter { $0.pair.components(separatedBy: "_").first != "ETH" && $0.pair.components(separatedBy: "_").last != "ETH" }
    self.cellViewModels = self.markets.map { KNMarketCellViewModel(market: $0) }
    self.updateDisplayDataSource()
  }
}
