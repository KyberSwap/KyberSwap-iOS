// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class KNNotificationSettingViewModel {
  var isSeeMore: Bool = false
  private(set) var tokens: [String]
  private(set) var supportedTokens: [String]
  private let original: [String]

  init(tokens: [String], selected: [String]) {
    self.supportedTokens = tokens
    self.tokens = selected
    self.original = selected
    if self.supportedTokens.count <= 12 {
      self.isSeeMore = true
    }
  }

  func selectTokenSymbol(_ symbol: String) {
    if self.tokens.contains(symbol) {
      self.removeToken(symbol)
    } else {
      self.addToken(symbol)
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
