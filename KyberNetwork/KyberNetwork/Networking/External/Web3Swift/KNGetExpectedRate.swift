// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import BigInt
import TrustCore

struct KNGetExpectedRateEncode: Web3Request {
  typealias Response = String

  //swiftlint:disable line_length
  static let newABI = "{\"inputs\":[{\"internalType\":\"contract IERC20\",\"name\":\"src\",\"type\":\"address\"},{\"internalType\":\"contract IERC20\",\"name\":\"dest\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"srcQty\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"platformFeeBps\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"hint\",\"type\":\"bytes\"}],\"name\":\"getExpectedRateAfterFee\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"expectedRate\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}"
  static let oldABI = "{\"constant\":true,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"}, {\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"srcQty\",\"type\":\"uint256\"}],\"name\":\"getExpectedRate\",\"outputs\":[{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"}"

  let source: Address
  let dest: Address
  let amount: BigInt
  let hint: String

  var type: Web3RequestType {
    let platformBps: BigInt = BigInt(KNAppTracker.getPlatformFee(source: self.source, dest: self.dest))
    let hintEncode = self.hint.isEmpty ? self.hint.hexEncoded : self.hint
    let run: String = {
      return "web3.eth.abi.encodeFunctionCall(\(KNGetExpectedRateEncode.newABI), [\"\(source.description)\", \"\(dest.description)\", \"\(amount.hexEncoded)\", \"\(platformBps.hexEncoded)\", \"\(hintEncode)\"])"
    }()
    return .script(command: run)
  }
}

struct KNGetExpectedRateWithFeeDecode: Web3Request {
  typealias Response = String

    let data: String

    var type: Web3RequestType {
      let run = "web3.eth.abi.decodeParameter('uint', '\(data)')"
      return .script(command: run)
    }
}

struct KNGetExpectedRateDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameters([{\"name\":\"expectedRate\",\"type\":\"uint256\"}, {\"name\":\"slippageRate\",\"type\":\"uint256\"}], '\(data)')"
    return .script(command: run)
  }
}
