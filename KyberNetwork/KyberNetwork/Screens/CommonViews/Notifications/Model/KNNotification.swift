// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNNotification: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var title: String = ""
  @objc dynamic var content: String = ""
  @objc dynamic var scope: String = ""
  @objc dynamic var userID: Int = -1
  @objc dynamic var label: String = ""
  @objc dynamic var link: String = ""
  @objc dynamic var read: Bool = false
  @objc dynamic var createdDate: TimeInterval = 0.0
  @objc dynamic var updatedDate: TimeInterval = 0.0
  @objc dynamic var extraData: KNNotificationExtraData?

  convenience init(
    id: Int,
    title: String,
    content: String,
    scope: String,
    userID: Int,
    label: String,
    link: String,
    read: Bool,
    createdDate: TimeInterval,
    updatedDate: TimeInterval,
    data: JSONDictionary?
  ) {
    self.init()
    self.id = id
    self.title = title
    self.content = content
    self.scope = scope
    self.userID = userID
    self.label = label
    self.link = link
    self.read = read
    self.createdDate = createdDate
    self.updatedDate = updatedDate
    self.updateExtraData(data: data)
  }

  convenience init(json: JSONDictionary) {
    self.init()
    self.id = json["id"] as? Int ?? -1
    self.title = json["title"] as? String ?? ""
    self.content = json["content"] as? String ?? ""
    self.scope = json["scope"] as? String ?? ""
    self.userID = json["userID"] as? Int ?? 0
    self.label = json["label"] as? String ?? ""
    self.link = json["link"] as? String ?? ""
    self.read = json["read"] as? Bool ?? false
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
    self.updateExtraData(data: json["data"] as? JSONDictionary)
  }

  func updateExtraData(data: JSONDictionary?) {
    guard let extraData = data else {
      return
    }
    self.extraData = KNNotificationExtraData(json: extraData)
  }

  override class func primaryKey() -> String? {
    return "id"
  }

  func clone() -> KNNotification {
    return KNNotification(
      id: self.id,
      title: self.title,
      content: self.content,
      scope: self.scope,
      userID: self.userID,
      label: self.label,
      link: self.link,
      read: self.read,
      createdDate: self.createdDate,
      updatedDate: self.updatedDate,
      data: self.extraData?.toDict()
    )
  }
}

class KNNotificationExtraData: Object {
  @objc dynamic var base: String = ""
  @objc dynamic var token: String = ""
  @objc dynamic var orderId: Int = -1
  @objc dynamic var srcToken: String?
  @objc dynamic var dstToken: String?
  @objc dynamic var minRate: Double = 0.0
  @objc dynamic var srcAmount: Double = 0.0
  @objc dynamic var fee: Double = 0.0
  @objc dynamic var transferFee: Double = 0.0
  @objc dynamic var sender: String = ""
  @objc dynamic var createAt: Double = 0.0
  @objc dynamic var updatedAt: Double = 0.0
  @objc dynamic var receive: Double = 0.0
  @objc dynamic var txHash: String = ""
  @objc dynamic var sideTrade: String?

  convenience init(json: JSONDictionary) {
    self.init()
    self.base = json["base"] as? String ?? ""
    self.token = json["token"] as? String ?? ""
    self.orderId = json["order_id"] as? Int ?? -1
    self.srcToken = json["src_token"] as? String
    self.dstToken = json["dst_token"] as? String
    self.minRate = {
      if let value = json["min_rate"] as? Double { return value }
      if let valueStr = json["min_rate"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    self.srcAmount = {
      if let value = json["src_amount"] as? Double { return value }
      if let valueStr = json["src_amount"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    self.fee = {
      if let value = json["fee"] as? Double { return value }
      if let valueStr = json["fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    self.transferFee = {
      if let value = json["transfer_fee"] as? Double { return value }
      if let valueStr = json["transfer_fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    self.sender = json["sender"] as? String ?? ""
    self.createAt = {
      if let value = json["created_at"] as? Double { return value }
      if let valueStr = json["created_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    self.updatedAt = {
      if let value = json["updated_at"] as? Double { return value }
      if let valueStr = json["updated_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    self.receive = json["receive"] as? Double ?? 0.0
    self.txHash = json["tx_hash"] as? String ?? ""
    self.sideTrade = json["side_trade"] as? String
  }

  func toDict() -> JSONDictionary {
    var result: JSONDictionary = [
      "base": self.base,
      "token": self.token,
      "order_id": self.orderId,
      "src_token": self.srcToken ?? "",
      "dst_token": self.dstToken ?? "",
      "min_rate": self.minRate,
      "src_amount": self.srcAmount,
      "fee": self.fee,
      "transfer_fee": self.transferFee,
      "sender": self.sender,
      "created_at": self.createAt,
      "updated_at": self.updatedAt,
      "receive": self.receive,
      "tx_hash": self.txHash,
    ]
    if self.sideTrade != nil {
      result["side_trade"] = self.sideTrade
    }
    return result
  }
}
