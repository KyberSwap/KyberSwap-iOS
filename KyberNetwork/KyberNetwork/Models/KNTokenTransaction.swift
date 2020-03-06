// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift
import TrustKeystore
import TrustCore

// "ETH, ERC20 Tokens Transfer Events" by Address
class KNTokenTransaction: Object {

  @objc dynamic var id: String = ""
  @objc dynamic var blockNumber: Int = 0
  @objc dynamic var date: Date = Date()
  @objc dynamic var nonce: String = ""
  @objc dynamic var blockHash: String = ""
  @objc dynamic var from: String = ""
  @objc dynamic var contractAddress: String = ""
  @objc dynamic var to: String = ""
  @objc dynamic var value: String = ""
  @objc dynamic var tokenName: String = ""
  @objc dynamic var tokenSymbol: String = ""
  @objc dynamic var tokenDecimal: String = ""
  @objc dynamic var transactionIndex: String = ""
  @objc dynamic var gas: String = ""
  @objc dynamic var gasPrice: String = ""
  @objc dynamic var gasUsed: String = ""
  @objc dynamic var cumulativeGasUsed: String = ""
  @objc dynamic var input: String = ""
  @objc dynamic var confirmations: String = ""
  @objc dynamic var compoundKey: String = ""

  convenience init(dictionary: JSONDictionary, addressToSymbol: [String: String]) {
    self.init()
    self.id = dictionary["hash"] as? String ?? ""
    let blockNumberString: String = dictionary["blockNumber"] as? String ?? ""
    self.blockNumber = Int(blockNumberString) ?? 0
    let timeStamp: String = dictionary["timeStamp"]  as? String ?? ""
    self.date = Date(timeIntervalSince1970: Double(timeStamp) ?? 0.0)
    self.nonce = dictionary["nonce"] as? String ?? ""
    self.blockHash = dictionary["blockHash"] as? String ?? ""
    self.from = dictionary["from"] as? String ?? ""
    self.contractAddress = dictionary["contractAddress"] as? String ?? ""
    self.to = dictionary["to"] as? String ?? ""
    self.value = dictionary["value"] as? String ?? ""
    self.tokenName = dictionary["tokenName"] as? String ?? ""
    self.tokenSymbol = addressToSymbol[self.contractAddress.lowercased()] ?? dictionary["tokenSymbol"] as? String ?? ""
    self.tokenDecimal = dictionary["tokenDecimal"] as? String ?? ""
    self.transactionIndex = dictionary["transactionIndex"] as? String ?? ""
    self.gas = dictionary["gas"] as? String ?? ""
    self.gasPrice = dictionary["gasPrice"] as? String ?? ""
    self.gasUsed = dictionary["gasUsed"] as? String ?? ""
    self.cumulativeGasUsed = dictionary["cumulativeGasUsed"] as? String ?? ""
    self.input = dictionary["input"] as? String ?? ""
    self.confirmations = dictionary["confirmations"] as? String ?? ""
    self.compoundKey = "\(id)\(from)\(to)\(tokenSymbol)"
  }

  convenience init(internalDict: JSONDictionary, eth: TokenObject) {
    self.init()
    self.id = internalDict["hash"] as? String ?? ""
    let blockNumberString: String = internalDict["blockNumber"] as? String ?? ""
    self.blockNumber = Int(blockNumberString) ?? 0
    let timeStamp: String = internalDict["timeStamp"]  as? String ?? ""
    self.date = Date(timeIntervalSince1970: Double(timeStamp) ?? 0.0)
    self.nonce = internalDict["nonce"] as? String ?? ""
    self.from = internalDict["from"] as? String ?? ""
    self.to = internalDict["to"] as? String ?? ""
    self.contractAddress = internalDict["contractAddress"] as? String ?? ""
    self.value = internalDict["value"] as? String ?? ""
    if contractAddress.isEmpty && self.value != "0" {
      // ETH Transfer
      self.contractAddress = eth.contract
      self.tokenName = eth.name
      self.tokenSymbol = eth.symbol
      self.tokenDecimal = "\(eth.decimals)"
      self.gas = internalDict["gas"] as? String ?? ""
      self.gasPrice = internalDict["gasPrice"] as? String ?? ""
      self.gasUsed = internalDict["gasUsed"] as? String ?? ""
      self.cumulativeGasUsed = internalDict["cumulativeGasUsed"] as? String ?? ""
      self.input = internalDict["input"] as? String ?? ""
      self.confirmations = internalDict["confirmations"] as? String ?? ""
      self.compoundKey = "\(id)\(from)\(to)\(tokenSymbol)"
    }
  }

  override static func primaryKey() -> String? {
    return "compoundKey"
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let object = object as? KNTokenTransaction else { return false }
    return object.compoundKey == self.compoundKey
  }
}

extension KNTokenTransaction {
  func getToken() -> TokenObject? {
    guard let _ = Address(string: self.contractAddress) else { return nil }
    return TokenObject(
      contract: self.contractAddress,
      name: self.tokenName,
      symbol: self.tokenSymbol,
      decimals: Int(self.tokenDecimal) ?? 18,
      value: "0",
      isCustom: false,
      isDisabled: false
    )
  }
}

extension KNTokenTransaction {
  func toTransaction(type: TransactionType = .normal) -> Transaction {
    let amountString: String = {
      let number = EtherNumberFormatter.full.number(from: self.value, decimals: 0)
      let decimals: Int = Int(self.tokenDecimal) ?? 18
      let amount: String = number?.string(decimals: decimals, minFractionDigits: 0, maxFractionDigits: decimals) ?? "0.0"
      return amount
    }()
    let localObject = LocalizedOperationObject(
      from: from,
      to: to,
      contract: contractAddress,
      type: "transfer",
      value: amountString,
      symbol: tokenSymbol,
      name: tokenName,
      decimals: Int(tokenDecimal) ?? 0
    )
    return Transaction(
      id: id,
      blockNumber: blockNumber,
      from: from,
      to: to,
      value: amountString,
      gas: gas,
      gasPrice: gasPrice,
      gasUsed: gasUsed,
      nonce: nonce,
      date: date,
      localizedOperations: [localObject],
      state: .completed,
      type: type
    )
  }
}
