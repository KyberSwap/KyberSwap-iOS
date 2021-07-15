//
//  OverviewEmptyTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 7/12/21.
//

import UIKit

class OverviewEmptyTableViewCell: UITableViewCell {
  
  static let kCellID: String = "OverviewEmptyTableViewCell"
  static let kCellHeight: CGFloat = 400
  
  @IBOutlet weak var imageIcon: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var button1: UIButton!
  @IBOutlet weak var button2: UIButton!
  var action: (() -> ())?
  
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.button1.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
    self.button2.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
  }
  
  @IBAction func button1Tapped(_ sender: UIButton) {
    (self.action ?? {})()
  }
}
