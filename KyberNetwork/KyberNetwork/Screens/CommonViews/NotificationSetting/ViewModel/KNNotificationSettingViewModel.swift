// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class KNNotificationSettingViewModel {
  var isSeeMore: Bool = false
  var notiStatus: Bool
  private(set) var tokens: [String]
  private(set) var supportedTokens: [String]
  private let original: [String]

  init(tokens: [String], selected: [String], notiStatus: Bool) {
    self.supportedTokens = tokens
    self.tokens = selected
    self.original = selected
    if self.supportedTokens.count <= 12 {
      self.isSeeMore = true
    }
    self.notiStatus = notiStatus
    self.supportedTokens.sort { (t0, t1) -> Bool in
      let isContain0 = self.tokens.contains(t0)
      let isContain1 = self.tokens.contains(t1)
      if isContain0 && !isContain1 { return true }
      if !isContain0 && isContain1 { return false }
      return t0 < t1
    }
  }

  func selectTokenSymbol(_ symbol: String) {
    if self.tokens.contains(symbol) {
      self.removeToken(symbol)
      KNCrashlyticsUtil.logCustomEvent(withName: "pricetrending_token", customAttributes: ["enable_token": "false"])
    } else {
      self.addToken(symbol)
      KNCrashlyticsUtil.logCustomEvent(withName: "pricetrending_token", customAttributes: ["enable_token": "true"])
    }
  }

  func addToken(_ token: String) {
    if self.tokens.first(where: { return $0 == token }) == nil {
      self.tokens.append(token)
    }
  }

  func removeToken(_ token: String) {
    if let id = self.tokens.index(of: token) {
      self.tokens.remove(at: id)
    }
  }

  func updateTokens(_ tokens: [String]) {
    self.tokens = tokens
  }

  func resetTokens() {
    self.tokens = self.original
    self.isSeeMore = false
  }
}
