//
//  GetSymbol.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/16/21.
//

import Foundation
import TrustKeystore
import TrustCore

struct GetERC20SymbolEncode: Web3Request {
  typealias Response = String

  static let abi = "{\"constant\": true,\"inputs\": [],\"name\": \"symbol\",\"outputs\": [{\"name\": \"\",\"type\": \"string\"}],\"payable\": false,\"stateMutability\": \"view\",\"type\": \"function\"}"

  var type: Web3RequestType {
      let run = "web3.eth.abi.encodeFunctionCall(\(GetERC20SymbolEncode.abi),[])"
      return .script(command: run)
  }
}

struct GetERC20SymbolDecode: Web3Request {
  typealias Response = String
  
  let data: String
  
  var type: Web3RequestType {
    let run = "web3.eth.abi.decodeParameter('string', '\(data)')"
    return .script(command: run)
  }
}
