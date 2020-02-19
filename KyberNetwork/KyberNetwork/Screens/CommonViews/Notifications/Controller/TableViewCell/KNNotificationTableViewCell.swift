// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNNotificationTableViewCell: UITableViewCell {

  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  func updateCell(with noti: KNNotification, index: Int) {
    self.iconImageView.image = UIImage(named: "noti_icon_\(noti.label)")
    self.backgroundColor = {
      if !noti.read && IEOUserStorage.shared.user != nil { return UIColor(red: 232, green: 239, blue: 255) }
      return UIColor(red: 255, green: 255, blue: 255)
    }()
    self.titleLabel.text = noti.title
    self.descriptionLabel.text = noti.content
    self.timeLabel.text = {
      let notiDate = Date(timeIntervalSince1970: noti.updatedDate)
      let timePassed = Date().timeIntervalSince(notiDate)
      if timePassed > 24.0 * 60.0 * 60.0 {
        return DateFormatterUtil.shared.limitOrderFormatter.string(from: notiDate)
      }
      if timePassed > 60.0 * 60.0 {
        let hours = Int(floor(timePassed)) / (60 * 60)
        if hours == 1 { return "\(hours) hour ago" }
        return "\(hours) hours ago"
      }
      if timePassed > 60.0 {
        let mins = Int(floor(timePassed)) / 60
        if mins == 1 { return "\(mins) min ago" }
        return "\(mins) mins ago"
      }
      return "just now"
    }()
  }
}
