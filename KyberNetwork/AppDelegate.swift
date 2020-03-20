// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import UserNotificationsUI
import UserNotifications
import OneSignal
import TwitterKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
  var window: UIWindow?
  var coordinator: KNAppCoordinator!

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (_, _) in
      DispatchQueue.main.async {
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = 0
      }
    }
    UNUserNotificationCenter.current().delegate = self
    window = UIWindow(frame: UIScreen.main.bounds)
    do {
      let keystore = try EtherKeystore()
      coordinator = KNAppCoordinator(window: window!, keystore: keystore)
      coordinator.start()
      coordinator.appDidFinishLaunch()
    } catch {
      print("EtherKeystore init issue.")
    }
    KNReachability.shared.startNetworkReachabilityObserver()
    OneSignal.setRequiresUserPrivacyConsent(false)
    let notficationReceiveBlock: OSHandleNotificationReceivedBlock = { notification in
      // This block gets called when notification received
      self.coordinator.appDidReceiverOneSignalPushNotification(notification: notification)
    }
    let notificationOpenedBlock: OSHandleNotificationActionBlock = { result in
      // This block gets called when the user reacts to a notification received
      self.coordinator.appDidReceiverOneSignalPushNotification(result: result)
    }
    let oneSignalInitSettings = [
      kOSSettingsKeyAutoPrompt: false,
      kOSSettingsKeyInAppLaunchURL: true,
    ]
    OneSignal.initWithLaunchOptions(
      launchOptions,
      appId: KNEnvironment.default.oneSignAppID,
      handleNotificationReceived: notficationReceiveBlock,
      handleNotificationAction: notificationOpenedBlock,
      settings: oneSignalInitSettings
    )
    OneSignal.inFocusDisplayType = .notification
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    FirebaseApp.configure()

    return true
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
    KNAppTracker.updatePushNotificationToken(token)
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.updateOneSignalPlayerIDWithRetry() }
  }

  func applicationWillResignActive(_ application: UIApplication) {
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    coordinator.appDidBecomeActive()
    KNReachability.shared.startNetworkReachabilityObserver()
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    coordinator.appDidEnterBackground()
    KNReachability.shared.stopNetworkReachabilityObserver()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    self.coordinator.appWillEnterForeground()
  }

  func applicationWillTerminate(_ application: UIApplication) {
    self.coordinator.appWillTerminate()
  }

  func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplicationExtensionPointIdentifier) -> Bool {
    if extensionPointIdentifier == UIApplicationExtensionPointIdentifier.keyboard {
      return false
    }
    return true
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
    TWTRTwitter.sharedInstance().application(app, open: url, options: options)
    ApplicationDelegate.shared.application(app, open: url, options: options)
    return true
  }

  // Respond to URI scheme links
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    GIDSignIn.sharedInstance()?.handle(url, sourceApplication: sourceApplication, annotation: annotation)
    return true
  }

  // Respond to Universal Links
  func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
    return true
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    guard let txHash = response.notification.request.content.userInfo["transaction_hash"] as? String else {
      completionHandler()
      return
    }
    self.coordinator.appDidReceiveLocalNotification(transactionHash: txHash)
    completionHandler()
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
  }
}
