// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Foundation
import BigInt

struct KNMarketCellViewModel {
  let pairName: String
  let price: String
  let volume: String
  let change24h: NSAttributedString
  let isFav: Bool
  let source: KNMarket

  init(market: KNMarket) {
    self.source = market
    var marketPairName = market.pair
    let firstSymbol = market.pair.components(separatedBy: "_").first ?? ""
    let secondSymbol = market.pair.components(separatedBy: "_").last ?? ""
    if firstSymbol == "ETH" || firstSymbol == "WETH" {
      marketPairName = "ETH*_\(secondSymbol)"
    } else if secondSymbol == "ETH" || secondSymbol == "WETH" {
      marketPairName = "\(firstSymbol)_ETH*"
    }
    let pairs = marketPairName.components(separatedBy: "_")
    self.pairName = "\(pairs.last ?? "")/\(pairs.first ?? "")"
    self.price = {
      let price = market.sellPrice > 0 ? market.sellPrice : market.buyPrice
      if price == 0 { return "--" }
      return BigInt(price * pow(10.0, 18.0)).displayRate(decimals: 18)
    }()
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    let volDouble = KNRateCoordinator.shared.getMarketVolume(pair: market.pair)
    self.volume = {
      if volDouble == 0 { return "--" }
      return formatter.string(from: NSNumber(value: volDouble)) ?? "--"
    }()
    let upAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 49, green: 203, blue: 158),
    ]

    let downAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 250, green: 101, blue: 102),
    ]
    let zeroAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
    ]
    var attributes: [NSAttributedStringKey: Any] = [:]
    if market.change == 0 {
      attributes = zeroAttributes
    } else if market.change > 0 {
      attributes = upAttributes
    } else {
      attributes = downAttributes
    }
    let displayPrice = NumberFormatterUtil.shared.displayPercentage(from: fabs(market.change))
    self.change24h = NSAttributedString(string: "\(displayPrice)%", attributes: attributes)
    self.isFav = KNAppTracker.isMarketFavourite(market.pair)
  }

  static func compareViewModel(left: KNMarketCellViewModel, right: KNMarketCellViewModel, type: MarketSortType) -> Bool {
    switch type {
    case .pair(let asc):
      return asc ? left.pairName < right.pairName : left.pairName > right.pairName
    case .price(let asc):
      let leftPrice = left.source.sellPrice > 0 ? left.source.sellPrice : left.source.buyPrice
      let rightPrice = right.source.sellPrice > 0 ? right.source.sellPrice : right.source.buyPrice
      return asc ? leftPrice < rightPrice : leftPrice > rightPrice
    case .volume(let asc):
      let leftVolume = KNRateCoordinator.shared.getMarketVolume(pair: left.source.pair)
      let rightVolume = KNRateCoordinator.shared.getMarketVolume(pair: right.source.pair)
      return asc ? leftVolume < rightVolume : leftVolume > rightVolume
    case .change(let asc):
      if left.source.buyPrice == 0 && left.source.sellPrice == 0 { return false }
      if right.source.buyPrice == 0 && right.source.sellPrice == 0 { return true }
      return asc ? left.source.change < right.source.change : left.source.change > right.source.change
    }
  }
}

protocol KNMarketTableViewCellDelegate: class {
  func marketTableViewCellDidSelectFavorite(_ cell: KNMarketTableViewCell, isFav: Bool)
}

class KNMarketTableViewCell: UITableViewCell {
  static let kCellID: String = "KNMarketTableViewCell"
  static let kCellHeight: CGFloat = 44

  @IBOutlet weak var pairNameLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var changeButton: UIButton!
  @IBOutlet weak var favoriteButton: UIButton!

  var viewModel: KNMarketCellViewModel!
  weak var delegate: KNMarketTableViewCellDelegate?

  func updateViewModel(_ viewModel: KNMarketCellViewModel) {
    self.viewModel = viewModel
    self.pairNameLabel.text = viewModel.pairName
    self.priceLabel.text = viewModel.price
    self.volumeLabel.text = viewModel.volume
    if viewModel.source.sellPrice == 0 && viewModel.source.buyPrice == 0 {
      let zeroAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
      ]
      self.changeButton.setAttributedTitle(NSAttributedString(string: "--", attributes: zeroAttributes), for: .normal)
    } else {
      self.changeButton.setAttributedTitle(viewModel.change24h, for: .normal)
    }
    let favImg = viewModel.isFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favoriteButton.setImage(favImg, for: .normal)
  }

  @IBAction func favouriteButtonTapped(_ sender: UIButton) {
    let updateFav = !self.viewModel.isFav
    self.delegate?.marketTableViewCellDidSelectFavorite(self, isFav: updateFav)
  }
}
