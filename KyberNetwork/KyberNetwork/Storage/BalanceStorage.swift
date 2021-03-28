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
    self.supportedTokenBalances = balances
    Storage.store(balances, as: unwrapped.address.description + Constants.balanceStoreFileName)
  }
  
  func setCustomTokenBalance(_ balance: TokenBalance) {
    self.customTokenBalances.append(balance)
  }
  
  func saveCustomTokenBalance() {
    guard let unwrapped = self.wallet else {
      return
    }
    Storage.store(self.customTokenBalances, as: unwrapped.address.description + Constants.balanceStoreFileName)
  }
  
  func cleanCustomTokenBalance() {
    self.customTokenBalances.removeAll()
  }

  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    self.supportedTokenBalances = Storage.retrieve(wallet.address.description + Constants.balanceStoreFileName, as: [TokenBalance].self) ?? []
    self.allLendingBalance = Storage.retrieve(wallet.address.description + Constants.lendingBalanceStoreFileName, as: [LendingPlatformBalance].self) ?? []
    self.distributionBalance = Storage.retrieve(wallet.address.description + Constants.lendingDistributionBalanceStoreFileName, as: LendingDistributionBalance.self)
    self.customTokenBalances = Storage.retrieve(wallet.address.description + Constants.customBalanceStoreFileName, as: [TokenBalance].self) ?? []
  }

  func balanceForAddress(_ address: String) -> TokenBalance? {
    let balance = self.allBalance.first { (balance) -> Bool in
      return balance.address.lowercased() == address.lowercased()
    }
    return balance
  }

  func setLendingBalances(_ balances: [LendingPlatformBalance]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.allLendingBalance = balances
    Storage.store(balances, as: unwrapped.address.description + Constants.lendingBalanceStoreFileName)
  }

  func setLendingDistributionBalance(_ balance: LendingDistributionBalance) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.distributionBalance = balance
    Storage.store(balance, as: unwrapped.address.description + Constants.lendingDistributionBalanceStoreFileName)
  }

  func balanceETH() -> String {
    return self.balanceForAddress("0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")?.balance ?? ""
  }

  func getBalanceETHBigInt() -> BigInt {
    return BigInt(self.balanceETH()) ?? BigInt(0)
  }
}
