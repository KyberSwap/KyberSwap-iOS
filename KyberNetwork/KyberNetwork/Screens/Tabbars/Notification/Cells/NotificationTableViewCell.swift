//
//  NotificationTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/2/21.
//

import UIKit
import Kingfisher

struct NotificationCellViewModel {
  let notification: NotificationItem
  
  var timeText: String {
    guard let updateDate = DateFormatterUtil.shared.notificationDateFormatter.date(from: self.notification.updatedAt) else { return "" }
    let now = Date()
    let dayInterval = now.days(from: updateDate)
    if dayInterval < 7 {
      return "\(dayInterval) days ago"
    }
    let hourInterval = now.hours(from: updateDate)
    if hourInterval < 24 {
      return "\(hourInterval) mins ago"
    }
    let minuterInterval = now.minutes(from: updateDate)
    if minuterInterval < 60 {
      return "\(minuterInterval) mins ago"
    }
    let secondInterval = now.seconds(from: updateDate)
    if secondInterval <= 15 {
      return "just now".toBeLocalised()
    } else if secondInterval < 60 {
      return "\(secondInterval) secs ago"
    }
    
    
    return DateFormatterUtil.shared.notificationDisplayDateFormatter.string(from: updateDate)
  }
}

class NotificationTableViewCell: UITableViewCell {
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!
  
  static let cellHeight: CGFloat = 60
  static let cellID: String = "NotificationTableViewCell"
  
  func updateCell(viewModel: NotificationCellViewModel) {
    let url = URL(string: viewModel.notification.image)
    self.iconImageView.kf.setImage(with: url)
    self.titleLabel.text = viewModel.notification.title
    self.subTitleLabel.text = viewModel.notification.content
    self.timeLabel.text = viewModel.timeText
  }
}
