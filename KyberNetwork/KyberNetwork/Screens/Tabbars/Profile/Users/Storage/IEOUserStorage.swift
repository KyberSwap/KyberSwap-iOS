// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class IEOUserStorage {
  static let shared = IEOUserStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var user: IEOUser? {
    return self.objects.first(where: { $0.isSignedIn })
  }

  var objects: [IEOUser] {
    if self.realm == nil { return [] }
    if self.realm.objects(IEOUser.self).isInvalidated { return [] }
    return self.realm.objects(IEOUser.self)
      .filter { return $0.userID != -1 }
  }

  func add(objects: [IEOUser]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(objects, update: .modified)
    try! self.realm.commitWrite()
  }

  func update(objects: [IEOUser]) {
    self.add(objects: objects)
  }

  @discardableResult
  func updateToken(object: IEOUser, type: String, accessToken: String, refreshToken: String, expireTime: Double) -> IEOUser {
    if self.realm == nil { return object }
    self.realm.beginWrite()
    object.updateToken(
      type: type,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expireTime: expireTime
    )
    try! self.realm.commitWrite()
    return object
  }

  func getObject(primaryKey: Int) -> IEOUser? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: IEOUser.self, forPrimaryKey: primaryKey)
  }

  func delete(objects: [IEOUser]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.delete(objects)
    try! self.realm.commitWrite()
  }

  func signedOut() {
    if self.realm == nil { return }
    self.delete(objects: self.objects)
    KNAlertStorage.shared.deleteAll()
  }

  func signedIn() {
    if self.realm == nil { return }
    guard let user = self.objects.first else { return }
    self.realm.beginWrite()
    user.isSignedIn = true
    self.realm.add(user, update: .modified)
    try! self.realm.commitWrite()
    // Remove all other users
    let removedUsers = self.objects.filter({ return !$0.isSignedIn })
    self.delete(objects: removedUsers)
  }
}
