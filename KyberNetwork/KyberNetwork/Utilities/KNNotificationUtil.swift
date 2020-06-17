// Copyright SIX DAY LLC. All rights reserved.

import NotificationCenter
import UserNotifications

// Transaction Keys
let kTransactionDidUpdateNotificationKey = "kTransactionDidUpdateNotificationKey"
let kTransactionListDidUpdateNotificationKey = "kTransactionListDidUpdateNotificationKey"
let kOpenExchangeTokenViewKey = "kOpenExchangeTokenViewKey"

// Token Transaction Key
let kTokenTransactionListDidUpdateNotificationKey = "kTokenTransactionListDidUpdateNotificationKey"
let kTokenObjectListDidUpdateNotificationKey = "kTokenObjectListDidUpdateNotificationKey"

// Tokens
let kSupportedTokenListDidUpdateNotificationKey = "kSupportedTokenListDidUpdateNotificationKey"

// Balance Keys
let kOtherBalanceDidUpdateNotificationKey = "kOtherBalanceDidUpdateNotificationKey"
let kFavouriteTokensUpdateNotificationKey = "kFavouriteTokensUpdateNotificationKey"

// Rate
let kExchangeTokenRateNotificationKey = "kExchangeTokenRateNotificationKey"
let kExchangeUSDRateNotificationKey = "kExchangeUSDRateNotificationKey"

let kProdCachedRateSuccessToLoadNotiKey = "kProdCachedRateSuccessToLoadNotiKey"
let kProdCachedRateFailedToLoadNotiKey = "kProdCachedRateFailedToLoadNotiKey"

let kCoinTickersDidUpdateNotificationKey = "kCoinTickerDataDidUpdateNotificationKey"

// Market
let kMarketSuccessToLoadNotiKey = "kMarketSuccessToLoadNotiKey"
let kMarketFailedToLoadNotiKey = "kMarketFailedToLoadNotiKey"

// Gas Price
let kGasPriceDidUpdateNotificationKey = "kGasPriceDidUpdateNotificationKey"

let kUpdateListContactNotificationKey = "kUpdateListContactNotificationKey"

let kUpdateListAlertsNotificationKey = "kUpdateListAlertsNotificationKey"
let kUpdateListNotificationsKey = "kUpdateListNotificationsKey"

let kUpdateListOrdersNotificationKey = "kUpdateListOrdersNotificationKey"

let kRefreshBalanceNotificationKey = "kRefreshBalanceNotificationKey"

// IEO
let kIEOUserDidUpdateNotificationKey = "kIEOUserDidUpdateNotificationKey"
let kIEOTxListUpdateNotificationKey = "kIEOTxListUpdateNotificationKey"

let kUserWalletsListUpdatedNotificationKey = "kUserWalletsListUpdatedNotificationKey"

// Receive txs
let kNewReceivedTransactionKey = "kNewReceivedTransactionKey"

class KNNotificationUtil {

  static func postNotification(for key: String, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
    let notificationName = Notification.Name(rawValue: key)
    NotificationCenter.default.post(name: notificationName, object: object, userInfo: userInfo)
  }

  static func notificationName(from name: String) -> Notification.Name {
    return Notification.Name(name)
  }

  static func localPushNotification(title: String, body: String, userInfo: [AnyHashable: Any] = [:]) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.userInfo = userInfo
    if #available(iOS 12, *) {
      if isDebug { print("Using iOS 12") }
    } else {
      content.setValue("YES", forKey: "shouldAlwaysAlertWhileAppIsForeground")
    }
    let request = UNNotificationRequest(identifier: "localPushNotification", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { error in
      if isDebug { NSLog("Error \(error.debugDescription)") }
    }
  }
}
