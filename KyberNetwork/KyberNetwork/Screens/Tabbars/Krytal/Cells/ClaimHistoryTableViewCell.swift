//
//  ClaimHistoryTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/3/21.
//

import UIKit

struct ClaimHistoryCellViewModel {
  let historyItem: Claim
  
  var displayPoint: String {
    return "\(self.historyItem.amount) KP"
  }
  
  var displayStatus: String {
    return self.historyItem.fulfill ? "RECEIVE" : "UNFULLFILL"
  }
  
  var displayTime: String {
    let date = Date(timeIntervalSince1970: TimeInterval(self.historyItem.timestamp))
    return DateFormatterUtil.shared.historyTransactionDateFormatter.string(from: date)
  }
}

class ClaimHistoryTableViewCell: UITableViewCell {
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var statusLable: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  static let cellHeight: CGFloat = 44
  static let cellID: String = "ClaimHistoryTableViewCell"

  func updateCell(viewModel: ClaimHistoryCellViewModel) {
    self.amountLabel.text = viewModel.displayPoint
    self.statusLable.text = viewModel.displayStatus
    self.timeLabel.text = viewModel.displayTime
  }
}
