// Copyright SIX DAY LLC. All rights reserved.

import BigInt

struct KNTransactionReceipt: Decodable {
  let id: String
  let index: String
  let blockHash: String
  let blockNumber: String
  let gasUsed: String
  let cumulativeGasUsed: String
  let contractAddress: String
  let logsData: String
  let logsBloom: String
  let status: String
}

extension KNTransactionReceipt {
  static func from(_ dictionary: JSONDictionary) -> KNTransactionReceipt? {
    let id = dictionary["transactionHash"] as? String ?? ""
    let index = dictionary["transactionIndex"] as? String ?? ""
    let blockHash = dictionary["blockHash"] as? String ?? ""
    let blockNumber = dictionary["blockNumber"] as? String ?? ""
    let cumulativeGasUsed = dictionary["cumulativeGasUsed"] as? String ?? ""
    let gasUsed = dictionary["gasUsed"] as? String ?? ""
    let contractAddress = dictionary["contractAddress"] as? String ?? ""
    let customRPC: KNCustomRPC = KNEnvironment.default.knCustomRPC!
    let logsData: String = {
      if let logs: [JSONDictionary] = dictionary["logs"] as? [JSONDictionary] {
        for log in logs {
          let address = log["address"] as? String ?? ""
          let topics = log["topics"] as? [String] ?? []
          let data = log["data"] as? String ?? ""
          if address.lowercased() == customRPC.networkAddress.lowercased(),
          topics.first == customRPC.tradeTopic {
            return data
          }
        }
      }
      return ""
    }()

    let logsBloom = dictionary["logsBloom"] as? String ?? ""
    let status = dictionary["status"] as? String ?? ""

    return KNTransactionReceipt(
      id: id,
      index: index.drop0x,
      blockHash: blockHash,
      blockNumber: BigInt(blockNumber.drop0x, radix: 16)?.description ?? "",
      gasUsed: BigInt(gasUsed.drop0x, radix: 16)?.fullString(units: .ether) ?? "",
      cumulativeGasUsed: BigInt(cumulativeGasUsed.drop0x, radix: 16)?.fullString(units: .ether) ?? "",
      contractAddress: contractAddress,
      logsData: logsData,
      logsBloom: logsBloom,
      status: status.drop0x
    )
  }
}

extension KNTransactionReceipt {

  func toTransaction(from transaction: KNTransaction, logsDict: JSONDictionary?) -> KNTransaction {
    if transaction.isInvalidated { return transaction }
    let localObjects: [LocalizedOperationObject] = {
      guard let json = logsDict else {
        if transaction.localizedOperations.isInvalidated { return [] }
        return Array(transaction.localizedOperations)
      }
      let (valueString, decimals): (String, Int) = {
        let value = BigInt(json["destAmount"] as? String ?? "") ?? BigInt(0)
        if let token = KNSupportedTokenStorage.shared.supportedTokens.first(where: { $0.contract == (json["dest"] as? String ?? "").lowercased() }) {
          return (value.fullString(decimals: token.decimals), token.decimals)
        }
        return (value.fullString(decimals: 18), 18)
      }()
      let localObject = LocalizedOperationObject(
        from: (json["src"] as? String ?? "").lowercased(),
        to: (json["dest"] as? String ?? "").lowercased(),
        contract: nil,
        type: "exchange",
        value: valueString,
        symbol: transaction.localizedOperations.first?.symbol,
        name: transaction.localizedOperations.first?.name,
        decimals: decimals
      )
      return [localObject]
    }()
    let newTransaction = KNTransaction(
      id: transaction.id,
      blockNumber: Int(self.blockNumber) ?? transaction.blockNumber,
      from: transaction.from,
      to: transaction.to,
      value: transaction.value,
      gas: transaction.gas,
      gasPrice: transaction.gasPrice,
      gasUsed: self.gasUsed,
      nonce: transaction.nonce,
      date: transaction.date,
      localizedOperations: localObjects,
      state: self.status == "1" ? .completed : .failed,
      type: transaction.type
    )
    return newTransaction
  }
}
