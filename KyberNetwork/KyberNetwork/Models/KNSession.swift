// Copyright SIX DAY LLC. All rights reserved.

import APIKit
import JSONRPCKit
import BigInt
import TrustKeystore
import TrustCore
import RealmSwift

protocol KNSessionDelegate: class {
  func userDidClickExitSession()
}

class KNSession {

  private(set) var keystore: Keystore
  private(set) var wallet: Wallet
  let web3Swift: Web3Swift
  let externalProvider: KNExternalProvider
  private(set) var realm: Realm
  private(set) var transactionStorage: TransactionsStorage
  private(set) var tokenStorage: KNTokenStorage

  private(set) var transacionCoordinator: KNTransactionCoordinator?

  init(keystore: Keystore,
       wallet: Wallet) {
    self.keystore = keystore
    self.wallet = wallet
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpoint + KNEnvironment.default.nodeEndpoint) {
      self.web3Swift = Web3Swift(url: path)
    } else {
      self.web3Swift = Web3Swift()
    }
    // Wallet type should always be real(account)
    var account: Account!
    if case .real(let acc) = self.wallet.type {
      account = acc
    }
    let config = RealmConfiguration.configuration(for: wallet, chainID: KNEnvironment.default.chainID)
    self.realm = try! Realm(configuration: config)
    self.transactionStorage = TransactionsStorage(realm: self.realm)
    self.tokenStorage = KNTokenStorage(realm: self.realm)
    self.externalProvider = KNExternalProvider(web3: self.web3Swift, keystore: self.keystore, account: account)
    let pendingTxs = self.transactionStorage.kyberPendingTransactions
    if let tx = pendingTxs.first(where: { $0.from.lowercased() == wallet.address.description.lowercased() }), let nonce = Int(tx.nonce) {
      self.externalProvider.updateNonceWithLastRecordedTxNonce(nonce)
    }
  }

  func startSession() {
    self.web3Swift.start()
    self.transacionCoordinator?.stop()
    self.transacionCoordinator = KNTransactionCoordinator(
      transactionStorage: self.transactionStorage,
      tokenStorage: self.tokenStorage,
      externalProvider: self.externalProvider,
      wallet: self.wallet
    )
    self.transacionCoordinator?.start()
  }

  func stopSession() {
    self.transacionCoordinator?.stop()
    self.transacionCoordinator = nil

    self.keystore.wallets.forEach { self.removeWallet($0) }
    KNAppTracker.resetAllAppTrackerData()
    self.keystore.recentlyUsedWallet = nil
  }

  // Switch between wallets
  func switchSession(_ wallet: Wallet) {
    self.transacionCoordinator?.stop()
    self.transacionCoordinator = nil

    self.wallet = wallet
    self.keystore.recentlyUsedWallet = wallet

    var account: Account!
    if case .real(let acc) = self.wallet.type {
      account = acc
    }
    self.externalProvider.updateNewAccount(account)
    let config = RealmConfiguration.configuration(for: wallet, chainID: KNEnvironment.default.chainID)
    self.realm = try! Realm(configuration: config)
    self.transactionStorage = TransactionsStorage(realm: self.realm)
    self.tokenStorage = KNTokenStorage(realm: self.realm)
    self.transacionCoordinator = KNTransactionCoordinator(
      transactionStorage: self.transactionStorage,
      tokenStorage: self.tokenStorage,
      externalProvider: self.externalProvider,
      wallet: self.wallet
    )
    self.transacionCoordinator?.start()
    let pendingTxs = self.transactionStorage.kyberPendingTransactions
    if let tx = pendingTxs.first(where: { $0.from.lowercased() == wallet.address.description.lowercased() }), let nonce = Int(tx.nonce) {
      self.externalProvider.updateNonceWithLastRecordedTxNonce(nonce)
    }
  }

  // Remove a wallet, it should not be a current wallet
  @discardableResult
  func removeWallet(_ wallet: Wallet) -> Bool {
    if let recentWallet = self.keystore.recentlyUsedWallet, recentWallet == wallet {
      self.transacionCoordinator?.stop()
      self.transacionCoordinator = nil
    }
    // delete all storage for each wallet
    let deleteResult = self.keystore.delete(wallet: wallet)
    switch deleteResult {
    case .failure(let err):
      if case .failedToDeleteAccount = err {
        return false
      }
    default: break
    }
    KNAppTracker.resetAppTrackerData(for: wallet.address)
    for env in KNEnvironment.allEnvironments() {
      // Remove token and transaction storage
      let config = RealmConfiguration.configuration(for: wallet, chainID: env.chainID)
      let realm = try! Realm(configuration: config)
      let transactionStorage = TransactionsStorage(realm: realm)
      transactionStorage.deleteAll()
      let tokenStorage = KNTokenStorage(realm: realm)
      tokenStorage.deleteAll()

      // Remove wallet storage
      let globalConfig = RealmConfiguration.globalConfiguration(for: env.chainID)
      let globalRealm = try! Realm(configuration: globalConfig)
      if let walletObject = globalRealm.object(ofType: KNWalletObject.self, forPrimaryKey: wallet.address.description) {
        KNWalletPromoInfoStorage.shared.removeWalletPromoInfo(address: walletObject.address)
        try! globalRealm.write { globalRealm.delete(walletObject) }
      }
    }
    return true
  }

  func addNewPendingTransaction(_ transaction: Transaction) {
    // Put here to be able force update new pending transaction immmediately
    let kyberTx = KNTransaction.from(transaction: transaction)
    self.transactionStorage.addKyberTransactions([kyberTx])
    self.transacionCoordinator?.updatePendingTransaction(kyberTx)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: transaction.id,
      userInfo: nil
    )
  }

  func updatePendingTransactionWithHash(hashTx: String,
                                        ultiTransaction: Transaction,
                                        state: TransactionState = .cancelling,
                                        completion: @escaping () -> Void = {}) {
    if transactionStorage.updateKyberTransaction(forPrimaryKey: hashTx, state: state) {
      self.addNewPendingTransaction(ultiTransaction)
      completion()
    }
  }

  func updateFailureTransaction(type: TransactionType) -> Bool {
    var hashTx = ""
    switch type {
    case .speedup:
      hashTx = transactionStorage.kyberSpeedUpProcessingTransactions.first?.id ?? ""
    case .cancel:
      hashTx = transactionStorage.kyberCancelProcessingTransactions.first?.id ?? ""
    default:
      return false
    }
    guard !hashTx.isEmpty else {
      return false
    }
    if isDebug { print("[Debug] call update original tx \(hashTx)") }
    if transactionStorage.updateKyberTransaction(forPrimaryKey: hashTx, state: .pending) {
      guard let transaction = transactionStorage.getKyberTransaction(forPrimaryKey: hashTx), transaction.isInvalidated == false else { return false }
      self.transacionCoordinator?.updatePendingTransaction(transaction)
      KNNotificationUtil.postNotification(
        for: kTransactionDidUpdateNotificationKey,
        object: transaction.id,
        userInfo: nil
      )
    }
    return true
  }

  static func resumeInternalSession() {
    KNRateCoordinator.shared.resume()
    KNGasCoordinator.shared.resume()
    KNRecentTradeCoordinator.shared.resume()
    KNSupportedTokenCoordinator.shared.resume()
    KNNotificationCoordinator.shared.resume()
  }

  static func pauseInternalSession() {
    KNRateCoordinator.shared.pause()
    KNGasCoordinator.shared.pause()
    KNRecentTradeCoordinator.shared.pause()
    KNSupportedTokenCoordinator.shared.pause()
    KNNotificationCoordinator.shared.pause()
  }
}

extension KNSession {
  var sessionID: String {
    return KNSession.sessionID(from: self.wallet)
  }

  static func sessionID(from wallet: Wallet) -> String {
    return KNSession.sessionID(from: wallet.address)
  }

  static func sessionID(from address: Address) -> String {
    if KNEnvironment.default == .production {
      return "sessionID-\(address.description)"
    }
    return "sessionID-\(KNEnvironment.default.displayName)-\(address.description)"
  }
}
