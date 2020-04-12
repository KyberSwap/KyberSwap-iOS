//
//  MarketTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/8/20.
//

import UIKit
import Foundation

struct KNMarketCellViewModel {
  let pairName: String
  let price: String
  let volume: String
  let change24h: NSAttributedString
  let isFav: Bool

  init(market: KNMarket) {
    self.pairName = market.pair.replacingOccurrences(of: "_", with: "/")
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    self.price = formatter.string(from: NSNumber(value: market.sellPrice)) ?? ""
    self.volume = formatter.string(from: NSNumber(value: market.volume)) ?? ""
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
    self.change24h = NSAttributedString(string: "\(fabs(market.change))", attributes: attributes)
    self.isFav = KNAppTracker.isMarketFavourite(market.pair)
  }

  static func compareViewModel(left: KNMarketCellViewModel, right: KNMarketCellViewModel, type: MarketSortType) -> Bool {
    switch type {
    case .pair(let asc):
      return asc ? left.pairName < right.pairName : left.pairName > right.pairName
    case .price(let asc):
      return asc ? left.price < right.price : left.price > right.price
    case .volume(let asc):
      return asc ? left.volume < right.volume : left.volume > right.volume
    case .change(let asc):
      return asc ? left.change24h.string < right.change24h.string : left.change24h.string > right.change24h.string
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
    self.changeButton.setAttributedTitle(viewModel.change24h, for: .normal)
    let favImg = viewModel.isFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favoriteButton.setImage(favImg, for: .normal)
  }

  @IBAction func favouriteButtonTapped(_ sender: UIButton) {
    let updateFav = !self.viewModel.isFav
    let pair = self.viewModel.pairName.replacingOccurrences(of: "/", with: "_")
    KNAppTracker.updateFavouriteMarket(pair, add: updateFav)
    let favImg = updateFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favoriteButton.setImage(favImg, for: .normal)
    self.delegate?.marketTableViewCellDidSelectFavorite(self, isFav: updateFav)
  }
}
