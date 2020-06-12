// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore

class KNLoadBalanceCoordinator {

  fileprivate var session: KNSession!
  fileprivate var ethToken: TokenObject!

  fileprivate var fetchETHBalanceTimer: Timer?
  fileprivate var isFetchingETHBalance: Bool = false
  var ethBalance: Balance = Balance(value: BigInt(0))

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false

  var otherTokensBalance: [String: Balance] = [:]

  fileprivate var fetchNonSupportedBalanceTimer: Timer?
  fileprivate var isFetchNonSupportedBalance: Bool = false

  fileprivate var lastRefreshTime: Date = Date()

  var totalBalanceInUSD: BigInt {
    let balanceValue: BigInt = {
      var value = BigInt(0)
      if self.ethToken != nil, let ethRate = KNRateCoordinator.shared.usdRate(for: self.ethToken) {
        value = ethRate.rate * ethBalance.value / BigInt(EthereumUnit.ether.rawValue)
      }
      let tokens = KNSupportedTokenStorage.shared.supportedTokens
      for token in tokens {
        if let balance = otherTokensBalance[token.contract.lowercased()], !balance.value.isZero, let rate = KNRateCoordinator.shared.usdRate(for: token) {
          value += rate.rate * balance.value / BigInt(10).power(token.decimals)
        }
      }
      return value
    }()
    return balanceValue
  }

  var totalBalanceInETH: BigInt {
    let balanceValue: BigInt = {
      var value = self.ethBalance.value
      if self.ethToken == nil { return value }

      let tokenObjects = KNSupportedTokenStorage.shared.supportedTokens

      for tokenObj in tokenObjects {
        if let balance = otherTokensBalance[tokenObj.contract.lowercased()], !balance.value.isZero, let rate = KNRateCoordinator.shared.getRate(from: tokenObj, to: self.ethToken) {
          value += rate.rate * balance.value / BigInt(10).power(tokenObj.decimals)
        }
      }
      return value
    }()
    return balanceValue
  }

  deinit {
    self.exit()
    let name = Notification.Name(kRefreshBalanceNotificationKey)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  init(session: KNSession) {
    self.session = session
    self.ethToken = session.tokenStorage.ethToken
    self.updateBalancesFromLocalData()
    let name = Notification.Name(kRefreshBalanceNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.shouldRefreshBalance(_:)),
      name: name,
      object: nil
    )
  }

  func restartNewSession(_ session: KNSession) {
    self.session = session
    self.ethToken = session.tokenStorage.ethToken
    self.ethBalance = Balance(value: BigInt(0))
    self.otherTokensBalance = [:]
    self.updateBalancesFromLocalData()
    self.resume()
  }

  fileprivate func updateBalancesFromLocalData() {
    let tokens = self.session.tokenStorage.tokens
    tokens.forEach { token in
      if token.isETH {
        self.ethBalance = Balance(value: token.valueBigInt)
      } else {
        self.otherTokensBalance[token.contract.lowercased()] = Balance(value: token.valueBigInt)
      }
    }
  }

  @objc func shouldRefreshBalance(_ sender: Any?) {
    if Date().timeIntervalSince(self.lastRefreshTime) >= 15.0 {
      self.lastRefreshTime = Date()
      self.fetchETHBalance(nil)
      self.fetchOtherTokenBalancesNew(nil)
    }
  }

  func forceUpdateBalanceTransactionsCompleted() {
    self.shouldRefreshBalance(nil)
  }

  func resume() {
    self.lastRefreshTime = Date()
    fetchETHBalanceTimer?.invalidate()
    isFetchingETHBalance = false
    fetchETHBalance(nil)

    fetchETHBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds20,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchETHBalance(timer)
      }
    )

    fetchOtherTokensBalanceTimer?.invalidate()
    isFetchingOtherTokensBalance = false
    fetchOtherTokenBalancesNew(nil)

    fetchOtherTokensBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] timer in
      self?.fetchOtherTokenBalancesNew(timer)
      }
    )

    fetchNonSupportedBalanceTimer?.invalidate()
    isFetchNonSupportedBalance = false
    fetchNonSupportedTokensBalancesNew(nil)

    fetchNonSupportedBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] timer in
        self?.fetchNonSupportedTokensBalancesNew(timer)
      }
    )
  }

  func pause() {
    fetchETHBalanceTimer?.invalidate()
    fetchETHBalanceTimer = nil
    isFetchingETHBalance = true

    fetchOtherTokensBalanceTimer?.invalidate()
    fetchOtherTokensBalanceTimer = nil
    isFetchingOtherTokensBalance = true

    fetchNonSupportedBalanceTimer?.invalidate()
    fetchNonSupportedBalanceTimer = nil
    isFetchNonSupportedBalance = true
  }

  func exit() {
    pause()
  }

  @objc func fetchETHBalance(_ sender: Timer?) {
    if isFetchingETHBalance { return }
    isFetchingETHBalance = true
    let currentWallet = self.session.wallet
    let address = self.ethToken.address
    if self.session == nil {
      self.isFetchingETHBalance = false
      return
    }
    self.session.externalProvider.getETHBalance { [weak self] result in
      guard let `self` = self else { return }
      if self.session == nil || currentWallet != self.session.wallet {
        self.isFetchingETHBalance = false
        return
      }
      self.isFetchingETHBalance = false
      switch result {
      case .success(let balance):
        if self.ethBalance.value != balance.value {
          self.ethBalance = balance
          self.session.tokenStorage.updateBalance(for: address, balance: balance.value)
          KNNotificationUtil.postNotification(for: kETHBalanceDidUpdateNotificationKey)
        }
      case .failure(let error):
        NSLog("Load ETH Balance failed with error: \(error.description)")
      }
    }
  }

  func fetchTokenAddressAfterTx(token1: String, token2: String) {
    let group = DispatchGroup()
    group.enter()
    self.loadBalanceForToken(token1) {
      group.leave()
    }
    if token1 != token2 {
      group.enter()
      self.loadBalanceForToken(token2) {
        group.leave()
      }
    }
    group.notify(queue: .main) {
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
    }
  }

  fileprivate func loadBalanceForToken(_ token: String, completion: @escaping () -> Void) {
    let currentWallet = self.session.wallet
    let address = self.ethToken.address
    if token.lowercased() == self.ethToken.contract.lowercased() {
      self.session.externalProvider.getETHBalance { [weak self] result in
        guard let `self` = self else {
          completion()
          return
        }
        if self.session == nil || currentWallet != self.session.wallet {
          completion()
          return
        }
        if case .success(let balance) = result {
          if self.ethBalance.value != balance.value {
            self.ethBalance = balance
            self.session.tokenStorage.updateBalance(for: address, balance: balance.value)
            KNNotificationUtil.postNotification(for: kETHBalanceDidUpdateNotificationKey)
          }
        }
        completion()
      }
    } else if let address = Address(string: token) {
      self.session.externalProvider.getTokenBalance(for: address) { [weak self] result in
        guard let `self` = self else {
          completion()
          return
        }
        if self.session == nil || currentWallet != self.session.wallet { completion(); return }
        if case .success(let bigInt) = result {
          let balance = Balance(value: bigInt)
          self.otherTokensBalance[token.lowercased()] = balance
          self.session.tokenStorage.updateBalance(for: address, balance: bigInt)
        }
        completion()
      }
    } else {
      completion()
    }
  }

  @objc func fetchOtherTokenBalancesNew(_ sender: Timer?, isRetry: Bool = true) {
    guard KNReachability.shared.reachabilityManager?.isReachable == true else { return }
    if isFetchingOtherTokensBalance { return }
    isFetchingOtherTokensBalance = true

    let tokenContracts = self.session.tokenStorage.tokens.filter({ return !$0.isETH && $0.isSupported }).map({ $0.contract })

    let tokens = tokenContracts.map({ return Address(string: $0)! })

    self.fetchTokenBalances(tokens: tokens) { [weak self] result in
      guard let `self` = self else { return }
      self.isFetchingOtherTokensBalance = false
      switch result {
      case .success(let isLoaded):
        if !isLoaded {
          self.fetchOtherTokenChucked()
        }
      case .failure(let error):
        if error.code == NSURLErrorNotConnectedToInternet { return }
        guard isRetry else {
          return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
          self.fetchOtherTokenBalancesNew(nil, isRetry: false)
        }
      }
    }
  }

  @objc func fetchOtherTokenChucked(chunkedNum: Int = 20) {
    KNCrashlyticsUtil.logCustomEvent(
      withName: "load_balance_load_token_chucked",
      customAttributes: nil
    )
    if isFetchingOtherTokensBalance { return }
    isFetchingOtherTokensBalance = true
    //1. sort token base on their balance
    let sortedTokens = self.session.tokenStorage.tokens.filter({ return !$0.isETH && $0.isSupported }).sorted { (left, right) -> Bool in
      return left.value > right.value
    }
    let sortedAddress = sortedTokens.map({ $0.contract }).map({ return Address(string: $0)! })

    //2. peform load in sequence
    let chunkedAddress = sortedAddress.chunked(into: chunkedNum)

    let group = DispatchGroup()
    chunkedAddress.forEach { (addresses) in
      group.enter()
      self.fetchTokenBalances(tokens: addresses) { [weak self] result in
        guard let `self` = self else { return }
        group.leave()
        switch result {
        case .success(let isLoaded):
          if !isLoaded {
            self.fetchOtherTokenBalances(addresses: addresses)
          }
        case .failure:
          KNCrashlyticsUtil.logCustomEvent(
            withName: "load_balance_load_token_chucked_failure",
            customAttributes: nil
          )
        }
      }
    }
    group.notify(queue: .main) {
      self.isFetchingOtherTokensBalance = false
    }
  }

  func fetchOtherTokenBalances(addresses: [Address]) {
    KNCrashlyticsUtil.logCustomEvent(
      withName: "load_balance_load_token_balance_one_by_one",
      customAttributes: nil
    )
    var isBalanceChanged: Bool = false
    let currentWallet = self.session.wallet
    var delay = 0.2
    let group = DispatchGroup()
    addresses.forEach { (address) in
      group.enter()
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
         self.session.externalProvider.getTokenBalance(for: address, completion: { [weak self] result in
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
             NSLog("---- Balance: Fetch token balance for contract \(address) successfully: \(bigInt.shortString(decimals: 0))")
           case .failure(let error):
             NSLog("---- Balance: Fetch token balance failed with error: \(error.description). ----")
           }
           group.leave()
         })
      }
      delay += 0.2
    }

    group.notify(queue: .main) {
      self.isFetchingOtherTokensBalance = false
      if isBalanceChanged {
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      }
    }
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
      case .failure:
        KNCrashlyticsUtil.logCustomEvent(
          withName: "load_balance_load_unsupported_token_failure",
          customAttributes: nil
        )
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
      self.fetchTokenBalances(tokens: addresses) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let isLoaded):
          if !isLoaded {
            self.fetchNonSupportedTokensBalance(nil)
          } else {
            let tokens = self.session.tokenStorage.tokens.filter({ return !$0.isSupported && $0.valueBigInt == BigInt(0) })
            self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
          }
        case .failure:
          KNCrashlyticsUtil.logCustomEvent(
            withName: "load_balance_load_unsupported_token_chunked_failure",
            customAttributes: nil
          )
        }
      }
    }
    group.notify(queue: .main) {
      self.isFetchNonSupportedBalance = false
    }
  }

  @objc func fetchNonSupportedTokensBalance(_ sender: Any?) {
    if self.isFetchNonSupportedBalance { return }
    self.isFetchNonSupportedBalance = true
    var isBalanceChanged: Bool = false
    let tokenContracts = self.session.tokenStorage.tokens.filter({ return !$0.isETH && !$0.isSupported }).map({ $0.contract })
    let currentWallet = self.session.wallet
    let group = DispatchGroup()
    var counter = 0
    var delay = 0.2
    var zeroBalanceAddresses: [String] = []
    for contract in tokenContracts {
      if let contractAddress = Address(string: contract) {
        group.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
          if self.session == nil { group.leave(); return }
          self.session.externalProvider.getTokenBalance(for: contractAddress, completion: { [weak self] result in
            guard let `self` = self else { group.leave(); return }
            if self.session == nil || currentWallet != self.session.wallet { group.leave(); return }
            switch result {
            case .success(let bigInt):
              let balance = Balance(value: bigInt)
              if self.otherTokensBalance[contract.lowercased()] == nil || self.otherTokensBalance[contract.lowercased()]!.value != bigInt {
                isBalanceChanged = true
              }
              self.otherTokensBalance[contract.lowercased()] = balance
              self.session.tokenStorage.updateBalance(for: contractAddress, balance: bigInt)
              if bigInt == BigInt(0) { zeroBalanceAddresses.append(contract.lowercased()) }
              NSLog("---- Balance: Fetch token balance for contract \(contract) successfully: \(bigInt.shortString(decimals: 0))")
            case .failure(let error):
              NSLog("---- Balance: Fetch token balance failed with error: \(error.description). ----")
            }
            counter += 1
            if counter % 32 == 0 && isBalanceChanged {
              KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
            }
            group.leave()
          })
        }
        delay += 0.2
      }
    }
    // notify when all load balances are done
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
    if tokens.isEmpty {
      completion(.success(true))
      return
    }
    var isBalanceChanged = false
    self.session.externalProvider.getMultipleERC20Balances(tokens) { [weak self] result in
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
}
