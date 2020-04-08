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
  
  init(market: KNMarket) {
    self.pairName = market.pair
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
    self.change24h = NSAttributedString(string: "\(fabs(market.change))", attributes: market.change > 0 ? upAttributes : downAttributes)
  }
}

class KNMarketTableViewCell: UITableViewCell {
  static let kCellID: String = "KNMarketTableViewCell"
  static let kCellHeight: CGFloat = 44

  @IBOutlet weak var pairNameLabel: UILabel!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var changeButton: UIButton!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  func updateViewModel(_ viewModel: KNMarketCellViewModel) {
    self.pairNameLabel.text = viewModel.pairName
    self.priceLabel.text = viewModel.price
    self.volumeLabel.text = viewModel.volume
    self.changeButton.setAttributedTitle(viewModel.change24h, for: .normal)
  }
}
