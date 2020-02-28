// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Result
import FBSDKLoginKit
import FBSDKCoreKit
import GoogleSignIn
import TwitterKit

class KNProfileHomeCoordinator: NSObject, Coordinator {

  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession

  fileprivate(set) var accessTokenExpireTimer: Timer?

  fileprivate(set) var webViewSignInVC: KGOInAppSignInViewController?
  fileprivate var newAlertController: KNNewAlertViewController?

  lazy var rootViewController: KNProfileHomeViewController = {
    let viewModel = KNProfileHomeViewModel()
    let controller = KNProfileHomeViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var manageAlertCoordinator: KNManageAlertCoordinator?

  fileprivate var loadUserInfoTimer: Timer?
  internal var lastUpdatedUserInfo: Date?

  internal var isSignIn: Bool = false
  internal var isSubscribe: Bool = false
  internal var accountType: KNSocialAccountsType?

  internal var signUpViewController: KNSignUpViewController?
  internal var confirmSignUpVC: KNConfirmSignUpViewController?
  internal var consentDataVC: KNTransferConsentViewController?

  lazy var loginManager: LoginManager = {
    let manager = LoginManager()
//    manager.loginBehavior = .
    return manager
  }()

  deinit {
    self.stop()
  }

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
  ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
    self.timerAccessTokenExpired()
    let cookieJar = HTTPCookieStorage.shared
    for cookie in (cookieJar.cookies ?? []) {
      cookieJar.deleteCookie(cookie)
    }
    if IEOUserStorage.shared.user != nil {
      if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.resume() }
      self.timerLoadUserInfo()
    }
  }

  func stop() {
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.pause() }
    // Remove notification observer
    self.accessTokenExpireTimer?.invalidate()
    self.accessTokenExpireTimer = nil
    self.loadUserInfoTimer?.invalidate()
    self.loadUserInfoTimer = nil
    self.navigationController.popToRootViewController(animated: false)
    self.manageAlertCoordinator = nil
    self.newAlertController = nil
    self.loadUserInfoTimer?.invalidate()
    self.loadUserInfoTimer = nil
    self.signUpViewController = nil
    self.confirmSignUpVC = nil
  }

  internal func timerAccessTokenExpired() {
    if let user = IEOUserStorage.shared.user {
      let time = Date(timeIntervalSince1970: user.expireTime).timeIntervalSinceNow
      guard time > 0 else {
        self.handleUserAccessTokenExpired()
        return
      }
      self.accessTokenExpireTimer?.invalidate()
      self.accessTokenExpireTimer = Timer.scheduledTimer(
        withTimeInterval: time,
        repeats: false,
        block: { [weak self] _ in
          self?.handleUserAccessTokenExpired()
        }
      )
    }
  }

  internal func timerLoadUserInfo() {
    self.loadUserInfoTimer?.invalidate()
    guard let user = IEOUserStorage.shared.user else {
      self.loadUserInfoTimer?.invalidate()
      return
    }
    self.getUserInfo(
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
      expireTime: user.expireTime,
      hasUser: true,
      showError: false
    ) { success in
        if success {
          self.rootViewController.coordinatorUserDidSignInSuccessfully(isFirstTime: true)
        }
    }

    self.loadUserInfoTimer?.invalidate()
    self.loadUserInfoTimer = Timer.scheduledTimer(
      withTimeInterval: KNEnvironment.default.isMainnet ? 60.0 : 10.0,
      repeats: true,
      block: { [weak self] _ in
        guard let user = IEOUserStorage.shared.user else {
          self?.loadUserInfoTimer?.invalidate()
          return
        }
        self?.getUserInfo(
          accessToken: user.accessToken,
          refreshToken: user.refreshToken,
          expireTime: user.expireTime,
          hasUser: true,
          showError: false
        ) { success in
            if success {
              self?.rootViewController.coordinatorUserDidSignInSuccessfully()
            }
        }
      }
    )
  }

  // MARK: Update from app coordinator
  func updateSession(_ session: KNSession) {
    self.session = session
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateWalletObjects() {
  }
}

// MARK: Callbacks, networking
extension KNProfileHomeCoordinator {
  fileprivate func handleUserSignOut() {
    let alertController = UIAlertController(
      title: nil,
      message: NSLocalizedString("do.you.want.to.log.out?", value: "Do you want to log out?", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("log.out", value: "Log Out", comment: ""), style: .default, handler: { _ in
      self.signUserOut()
    }))
    self.rootViewController.present(alertController, animated: true, completion: nil)
  }

  func signUserOut() {
    // log user out of facebook
    if AccessToken.current != nil { LoginManager().logOut() }
    // logout google
    GIDSignIn.sharedInstance().signOut()

    // stop loading data
    self.loadUserInfoTimer?.invalidate()
    self.lastUpdatedUserInfo = nil

    // remove user's data
    IEOUserStorage.shared.signedOut()
    self.rootViewController.coordinatorDidSignOut()
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.pause() }

    let cookieJar = HTTPCookieStorage.shared
    for cookie in (cookieJar.cookies ?? []) {
      cookieJar.deleteCookie(cookie)
    }

    KNNotificationCoordinator.shared.loadListNotifications(pageIndex: 0) { _, _  in }
  }

  // Get current user's info data, to sync between mobile (iOS + Android) and web
  // this method will be called repeatedly
  func getUserInfo(accessToken: String, refreshToken: String, expireTime: Double, hasUser: Bool, showError: Bool = false, completion: @escaping (Bool) -> Void) {
    // got access token, user access token  to retrieve user information
    KNSocialAccountsCoordinator.shared.getUserInfo(authToken: accessToken) { [weak self] result in
      guard let _ = `self` else { return }
      self?.navigationController.hideLoading()
      if hasUser && IEOUserStorage.shared.user == nil {
        self?.loadUserInfoTimer?.invalidate()
        return
      }
      switch result {
      case .success(let userInfo):
        let success = userInfo["success"] as? Bool ?? true
        let message = userInfo["message"] as? String ?? ""
        guard success else {
          if message == "Not Authenticated" {
            // not authenticated -> session expired
            self?.signUserOut()
          }
          if showError {
            self?.navigationController.showWarningTopBannerMessage(
              with: NSLocalizedString("error", value: "Error", comment: ""),
              message: NSLocalizedString("can.not.get.user.info", value: "Can not get user info", comment: "") + ": \(message)"
            )
            KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["type": "get_user_info_failed"])
          }
          completion(false)
          return
        }
        if KNAppTracker.shouldShowUserTranserConsentPopUp() {
          // for force logout, user should be asked when log in
          let authInfo: JSONDictionary = [
            "auth_token": accessToken,
            "refresh_token": refreshToken,
            "expiration_time": expireTime,
          ]
          if let perm = userInfo["transfer_permission"] as? String, perm.lowercased() != "yes" && perm.lowercased() != "no" {
            KNAppTracker.updateShouldShowUserTranserConsentPopUp(false)
            let isForceLogout = userInfo["force_logout"] as? Bool ?? false
            self?.openTransferConsentView(
              isForceLogout: false,
              authInfo: authInfo,
              userInfo: userInfo
            )
            if isForceLogout { return }
          }
        }
        let user = IEOUser(dict: userInfo)
        IEOUserStorage.shared.update(objects: [user])
        IEOUserStorage.shared.updateToken(
          object: user,
          type: "",
          accessToken: accessToken,
          refreshToken: refreshToken,
          expireTime: expireTime
        )
        self?.timerAccessTokenExpired()
        if !hasUser { self?.timerLoadUserInfo() }
        self?.rootViewController.coordinatorUserDidSignInSuccessfully()
        self?.lastUpdatedUserInfo = Date()
        if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.updateUserSignedInPushTokenWithRetry() }
        completion(true)
      // Already have user
      case .failure:
        if showError {
          self?.navigationController.showWarningTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
          )
        }
        completion(false)
      }
    }
  }

  // Call refresh token API to refresh token
  fileprivate func handleUserAccessTokenExpired() {
    guard let user = IEOUserStorage.shared.user else { return }
    let refreshToken = user.refreshToken
    KNSocialAccountsCoordinator.shared.callRefreshToken(refreshToken) { [weak self] result in
      switch result {
      case .success(let data):
        if let success = data["success"] as? Bool, success,
          let json = data["data"] as? JSONDictionary,
          let authToken = json["auth_token"] as? String,
          let refreshToken = json["refresh_token"] as? String {
          let expireTime: Double = {
            let time = json["expiration_time"] as? String ?? ""
            let date = DateFormatterUtil.shared.promoCodeDateFormatter.date(from: time)
            return date?.timeIntervalSince1970 ?? 0.0
          }()
          IEOUserStorage.shared.updateToken(
            object: user,
            type: "",
            accessToken: authToken,
            refreshToken: refreshToken,
            expireTime: expireTime
          )
          self?.timerAccessTokenExpired()
          KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["type": "expiry_session_reload_successfully"])
          return
        }
      case .failure:
        break
      }
      // Error for some reason
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["type": "expiry_session_failed_reload"])
      KNNotificationUtil.localPushNotification(
        title: NSLocalizedString("session.expired", value: "Session expired", comment: ""),
        body: NSLocalizedString("your.session.has.expired.sign.in.to.continue", value: "Your session has expired, please sign in again to continue", comment: "")
      )

      if AccessToken.current != nil { LoginManager().logOut() }
      // logout google
      GIDSignIn.sharedInstance().signOut()

      // stop loading data
      self?.loadUserInfoTimer?.invalidate()
      self?.lastUpdatedUserInfo = nil

      // remove user's data
      IEOUserStorage.shared.signedOut()
      if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.pause() }

      self?.navigationController.popToRootViewController(animated: true)
      self?.rootViewController.coordinatorDidSignOut()
    }
  }
}

extension KNProfileHomeCoordinator: KNProfileHomeViewControllerDelegate {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent) {
    switch event {
    case .logOut:
      self.handleUserSignOut()
    case .managePriceAlerts:
      if let topVC = self.navigationController.topViewController, topVC is KNManageAlertsViewController { return }
      self.manageAlertCoordinator = KNManageAlertCoordinator(navigationController: self.navigationController)
      self.manageAlertCoordinator?.start()
    case .addPriceAlert:
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["value": "add_new_alert"])
      if KNAlertStorage.shared.isMaximumAlertsReached {
        self.showAlertMaximumPriceAlertsReached()
      } else {
        if let topVC = self.navigationController.topViewController, topVC is KNNewAlertViewController { return }
        self.newAlertController = KNNewAlertViewController()
        self.newAlertController?.loadViewIfNeeded()
        self.navigationController.pushViewController(self.newAlertController!, animated: true)
      }
    case .editAlert(let alert):
      if let topVC = self.navigationController.topViewController, topVC is KNNewAlertViewController { return }
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["value": "edit_alert"])
      self.newAlertController = KNNewAlertViewController()
      self.newAlertController?.loadViewIfNeeded()
      self.navigationController.pushViewController(self.newAlertController!, animated: true) {
        self.newAlertController?.updateEditAlert(alert)
      }
    case .leaderBoard:
      if let topVC = self.navigationController.topViewController, topVC is KNAlertLeaderBoardViewController { return }
      let leaderBoardVC = KNAlertLeaderBoardViewController(isShowingResult: false)
      leaderBoardVC.loadViewIfNeeded()
      leaderBoardVC.delegate = self
      self.navigationController.pushViewController(leaderBoardVC, animated: true)
    }
  }

  fileprivate func showAlertMaximumPriceAlertsReached() {
    let message = NSLocalizedString("You already have 10 (maximum) alerts in your inbox. Please delete an existing alert to add a new one", comment: "")
    let alertController = UIAlertController(
      title: NSLocalizedString("Alert limit exceeded", value: "Alert limit exceeded", comment: ""),
      message: message,
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", value: "OK", comment: ""), style: .cancel, handler: nil))
    self.navigationController.present(alertController, animated: true, completion: nil)
  }
}

extension KNProfileHomeCoordinator: KNAlertLeaderBoardViewControllerDelegate {
  func alertLeaderBoardViewControllerOpenCampaignResult() {
    guard IEOUserStorage.shared.user != nil else { return }
    let leaderBoardVC = KNAlertLeaderBoardViewController(isShowingResult: true)
    leaderBoardVC.loadViewIfNeeded()
    leaderBoardVC.delegate = self
    self.navigationController.pushViewController(leaderBoardVC, animated: true)
  }

  func alertLeaderBoardViewControllerShouldBack() {
    self.navigationController.popViewController(animated: true)
  }
}
