//
//  BalanceStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/21/21.
//

import Foundation
import BigInt

class BalanceStorage {
  static let shared = BalanceStorage()
  private var supportedTokenBalances: [TokenBalance] = []
  private var allLendingBalance: [LendingPlatformBalance] = []
  private var distributionBalance: LendingDistributionBalance?
  private var wallet: Wallet?
  private var customTokenBalances: [TokenBalance] = []
  
  var allBalance: [TokenBalance] {
    return self.supportedTokenBalances + self.customTokenBalances
  }
  
  func getAllLendingBalances() -> [LendingPlatformBalance] {
    if self.allLendingBalance.isEmpty, let unwrapped = self.wallet {
      self.updateCurrentWallet(unwrapped)
    }
    return self.allLendingBalance
  }
  
  func getDistributionBalance() -> LendingDistributionBalance? {
    return self.distributionBalance
  }

  func setBalances(_ balances: [TokenBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    balances.forEach { (item) in
      if let balance = self.supportedTokenBalanceForAddress(item.address) {
        balance.balance = item.balance
      } else {
        self.supportedTokenBalances.append(item)
      }
    }
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.balanceStoreFileName)
  }
  
  func setCustomTokenBalance(_ balance: TokenBalance) {
    if let savedBalance = self.customTokenBalanceForAddress(balance.address) {
      savedBalance.balance = balance.balance
    } else {
      self.customTokenBalances.append(balance)
    }
  }
  
  func saveCustomTokenBalance() {
    guard let unwrapped = self.wallet else {
      return
    }
    Storage.store(self.customTokenBalances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.customBalanceStoreFileName)
  }
  
  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    self.supportedTokenBalances = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
    self.allLendingBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingBalanceStoreFileName, as: [LendingPlatformBalance].self) ?? []
    self.distributionBalance = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.lendingDistributionBalanceStoreFileName, as: LendingDistributionBalance.self)
    self.customTokenBalances = Storage.retrieve(KNEnvironment.default.envPrefix + wallet.address.description.lowercased() + Constants.customBalanceStoreFileName, as: [TokenBalance].self) ?? []
    
    print("[Balance][Update wallet] \(supportedTokenBalances)")
  }

  func balanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.allBalance.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }
  
  func supportedTokenBalanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.supportedTokenBalances.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }
  
  func customTokenBalanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.customTokenBalances.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }

  func setLendingBalances(_ balances: [LendingPlatformBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.allLendingBalance = balances
    Storage.store(balances, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.lendingBalanceStoreFileName)
  }

  func setLendingDistributionBalance(_ balance: LendingDistributionBalance) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.distributionBalance = balance
    Storage.store(balance, as: KNEnvironment.default.envPrefix + unwrapped.address.description.lowercased() + Constants.lendingDistributionBalanceStoreFileName)
  }

  func balanceETH() -> String {
    return self.balanceForAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")?.balance ?? ""
  }
  
  func balanceBNB() -> String {
    return self.balanceForAddress(Constants.bnbAddress)?.balance ?? ""
  }

  func getBalanceETHBigInt() -> BigInt {
    return BigInt(self.balanceETH()) ?? BigInt(0)
  }
  
  func getBalanceBNBBigInt() -> BigInt {
    return BigInt(self.balanceBNB()) ?? BigInt(0)
  }
}
