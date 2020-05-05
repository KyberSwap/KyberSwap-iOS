// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import GoogleSignIn
import Result
import TwitterKit
import Moya

enum KNSocialAccountsType {
  case facebook(name: String, email: String, icon: String, accessToken: String)
  case google(name: String, email: String, icon: String, accessToken: String)
  case twitter(name: String, email: String, icon: String, authToken: String, authTokenSecret: String)
  case normal(name: String, email: String, password: String)
  case apple(name: String, email: String?, userId: String, idToken: String, isSignUp: Bool)

  var isEmail: Bool {
    if case .normal = self { return true }
    return false
  }
}

class KNSocialAccountsCoordinator {
  let provider = MoyaProvider<NativeSignInUpService>(plugins: [MoyaCacheablePlugin()])

  static let shared = KNSocialAccountsCoordinator()

  func signUpEmail(_ email: String, password: String, name: String, isSubs: Bool, completion: @escaping (Result<(Bool, String), AnyError>) -> Void) {
    let request = NativeSignInUpService.signUpEmail(
      email: email,
      password: password,
      name: name,
      isSubs: isSubs
    )
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let json):
        let success = json["success"] as? Bool ?? false
        let message = json["message"] as? String ?? ""
        completion(.success((success, message)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func signInEmail(_ email: String, password: String, twoFA: String?, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.signInEmail(email: email, password: password, twoFA: twoFA)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func resetPassword(_ email: String, completion: @escaping (Result<(Bool, String), AnyError>) -> Void) {
    let request = NativeSignInUpService.resetPassword(email: email)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let json):
        let success = json["success"] as? Bool ?? false
        let message = json["message"] as? String ?? ""
        completion(.success((success, message)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func signInSocial(type: String, email: String, name: String, photo: String, accessToken: String, secret: String?, twoFA: String?, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.signInSocial(
      type: type,
      email: email,
      name: name,
      photo: photo,
      accessToken: accessToken,
      secret: secret,
      twoFA: twoFA
    )
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func confirmSignUpSocial(type: String, email: String, name: String, photo: String, accessToken: String, secret: String?, subscription: Bool, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.confirmSignUpSocial(
      type: type,
      email: email,
      name: name,
      photo: photo,
      isSubs: subscription,
      accessToken: accessToken,
      secret: secret
    )
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func signInApple(name: String, userId: String, idToken: String, isSignUp: Bool, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.signInWithApple(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func confirmSignInWithApple(name: String, userId: String, idToken: String, isSignUp: Bool, isSub: Bool, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.confirmSignInWithApple(name: name, userId: userId, idToken: idToken, isSignUp: isSignUp, isSubs: isSub)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func updatePassword(_ email: String, oldPassword: String, newPassword: String, accessToken: String, completion: @escaping (Result<(Bool, String), AnyError>) -> Void) {
    let request = NativeSignInUpService.updatePassword(
      email: email,
      oldPassword: oldPassword,
      newPassword: newPassword,
      authenToken: accessToken
    )
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let json):
        let success = json["success"] as? Bool ?? false
        let message = json["message"] as? String ?? ""
        completion(.success((success, message)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func callRefreshToken(_ refreshToken: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.refreshToken(refreshToken: refreshToken)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func getUserAuthData(email: String, password: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.getUserAuthToken(email: email, password: password)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func getUserInfo(authToken: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.getUserInfo(authToken: authToken)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  func transferConsentPermission(authToken: String, answer: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = NativeSignInUpService.transferConsent(authToken: authToken, answer: answer)
    self.sendRequest(request) { [weak self] result in
      guard let _ = self else { return }
      completion(result)
    }
  }

  fileprivate func sendRequest(_ request: NativeSignInUpService, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(request) { [weak self] (result) in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              completion(.success(json))
            } catch let err {
              completion(.failure(AnyError(err)))
            }
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}
