// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import Moya

class KNLoadBalanceCoordinator {

  fileprivate var session: KNSession! //TODO: use general provider to load balance instead of external provider

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false

  var otherTokensBalance: [String: Balance] = [:]

  fileprivate var fetchBalanceTimer: Timer?
  fileprivate var isFetchNonSupportedBalance: Bool = false

  fileprivate var lastRefreshTime: Date = Date()


  

  deinit {
    self.exit()
//    let name = Notification.Name(kRefreshBalanceNotificationKey)
//    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  init(session: KNSession) {
    self.session = session
  }

  func restartNewSession(_ session: KNSession) {
    self.session = session
    self.resume()
  }

  func loadAllBalances() {
    self.loadAllTokenBalance()
    self.loadLendingBalances()
    self.loadLendingDistributionBalance()
    self.loadBalanceForCustomToken()
  }

  func resume() {
    fetchBalanceTimer?.invalidate()
    fetchBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] timer in
        self?.loadAllBalances()
      }
    )
    self.loadAllBalances()
  }

  func pause() {
    fetchOtherTokensBalanceTimer?.invalidate()
    fetchOtherTokensBalanceTimer = nil
    isFetchingOtherTokensBalance = true

    fetchBalanceTimer?.invalidate()
    fetchBalanceTimer = nil
    isFetchNonSupportedBalance = true
  }

  func exit() {
    pause()
  }


  @objc func fetchNonSupportedTokensBalancesNew(_ sender: Any?) {
    if self.isFetchNonSupportedBalance { return }
    self.isFetchNonSupportedBalance = true
    let tokenContracts = self.session.tokenStorage.tokens.filter({ return !$0.isETH && !$0.isSupported }).map({ $0.contract })

    let tokens = tokenContracts.map({ return Address(string: $0)! })

    self.fetchTokenBalances(tokens: tokens) { [weak self] result in
      guard let `self` = self else { return }
      self.isFetchNonSupportedBalance = false
      switch result {
      case .success(let isLoaded):
        if !isLoaded {
          self.fetchNonSupportedTokensBalancesChunked()
        } else {
          let tokens = self.session.tokenStorage.tokens.filter({ return !$0.isSupported && $0.valueBigInt == BigInt(0) })
          self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
        }
      case .failure(let error):
        if error.code == NSURLErrorNotConnectedToInternet { return }
        self.fetchNonSupportedTokensBalancesChunked()
      }
    }
  }

  func fetchNonSupportedTokensBalancesChunked(chunkedNum: Int = 20) {
    if self.isFetchNonSupportedBalance { return }
    self.isFetchNonSupportedBalance = true
    let sortedTokens = self.session.tokenStorage.tokens.filter({ return !$0.isETH && !$0.isSupported }).sorted { (left, right) -> Bool in
      return left.value > right.value
    }
    let sortedAddress = sortedTokens.map({ $0.contract }).map({ return Address(string: $0)! })
    let chunkedAddress = sortedAddress.chunked(into: chunkedNum)
    let group = DispatchGroup()
    chunkedAddress.forEach { (addresses) in
      group.enter()
      self.fetchTokenBalances(tokens: addresses) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let isLoaded):
          if !isLoaded {
            self.fetchNonSupportedTokensBalances(addresses: addresses)
          } else {
            let tokens = self.session.tokenStorage.tokens.filter({ return !$0.isSupported && $0.valueBigInt == BigInt(0) })
            self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
          }
        case .failure(let error):
          if error.code == NSURLErrorNotConnectedToInternet { return }
          self.fetchNonSupportedTokensBalances(addresses: addresses)
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      self.isFetchNonSupportedBalance = false
    }
  }

  func fetchNonSupportedTokensBalances(addresses: [Address]) {
    guard let provider = self.session.externalProvider else {
      return
    }
    var isBalanceChanged: Bool = false
    let currentWallet = self.session.wallet
    var zeroBalanceAddresses: [String] = []
    let group = DispatchGroup()
    var delay = 0.2
    self.isFetchNonSupportedBalance = true
    addresses.forEach { (address) in
      group.enter()
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        if self.session == nil { group.leave(); return }
        provider.getTokenBalance(for: address, completion: { [weak self] result in
          guard let `self` = self else { group.leave(); return }
          if self.session == nil || currentWallet != self.session.wallet { group.leave(); return }
          switch result {
          case .success(let bigInt):
            let balance = Balance(value: bigInt)
            if self.otherTokensBalance[address.description.lowercased()] == nil || self.otherTokensBalance[address.description.lowercased()]!.value != bigInt {
              isBalanceChanged = true
            }
            self.otherTokensBalance[address.description.lowercased()] = balance
            self.session.tokenStorage.updateBalance(for: address, balance: bigInt)
            if bigInt == BigInt(0) { zeroBalanceAddresses.append(address.description.lowercased()) }
            NSLog("---- Balance: Fetch token balance for contract \(address.description) successfully: \(bigInt.shortString(decimals: 0))")
          case .failure(let error):
            NSLog("---- Balance: Fetch token balance failed with error: \(error.description). ----")
          }
          group.leave()
        })
      }
      delay += 0.2
    }

    group.notify(queue: .main) {
      self.isFetchNonSupportedBalance = false
      if isBalanceChanged {
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      }
      if !zeroBalanceAddresses.isEmpty {
        let tokens = self.session.tokenStorage.tokens.filter({
          return zeroBalanceAddresses.contains($0.contract.lowercased())
        })
        self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
      }
    }
  }

  fileprivate func fetchTokenBalances(tokens: [Address], completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if tokens.isEmpty {
      completion(.success(true))
      return
    }
    var isBalanceChanged = false
    provider.getMultipleERC20Balances(tokens) { [weak self] result in
      guard let `self` = self else {
        completion(.success(false))
        return
      }
      switch result {
      case .success(let values):
        if values.count == tokens.count {
          for id in 0..<values.count {
            let balance = Balance(value: values[id])
            let addr = tokens[id].description.lowercased()
            if self.otherTokensBalance[addr.lowercased()] == nil || self.otherTokensBalance[addr.lowercased()]!.value != values[id] {
              isBalanceChanged = true
            }
            self.otherTokensBalance[addr.lowercased()] = balance
            self.session.tokenStorage.updateBalance(for: tokens[id], balance: values[id])
            if isDebug {
              NSLog("---- Balance: Fetch token balance for contract \(addr) successfully: \(values[id].shortString(decimals: 0))")
            }
          }
          if isBalanceChanged {
            KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          }
          completion(.success(true))
        } else {
          completion(.success(false))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  //MARK:-new balance load implementation
  func loadAllTokenBalance() {
    let tokens = KNSupportedTokenStorage.shared.getSupportedTokens()
    var erc20Address: [Address] = []
    tokens.forEach { (token) in
      if let address = Address(string: token.address) {
        erc20Address.append(address)
      }
    }
    guard !erc20Address.isEmpty else {
      return
    }
    KNGeneralProvider.shared.getMutipleERC20Balances(for: self.session.wallet.address, tokens: erc20Address) { result in
      switch result {
      case .success(let values):
        if values.count == erc20Address.count {
          var balances: [TokenBalance] = []
          for id in 0..<values.count {
            let balance = TokenBalance(address: erc20Address[id].description.lowercased(), balance: values[id].description)
            balances.append(balance)
          }
          BalanceStorage.shared.setBalances(balances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        } else {
          print("[LoadBalanceCoordinator] load error not equal count")
        }
      case .failure(let error):
        print("[LoadBalanceCoordinator] load error \(error.description)")
      }
    }
  }

  func loadBalanceForCustomToken() {
    let tokens = KNSupportedTokenStorage.shared.getCustomToken()
    let addresses = tokens.map { (token) -> String in
      return token.address
    }
    let group = DispatchGroup()
    addresses.forEach { (addressString) in
      guard let address = Address(string: addressString) else { return }
      group.enter()
      KNGeneralProvider.shared.getTokenBalance(for: self.session.wallet.address, contract: address) { result in
        if case .success(let bigInt) = result {
          let balance = TokenBalance(address: addressString, balance: bigInt.description)
          BalanceStorage.shared.setCustomTokenBalance(balance)
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      BalanceStorage.shared.saveCustomTokenBalance()
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    }
  }

  func loadLendingBalances() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getLendingBalance(address: self.session.wallet.address.description)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["result"] as? [JSONDictionary] {
        var balances: [LendingPlatformBalance] = []
        result.forEach { (element) in
          var lendingBalances: [LendingBalance] = []
          if let lendingBalancesDicts = element["balances"] as? [JSONDictionary] {
            lendingBalancesDicts.forEach { (item) in
              lendingBalances.append(LendingBalance(dictionary: item))
            }
          }
          let platformBalance = LendingPlatformBalance(name: element["name"] as? String ?? "", balances: lendingBalances)
          balances.append(platformBalance)
        }
        BalanceStorage.shared.setLendingBalances(balances)
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      } else {
        self.loadLendingBalances()
      }
    }
  }

  func loadLendingDistributionBalance() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getLendingDistributionBalance(lendingPlatform: "Compound", address: self.session.wallet.address.description)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["balance"] as? JSONDictionary {
        let balance = LendingDistributionBalance(dictionary: result)
        BalanceStorage.shared.setLendingDistributionBalance(balance)
      } else {
        self.loadLendingDistributionBalance()
      }
    }
  }
  
}
