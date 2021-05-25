// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNWalletObject: Object {

  @objc dynamic var address: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var icon: String = ""
  @objc dynamic var isBackedUp: Bool = true
  @objc dynamic var isWatchWallet: Bool = false
  @objc dynamic var date: Date = Date()

  convenience init(address: String, name: String = "Untitled", isBackedUp: Bool = true, isWatchWallet: Bool = false) {
    self.init()
    self.address = address
    self.name = name
    self.icon = ""
    self.date = Date()
    self.isBackedUp = isBackedUp
    self.isWatchWallet = isWatchWallet
  }

  convenience init(address: String, name: String, icon: String, date: Date, isBackedUp: Bool = true, isWatchWallet: Bool) {
    self.init()
    self.address = address
    self.name = name
    self.icon = icon
    self.date = date
    self.isBackedUp = isBackedUp
    self.isWatchWallet = isWatchWallet
  }

  func copy(withNewName newName: String) -> KNWalletObject {
    return KNWalletObject(
      address: self.address,
      name: newName,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet
    )
  }

  override class func primaryKey() -> String? {
    return "address"
  }

  func clone() -> KNWalletObject {
    return KNWalletObject(
      address: self.address,
      name: self.name,
      icon: self.icon,
      date: self.date,
      isBackedUp: self.isBackedUp,
      isWatchWallet: self.isWatchWallet
    )
  }
}

class KNWalletPromoInfoStorage: NSObject {

  let userDefaults = UserDefaults.standard
  let destAddressKey = "destAddressKey"
  let expiredTimeKey = "expiredTimeKey"
  static let shared = KNWalletPromoInfoStorage()
  var kKeyPrefix: String {
    return "\(KNEnvironment.default.displayName)_\(KNGeneralProvider.shared.customRPC.chainID)_"
  }

  override init() {}

  func addWalletPromoInfo(address: String, destinationToken: String, destAddress: String?, expiredTime: TimeInterval) {
    self.userDefaults.set(destinationToken, forKey: kKeyPrefix + address.lowercased())
    if let destAddr = destAddress {
      self.userDefaults.set(destAddr, forKey: kKeyPrefix + destAddressKey + address.lowercased())
    } else {
      self.userDefaults.removeObject(forKey: kKeyPrefix + destAddressKey + address.lowercased())
    }
    self.userDefaults.set(expiredTime, forKey: kKeyPrefix + expiredTimeKey + address.lowercased())
    self.userDefaults.synchronize()
  }

  func removeWalletPromoInfo(address: String) {
    self.userDefaults.removeObject(forKey: kKeyPrefix + address.lowercased())
    self.userDefaults.removeObject(forKey: kKeyPrefix + destAddressKey + address.lowercased())
    self.userDefaults.removeObject(forKey: kKeyPrefix + expiredTimeKey + address.lowercased())
    self.userDefaults.synchronize()
  }

  func getDestinationToken(from address: String) -> String? {
    return self.userDefaults.object(forKey: kKeyPrefix + address.lowercased()) as? String
  }

  func getDestWallet(from address: String) -> String? {
    return self.userDefaults.object(forKey: kKeyPrefix + destAddressKey + address.lowercased()) as? String
  }

  func getExpiredTime(from address: String) -> TimeInterval? {
    return self.userDefaults.object(forKey: kKeyPrefix + expiredTimeKey + address.lowercased()) as? TimeInterval
  }
}
