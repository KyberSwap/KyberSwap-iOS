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

  var extraData: JSONDictionary? {
    let key = "notifications_\(KNEnvironment.default.displayName)_\(id)_\(userID)"
    if let data = UserDefaults.standard.object(forKey: key) as? Data {
      return NSKeyedUnarchiver.unarchiveObject(with: data) as? JSONDictionary
    }
    return nil
  }

  func updateExtraData(data: JSONDictionary?) {
    let key = "notifications_\(KNEnvironment.default.displayName)_\(id)_\(userID)"
    if let data = data {
      let encodedData = NSKeyedArchiver.archivedData(withRootObject: data)
      UserDefaults.standard.set(encodedData, forKey: key)
    } else {
      UserDefaults.standard.set(nil, forKey: key)
    }
    UserDefaults.standard.synchronize()
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
      data: self.extraData
    )
  }
}
