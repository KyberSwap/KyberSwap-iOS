// Copyright SIX DAY LLC. All rights reserved.

import FirebaseAnalytics

class KNCrashlyticsUtil {

  static func logCustomEvent(withName name: String, customAttributes: [String: Any]?) {
//    if !isDebug {
      Analytics.logEvent(name, parameters: customAttributes)
//    }
  }
}
