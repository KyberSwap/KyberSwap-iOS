// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class KNNotificationSettingViewModel {
  var isSeeMore: Bool = false
  private(set) var tokens: [String] = []
  private(set) var supportedTokens: [String]
  
  init(tokens: [String]) {
    self.supportedTokens = tokens
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
}
