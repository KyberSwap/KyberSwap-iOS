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
  
  
  
  init() {
    self.supportedToken = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.favedTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.favedTokenStoreFileName, as: [FavedToken].self) ?? []
    self.customTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName, as: [Token].self) ?? []
  }

  //TODO: temp wrap method delete later
  var supportedTokens: [TokenObject] {
    return self.getAllTokenObject()
  }

  var ethToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "ETH"
    } ?? Token(name: "Ethereum", symbol: "ETH", address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", decimals: 18, logo: "eth")
    return token.toObject()
  }

  var wethToken: TokenObject? {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "WETH"
    } ?? Token(name: "Wrapped Ether", symbol: "WETH", address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", decimals: 18, logo: "weth")
    return token.toObject()
  }

  var kncToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "KNC"
    } ?? Token(name: "KyberNetwork", symbol: "WETH", address: "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", decimals: 18, logo: "knc")
    return token.toObject()
  }
  
  var bnbToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "BNB"
    } ?? Token(name: "BNB", symbol: "BNB", address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", decimals: 18, logo: "bnb")
    return token.toObject()
  }
  
  var busdToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "BUSD"
    } ?? Token(name: "BUSD", symbol: "BUSD", address: "0xa2d2b501e6788158da07fa7e14dee9f2c5a01054", decimals: 18, logo: "")
    return token.toObject()
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    let token = self.getTokenWith(address: key)
    return token?.toObject()
  }
  //MARK:-new data type implemetation
  func reloadData() {
    self.supportedToken = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.customTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName, as: [Token].self) ?? []
  }
  
  func getSupportedTokens() -> [Token] {
    return self.supportedToken
  }

  func updateSupportedTokens(_ tokens: [Token]) {
    Storage.store(tokens, as: KNEnvironment.default.envPrefix + Constants.tokenStoreFileName)
    self.supportedToken = tokens
  }

  func getTokenWith(address: String) -> Token? {
    return self.allTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }
  }

  func getFavedTokenWithAddress(_ address: String) -> FavedToken? {
    let faved = self.favedTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
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
    Storage.store(self.favedTokens, as: KNEnvironment.default.envPrefix + Constants.favedTokenStoreFileName)
  }
  
  func saveCustomToken(_ token: Token) {
    self.customTokens.append(token)
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
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
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
  }
  
  func editCustomToken(address: String, newAddress: String, symbol: String, decimal: Int) {
    guard let token = self.getCustomTokenWith(address: address) else { return }
    token.address = newAddress
    token.symbol = symbol
    token.decimals = decimal
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
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
