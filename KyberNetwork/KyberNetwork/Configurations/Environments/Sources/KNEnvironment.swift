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

  static let internalBaseEndpoint: String = {
    return KNAppTracker.internalCachedEnpoint()
  }()

  static let internalTrackerEndpoint: String = {
    return KNAppTracker.internalTrackerEndpoint()
  }()

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
      case .mainnetTest, .production: return "https://kyberswap.com/api/currencies"
      case .staging: return "\(KNSecret.stagingProfileURL)/api/currencies"
      case .ropsten: return "\(KNSecret.debugProfileURL)/api/currencies"
      case .rinkeby: return KNSecret.rinkebyApiURL + KNSecret.currencies
      case .kovan: return KNSecret.kovanApiURL + KNSecret.currencies
      }
    }()
    return baseString
  }

  var profileURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.kyberswapProfileURL
    case .ropsten, .rinkeby, .kovan: return KNSecret.debugProfileURL
    case .staging: return KNSecret.stagingProfileURL
    }
  }

  var kyberAPIEnpoint: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.trackerURL
    case .ropsten, .rinkeby: return KNSecret.debugTrackerURL
    case .kovan: return KNSecret.kovanApiURL
    }
  }

  var oneSignAppID: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.oneSignalAppID
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
    case .mainnetTest, .production, .staging: return KNSecret.prodCachedRateURL
    case .ropsten, .rinkeby, .kovan: return KNSecret.devCachedRateURL
    }
  }

  var cachedSourceAmountRateURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production, .staging: return KNSecret.trackerURL
    default: return KNSecret.debugTrackerURL
    }
  }

  var cachedUserCapURL: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.userCapURL
    case .staging: return KNSecret.stagingCacheCapURL
    default: return KNSecret.ropstenCacheCapURL
    }
  }

  var gasLimitEnpoint: String {
    switch KNEnvironment.default {
    case .mainnetTest, .production: return KNSecret.trackerURL
    case .staging: return KNSecret.stagingTrackerURL
    case .kovan: return KNSecret.kovanApiURL
    default: return KNSecret.debugTrackerURL
    }
  }

  var expectedRateEndpoint: String {
    switch KNEnvironment.default {
    case .staging: return KNSecret.stagingProfileURL
    case .mainnetTest, .production: return "https://api.kyber.network"
    case .kovan: return KNSecret.kovanApiURL
    default: return KNSecret.defaultDevApiURL
    }
  }

  var isKatalyst: Bool {
    return self == .ropsten || self == .staging
  }
}
