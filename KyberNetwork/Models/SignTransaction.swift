// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import BigInt
import TrustCore
import TrustKeystore
import Result

public struct SignTransaction {
    let value: BigInt
    let account: Account
    let to: Address?
    let nonce: Int
    let data: Data
    let gasPrice: BigInt
    let gasLimit: BigInt
    let chainID: Int
}

extension SignTransaction {
  func toSignTransactionObject() -> SignTransactionObject {
    return SignTransactionObject(value: self.value.description, from: self.account.address.description, to: self.to?.description, nonce: self.nonce, data: self.data, gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, chainID: self.chainID)
  }
  
  func send(provider: KNExternalProvider, completion: @escaping (Result<String, AnyError>) -> Void) {
    provider.signTransactionData(from: self) { (result) in
      switch result {
      case .success((let signData, _)):
        KNGeneralProvider.shared.sendSignedTransactionData(signData) { (sendResult) in
          switch sendResult {
          case .success(let hash):
            provider.minTxCount += 1
            completion(.success(hash))
          case .failure(let sendError):
            completion(.failure(sendError))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
}

extension SignTransaction {
  func toTransaction(hash: String, fromAddr: String, type: TransactionType = .earn) -> Transaction {
    return Transaction(
      id: hash,
      blockNumber: 0,
      from: fromAddr,
      to: self.to?.description ?? "",
      value: self.value.description,
      gas: self.gasLimit.description,
      gasPrice: self.gasPrice.description,
      gasUsed: self.gasLimit.description,
      nonce: "\(self.nonce)",
      date: Date(),
      localizedOperations: [],
      state: .pending,
      type: type
    )
  }
}
