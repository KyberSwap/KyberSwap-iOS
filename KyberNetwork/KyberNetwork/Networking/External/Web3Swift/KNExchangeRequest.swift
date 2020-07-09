// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Foundation
import BigInt
import TrustKeystore
import TrustCore

//swiftlint:disable line_length
struct KNExchangeRequestEncode: Web3Request {
  typealias Response = String

  static let newABI = "{\"inputs\":[{\"internalType\":\"contract IERC20\",\"name\":\"src\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"internalType\":\"contract IERC20\",\"name\":\"dest\",\"type\":\"address\"},{\"internalType\":\"address payable\",\"name\":\"destAddress\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"internalType\":\"address payable\",\"name\":\"platformWallet\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"platformFeeBps\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"hint\",\"type\":\"bytes\"}],\"name\":\"tradeWithHintAndFee\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"destAmount\",\"type\":\"uint256\"}],\"stateMutability\":\"payable\",\"type\":\"function\"}"
  static let oldABI = "{\"constant\":false,\"inputs\":[{\"name\":\"src\",\"type\":\"address\"},{\"name\":\"srcAmount\",\"type\":\"uint256\"},{\"name\":\"dest\",\"type\":\"address\"},{\"name\":\"destAddress\",\"type\":\"address\"},{\"name\":\"maxDestAmount\",\"type\":\"uint256\"},{\"name\":\"minConversionRate\",\"type\":\"uint256\"},{\"name\":\"walletId\",\"type\":\"address\"},{\"name\":\"hint\",\"type\":\"bytes\"}],\"name\":\"tradeWithHint\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":true,\"stateMutability\":\"payable\",\"type\":\"function\"}"

  let exchange: KNDraftExchangeTransaction
  let address: Address

  var type: Web3RequestType {
    let minRate: BigInt = {
      guard let minRate = exchange.minRate else { return BigInt(0) }
      return minRate * BigInt(10).power(18 - exchange.to.decimals)
    }()
    let platformWallet: String = "0x9a68f7330A3Fe9869FfAEe4c3cF3E6BBef1189Da"

    let destAddress: String = {
      if let destAddr = KNWalletPromoInfoStorage.shared.getDestWallet(from: address.description), let wallet = Address(string: destAddr) { return wallet.description }
      return address.description
    }()
    let run: String = {
      let hint = "".hexEncoded
      let platformFeeBps: BigInt = BigInt(KNAppTracker.getPlatformFee(source: self.exchange.from.addressObj, dest: self.exchange.to.addressObj))
      return "web3.eth.abi.encodeFunctionCall(\(KNExchangeRequestEncode.newABI), [\"\(exchange.from.address.description)\", \"\(exchange.amount.description)\", \"\(exchange.to.address.description)\", \"\(destAddress)\", \"\(exchange.maxDestAmount.description)\", \"\(minRate.description)\", \"\(platformWallet)\", \"\(platformFeeBps.description)\", \"\(hint)\"])"
    }()
    return .script(command: run)
  }
}

struct KNExchangeEventDataDecode: Web3Request {
  typealias Response = [String: String]

  let data: String

  var type: Web3RequestType {
    let run: String = {
      return "we3.eth.abi.decodeParameters([{\"indexed\":true,\"internalType\":\"address\",\"name\":\"trader\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"contract IERC20\",\"name\":\"src\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"contract IERC20\",\"name\":\"dest\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"destAddress\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"actualSrcAmount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"actualDestAmount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"platformWallet\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"platformFeeBps\",\"type\":\"uint256\"}], \"\(data)\")"
    }()
    return .script(command: run)
  }
}
