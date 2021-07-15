// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNTrackerRateStorage {

  static var shared = KNTrackerRateStorage()
  private(set) var realm: Realm!
  private var allPrices: [TokenPrice]

  init() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
  }

  func reloadData() {
    self.allPrices = KNTrackerRateStorage.loadPricesFromLocalData()
  }

  //MARK: new implementation
  static func loadPricesFromLocalData() -> [TokenPrice] {
    if KNEnvironment.default != .ropsten {
      return Storage.retrieve(KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName, as: [TokenPrice].self) ?? []
    } else {
      if let json = KNJSONLoaderUtil.jsonDataFromFile(with: "tokens_price") as? [String: JSONDictionary] {
        var result: [TokenPrice] = []
        json.keys.forEach { (key) in
          var dict = json[key]
          dict?["address"] = key
          if let notNil = dict {
            let price = TokenPrice(dictionary: notNil)
            result.append(price)
          }
        }
        return result

      } else {
        return []
      }
    }
  }
  
  func getAllPrices() -> [TokenPrice] {
    return self.allPrices
  }
  
  func getPriceWithAddress(_ address: String) -> TokenPrice? {
    return self.allPrices.first { (item) -> Bool in
      return item.address.lowercased() == address.lowercased()
    }
  }
  
  func getLastPriceWith(address: String, currency: CurrencyMode) -> Double {
    guard let price = self.getPriceWithAddress(address) else {
      return 0.0
    }
    switch currency {
    case .usd:
      return price.usd
    case .eth:
      return price.eth
    case .btc:
      return price.btc
    }
  }

  func getETHPrice() -> TokenPrice? {
    if KNGeneralProvider.shared.isEthereum {
      return self.getPriceWithAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
    } else {
      return self.getPriceWithAddress(Constants.bnbAddress)
    }
    
  }
  
  func updatePrices(_ prices: [TokenPrice]) {
    prices.forEach { (item) in
      if let saved = self.getPriceWithAddress(item.address) {
        saved.eth = item.eth
        saved.eth24hVol = item.eth24hVol
        saved.ethMarketCap = item.ethMarketCap
        saved.eth24hChange = item.eth24hChange
        
        saved.usd = item.usd
        saved.usd24hVol = item.usd24hVol
        saved.usdMarketCap = item.usdMarketCap
        saved.usd24hChange = item.usd24hChange
        
        saved.btc = item.btc
        saved.btc24hVol = item.btc24hVol
        saved.btcMarketCap = item.btcMarketCap
        saved.btc24hChange = item.btc24hChange
      } else {
        self.allPrices.append(item)
      }
    }
    Storage.store(self.allPrices, as: KNEnvironment.default.envPrefix + Constants.coingeckoPricesStoreFileName)
  }
}

