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

  //TODO: temp wrap method delete later
  var supportedTokens: [TokenObject] {
    return self.getAllTokenObject()
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
  
  func getAllTokenObject() -> [TokenObject] {
    return self.allTokens.map { (token) -> TokenObject in
      return token.toObject()
    }
  }
  
  func getETH() -> Token {
    return self.supportedToken.first { (item) -> Bool in
      return item.symbol == "ETH"
    } ?? Token(name: "Ethereum", symbol: "ETH", address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", decimals: 18, logo: "eth")
  }
  
  func getKNC() -> Token {
    return self.supportedToken.first { (item) -> Bool in
      return item.symbol == "KNC"
    } ?? Token(name: "KyberNetwork", symbol: "KNC", address: "0x7b2810576aa1cce68f2b118cef1f36467c648f92", decimals: 18, logo: "knc")
  }
}
