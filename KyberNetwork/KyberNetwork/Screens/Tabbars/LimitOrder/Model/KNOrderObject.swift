// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

enum KNOrderState: Int {
  case open
  case inProgress
  case filled
  case cancelled
  case invalidated
  case unknown
}

class KNOrderObject: NSObject {

  var id: Int = -1
  var sourceToken: String = ""
  var destToken: String = ""
  var targetPrice: Double = 0.0
  var sourceAmount: Double = 0.0
  var fee: Double = 0.0
  var nonce: String = ""
  var sender: String = ""
  var sideTrade: String?
  var createdDate: TimeInterval = 0.0
  var filledDate: TimeInterval = 0.0
  var messages: String = ""
  var txHash: String?
  var actualDestAmount: Double = 0.0
  var stateValue: Int = KNOrderState.open.rawValue

  convenience init(
    id: Int = -1,
    from: String,
    to: String,
    amount: Double,
    price: Double,
    fee: Double,
    nonce: String,
    sender: String,
    sideTrade:String?,
    createdDate: TimeInterval = Date().timeIntervalSince1970,
    filledDate: TimeInterval = 0.0,
    messages: String,
    txHash: String?,
    stateValue: Int = KNOrderState.open.rawValue,
    actualDestAmount: Double = 0.0
    ) {
    self.init()
    self.id = id
    self.sourceToken = from
    self.destToken = to
    self.sourceAmount = amount
    self.targetPrice = price
    self.fee = fee
    self.nonce = nonce
    self.sender = sender
    self.sideTrade = sideTrade
    self.createdDate = createdDate
    self.filledDate = filledDate
    self.messages = messages
    self.txHash = txHash
    self.stateValue = stateValue
    self.actualDestAmount = actualDestAmount
  }

  convenience init(json: JSONDictionary) {
    self.init()
    self.id = json["id"] as? Int ?? -1
    self.sourceToken = json["src"] as? String ?? ""
    self.destToken = json["dst"] as? String ?? ""
    self.sourceAmount = json["src_amount"] as? Double ?? 0.0
    self.targetPrice = json["min_rate"] as? Double ?? 0.0
    self.fee = json["fee"] as? Double ?? 0.0
    self.fee += (json["transfer_fee"] as? Double ?? 0.0)
    self.sender = json["addr"] as? String ?? ""
    self.nonce = json["nonce"] as? String ?? ""
    self.stateValue = {
      let status = json["status"] as? String ?? ""
      if status == "open" { return 0 }
      if status == "in_progress" { return 1 }
      if status == "filled" { return 2 }
      if status == "cancelled" { return 3 }
      if status == "invalidated" { return 4 }
      return 5
    }()
    self.sideTrade = json["side_trade"] as? String
    self.createdDate = json["created_at"] as? Double ?? 0.0
    self.filledDate = json["updated_at"] as? Double ?? 0.0
    self.txHash = json["tx_hash"] as? String
    self.messages = {
      let msgs = json["messages"] as? [String] ?? []
      return msgs.joined(separator: ". ")
    }()
    self.actualDestAmount = json["receive"] as? Double ?? 0.0
  }

  convenience init(fields: [String], data: [Any]) {
    self.init()
    if let idx = fields.index(of: "id") {
      self.id = data[idx] as? Int ?? -1
    }
    if let idx = fields.index(of: "addr") {
      self.sender = data[idx] as? String ?? ""
    }
    if let idx = fields.index(of: "nonce") {
      self.nonce = data[idx] as? String ?? ""
    }
    if let idx = fields.index(of: "src") {
      self.sourceToken = data[idx] as? String ?? ""
    }
    if let idx = fields.index(of: "dst") {
      self.destToken = data[idx] as? String ?? ""
    }
    if let idx = fields.index(of: "src_amount") {
      self.sourceAmount = data[idx] as? Double ?? 0.0
    }
    if let idx = fields.index(of: "min_rate") {
      self.targetPrice = data[idx] as? Double ?? 0.0
    }
    if let idx = fields.index(of: "fee") {
      self.fee = data[idx] as? Double ?? 0.0
    }
    if let idx = fields.index(of: "transfer_fee") {
      self.fee += data[idx] as? Double ?? 0.0 // adding transfer fee
    }
    if let idx = fields.index(of: "status") {
      self.stateValue = {
        let status = data[idx] as? String ?? ""
        if status == "open" { return 0 }
        if status == "in_progress" { return 1 }
        if status == "filled" { return 2 }
        if status == "cancelled" { return 3 }
        if status == "invalidated" { return 4 }
        return 5
      }()
    }
    if let idx = fields.index(of: "side_trade") {
      self.sideTrade = data[idx] as? String
    }
    if let idx = fields.index(of: "msg") {
      self.messages = data[idx] as? String ?? ""
    }
    if let idx = fields.index(of: "tx_hash") {
      self.txHash = data[idx] as? String
    }
    if let idx = fields.index(of: "created_at") {
      self.createdDate = data[idx] as? Double ?? 0.0
    }
    if let idx = fields.index(of: "updated_at") {
      self.filledDate = data[idx] as? Double ?? 0.0
    }
    if let idx = fields.index(of: "receive") {
      self.actualDestAmount = data[idx] as? Double ?? 0.0
    }
  }

  var state: KNOrderState { return KNOrderState(rawValue: self.stateValue) ?? .open }

  var dateToDisplay: Date {
    if self.filledDate != 0.0 { return Date(timeIntervalSince1970: self.filledDate) }
    return Date(timeIntervalSince1970: self.createdDate)
  }

  var srcTokenSymbol: String {
    return self.sourceToken
  }

  var destTokenSymbol: String {
    return self.destToken
  }

  var extraAmount: Double {
    let actualSrc = self.sourceAmount * (1.0 - self.fee)
    return max(0.0, self.actualDestAmount - actualSrc * self.targetPrice)
  }

  func clone() -> KNOrderObject {
    return KNOrderObject(
      id: self.id,
      from: self.sourceToken,
      to: self.destToken,
      amount: self.sourceAmount,
      price: self.targetPrice,
      fee: self.fee,
      nonce: self.nonce,
      sender: self.sender,
      sideTrade: self.sideTrade,
      createdDate: self.createdDate,
      filledDate: self.filledDate,
      messages: self.messages,
      txHash: self.txHash,
      stateValue: self.stateValue,
      actualDestAmount: self.actualDestAmount
    )
  }
}
