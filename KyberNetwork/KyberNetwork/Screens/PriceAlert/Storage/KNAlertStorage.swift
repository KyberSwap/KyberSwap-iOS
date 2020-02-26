// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

class KNAlertStorage {
  static let shared: KNAlertStorage = KNAlertStorage()
  private(set) var realm: Realm!

  init() {
    let config = RealmConfiguration.globalConfiguration()
    self.realm = try! Realm(configuration: config)
  }

  var alerts: [KNAlertObject] {
    if self.realm == nil { return [] }
    if self.realm.objects(KNAlertObject.self).isInvalidated { return [] }
    return self.realm.objects(KNAlertObject.self)
      .filter({ return $0.id != -1 })
  }

  var isMaximumAlertsReached: Bool { return self.alerts.count >= 10 }

  func addNewAlert(_ alert: KNAlertObject) {
    self.addNewAlerts([alert])
  }

  func addNewAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(alerts, update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func updateAlert(_ alert: KNAlertObject) {
    self.updateAlerts([alert])
  }

  func updateAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.realm.add(alerts, update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func updateAlertsFromServer(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    // filter removed alerts
    let alertIDs = alerts.map({ return $0.id })
    let removedAlerts = self.alerts.filter({ return !alertIDs.contains($0.id) })
    removedAlerts.forEach({ $0.removeRewardData() })
    self.realm.delete(removedAlerts)
    self.realm.add(alerts, update: .modified)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func deleteAlert(_ alert: KNAlertObject) {
    self.deleteAlerts([alert])
  }

  func deleteAlert(with ID: Int) {
    if self.realm == nil { return }
    guard let alert = self.getObject(primaryKey: ID) else { return }
    self.deleteAlert(alert)
  }

  func deleteAlerts(_ alerts: [KNAlertObject]) {
    if self.realm == nil { return }
    self.realm.beginWrite()
    alerts.forEach({ $0.removeRewardData() })
    self.realm.delete(alerts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func getObject(primaryKey: Int) -> KNAlertObject? {
    if self.realm == nil { return nil }
    return self.realm.object(ofType: KNAlertObject.self, forPrimaryKey: primaryKey)
  }

  func deleteAll() {
    if self.realm == nil { return }
    self.realm.beginWrite()
    self.alerts.forEach({ $0.removeRewardData() })
    self.realm.delete(self.alerts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }

  func deleteAllTriggerd() {
    if self.realm == nil { return }
    self.realm.beginWrite()
    let alerts = self.alerts.filter({ return $0.state != .active })
    alerts.forEach({ $0.removeRewardData() })
    self.realm.delete(alerts)
    try! self.realm.commitWrite()
    KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
  }
}
