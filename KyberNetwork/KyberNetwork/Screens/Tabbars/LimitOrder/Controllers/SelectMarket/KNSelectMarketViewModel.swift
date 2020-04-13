//
//  KNSelectMarketViewModel.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/8/20.
//

import Foundation

enum MarketType: String {
  case dai = "DAI"
  case eth = "ETH"
  case wbtc = "WBTC"
  case sai = "SAI"
  case tusd = "TUSD"
  case usdc = "USDC"
  case usdt = "USDT"
}

enum MarketSortType {
  case pair(asc: Bool)
  case price(asc: Bool)
  case volume(asc: Bool)
  case change(asc: Bool)
}

class KNSelectMarketViewModel {
  fileprivate var markets: [KNMarket]
  fileprivate var cellViewModels: [KNMarketCellViewModel]
  var marketType: MarketType = .dai {
    didSet {
      if !self.isFav {
        self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
      }
      self.updateDisplayDataSource()
    }
  }
  var sortType: MarketSortType = .price(asc: true) {
    didSet {
      if !self.isFav {
        self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
      }
      self.updateDisplayDataSource()
    }
  }
  var displayCellViewModels: [KNMarketCellViewModel]
  var pickerViewSelectedValue: MarketType?
  var isFav: Bool = false
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
    let filterd = self.cellViewModels.filter { $0.pairName.contains(MarketType.dai.rawValue) }
    let sorted = filterd.sorted { (left, right) -> Bool in
      return KNMarketCellViewModel.compareViewModel(left: left, right: right, type: .price(asc: true))
    }
    self.displayCellViewModels = sorted
    let quoteTokens = KNSupportedTokenStorage.shared.supportedTokens.filter { $0.extraData?.isQuote == true && !$0.isETH && !$0.isWETH }
    self.pickerViewData = quoteTokens.map { $0.symbol }.sorted()
  }

  fileprivate func updateDisplayDataSource() {
    let filterOption = self.searchText.isEmpty ? self.marketType.rawValue : self.searchText.uppercased()
    let filterd = self.cellViewModels.filter { $0.pairName.contains(filterOption) }
    let sorted = filterd.sorted { (left, right) -> Bool in
      return KNMarketCellViewModel.compareViewModel(left: left, right: right, type: self.sortType)
    }
    self.displayCellViewModels = sorted
  }

  func updateMarketFromCoordinator() {
    self.markets = KNRateCoordinator.shared.cachedMarket
    if !self.isFav {
      self.cellViewModels =  self.markets.map { KNMarketCellViewModel(market: $0) }
    }
    self.updateDisplayDataSource()
  }

  func getMarketObject(viewModel: KNMarketCellViewModel) -> KNMarket? {
    let searchKey = viewModel.pairName.replacingOccurrences(of: "/", with: "_")
    let market = self.markets.first { (item) -> Bool in
      return item.pair == searchKey
    }
    return market
  }

  func generateFavouriteData() {
    let favored = KNAppTracker.getListFavouriteTokens()
    let filterKeys = favored.map { $0.replacingOccurrences(of: "_", with: "/") }
    let favoredCellVM = self.cellViewModels.filter { (vm) -> Bool in
        return filterKeys.contains(vm.pairName)
    }
    self.cellViewModels = favoredCellVM
    self.updateDisplayDataSource()
  }
}
