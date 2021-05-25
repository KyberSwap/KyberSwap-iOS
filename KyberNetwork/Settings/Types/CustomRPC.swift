// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct CustomRPC {
  let chainID: Int
  let name: String
  let symbol: String
  let endpoint: String
  let endpointKyber: String
  let endpointAlchemy: String
  let etherScanEndpoint: String
  let ensAddress: String
  let wrappedAddress: String
  let apiEtherscanEndpoint: String
}

extension CustomRPC: Equatable {
  public static func == (lhs: CustomRPC, rhs: CustomRPC) -> Bool {
    return
      lhs.chainID == rhs.chainID &&
      lhs.name == rhs.name &&
      lhs.symbol == rhs.symbol &&
      lhs.endpoint == rhs.symbol &&
      lhs.endpointKyber == rhs.endpointKyber &&
      lhs.endpointAlchemy == rhs.endpointAlchemy
  }
}
