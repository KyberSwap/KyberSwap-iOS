// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTokenStorage {

  private(set) var realm: Realm

  init(realm: Realm) {
    self.realm = realm
    self.addKyberSupportedTokens()
  }

  func addKyberSupportedTokens() {
    // update balance
    let supportedTokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens
    let tokenObjects = supportedTokens.map({ return $0.clone() })
    tokenObjects.forEach { tokenObject in
      if let token = self.tokens.first(where: { $0.contract == tokenObject.contract }) {
        tokenObject.value = token.value
      }
    }
    self.add(tokens: tokenObjects)
    // new list of supported has been updated, update list of tokens in the wallet
    for token in self.tokens {
      if token.isSupported, supportedTokens.first(where: { $0.contract == token.contract }) == nil {
        self.realm.beginWrite()
        token.isSupported = false
        try! self.realm.commitWrite()
      }
    }
  }

  var tokens: [TokenObject] {
    if self.realm.objects(TokenObject.self).isInvalidated { return [] }
    return self.realm.objects(TokenObject.self)
      .filter { return !$0.contract.isEmpty && !$0.isDisabled }
  }

  var ethToken: TokenObject {
   return self.tokens.first(where: { $0.isETH })?.clone() ?? KNSupportedTokenStorage.shared.ethToken
  }

  var kncToken: TokenObject {
    return self.tokens.first(where: { $0.isKNC })?.clone() ?? KNSupportedTokenStorage.shared.kncToken
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }

  func addCustom(token: ERC20Token) {
    // Don't add custom token if it is existed
    if self.tokens.first(where: { $0.contract == token.contract.description.lowercased() }) != nil { return }
    let newToken = TokenObject(
      contract: token.contract.description.lowercased(),
      name: token.name,
      symbol: token.symbol.uppercased(),
      decimals: token.decimals,
      value: "0",
      isCustom: true
    )
    add(tokens: [newToken])
  }

  func add(tokens: [TokenObject]) {
    self.realm.beginWrite()
    self.realm.add(tokens, update: .modified)
    try! self.realm.commitWrite()
  }

  func updateBalance(for token: TokenObject, balance: BigInt) {
    if token.isInvalidated { return }
    self.realm.beginWrite()
    token.value = balance.description
    try! self.realm.commitWrite()
  }

  func updateBalance(for address: Address, balance: BigInt) {
    if let token = self.tokens.first(where: { $0.contract.lowercased() == address.description.lowercased() }) {
      if token.isInvalidated { return }
      self.realm.beginWrite()
      token.value = balance.description
      try! self.realm.commitWrite()
    }
  }

  func delete(tokens: [TokenObject]) {
    realm.beginWrite()
    realm.delete(tokens)
    try! realm.commitWrite()
  }

  func disableUnsupportedTokensWithZeroBalance(tokens: [TokenObject]) {
    if tokens.isEmpty { return }
    tokens.forEach { token in
      if token.isInvalidated { return }
      self.realm.beginWrite()
      token.isDisabled = true
      try! self.realm.commitWrite()
    }
    KNNotificationUtil.postNotification(for: kSupportedTokenListDidUpdateNotificationKey)
  }

  func deleteAll() {
    if realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(realm.objects(TokenObject.self))
    try! self.realm.commitWrite()
  }

  func findTokensWithAddresses(addresses: [String]) -> [TokenObject] {
    return self.tokens.filter { (token) -> Bool in
      return addresses.contains(token.contract.lowercased())
    }
  }
  
}
