// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import TrustCore

class KNContact: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var lastUsed: Date = Date()

  convenience init(address: String, name: String) {
    self.init()
    self.name = name
    self.address = {
      guard let addr = Address(string: address) else { return address }
      return addr.description
    }()
    self.lastUsed = Date()
  }

  override static func primaryKey() -> String {
    return "address"
  }
  
  func clone() -> KNContact {
    return KNContact(address: self.address, name: self.name)
  }
}
