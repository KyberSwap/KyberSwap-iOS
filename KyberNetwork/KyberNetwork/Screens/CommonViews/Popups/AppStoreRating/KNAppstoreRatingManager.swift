// Copyright SIX DAY LLC. All rights reserved.

import StoreKit

enum KNAppstoreRatingManager {
  static let kLastTimePromptedRatingKey = "kLastTimePromptedRatingKey"
  static let kNumberImportActionsKey = "kNumberImportActionsKey"
  static let kLastVersionPromptedForReviewKey = "kLastVersionPromptedForReviewKey"

  @available(iOS 10.3, *)
  static func requestReviewIfAppropriate() {
    /* Temp disable because we don't have app on AppStore
    let numberActions = UserDefaults.standard.integer(forKey: kNumberImportActionsKey) + 1
    UserDefaults.standard.set(numberActions, forKey: kNumberImportActionsKey)
    UserDefaults.standard.synchronize()

    let lastTimePrompted: Double = UserDefaults.standard.object(forKey: kLastTimePromptedRatingKey) as? Double ?? 0.0
    let interval = isDebug ? 300.0 : 30.0 * 24.0 * 60.0 * 60.0 // 5 mins for dev, 30 days for prod
    let actions = isDebug ? 10 : 60
    if Date().timeIntervalSince1970 < lastTimePrompted + interval && numberActions < actions { return }

    let infoDictionaryKey = kCFBundleVersionKey as String
    guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
        else {
      fatalError("Expected to find a bundle version in the info dictionary")
    }

    let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: kLastVersionPromptedForReviewKey)

    // only check version for mainnet
    if currentVersion != lastVersionPromptedForReview || !KNEnvironment.default.isMainnet {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        KNCrashlyticsUtil.logCustomEvent(withName: "show_rating_request", customAttributes: nil)
        SKStoreReviewController.requestReview()
        UserDefaults.standard.set(currentVersion, forKey: kLastVersionPromptedForReviewKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: kLastTimePromptedRatingKey)
        UserDefaults.standard.set(0, forKey: kNumberImportActionsKey)
        UserDefaults.standard.synchronize()
      }
    }
    */
  }
}
