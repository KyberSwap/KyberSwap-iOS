// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit

class KNExternalProvider {

  let keystore: Keystore
  fileprivate var account: Account
  let web3Swift: Web3Swift
  let knCustomRPC: KNCustomRPC!
  let networkAddress: Address!
  let limitOrderAddress: Address!

  var minTxCount: Int {
    didSet {
      KNAppTracker.updateTransactionNonce(self.minTxCount, address: self.account.address)
    }
  }

  init(web3: Web3Swift, keystore: Keystore, account: Account) {
    self.keystore = keystore
    self.account = account
    self.web3Swift = web3
    let customRPC: KNCustomRPC = KNEnvironment.default.knCustomRPC!
    self.knCustomRPC = customRPC
    self.networkAddress = Address(string: customRPC.networkAddress)
    self.minTxCount = 0
    self.limitOrderAddress = Address(string: customRPC.limitOrderAddress)
  }

  func updateNonceWithLastRecordedTxNonce(_ nonce: Int) {
    KNGeneralProvider.shared.getTransactionCount(
      for: self.account.address.description,
      state: "pending") { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let txCount) = result {
        self.minTxCount = max(self.minTxCount, min(txCount, nonce + 1))
      }
    }
  }

  func updateNewAccount(_ account: Account) {
    self.account = account
    self.minTxCount = 0
  }

  // MARK: Balance
  public func getETHBalance(completion: @escaping (Result<Balance, AnyError>) -> Void) {
    KNGeneralProvider.shared.getETHBalanace(
      for: self.account.address.description,
      completion: completion
    )
  }

  public func getTokenBalance(for contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTokenBalance(
      for: self.account.address,
      contract: contract,
      completion: completion
    )
  }

  // MARK: Transaction
  func getTransactionCount(completion: @escaping (Result<Int, AnyError>) -> Void) {
    KNGeneralProvider.shared.getTransactionCount(
    for: self.account.address.description) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let txCount):
        self.minTxCount = max(self.minTxCount, txCount)
        completion(.success(txCount))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func transfer(transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: transaction, nonce: self.minTxCount, data: data, completion: { signResult in
              switch signResult {
              case .success(let signData):
                KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success = result { self.minTxCount += 1 }
                  completion(result)
                })
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func speedUpTransferTransaction(transaction: UnconfirmedTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.requestDataForTokenTransfer(transaction, completion: { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        self.signTransactionData(from: transaction, nonce: Int(transaction.nonce!), data: data, completion: { signResult in
          switch signResult {
          case .success(let signData):
            KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { result in
              completion(result)
            })
          case .failure(let error):
            completion(.failure(error))
          }
        })
      case .failure(let error):
        completion(.failure(error))
      }
    })
  }

  func speedUpSwapTransaction(
    for token: TokenObject,
    amount: BigInt,
    nonce: Int,
    data: Data,
    gasPrice: BigInt,
    gasLimit: BigInt,
    completion: @escaping (Result<String, AnyError>) -> Void) {
    self.signTransactionData(
      for: token,
      amount: amount,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit) { (signResult) in
        switch signResult {
        case .success(let signData):
          KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { result in
            completion(result)
          })
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  func exchange(exchange: KNDraftExchangeTransaction, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else { return }
      switch txCountResult {
      case .success:
        self.requestDataForTokenExchange(exchange, completion: { [weak self] dataResult in
          guard let `self` = self else { return }
          switch dataResult {
          case .success(let data):
            self.signTransactionData(from: exchange, nonce: self.minTxCount, data: data, completion: { signResult in
              switch signResult {
              case .success(let signData):
                KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { [weak self] result in
                  guard let `self` = self else { return }
                  if case .success = result { self.minTxCount += 1 }
                  completion(result)
                })
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func sendTxWalletConnect(txData: JSONDictionary, completion: @escaping (Result<String?, AnyError>) -> Void) {
    guard let value = (txData["value"] as? String ?? "").fullBigInt(decimals: 0),
      let from = txData["from"] as? String, let to = txData["to"] as? String,
      let gasPrice = (txData["gasPrice"] as? String ?? "").fullBigInt(decimals: 0),
      let gasLimit = (txData["gasLimit"] as? String ?? "").fullBigInt(decimals: 0),
      from.lowercased() == self.account.address.description.lowercased(),
      !gasPrice.isZero, !gasLimit.isZero else {
      completion(.success(nil))
      return
    }

    // Parse data from hex string
    let dataParse: Data? = (txData["data"] as? String ?? "").dataFromHex()
    guard let data = dataParse else {
      completion(.success(nil))
      return
    }

    guard let toAddr = Address(string: to) else {
      completion(.success(nil))
      return
    }
    self.getTransactionCount { [weak self] txCountResult in
      guard let `self` = self else {
        completion(.success(nil))
        return
      }
      switch txCountResult {
      case .success:
        let signTx = SignTransaction(
          value: value,
          account: self.account,
          to: toAddr,
          nonce: self.minTxCount,
          data: data,
          gasPrice: gasPrice,
          gasLimit: gasLimit,
          chainID: KNEnvironment.default.chainID
        )
        self.signTransactionData(from: signTx) { [weak self] signResult in
          switch signResult {
          case .success(let signData):
            KNGeneralProvider.shared.sendSignedTransactionData(signData, completion: { [weak self] result in
              guard let `self` = self else { return }
              switch result {
              case .success(let txHash):
                self.minTxCount += 1
                completion(.success(txHash))
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getReceipt(for transaction: KNTransaction, completion: @escaping (Result<KNTransaction, AnyError>) -> Void) {
    let request = KNGetTransactionReceiptRequest(hash: transaction.id)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let receipt):
        self.getExchangeTransactionDecode(receipt.logsData, completion: { decodeResult in
          let dict: JSONDictionary? = {
            if case .success(let json) = decodeResult {
              return json
            }
            return nil
          }()
          let newTransaction = receipt.toTransaction(from: transaction, logsDict: dict)
          completion(.success(newTransaction))
        })
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getTransactionByHash(_ hash: String, completion: @escaping (PendingTransaction?, SessionTaskError?) -> Void) {
    let request = GetTransactionRequest(hash: hash)
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let response):
        completion(response, nil)
      case .failure(let error):
        completion(nil, error)
      }
    }
  }

  func getAllowance(token: TokenObject, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: token,
      address: self.account.address,
      networkAddress: self.networkAddress,
      completion: completion
    )
  }

  func getAllowanceLimitOrder(token: TokenObject, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    KNGeneralProvider.shared.getAllowance(
      for: token,
      address: self.account.address,
      networkAddress: self.limitOrderAddress,
      completion: completion
    )
  }

  // Encode function, get transaction count, sign transaction, send signed data
  func sendApproveERC20Token(exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.sendApproveERCToken(
      for: exchangeTransaction.from,
      value: BigInt(2).power(255),
      gasPrice: exchangeTransaction.gasPrice ?? KNGasCoordinator.shared.defaultKNGas,
      completion: completion
    )
  }

  func sendApproveERCToken(for token: TokenObject, value: BigInt, gasPrice: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      token: token,
      value: value,
      account: self.account,
      keystore: self.keystore,
      currentNonce: self.minTxCount,
      networkAddress: self.networkAddress,
      gasPrice: gasPrice
    ) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let txCount):
          self.minTxCount = txCount
          completion(.success(true))
        case .failure(let error):
          completion(.failure(error))
        }
    }
  }

  func sendApproveERCTokenLimitOrder(for token: TokenObject, value: BigInt, gasPrice: BigInt, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    KNGeneralProvider.shared.approve(
      token: token,
      value: value,
      account: self.account,
      keystore: self.keystore,
      currentNonce: self.minTxCount,
      networkAddress: self.limitOrderAddress,
      gasPrice: gasPrice
    ) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let txCount):
        self.minTxCount = txCount
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  // MARK: Rate
  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    KNGeneralProvider.shared.getExpectedRate(
      from: from,
      to: to,
      amount: amount,
      completion: completion
    )
  }

  // MARK: Estimate Gas
  func getEstimateGasLimit(for transferTransaction: UnconfirmedTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {

    let defaultGasLimit: BigInt = {
      KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transferTransaction.transferType.tokenObject())
    }()
    self.requestDataForTokenTransfer(transferTransaction) { [weak self] result in
      guard let `self` = self else { return }
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.addressToSend(transferTransaction)?.description,
          gasPrice: transferTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: self.valueToSend(transferTransaction),
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: false,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getEstimateGasLimit(for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let value: BigInt = exchangeTransaction.from.isETH ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.calculateDefaultGasLimit(from: exchangeTransaction.from, to: exchangeTransaction.to)
    }()

    self.requestDataForTokenExchange(exchangeTransaction) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: self.account.address.description,
          to: self.networkAddress.description,
          gasPrice: exchangeTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: value,
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: true,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  static func estimateGasLimit(from: String, to: String?, gasPrice: BigInt, value: BigInt, data: Data, defaultGasLimit: BigInt, isSwap: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: from,
      to: to,
      value: value,
      data: data,
      gasPrice: gasPrice
    )
    NSLog("------ Estimate gas used ------")
    Session.send(EtherServiceRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let value):
        let gasLimit: BigInt = {
          var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
          // Used  120% of estimated gas for safer
          limit += (limit * 20 / 100)
          limit += isSwap ? 100000 : 20000 // add 100k if it is a swap, otherwise 20k
          return min(limit, defaultGasLimit)
        }()
        NSLog("------ Estimate gas used: \(gasLimit.fullString(units: .wei)) ------")
        completion(.success(gasLimit))
      case .failure(let error):
        NSLog("------ Estimate gas used failed: \(error.localizedDescription) ------")
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getMultipleERC20Balances(_ tokens: [Address], completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    KNGeneralProvider.shared.getMutipleERC20Balances(for: self.account.address, tokens: tokens, completion: completion)
  }

  // MARK: Sign transaction
  private func signTransactionData(from transaction: UnconfirmedTransaction, nonce: Int, data: Data?, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let defaultGasLimit: BigInt = KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transaction.transferType.tokenObject())
    let signTransaction: SignTransaction = SignTransaction(
      value: self.valueToSend(transaction),
      account: self.account,
      to: self.addressToSend(transaction),
      nonce: nonce,
      data: data ?? Data(),
      gasPrice: transaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: transaction.gasLimit ?? defaultGasLimit,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from exchange: KNDraftExchangeTransaction, nonce: Int, data: Data, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: exchange.from.isETH ? exchange.amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: exchange.gasPrice ?? KNGasConfiguration.gasPriceDefault,
      gasLimit: exchange.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(for token: TokenObject, amount: BigInt, nonce: Int, data: Data, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signTransaction: SignTransaction = SignTransaction(
      value: token.isETH ? amount : BigInt(0),
      account: self.account,
      to: self.networkAddress,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNEnvironment.default.chainID
    )
    self.signTransactionData(from: signTransaction, completion: completion)
  }

  private func signTransactionData(from signTransaction: SignTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let signResult = self.keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  // MARK: Web3Swift Encode/Decode data
  func getExchangeTransactionDecode(_ data: String, completion: @escaping (Result<JSONDictionary, AnyError>) -> Void) {
    let request = KNExchangeEventDataDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let json):
        completion(.success(json))
      case .failure(let error):
        if let err = error.error as? JSErrorDomain {
          if case .invalidReturnType(let object) = err, let json = object as? JSONDictionary {
            completion(.success(json))
            return
          }
        }
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenTransfer(_ transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    if transaction.transferType.isETHTransfer() {
      completion(.success(Data()))
      return
    }
    self.web3Swift.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to?.description ?? "")) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func requestDataForTokenExchange(_ exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: self.account.address)
    self.web3Swift.request(request: encodeRequest) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  // MARK: Helper
  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    return transaction.transferType.isETHTransfer() ? transaction.value : BigInt(0)
  }

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> Address? {
    let address: Address? = {
      switch transaction.transferType {
      case .ether: return transaction.to
      case .token(let token):
        return token.address
      }
    }()
    return address
  }
}
