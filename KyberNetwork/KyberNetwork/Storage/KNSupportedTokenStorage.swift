// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNSupportedTokenStorage {
  
  private var supportedToken: [Token]
  private var favedTokens: [FavedToken]
  private var customTokens: [Token]
  
  var allTokens: [Token] {
    return self.supportedToken + self.customTokens
  }
  
  static let shared = KNSupportedTokenStorage()
  lazy var realm: Realm = {
    let config = RealmConfiguration.globalConfiguration()
    return try! Realm(configuration: config)
  }()
  
  
  
  init() {
    self.supportedToken = Storage.retrieve(Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.favedTokens = Storage.retrieve(Constants.favedTokenStoreFileName, as: [FavedToken].self) ?? []
    self.customTokens = Storage.retrieve(Constants.customTokenStoreFileName, as: [Token].self) ?? []
  }

  func addLocalSupportedTokens() {
    let supportedTokenObjects = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile()
    supportedTokenObjects.forEach { token in
      if let savedToken = self.supportedTokens.first(where: { $0.contract == token.contract }) {
        token.value = savedToken.value
      }
    }
    self.add(tokens: supportedTokenObjects)
  }

  var supportedTokens: [TokenObject] {
    if self.realm.objects(TokenObject.self).isInvalidated { return [] }
    return self.realm.objects(TokenObject.self)
      .filter { return !$0.contract.isEmpty }
  }

  var ethToken: TokenObject {
    return self.supportedTokens.first(where: { return $0.isETH })!.clone()
  }

  var wethToken: TokenObject? {
    return self.supportedTokens.first(where: { return $0.isWETH })?.clone()
  }

  var kncToken: TokenObject {
    return self.supportedTokens.first(where: { $0.isKNC })!.clone()
  }

  var ptToken: TokenObject? {
    return self.supportedTokens.first(where: { $0.isPromoToken })?.clone()
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    return self.realm.object(ofType: TokenObject.self, forPrimaryKey: key)
  }
  
  

  /**
   Update supported token list if needed
   */
  func updateSupportedTokens(tokenObjects: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    let savedTokens = self.supportedTokens
    let needUpdate: Bool = {
      if savedTokens.count != tokenObjects.count { return true }
      for id in 0..<savedTokens.count where savedTokens[id].contract != tokenObjects[id].contract { return true }
      return false
    }()
    if !needUpdate { return }
    tokenObjects.forEach { token in
      if let savedToken = savedTokens.first(where: { $0.contract == token.contract }) {
        token.value = savedToken.value
      }
    }
    self.add(tokens: tokenObjects)
    let removedTokens = savedTokens.filter { token -> Bool in
      return tokenObjects.first(where: { $0.contract == token.contract }) == nil
    }
    self.delete(tokens: removedTokens)
    // Send post notification to update other UI if needed
    KNNotificationUtil.postNotification(for: kSupportedTokenListDidUpdateNotificationKey)
  }

  func add(tokens: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.add(tokens, update: .modified)
    try! self.realm.commitWrite()
  }

  func delete(tokens: [TokenObject]) {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(tokens)
    try! realm.commitWrite()
  }

  func deleteAll() {
    if self.realm.objects(TokenObject.self).isInvalidated { return }
    self.realm.beginWrite()
    self.realm.delete(realm.objects(TokenObject.self))
    try! self.realm.commitWrite()
  }

  //MARK:-new data type implemetation
  func reloadData() {
    self.supportedToken = Storage.retrieve(Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.customTokens = Storage.retrieve(Constants.customTokenStoreFileName, as: [Token].self) ?? []
  }
  
  func getSupportedTokens() -> [Token] {
    return self.supportedToken
  }

  func updateSupportedTokens(_ tokens: [Token]) {
    Storage.store(tokens, as: Constants.tokenStoreFileName)
    self.supportedToken = tokens
  }

  func getTokenWith(address: String) -> Token? {
    return self.allTokens.first { (token) -> Bool in
      return token.address == address
    }
  }

  func getFavedTokenWithAddress(_ address: String) -> FavedToken? {
    let faved = self.favedTokens.first { (token) -> Bool in
      return token.address == address
    }
    return faved
  }

  func getFavedStatusWithAddress(_ address: String) -> Bool {
    let faved = self.getFavedTokenWithAddress(address)
    return faved?.status ?? false
  }

  func setFavedStatusWithAddress(_ address: String, status: Bool) {
    if let faved = self.getFavedTokenWithAddress(address) {
      faved.status = status
    } else {
      let newStatus = FavedToken(address: address, status: status)
      self.favedTokens.append(newStatus)
    }
    Storage.store(self.favedTokens, as: Constants.favedTokenStoreFileName)
  }
  
  func saveCustomToken(_ token: Token) {
    self.customTokens.append(token)
    Storage.store(self.customTokens, as: Constants.customTokenStoreFileName)
  }

  func isTokenSaved(_ token: Token) -> Bool {
    let tokens = self.allTokens
    let saved = tokens.first { (item) -> Bool in
      return item.address.lowercased() == token.address.lowercased()
    }
  
    return saved != nil
  }

  func getCustomToken() -> [Token] {
    return self.customTokens
  }
  
  func getCustomTokenWith(address: String) -> Token? {
    return self.customTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }
  }
  
  func deleteCustomToken(address: String) {
    guard let index = self.customTokens.firstIndex(where: { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }) else { return }
    self.customTokens.remove(at: index)
    Storage.store(self.customTokens, as: Constants.customTokenStoreFileName)
  }
  
  func editCustomToken(address: String, newAddress: String, symbol: String, decimal: Int) {
    guard let token = self.getCustomTokenWith(address: address) else { return }
    token.address = newAddress
    token.symbol = symbol
    token.decimals = decimal
    Storage.store(self.customTokens, as: Constants.customTokenStoreFileName)
  }
}
