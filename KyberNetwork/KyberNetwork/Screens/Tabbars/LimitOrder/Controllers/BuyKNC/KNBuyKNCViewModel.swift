// Copyright SIX DAY LLC. All rights reserved.

import Foundation

class KNBuyKNCViewModel {
  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject
  fileprivate(set) var market: KNMarket?
  
  init(wallet: Wallet) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr) ?? KNWalletObject(address: addr)
  }
  
  var walletNameString: String {
    let addr = self.walletObject.address.lowercased()
    return "|  \(addr.prefix(10))...\(addr.suffix(8))"
  }
  
  var targetPrice: String {
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    return formatter.string(from: NSNumber(value: self.market?.buyPrice ?? 0)) ?? ""
  }
  
  func updateMarket(name: String = "ETH_KNC") {
    self.market = KNRateCoordinator.shared.getMarketWith(name: name)
  }
}
