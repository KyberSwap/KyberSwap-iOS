// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import Result
import TwitterKit
import Moya
import AuthenticationServices

// swiftlint:disable file_length
extension KNProfileHomeCoordinator: KNSignUpViewControllerDelegate {
  func signUpViewController(_ controller: KNSignUpViewController, run event: KNSignUpViewEvent) {
    self.isSignIn = false
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
      self.signUpViewController = nil
    case .pressedGoogle:
      self.authenticateGoogle()
    case .pressedFacebook:
      self.authenticateFacebook()
    case .pressedTwitter:
      self.authenticateTwitter()
    case .alreadyMemberSignIn:
      self.navigationController.popViewController(animated: true)
      self.signUpViewController = nil
    case .openTAC:
      UIApplication.shared.open(URL(string: "https://files.kyberswap.com/tac.pdf")!, options: [:], completionHandler: nil)
    case .signUp(let accountType, let isSubs):
      self.isSubscribe = isSubs
      self.accountType = accountType
      self.proceedSignUp(accountType: accountType)
    case .pressedApple:
      self.authenticateApple()
    }
  }
}

extension KNProfileHomeCoordinator {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNSignInViewEvent) {
    self.isSignIn = true
    self.isSubscribe = false
    switch event {
    case .forgotPassword:
      let forgotPassVC = KNForgotPasswordViewController()
      forgotPassVC.loadViewIfNeeded()
      forgotPassVC.modalPresentationStyle = .overFullScreen
      forgotPassVC.modalTransitionStyle = .crossDissolve
      self.navigationController.present(forgotPassVC, animated: true, completion: nil)
    case .signInWithEmail(let email, let password):
      let accountType = KNSocialAccountsType.normal(name: "", email: email, password: password)
      self.accountType = accountType
      self.proceedSignIn(accountType: accountType)
    case .signInWithFacebook:
      self.authenticateFacebook()
    case .signInWithGoogle:
      self.authenticateGoogle()
    case .signInWithTwitter:
      self.authenticateTwitter()
    case .dontHaveAccountSignUp:
      self.openSignUpView()
    case .signInWithApple:
      self.authenticateApple()
    }
  }

  fileprivate func openSignUpView() {
    self.signUpViewController = nil
    self.signUpViewController = {
      let viewModel = KNSignUpViewModel()
      let controller = KNSignUpViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.signUpViewController!, animated: true)
  }

  fileprivate func authenticateApple() {
    if #available(iOS 13.0, *) {
      KNAppTracker.saveLastTimeAuthenticate()
      let provider = ASAuthorizationAppleIDProvider()
      let request = provider.createRequest()
      request.requestedScopes = [.fullName, .email]
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.presentationContextProvider = self
        authController.delegate = self
        authController.performRequests()
    } else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Sign in with Apple feature is only available for iOS 13 and newer".toBeLocalised(),
        time: 2.0
      )
    }
  }
}

// MARK: Handle Facebook authentication
extension KNProfileHomeCoordinator {
  fileprivate func authenticateFacebook() {
    self.loginManager.logOut()
    self.retrieveFacebokAccessToken { (accessToken, isError) in
      guard let accessToken = accessToken else {
        if isError {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: "Can not get your information from Facebook. Please try again".toBeLocalised(),
            time: 1.5
          )
        }
        return
      }
      self.retrieveFacebookData(accessToken: accessToken, completion: { [weak self] result in
        guard let `self` = self else { return }
        if case .success(let accountData) = result, let data = accountData {
          self.accountType = data
          if self.isSignIn {
            self.proceedSignIn(accountType: data)
          } else {
            self.proceedSignUp(accountType: data)
          }
        } else {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: "Can not get your information from Facebook. Please try again".toBeLocalised(),
            time: 1.5
          )
        }
      })
    }
  }

  // Return (accessToken, isError) (show proper message when user cancelled
  fileprivate func retrieveFacebokAccessToken(completion: @escaping (AccessToken?, Bool) -> Void) {
    if let accessToken = AccessToken.current {
      completion(accessToken, false)
      return
    }
    self.loginManager.logIn(permissions: [.publicProfile, .email], viewController: self.navigationController) { loginResult in
      switch loginResult {
      case .failed:
        completion(nil, true)
      case .cancelled:
        completion(nil, false)
      case .success(_, _, let accessToken):
        completion(accessToken, false)
      }
    }
  }

  fileprivate func retrieveFacebookData(accessToken: AccessToken, completion: @escaping (Result<KNSocialAccountsType?, AnyError>) -> Void) {
    let params = ["fields": "id,email,name,first_name,last_name,picture.type(large)"]
    let request = GraphRequest(
      graphPath: "me", parameters: params,
      tokenString: accessToken.tokenString,
      version: nil,
      httpMethod: .get
    )
    request.start { (_, result, error) in
      if error == nil, let value = result, let dict = value as? JSONDictionary, let email = dict["email"] as? String, !email.isEmpty {
        let name = dict["name"] as? String ?? ""
        let icon: String = {
          let picture = dict["picture"] as? JSONDictionary ?? [:]
          let data = picture["data"] as? JSONDictionary ?? [:]
          return data["url"] as? String ?? ""
        }()
        let accountType = KNSocialAccountsType.facebook(name: name, email: email, icon: icon, accessToken: accessToken.tokenString)
        self.accountType = accountType
        completion(.success(accountType))
      } else {
        completion(.success(nil))
      }
    }
  }
}

// MARK: Handle Google authentication
extension KNProfileHomeCoordinator: GIDSignInDelegate {
  fileprivate func authenticateGoogle() {
    GIDSignIn.sharedInstance()?.signOut() // TOMO: Remove
    GIDSignIn.sharedInstance()?.clientID = KNEnvironment.default.googleSignInClientID
    GIDSignIn.sharedInstance()?.delegate = self
    GIDSignIn.sharedInstance()?.presentingViewController = self.navigationController
    GIDSignIn.sharedInstance()?.signIn()
  }

  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if error != nil {
      self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Can not get your information from Google. Please try again".toBeLocalised(),
        time: 1.5
      )
    } else {
      guard let email = user.profile.email, !email.isEmpty else {
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: "Can not get email from your Google account".toBeLocalised(),
          time: 1.5
        )
        return
      }
      let idToken = user.authentication.idToken ?? "" // Safe to send to the server
      let fullName = user.profile.name ?? ""
      let icon: String = {
        let url = user.profile.imageURL(withDimension: 256)
        if url == nil { return "" }
        return url?.absoluteString ?? ""
      }()
      let accountType = KNSocialAccountsType.google(name: fullName, email: email, icon: icon, accessToken: idToken)
      self.accountType = accountType
      if self.isSignIn {
        self.proceedSignIn(accountType: accountType)
      } else {
        self.proceedSignUp(accountType: accountType)
      }
    }
  }

  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
  }

  func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
    self.navigationController.dismiss(animated: true, completion: nil)
  }

  func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
    self.navigationController.present(viewController, animated: true, completion: nil)
  }
}

// MARK: Handle Twitter authentication
extension KNProfileHomeCoordinator {
  fileprivate func authenticateTwitter() {
    TWTRTwitter.sharedInstance().logIn { (session, error) in
//      guard let `self` = self else { return }
      guard let session = session, error == nil else {
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: "Can not get your information from Twitter. Please try again".toBeLocalised(),
          time: 1.5
        )
        return
      }
      let userID = session.userID
      self.requestTwitterUserData(for: userID, authToken: session.authToken, authTokenSecret: session.authTokenSecret, completion: { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let accountType):
          self.accountType = accountType
          if self.isSignIn {
            self.proceedSignIn(accountType: accountType)
          } else {
            self.proceedSignUp(accountType: accountType)
          }
        case .failure:
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: "Can not get your information from Twitter. Please try again".toBeLocalised(),
            time: 2.0
          )
        }
      })
    }
  }

  fileprivate func requestTwitterUserData(for userID: String, authToken: String, authTokenSecret: String, completion: @escaping (Result<KNSocialAccountsType, AnyError>) -> Void) {
    var user: TWTRUser?
    var email: String?
    var error: Error?

    let client = TWTRAPIClient.withCurrentUser()
    let group = DispatchGroup()
    group.enter()
    client.loadUser(withID: userID, completion: { (userData, errorData) in
      user = userData
      if let err = errorData { error = err }
      group.leave()
    })
    group.enter()
    client.requestEmail(forCurrentUser: { (emailData, errorData) in
      email = emailData
      if let err = errorData { error = err }
      group.leave()
    })
    group.notify(queue: .main) {
      if let user = user, let email = email, !email.isEmpty {
        let accountType = KNSocialAccountsType.twitter(
          name: user.name,
          email: email,
          icon: user.profileImageLargeURL,
          authToken: authToken,
          authTokenSecret: authTokenSecret
        )
        self.accountType = accountType
        completion(.success(accountType))
      } else if let error = error {
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Handle sign in/up
extension KNProfileHomeCoordinator {
  fileprivate func proceedSignIn(accountType: KNSocialAccountsType, token: String? = nil, completion: ((Bool) -> Void)? = nil) {
    switch accountType {
    case .normal(_, let email, let password):
      self.signInEmail(email: email, password: password, token: token, completion: completion)
    case .facebook(let name, let email, let icon, let accessToken):
      self.signInSocialWithData(type: "facebook", email: email, name: name, photo: icon, accessToken: accessToken, token: token, completion: completion)
    case .twitter(let name, let email, let icon, let authToken, let authTokenSecret):
      self.signInSocialWithData(type: "twitter", email: email, name: name, photo: icon, accessToken: authToken, secret: authTokenSecret, token: token, completion: completion)
    case .google(let name, let email, let icon, let accessToken):
      self.signInSocialWithData(type: "google_oauth2", email: email, name: name, photo: icon, accessToken: accessToken, token: token, completion: completion)
    case .apple(let name, _, let userId, let idToken, let isSignUp):
      self.signInWithApple(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp, completion: completion)
    }
  }

  fileprivate func signInEmail(email: String, password: String, token: String? = nil, completion: ((Bool) -> Void)?) {
    self.navigationController.displayLoading()
    KNSocialAccountsCoordinator.shared.signInEmail(email, password: password, twoFA: token) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let data):
        let success = data["success"] as? Bool ?? false
        let message = data["message"] as? String ?? ""
        if success {
          self.userDidSignInWithData(data)
          completion?(true)
        } else {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: message,
            time: 1.5
          )
          completion?(false)
        }
      case .failure:
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
          time: 1.5
        )
        completion?(false)
      }
    }
  }

  fileprivate func signInSocialWithData(type: String, email: String, name: String, photo: String, accessToken: String, secret: String? = nil, token: String? = nil, completion: ((Bool) -> Void)?) {
    self.navigationController.displayLoading()
    KNSocialAccountsCoordinator.shared.signInSocial(
      type: type,
      email: email,
      name: name,
      photo: photo,
      accessToken: accessToken,
      secret: secret,
      twoFA: token
    ) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let data):
        let success = data["success"] as? Bool ?? false
        let message = data["message"] as? String ?? ""
        if success {
          self.userDidSignInWithData(data)
          completion?(true)
        } else {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: message,
            time: 2.0
          )
          completion?(false)
        }
      case .failure:
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
          time: 1.5
        )
        completion?(false)
      }
    }
  }

  fileprivate func signInWithApple(name: String, userId: String, idToken: String, isSignUp: Bool, completion: ((Bool) -> Void)?) {
    self.navigationController.displayLoading()
    KNSocialAccountsCoordinator.shared.signInApple(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let data):
        let success = data["success"] as? Bool ?? false
        let message = data["message"] as? String ?? ""
        if success {
          self.userDidSignInWithData(data)
          completion?(true)
        } else {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: message,
            time: 2.0
          )
          completion?(false)
        }
      case .failure:
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
          time: 1.5
        )
        completion?(false)
      }
    }
  }

  fileprivate func userDidSignInWithData(_ data: JSONDictionary, isSignUp: Bool = false) {
    let cookieJar = HTTPCookieStorage.shared
    for cookie in (cookieJar.cookies ?? []) {
      cookieJar.deleteCookie(cookie)
    }
    if let twoFactorAuthEnabled = data["2fa_required"] as? Bool, twoFactorAuthEnabled {
      self.openTwoFAConfirmView()
      return
    }
    if let isConfirmNeeded = data["confirm_signup_required"] as? Bool, isConfirmNeeded {
      self.openConfirmSignUpView()
      return
    }
    guard let authInfoDict = data["auth_info"] as? JSONDictionary, let userInfo = data["user_info"] as? JSONDictionary else {
      return
    }
    if let perm = userInfo["transfer_permission"] as? String, perm.lowercased() != "yes" && perm.lowercased() != "no" {
      KNAppTracker.updateShouldShowUserTranserConsentPopUp(false)
      let isForceLogout = userInfo["force_logout"] as? Bool ?? false
      self.openTransferConsentView(
        isForceLogout: isForceLogout,
        authInfo: authInfoDict,
        userInfo: userInfo
      )
      if isForceLogout { return }
    }
    self.signUserInWithData(authInfoDict: authInfoDict, userInfo: userInfo, isSignUp: isSignUp)
    if let user = IEOUserStorage.shared.user {
      Freshchat.sharedInstance().resetUser(completion: { () in
      })
      let chatUser = FreshchatUser.sharedInstance()
      chatUser.firstName = user.name
      Freshchat.sharedInstance().setUser(chatUser)
      if let saved = UserDefaults.standard.object(forKey: KNAppTracker.kSavedRestoreIDForLiveChat) as? [String: String],
        let restoreID = saved[user.userID.description] {
        Freshchat.sharedInstance().identifyUser(withExternalID: user.userID.description, restoreID: restoreID)
      } else {
        Freshchat.sharedInstance().identifyUser(withExternalID: user.userID.description, restoreID: nil)
      }
    }
  }

  fileprivate func signUserInWithData(authInfoDict: JSONDictionary, userInfo: JSONDictionary, isSignUp: Bool = false) {
    let authToken = authInfoDict["auth_token"] as? String ?? ""
    let refreshToken = authInfoDict["refresh_token"] as? String ?? ""
    let expiredTime: Double = {
      let time = authInfoDict["expiration_time"] as? String ?? ""
      let date = DateFormatterUtil.shared.promoCodeDateFormatter.date(from: time)
      return date?.timeIntervalSince1970 ?? 0.0
    }()

    if self.navigationController.viewControllers.count > 1 {
      // back to root view when user signed in successfully
      self.navigationController.popToRootViewController(animated: true)
    }
    // create and update user info
    let user = IEOUser(dict: userInfo)
    IEOUserStorage.shared.update(objects: [user])
    IEOUserStorage.shared.updateToken(
      object: user,
      type: "",
      accessToken: authToken,
      refreshToken: refreshToken,
      expireTime: expiredTime
    )
    self.timerAccessTokenExpired()
    self.timerLoadUserInfo()
    self.rootViewController.coordinatorUserDidSignInSuccessfully(isFirstTime: true)
    self.lastUpdatedUserInfo = Date()
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.updateOneSignalPlayerIDWithRetry() }
    KNCrashlyticsUtil.logCustomEvent(withName: "profile_signed_in_successfully", customAttributes: nil)
    let name = IEOUserStorage.shared.user?.name ?? ""
    let text = isSignUp ? "welcome.user.to.kyberswap".toBeLocalised() : NSLocalizedString("welcome.back.user", value: "Welcome back, %@", comment: "")
    let message = String(format: text, name)
    self.navigationController.showSuccessTopBannerMessage(with: "", message: message)
    if KNAppTracker.isPriceAlertEnabled { KNPriceAlertCoordinator.shared.resume() }
    KNNotificationCoordinator.shared.loadListNotifications(pageIndex: 0) { _, _  in }
    if KNAppTracker.shouldOpenLimitOrderAfterSignedIn() {
      self.navigationController.tabBarController?.selectedIndex = 2
    }
  }

  internal func openTransferConsentView(isForceLogout: Bool, authInfo: JSONDictionary, userInfo: JSONDictionary) {
    // only open if user's undecided
    self.consentDataVC = {
      let controller = KNTransferConsentViewController(
        isForceLogout: isForceLogout,
        authInfo: authInfo,
        userInfo: userInfo
      )
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.present(self.consentDataVC!, animated: true, completion: nil)
  }

  fileprivate func proceedSignUp(accountType: KNSocialAccountsType) {
    self.accountType = accountType
    switch accountType {
    case .normal(let name, let email, let password):
      self.signUpEmail(email, password: password, name: name, isSubs: self.isSubscribe)
    default:
      self.proceedSignIn(accountType: accountType)
    }
  }

  fileprivate func signUpEmail(_ email: String, password: String, name: String, isSubs: Bool) {
    self.navigationController.displayLoading()
    KNSocialAccountsCoordinator.shared.signUpEmail(email, password: password, name: name, isSubs: isSubs) { [weak self] result in
      guard let `self` = self else { return }
      self.navigationController.hideLoading()
      switch result {
      case .success(let data):
        if data.0 {
          // signed up successfully
          self.signUpViewController?.userDidSignedWithEmail()
        } else {
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", value: "Error", comment: ""),
            message: data.1,
            time: 2.0
          )
        }
      case .failure:
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
          time: 1.5
        )
      }
    }
  }

  fileprivate func openTwoFAConfirmView() {
    let controller = KNEnterTwoFactorAuthenViewController()
    controller.loadViewIfNeeded()
    controller.modalTransitionStyle = .crossDissolve
    controller.modalPresentationStyle = .overFullScreen
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
  }

  fileprivate func openConfirmSignUpView() {
    guard let accountType = self.accountType else { return }
    self.confirmSignUpVC = nil
    self.confirmSignUpVC = {
      let viewModel = KNConfirmSignUpViewModel(
        accountType: accountType,
        isSubscribe: self.isSubscribe
      )
      let controller = KNConfirmSignUpViewController(viewModel: viewModel)
      controller.loadViewIfNeeded()
      controller.delegate = self
      return controller
    }()
    self.navigationController.pushViewController(self.confirmSignUpVC!, animated: true)
  }
}

extension KNProfileHomeCoordinator: KNConfirmSignUpViewControllerDelegate {
  func confirmSignUpViewController(_ controller: KNConfirmSignUpViewController, run event: KNConfirmSignUpViewEvent) {
    switch event {
    case .back: self.navigationController.popViewController(animated: true)
    case .alreadyMemberSignIn: self.navigationController.popToRootViewController(animated: true)
    case .confirmSignUp(let accountType, let isSubscribe):
      switch accountType {
      case .facebook(let name, let email, let icon, let accessToken):
        self.sendConfirmSignUpRequest(type: "facebook", email: email, name: name, icon: icon, accessToken: accessToken, subscription: isSubscribe)
      case .twitter(let name, let email, let icon, let authToken, let authTokenSecret):
        self.sendConfirmSignUpRequest(type: "twitter", email: email, name: name, icon: icon, accessToken: authToken, secret: authTokenSecret, subscription: isSubscribe)
      case .google(let name, let email, let icon, let accessToken):
        self.sendConfirmSignUpRequest(type: "google_oauth2", email: email, name: name, icon: icon, accessToken: accessToken, subscription: isSubscribe)
      case .apple(let name, _, let userId, let idToken, let isSignUp):
        self.sendConfirmSignInWithAppleRequest(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp, isSub: isSubscribe)
      default: break
      }
    }
  }

  fileprivate func sendConfirmSignUpRequest(type: String, email: String, name: String, icon: String, accessToken: String, secret: String? = nil, subscription: Bool) {
    KNSocialAccountsCoordinator.shared.confirmSignUpSocial(
      type: type,
      email: email,
      name: name,
      photo: icon,
      accessToken: accessToken,
      secret: secret,
      subscription: subscription) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let data):
          let success = data["success"] as? Bool ?? false
          let message = data["message"] as? String ?? ""
          if success {
            self.navigationController.showWarningTopBannerMessage(
              with: NSLocalizedString("success", comment: ""),
              message: "You've successfully sign up".toBeLocalised(),
              time: 1.5
            )
            self.navigationController.popToRootViewController(animated: true)
            self.userDidSignInWithData(data, isSignUp: true)
          } else {
            self.navigationController.showWarningTopBannerMessage(
              with: NSLocalizedString("failed", comment: ""),
              message: message,
              time: 2.0
            )
          }
        case .failure:
          self.navigationController.showErrorTopBannerMessage(
            with: NSLocalizedString("error", comment: ""),
            message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
            time: 1.5
          )
        }
    }
  }

  fileprivate func sendConfirmSignInWithAppleRequest(name: String, userId: String, idToken: String, isSignUp: Bool, isSub: Bool) {
    KNSocialAccountsCoordinator.shared.confirmSignInWithApple(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp, isSub: isSub) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        let success = data["success"] as? Bool ?? false
        let message = data["message"] as? String ?? ""
        if success {
          self.navigationController.showWarningTopBannerMessage(
            with: NSLocalizedString("success", comment: ""),
            message: "You've successfully sign up".toBeLocalised(),
            time: 1.5
          )
          self.navigationController.popToRootViewController(animated: true)
          self.userDidSignInWithData(data, isSignUp: true)
        } else {
          self.navigationController.showWarningTopBannerMessage(
            with: NSLocalizedString("failed", comment: ""),
            message: message,
            time: 2.0
          )
        }
      case .failure:
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: ""),
          time: 1.5
        )
      }
    }
  }
}

extension KNProfileHomeCoordinator: KNEnterTwoFactorAuthenViewControllerDelegate {
  func enterTwoFactorAuthenViewController(_ controller: KNEnterTwoFactorAuthenViewController, token: String) {
    guard let accountType = self.accountType else { return }
    self.proceedSignIn(accountType: accountType, token: token) { [weak self] success in
      if !success { self?.openTwoFAConfirmView() }
    }
  }
}

extension KNProfileHomeCoordinator: KNTransferConsentViewControllerDelegate {
  func transferConsentViewController(_ controller: KNTransferConsentViewController, answer: Bool?, isForceLogout: Bool, authInfo: JSONDictionary, userInfo: JSONDictionary) {
    guard let userAns = answer else {
      controller.dismiss(animated: true, completion: nil)
      return
    }
    guard let accessToken = authInfo["auth_token"] as? String else { return }
    controller.displayLoading()
    self.sendUserAnswerForTransferringConsent(
      answer: userAns ? "yes" : "no",
      accessToken: accessToken) { [weak self] (error, newUserInfo) in
      guard let `self` = self else { return }
      controller.hideLoading()
      if let err = error {
        controller.showErrorTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: err
        )
      } else {
        controller.dismiss(animated: true) {
          if userAns {
            self.showSuccessTopBannerMessage(
              with: "",
              message: "Thank you, your profile will be surely copied. No futher action needed from you.".toBeLocalised(),
              time: 2.5
            )
            if isForceLogout {
              DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                // if isForceLogout -> user has not been signed in yet
                // since user's ans is yes, allow user to login
                self.signUserInWithData(authInfoDict: authInfo, userInfo: newUserInfo ?? userInfo)
                if let user = IEOUserStorage.shared.user {
                  Freshchat.sharedInstance().resetUser(completion: { () in
                  })
                  let chatUser = FreshchatUser.sharedInstance()
                  chatUser.firstName = user.name
                  Freshchat.sharedInstance().setUser(chatUser)
                  if let saved = UserDefaults.standard.object(forKey: KNAppTracker.kSavedRestoreIDForLiveChat) as? [String: String],
                    let restoreID = saved[user.userID.description] {
                    Freshchat.sharedInstance().identifyUser(withExternalID: user.userID.description, restoreID: restoreID)
                  } else {
                    Freshchat.sharedInstance().identifyUser(withExternalID: user.userID.description, restoreID: nil)
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  fileprivate func sendUserAnswerForTransferringConsent(answer: String, accessToken: String, completion: @escaping (String?, JSONDictionary?) -> Void) {
    KNSocialAccountsCoordinator.shared.transferConsentPermission(authToken: accessToken, answer: answer) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let json):
        let isSuccess = json["success"] as? Bool ?? false
        let message = isSuccess ? nil : json["message"] as? String ?? ""
        let userInfo = json["user_info"] as? JSONDictionary
        completion(message, userInfo)
      case .failure(let error):
        completion(error.prettyError, nil)
      }
    }
  }
}

@available(iOS 13.0, *)
extension KNProfileHomeCoordinator: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return self.rootViewController.view.window!
  }
}

@available(iOS 13.0, *)
extension KNProfileHomeCoordinator: ASAuthorizationControllerDelegate {
  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    print("authorization error")
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
      let userID = appleIDCredential.user
      let email = appleIDCredential.email
      let givenName = appleIDCredential.fullName?.givenName
      var identityToken = ""
      if let token = appleIDCredential.identityToken {
        identityToken = String(bytes: token, encoding: .utf8) ?? ""
        let accountType = KNSocialAccountsType.apple(name: givenName ?? "", email: email, userId: userID, idToken: identityToken, isSignUp: true)
        self.accountType = accountType
        self.proceedSignIn(accountType: accountType)
      }
    }
  }
}
