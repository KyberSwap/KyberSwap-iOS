// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit
import CryptoSwift

//swiftlint:disable file_length
class KNGeneralProvider {

  static let shared = KNGeneralProvider()

  lazy var web3Swift: Web3Swift = {
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpoint + KNEnvironment.default.nodeEndpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }()

  lazy var web3SwiftKyber: Web3Swift = {
    if let path = URL(string: KNEnvironment.default.kyberEndpointURL + KNEnvironment.default.nodeEndpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }()

  lazy var web3SwiftAlchemy: Web3Swift = {
    if let customRPC = KNEnvironment.default.customRPC, let path = URL(string: customRPC.endpointAlchemy + KNEnvironment.default.nodeEndpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }()

  lazy var networkAddress: Address = {
    return Address(string: KNEnvironment.default.knCustomRPC?.networkAddress ?? "")!
  }()

  lazy var limitOrderAddress: Address = {
    return Address(string: KNEnvironment.default.knCustomRPC?.limitOrderAddress ?? "")!
  }()

  lazy var wrapperAddress: Address = {
    return Address(string: KNEnvironment.default.knCustomRPC?.wrapperAddress ?? "")!
  }()

  init() { DispatchQueue.main.async { self.web3Swift.start() } }

  // MARK: Balance
  func getETHBalanace(for address: String, completion: @escaping (Result<Balance, AnyError>) -> Void) {
    DispatchQueue.global().async {
      let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(BalanceRequest(address: address)))
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let balance):
            completion(.success(balance))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func getEstimateGas(from: Address, to: Address, data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    DispatchQueue.global().async {
      let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(EstimateGasRequest(from: from, to: to, data: data)))
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let est):
            completion(.success(est))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func getGasPrice(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(GasPriceRequest()))
    Session.send(request) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let gasPrice):
          completion(.success(gasPrice))
        case .failure(let error):
          completion(.failure(AnyError(error)))
        }
      }
    }
  }

  func getTokenBalance(for address: Address, contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getTokenBalanceEncodeData(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: contract.description, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let balance):
                self.getTokenBalanceDecodeData(from: balance, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getMutipleERC20Balances(for address: Address, tokens: [Address], completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    let data = "0x6a385ae9"
      + "000000000000000000000000\(address.description.lowercased().drop0x)"
      + "0000000000000000000000000000000000000000000000000000000000000040"
    var tokenCount = BigInt(tokens.count).hexEncoded.drop0x
    tokenCount = [Character].init(repeating: "0", count: 64 - tokenCount.count) + tokenCount
    let tokenAddresses = tokens.map({ return "000000000000000000000000\($0.description.lowercased().drop0x)" }).joined(separator: "")
    let request = EtherServiceAlchemyRequest(
      batch: BatchFactory().create(CallRequest(to: self.wrapperAddress.description, data: "\(data)\(tokenCount)\(tokenAddresses)"))
    )
    DispatchQueue.global().async {
      Session.send(request) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            self.getMultipleERC20BalancesDecode(data: data, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  // MARK: Transaction count
  func getTransactionCount(for address: String, state: String = "latest", completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: address,
      state: state
    )))
    DispatchQueue.global().async {
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let count):
            completion(.success(count))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func getAllowance(for token: TokenObject, address: Address, networkAddress: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if token.isETH {
      // ETH no need to request for approval
      completion(.success(BigInt(2).power(255)))
      return
    }
    let tokenAddress: Address = Address(string: token.contract)!
    self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { [weak self] dataResult in
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: tokenAddress.description, data: data)
        let getAllowanceRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getAllowanceRequest) { [weak self] getAllowanceResult in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch getAllowanceResult {
              case .success(let data):
                self.getTokenAllowanceDecodeData(data, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", withKyber: Bool = false, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let source: Address = Address(string: from.contract)!
    let dest: Address = Address(string: to.contract)!
    self.getExpectedRateEncodeData(source: source, dest: dest, amount: amount, hint: hint) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: self.networkAddress.description, data: data)
        if withKyber {
          let getRateRequest = EtherServiceKyberRequest(batch: BatchFactory().create(callRequest))
          DispatchQueue.global().async {
            Session.send(getRateRequest) { [weak self] getRateResult in
              guard let `self` = self else { return }
              DispatchQueue.main.async {
                switch getRateResult {
                case .success(let rateData):
                  self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
                case .failure(let error):
                  completion(.failure(AnyError(error)))
                }
              }
            }
          }
        } else {
          let getRateRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
          DispatchQueue.global().async {
            Session.send(getRateRequest) { [weak self] getRateResult in
              guard let `self` = self else { return }
              DispatchQueue.main.async {
                switch getRateResult {
                case .success(let rateData):
                  self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
                case .failure(let error):
                  completion(.failure(AnyError(error)))
                }
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getResolverAddress(_ ensName: String, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    self.getResolverEncode(name: ensName) { result in
      switch result {
      case .success(let resp):
        let callRequest = CallRequest(
          to: KNEnvironment.default.knCustomRPC?.ensAddress ?? "",
          data: resp
        )
        let getResolverRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getResolverRequest) { getResolverResult in
            DispatchQueue.main.async {
              switch getResolverResult {
              case .success(let data):
                if data == "0x" {
                  completion(.success(nil))
                  return
                }
                let idx = data.index(data.endIndex, offsetBy: -40)
                let resolverAddress = String(data[idx...]).add0x
                completion(.success(Address(string: resolverAddress)))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getAddressFromResolver(_ ensName: String, resolverAddress: Address, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    self.getAddressFromResolverEncode(name: ensName) { result in
      switch result {
      case .success(let resp):
        let callRequest = CallRequest(
          to: resolverAddress.description,
          data: resp
        )
        let getResolverRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getResolverRequest) { getResolverResult in
            DispatchQueue.main.async {
              switch getResolverResult {
              case .success(let data):
                if data == "0x" {
                  completion(.success(nil))
                  return
                }
                let idx = data.index(data.endIndex, offsetBy: -40)
                let address = String(data[idx...]).add0x
                completion(.success(Address(string: address)))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getAddressByEnsName(_ name: String, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    KNGeneralProvider.shared.getResolverAddress(name) { result in
      switch result {
      case .success(let resolverAddr):
        guard let addr = resolverAddr else {
          completion(.success(nil))
          return
        }
        KNGeneralProvider.shared.getAddressFromResolver(name, resolverAddress: addr) { result2 in
          switch result2 {
          case .success(let finalAddr):
            completion(.success(finalAddr))
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func approve(token: TokenObject, value: BigInt = BigInt(2).power(256) - BigInt(1), account: Account, keystore: Keystore, currentNonce: Int, networkAddress: Address, gasPrice: BigInt, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    self.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, value: value, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    self.getTransactionCount(for: account.address.description) { result in
      switch result {
      case .success(let resp):
        txCount = max(resp, currentNonce)
      case .failure(let err):
        error = err
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }
      self.signTransactionData(
        forApproving: token,
        account: account,
        nonce: txCount,
        data: encodeData,
        keystore: keystore,
        gasPrice: gasPrice,
        completion: { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let signData):
            self.sendSignedTransactionData(signData, completion: { sendResult in
              switch sendResult {
              case .success:
                completion(.success(txCount + 1))
              case .failure(let error):
                completion(.failure(error))
              }
            })
          case .failure(let error):
            completion(.failure(error))
          }
        }
      )
    }
  }

  public func getUserCapInWei(for address: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getUserCapInWeiEncode(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let callReq = CallRequest(
          to: self.networkAddress.description,
          data: data
        )
        let ethService = EtherServiceAlchemyRequest(batch: BatchFactory().create(callReq))
        DispatchQueue.global(qos: .background).async {
          Session.send(ethService) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let resp):
                self.getUserCapInWeiDecode(from: resp, completion: { decodeResult in
                  switch decodeResult {
                  case .success(let value):
                    completion(.success(value))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func sendSignedTransactionData(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    var error: Error?
    var transactionID: String?
    var hasCompletionCalled: Bool = false
    let group = DispatchGroup()
    group.enter()
    self.sendRawTransactionWithInfura(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
      }
      group.leave()
    }
    group.enter()
    self.sendRawTransactionWithAlchemy(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
      }
      group.leave()
    }
    group.enter()
    self.sendRawTransactionWithKyber(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
      }
      group.leave()
    }
    group.notify(queue: .main) {
      if let id = transactionID {
        if !hasCompletionCalled { completion(.success(id)) }
      } else if let err = error {
        completion(.failure(AnyError(err)))
      }
    }
  }

  private func sendRawTransactionWithInfura(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func sendRawTransactionWithAlchemy(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceAlchemyRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func sendRawTransactionWithKyber(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceKyberRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Sign transaction
extension KNGeneralProvider {
  private func signTransactionData(forApproving token: TokenObject, account: Account, nonce: Int, data: Data, keystore: Keystore, gasPrice: BigInt, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let gasLimit: BigInt = {
      if let gasApprove = token.gasApproveDefault { return gasApprove }
      return KNGasConfiguration.approveTokenGasLimitDefault
    }()
    let signTransaction = SignTransaction(
      value: BigInt(0),
      account: account,
      to: Address(string: token.contract),
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNEnvironment.default.chainID
    )
    let signResult = keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }
}

// MARK: Web3Swift Encoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceEncodeData(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20BalanceEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getSendApproveERC20TokenEncodeData(networkAddress: Address, value: BigInt = BigInt(2).power(256) - BigInt(1), completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = ApproveERC20Encode(
      address: networkAddress,
      value: value
    )
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceEncodeData(for address: Address, networkAddress: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetTokenAllowanceEndcode(
      ownerAddress: address,
      spenderAddress: networkAddress
    )
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getExpectedRateEncodeData(source: Address, dest: Address, amount: BigInt, hint: String = "", completion: @escaping (Result<String, AnyError>) -> Void) {
    let encodeRequest = KNGetExpectedRateEncode(source: source, dest: dest, amount: amount, hint: hint)
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getUserCapInWeiEncode(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetUserCapInWeiEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getResolverEncode(name: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetResolverRequest(nameHash: self.nameHash(name: name))
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getAddressFromResolverEncode(name: String, completion: @escaping (Result<String, AnyError>) -> Void) {
     let request = KNGetAddressFromResolverRequest(nameHash: self.nameHash(name: name))
     self.web3Swift.request(request: request) { result in
       switch result {
       case .success(let data):
         completion(.success(data))
       case .failure(let error):
         completion(.failure(AnyError(error)))
       }
     }
   }

  fileprivate func nameHash(name: String) -> String {
    var node = Data.init(count: 32)
    let labels = name.components(separatedBy: ".")
    for label in labels.reversed() {
      let data = Data(bytes: SHA3(variant: .keccak256).calculate(for: label.bytes))
      node.append(data)
      node = Data(bytes: SHA3(variant: .keccak256).calculate(for: node.bytes))
    }
    return node.hexEncoded
  }

  fileprivate func getMutipleERC20BalancesEncode(from address: Address, tokens: [Address], completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetMultipleERC20BalancesEncode(address: address, tokens: tokens)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Web3Swift Decoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let request = GetERC20BalanceDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if data == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let decodeRequest = KNGetTokenAllowanceDecode(data: data)
    self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(remain))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getExpectedRateDecodeData(rateData: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let decodeRequest = KNGetExpectedRateWithFeeDecode(data: rateData)
    self.web3Swift.request(request: decodeRequest, completion: { (result) in
      switch result {
      case .success(let expectedRateData):
        let expectedRate: BigInt = BigInt(expectedRateData) ?? BigInt(0)
        let slippageRate: BigInt = expectedRate * BigInt(97) / BigInt(100)
        completion(.success((expectedRate, slippageRate)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getUserCapInWeiDecode(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let request = KNGetUserCapInWeiDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt(0)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  fileprivate func getMultipleERC20BalancesDecode(data: String, completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    let request = GetMultipleERC20BalancesDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        let res = data.map({ val -> BigInt in
          if val == "0x" { return BigInt(0) }
          return BigInt(val) ?? BigInt(0)
        })
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}
