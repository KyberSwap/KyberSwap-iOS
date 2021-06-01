// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import TrustKeystore
import TrustCore

enum TransferType {
    case ether(destination: Address?)
    case token(TokenObject)
}

extension TransferType {
    func symbol(server: RPCServer) -> String {
        switch self {
        case .ether:
            return server.symbol
        case .token(let token):
            return token.symbol
        }
    }

    func contract() -> Address {
        switch self {
        case .ether:
            return Address(string: TokensDataStore.etherToken(for: Config()).contract)!
        case .token(let token):
            return Address(string: token.contract)!
        }
    }

  func isETHTransfer() -> Bool {
    if case .ether = self { return true }
    return false
  }
}

extension TransferType {
  func tokenObject() -> TokenObject {
    switch self {
    case .ether:
      return KNGeneralProvider.shared.isEthereum ? KNSupportedTokenStorage.shared.ethToken : KNSupportedTokenStorage.shared.bnbToken
    case .token(let object):
      return object
    }
  }
}
