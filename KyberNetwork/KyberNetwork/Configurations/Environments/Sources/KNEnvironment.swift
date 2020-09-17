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
    return KNAppTracker.externalEnvironment()
  }

  var isMainnet: Bool {
    return KNEnvironment.default == .mainnetTest || KNEnvironment.default == .production || KNEnvironment.default == .staging
  }

  var chainID: Int {
    return self.customRPC?.chainID ?? 0
  }

  var etherScanIOURLString: String {
    return self.knCustomRPC?.etherScanEndpoint ?? ""
  }

  var enjinXScanIOURLString: String {
    return self.knCustomRPC?.enjinScanEndpoint ?? ""
  }

  var customRPC: CustomRPC? {
    return self.knCustomRPC?.customRPC
  }

  var knCustomRPC: KNCustomRPC? {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: self.configFileName) else {
      return nil
    }
    return KNCustomRPC(dictionary: json)
  }

  var configFileName: String {
    switch self {
    case .mainnetTest: return "config_env_mainnet_test"
    case .production: return "config_env_production"
    case .staging: return "config_env_staging2"
    case .ropsten: return "config_env_ropsten"
    case .kovan: return "config_env_kovan"
    case .rinkeby: return "config_env_rinkeby"
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
