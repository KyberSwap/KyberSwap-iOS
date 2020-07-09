// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum KNAlertState: Int {
  case active
  case triggered
  case cancelled
  case deleted
}

class KNAlertObject: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var token: String = ""
  @objc dynamic var currency: String = ""
  @objc dynamic var price: Double = 0.0
  @objc dynamic var isAbove: Bool = true
  @objc dynamic var currentPrice: Double = 0.0
  @objc dynamic var alertType: String = ""
  @objc dynamic var createdDate: TimeInterval = 0.0
  @objc dynamic var updatedDate: TimeInterval = 0.0
  @objc dynamic var triggeredDate: TimeInterval = 0.0
  @objc dynamic var stateValue: Int = KNAlertState.active.rawValue
  @objc dynamic var hasReward: Bool = false

  convenience init(token: String, currency: String, price: Double, currentPrice: Double, isAbove: Bool, type: String = "price") {
    self.init()
    self.id = -1
    self.token = token
    self.currency = currency
    self.price = price
    self.alertType = type
    self.isAbove = isAbove
    self.currentPrice = currentPrice
    self.createdDate = Date().timeIntervalSince1970
    self.updatedDate = Date().timeIntervalSince1970
    self.triggeredDate = 0.0
    self.stateValue = KNAlertState.active.rawValue
  }

  convenience init(json: JSONDictionary) {
    self.init()
    self.id = json["id"] as? Int ?? -1
    self.token = json["symbol"] as? String ?? ""
    self.currency = (json["base"] as? String ?? "").uppercased()
    self.alertType = json["alert_type"] as? String ?? ""
    self.price = json["alert_price"] as? Double ?? 0.0
    self.currentPrice = json["created_at_price"] as? Double ?? 0.0
    self.isAbove = json["is_above"] as? Bool ?? false
    let status = json["status"] as? String ?? ""
    self.stateValue = status.lowercased() == "active" ? 0 : 1 // active or triggered
    self.createdDate = {
      let string = json["created_at"] as? String ?? ""
      let date = DateFormatterUtil.shared.priceAlertAPIFormatter.date(from: string)
      return date?.timeIntervalSince1970 ?? 0.0
    }()
    self.updatedDate = {
      let string = json["updated_at"] as? String ?? ""
      let date = DateFormatterUtil.shared.priceAlertAPIFormatter.date(from: string)
      return date?.timeIntervalSince1970 ?? 0.0
    }()
    self.triggeredDate = {
      let string = json["triggered_at"] as? String ?? ""
      let date = DateFormatterUtil.shared.priceAlertAPIFormatter.date(from: string)
      return date?.timeIntervalSince1970 ?? 0.0
    }()
    self.hasReward = json["reward"] != nil
  }

  var json: JSONDictionary {
    return [
      "id": self.id,
      "symbol": self.token,
      "base": self.currency == "ETH" ? 0 : 1,
      "alert_type": 0, // type: 0 (price), 1 (percent)
      "status": 0, // active: 0, triggered: 1
      "alert_price": self.price,
      "created_at_price": self.currentPrice,
      "updated_at": self.updatedDate,
      "created_at": self.createdDate,
      "is_above": self.isAbove,
      "has_reward": self.hasReward
    ]
  }

  var state: KNAlertState { return KNAlertState(rawValue: self.stateValue) ?? .active }

  override class func primaryKey() -> String? {
    return "id"
  }
}
