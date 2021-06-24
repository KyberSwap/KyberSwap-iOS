//
//  EtherscanTransactionStorage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/9/21.
//

import Foundation

class EtherscanTransactionStorage {
  static let shared = EtherscanTransactionStorage()
  private var wallet: Wallet?
  private var tokenTransactions: [EtherscanTokenTransaction] = []
  private var internalTransaction: [EtherscanInternalTransaction] = []
  private var transactions: [EtherscanTransaction] = []
  private var historyTransactionModel: [HistoryTransaction] = []
  private var internalHistoryTransactions: [InternalHistoryTransaction] = []

  func updateCurrentWallet(_ wallet: Wallet) {
    self.wallet = wallet
    self.tokenTransactions = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName, as: [EtherscanTokenTransaction].self) ?? []
    self.internalTransaction = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName, as: [EtherscanInternalTransaction].self) ?? []
    self.transactions = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName, as: [EtherscanTransaction].self) ?? []
    self.historyTransactionModel = Storage.retrieve(wallet.address.description + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName, as: [HistoryTransaction].self) ?? []
    self.internalHistoryTransactions = []
//    DispatchQueue.global(qos: .background).async {
//      self.generateKrytalTransactionModel()
//    }
  }
  
  func setTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.tokenTransactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
  }

  func setInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.internalTransaction = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
  }

  func setTransactions(_ transactions: [EtherscanTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    self.transactions = transactions
    Storage.store(transactions, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
  }

  func getTokenTransaction() -> [EtherscanTokenTransaction] {
    return self.tokenTransactions
  }

  func getInternalTransaction() -> [EtherscanInternalTransaction] {
    return self.internalTransaction
  }

  func getTransaction() -> [EtherscanTransaction] {
    return self.transactions
  }

  func appendTokenTransactions(_ transactions: [EtherscanTokenTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanTokenTransaction] = []
    transactions.forEach { (item) in
      if !self.tokenTransactions.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    
    let result = newTx + self.tokenTransactions
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTokenTransactionsStoreFileName)
    self.tokenTransactions = result
  }
  
  fileprivate func checkRemoveInternalHistoryTransaction(_ hash: String) {
    let pendingHash = self.internalHistoryTransactions.map { $0.hash.lowercased() }
    if pendingHash.contains(hash.lowercased()) {
      let transaction = self.getInternalHistoryTransactionWithHash(hash.lowercased())
      KNNotificationUtil.postNotification(
        for: kTransactionDidUpdateNotificationKey,
        object: transaction,
        userInfo: nil
      )
      
      self.removeInternalHistoryTransactionWithHash(hash.lowercased())
    }
  }

  func appendInternalTransactions(_ transactions: [EtherscanInternalTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanInternalTransaction] = []
    transactions.forEach { (item) in
      if !self.internalTransaction.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.internalTransaction
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanInternalTransactionsStoreFileName)
    self.internalTransaction = result
  }

  func appendTransactions(_ transactions: [EtherscanTransaction]) {
    guard let unwrapped = self.wallet else {
      return
    }
    var newTx: [EtherscanTransaction] = []
    transactions.forEach { (item) in
      if !self.transactions.contains(item) {
        newTx.append(item)
      }
      self.checkRemoveInternalHistoryTransaction(item.hash)
    }
    guard !newTx.isEmpty else {
      return
    }
    let result = newTx + self.transactions
    Storage.store(result, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.etherscanTransactionsStoreFileName)
    self.transactions = result
  }

  func getCurrentTokenTransactionStartBlock() -> String {
    return self.tokenTransactions.first?.blockNumber ?? ""
  }
  
  func getCurrentInternalTransactionStartBlock() -> String {
    return self.internalTransaction.first?.blockNumber ?? ""
  }
  
  func getCurrentTransactionStartBlock() -> String {
    return self.transactions.first?.blockNumber ?? ""
  }

  func getInternalTransactionsWithHash(_ hash: String) -> [EtherscanInternalTransaction] {
    return self.internalTransaction.filter { (item) -> Bool in
      return item.hash == hash
    }
  }

  func getTokenTransactionWithHash(_ hash: String) -> [EtherscanTokenTransaction] {
    return self.tokenTransactions.filter { (item) -> Bool in
      return item.hash == hash
    }
  }

  func getTransactionWithHash(_ hash: String) -> [EtherscanTransaction] {
    return self.transactions.filter { (item) -> Bool in
      return item.hash == hash
    }
  }

  func generateKrytalTransactionModel() {
    guard let unwrapped = self.wallet else {
      return
    }
    
    let storedHashs = self.historyTransactionModel.map { $0.hash }
    
    var historyModel: [HistoryTransaction] = []
    self.getTransaction().forEach { (transaction) in
      var type = HistoryModelType.typeFromInput(transaction.input)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      if type == .transferETH && transaction.from == transaction.to {
        type = .selfTransfer
      } else if transaction.from.lowercased() != unwrapped.address.description.lowercased() && transaction.to.lowercased() == unwrapped.address.description.lowercased() {
        type = .receiveETH
      }
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: [transaction], internalTransactions: relatedInternalTx, tokenTransactions: relatedTokenTx, wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let etherscanTxHash = self.getTransaction().map { $0.hash }
    let internalTx = self.getInternalTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    internalTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedTokenTx = self.getTokenTransactionWithHash(transaction.hash)
      let model = HistoryTransaction(type: .receiveETH, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: [transaction], tokenTransactions: relatedTokenTx, wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    let tokenTx = self.getTokenTransaction().filter { (transaction) -> Bool in
      return !etherscanTxHash.contains(transaction.hash)
    }
    tokenTx.forEach { (transaction) in
      let relatedTx = self.getTransactionWithHash(transaction.hash)
      let relatedInternalTx = self.getInternalTransactionsWithHash(transaction.hash)
      let type: HistoryModelType = transaction.from.lowercased() == unwrapped.address.description.lowercased() ? .transferToken : .receiveToken
      let model = HistoryTransaction(type: type, timestamp: transaction.timeStamp, transacton: relatedTx, internalTransactions: relatedInternalTx, tokenTransactions: [transaction], wallet: unwrapped.address.description.lowercased())
      historyModel.append(model)
    }
    historyModel.sort { (left, right) -> Bool in
      return left.timestamp > right.timestamp
    }
    
    var newestTxs: [HistoryTransaction] = []
    historyModel.forEach { (txItem) in
      if !storedHashs.contains(txItem.hash) {
        newestTxs.append(txItem)
      }
    }
    
    print("[ESStorage][NewTX] \(newestTxs)")
    
    self.historyTransactionModel = historyModel
    Storage.store(self.historyTransactionModel, as: unwrapped.address.description + KNEnvironment.default.envPrefix + Constants.historyTransactionsStoreFileName)
    DispatchQueue.main.async {
      KNNotificationUtil.postNotification(for: kTokenTransactionListDidUpdateNotificationKey)
      newestTxs.forEach { (item) in
        if item.date.addingTimeInterval(10800) > Date() {
          if item.type == .receiveETH || item.type == .receiveToken || item.type == .earn {
            KNNotificationUtil.postNotification(for: kNewReceivedTransactionKey, object: item)
          }
        }
      }
    }
  }

  func getHistoryTransactionModel() -> [HistoryTransaction] {
    return self.historyTransactionModel
  }

  func getInternalHistoryTransaction() -> [InternalHistoryTransaction] {
    return self.internalHistoryTransactions
  }

  func appendInternalHistoryTransaction(_ tx: InternalHistoryTransaction) {
    self.internalHistoryTransactions.append(tx)
    KNNotificationUtil.postNotification(
      for: kTransactionDidUpdateNotificationKey,
      object: tx,
      userInfo: nil
    )
  }

  func isContainInsternalSendTransaction() -> Bool {
    let result = self.internalHistoryTransactions.first { (item) -> Bool in
      return item.type == .transferETH || item.type == .transferToken || item.type == .swap || item.type == .earn
    }
    return result != nil
  }

  func getInternalHistoryTransactionWithHash(_ hash: String) -> InternalHistoryTransaction? {
    return self.internalHistoryTransactions.first { (item) -> Bool in
      return item.hash.lowercased() == hash
    }
  }

  @discardableResult
  func removeInternalHistoryTransactionWithHash(_ hash: String) -> Bool {
    guard let index = self.internalHistoryTransactions.firstIndex(where: { (item) -> Bool in
      return item.hash.lowercased() == hash.lowercased()
    }) else {
      return false
    }
    self.internalHistoryTransactions.remove(at: index)
    return true
  }

  func getEtherscanToken() -> [Token] {
    var tokenSet = Set<Token>()
    let eth = KNGeneralProvider.shared.isEthereum ? KNSupportedTokenStorage.shared.ethToken.toToken() : KNSupportedTokenStorage.shared.bnbToken.toToken()
    tokenSet.insert(eth)
    self.tokenTransactions.forEach { (transaction) in
      let token = Token(name: transaction.tokenName, symbol: transaction.tokenSymbol, address: transaction.contractAddress, decimals: Int(transaction.tokenDecimal) ?? 0, logo: transaction.tokenSymbol)
      tokenSet.insert(token)
    }
    return Array(tokenSet).sorted { (left, right) -> Bool in
      return left.symbol > right.symbol
    }
  }
  
  
}
