// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNEnvironment: Int {

  case mainnetTest = 0
  case production = 1
  case staging = 2
  case ropsten = 3
  case kovan = 4
  case rinkeby = 5

  var displayName: String {
    switch self {
    case .mainnetTest: return "Mainnet"
    case .production: return "Production"
    case .staging: return "Staging"
    case .ropsten: return "Ropsten"
    case .kovan: return "Kovan"
    case .rinkeby: return "Rinkeby"
    }
  }

  static func allEnvironments() -> [KNEnvironment] {
    return [
      KNEnvironment.mainnetTest,
      KNEnvironment.production,
      KNEnvironment.staging,
      KNEnvironment.ropsten,
      KNEnvironment.kovan,
      KNEnvironment.rinkeby,
    ]
  }

  static var `default`: KNEnvironment {
    return .ropsten
  }

  var isMainnet: Bool {
    return KNEnvironment.default == .mainnetTest || KNEnvironment.default == .production || KNEnvironment.default == .staging
  }

  var envPrefix: String {
    let chain = KNGeneralProvider.shared.isEthereum ? "eth" : "bsc"
    return chain + "-" + self.displayName + "-"
  }
  
  var ethRPC: CustomRPC {
    switch self {
    case .ropsten:
      return Constants.ethRoptenPRC
    case .staging:
      return Constants.ethStaggingPRC
    default:
      return Constants.ethMainnetPRC
    }
  }
  
  var bscRPC: CustomRPC {
    switch self {
    case .ropsten:
      return Constants.bscRoptenPRC
    default:
      return Constants.bscMainnetPRC
    }
  }

  var configFileName: String {
    switch self {
    case .mainnetTest: return "config_env_mainnet_test"
    case .production: return "config_env_production"
    case .staging: return "config_env_production"
    case .ropsten: return "config_env_ropsten"
    case .kovan: return "config_env_kovan"
    case .rinkeby: return "config_env_rinkeby"
    }
  }
  
  var notificationAppID: String {
    switch self {
    case .ropsten:
      return "96c1718d-c4a1-4ce7-8583-59d39cabeaee"
    case .staging:
      return "361e7815-4da2-41c9-ba0a-d35add5a58ef"
    case .production:
      return "0487532e-7b19-415b-91a1-2a285b0b8382"
    default:
      return ""
    }
  }

  var apiEtherScanEndpoint: String {
    switch self {
    case .mainnetTest: return "http://api.etherscan.io/"
    case .production: return "http://api.etherscan.io/"
    case .staging: return "http://api.etherscan.io/"
    case .ropsten: return "http://api-ropsten.etherscan.io/"
    case .kovan: return "http://api-kovan.etherscan.io/"
    case .rinkeby: return "https://api-rinkeby.etherscan.io/"
    }
  }
  
  var krystalEndpoint: String {
    switch self {
    case .production:
      return KNSecret.productionKrytalURL
    case .ropsten:
      return KNSecret.devKrytalURL
    case .staging:
      return KNSecret.staggingKrytalURL
    default:
      return ""
    }
  }

  var supportedTokenEndpoint: String {
    let baseString: String = {
      switch self {
      case .mainnetTest, .production: return "\(KNSecret.prodKyberSwapURL)/api/currencies"
      case .staging: return "\(KNSecret.stagingKyberSwapURL)/api/currencies"
      case .ropsten: return "\(KNSecret.devKyberSwapURL)/api/currencies"
      case .rinkeby: return KNSecret.rinkebyApiURL + KNSecret.currencies
      case .kovan: return KNSecret.kovanApiURL + KNSecret.currencies
      }
    }()
    return baseString
  }

  var kyberswapURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodKyberSwapURL
    case .ropsten, .rinkeby, .kovan: return KNSecret.devKyberSwapURL
    case .staging: return KNSecret.stagingKyberSwapURL
    }
  }

  var kyberAPIEnpoint: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.prodApiURL
    case .ropsten: return KNSecret.ropstenApiURL
    case .kovan: return KNSecret.kovanApiURL
    default: return KNSecret.devApiURL
    }
  }

  var krytalAPIEndPoint: String {
    return KNSecret.devKrytalURL
  }

  var oneSignAppID: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.oneSignalAppIDProd
    case .ropsten, .rinkeby, .kovan: return KNSecret.oneSignalAppIDDev
    case .staging: return KNSecret.oneSignalAppIDStaging
    }
  }

  var googleSignInClientID: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodGoogleClientID
    case .staging: return KNSecret.stagingGoolgeClientID
    case .ropsten, .rinkeby, .kovan: return KNSecret.devGoogleClientID
    }
  }

  var twitterConsumerID: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodTwitterConsumerID
    case .ropsten, .rinkeby, .kovan: return KNSecret.devTwitterConsumerID
    case .staging: return KNSecret.stagingTwitterConsumerID
    }
  }

  var twitterSecretKey: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodTwitterSecretKey
    case .staging: return KNSecret.stagingTwitterSecretKey
    case .ropsten, .rinkeby, .kovan: return KNSecret.devTwitterSecretKey
    }
  }

  var nodeEndpoint: String { return "" }

  var cachedRateURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return "\(KNSecret.prodCacheURL)/rate"
    case .ropsten, .rinkeby, .kovan: return "\(KNSecret.ropstenCacheURL)/rate"
    }
  }

  var cachedURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.prodCacheURL
    case .ropsten, .rinkeby, .kovan: return KNSecret.ropstenCacheURL
    }
  }

  var cachedSourceAmountRateURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.prodApiURL
    default: return KNSecret.ropstenApiURL
    }
  }

  var cachedUserCapURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodCacheUserCapURL
    case .staging: return KNSecret.stagingCacheCapURL
    default: return KNSecret.ropstenCacheCapURL
    }
  }

  var gasLimitEnpoint: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodApiURL
    case .staging: return KNSecret.stagingApiURL
    case .ropsten: return KNSecret.ropstenApiURL
    case .kovan: return KNSecret.kovanApiURL
    default: return KNSecret.ropstenApiURL
    }
  }

  var expectedRateEndpoint: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.prodApiURL
    case .staging: return KNSecret.stagingApiURL
    case .ropsten: return KNSecret.ropstenApiURL
    case .kovan: return KNSecret.kovanApiURL
    default: return KNSecret.devApiURL
    }
  }

  var kyberEndpointURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.mainnetKyberNodeURL
    default: return KNSecret.ropstenKyberNodeURL
    }
  }
}
