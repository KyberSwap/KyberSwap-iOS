//
//  OverviewMarketTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import SwipeCellKit

class OverviewMarketCellViewModel {
  let token: Token
  let tokenPrice: TokenPrice
  var isFaved: Bool
  var type: CurrencyType
  
  init(token: Token, price: TokenPrice, isFaved: Bool, type: CurrencyType = .usd) {
    self.token = token
    self.tokenPrice = price
    self.isFaved = isFaved
    self.type = type
  }
  
  var displaySymbol: String {
    return self.token.symbol.uppercased()
  }
  
  var priceDouble: Double {
    switch self.type {
    case .usd:
      return self.tokenPrice.usd
    case .eth:
      return self.tokenPrice.eth
    case .btc:
      return self.tokenPrice.btc
    }
  }

  var displayPrice: String {
    let price = self.priceDouble
    switch self.type {
    case .usd:
      return "$" + String(format: "%.6f", price)
    case .eth:
      return String(format: "%.6f", price) + " ETH"
    case .btc:
      return String(format: "%.6f", price) + " BTC"
    }
  }
  
  var change24Double: Double {
    switch self.type {
    case .usd:
      return self.tokenPrice.usd24hChange
    case .eth:
      return self.tokenPrice.eth24hChange
    case .btc:
      return self.tokenPrice.btc24hChange
    }
  }
  
  var displayChange24h: String {
    let change24 = self.change24Double
    return String(format: "%.2f", change24) + "%"
  }
  
  var displayChange24Color: UIColor {
    let change24 = self.change24Double
    return change24 > 0 ? UIColor.Kyber.SWGreen : UIColor.Kyber.SWRed
  }
  
  var displayFavoriteImage: UIImage? {
    return self.isFaved ? UIImage(named: "fav_overview_icon") : UIImage(named: "unFav_overview_icon")
  }
}

class OverviewMarketTableViewCell: SwipeTableViewCell {
  static let kCellID: String = "OverviewMarketTableViewCell"
  static let kCellHeight: CGFloat = 44
  
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var tokenSymbolLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var change24Label: UILabel!
  @IBOutlet weak var favoriteButton: UIButton!
  weak var viewModel: OverviewMarketCellViewModel?

  func updateCell(viewModel: OverviewMarketCellViewModel) {
    self.tokenIconImageView.setSymbolImage(symbol: viewModel.token.symbol)
    self.tokenSymbolLabel.text = viewModel.displaySymbol
    self.priceLabel.text = viewModel.displayPrice
    self.change24Label.text = viewModel.displayChange24h
    self.change24Label.backgroundColor = viewModel.displayChange24Color
    self.favoriteButton.setImage(viewModel.displayFavoriteImage, for: .normal)
    self.viewModel = viewModel
  }
  
  @IBAction func favouriteButtonTapped(_ sender: Any) {
    guard let viewModel = self.viewModel else {
      return
    }
    viewModel.isFaved = !viewModel.isFaved
    self.updateCell(viewModel: viewModel)
    KNSupportedTokenStorage.shared.setFavedStatusWithAddress(viewModel.token.address, status: viewModel.isFaved)
  }
}
