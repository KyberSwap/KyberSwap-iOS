// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct Constants {
    public static let keychainKeyPrefix = "com.kyberswap.ios"
    public static let transactionIsLost = "is_lost"
    public static let transactionIsCancel = "is_cancel"
    public static let isDoneShowQuickTutorialForBalanceView = "balance_tutorial_done"
    public static let isDoneShowQuickTutorialForSwapView = "swap_tutorial_done"
    public static let isDoneShowQuickTutorialForLimitOrderView = "lo_tutorial_done"
    public static let isDoneShowQuickTutorialForHistoryView = "history_tutorial_done"
    public static let kisShowQuickTutorialForLongPendingTx = "kisShowQuickTutorialForLongPendingTx"
    public static let klimitNumberOfTransactionInDB = 1000
    public static let animationDuration = 0.5
    public static let useGasTokenDataKey = "use_gas_token_data_key"
  
  public static let oneSignalAppID = KNEnvironment.default == .ropsten ? "361e7815-4da2-41c9-ba0a-d35add5a58ef" : "0487532e-7b19-415b-91a1-2a285b0b8382"
  public static let gasTokenAddress = KNEnvironment.default == .ropsten ? "0x0000000000b3F879cb30FE243b4Dfee438691c04" : "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c"

  public static let krystalProxyAddress = KNEnvironment.default == .ropsten ? "0x1e49809B423C1E45645E523804E77584414963E6" : "0xCf276A0A972C504b88224E92d047b3DaD6A4a426"
  public static let krystalProxyAddressBSC = "0x8565Fb7dfB5D36b2aA00086ffc920cfF20db4F2f"
  public static let tokenStoreFileName = "token.data"
  public static let balanceStoreFileName = "_balance.data"
  public static let customBalanceStoreFileName = "-custom-balance.data"
  public static let favedTokenStoreFileName = "faved_token.data"
  public static let lendingBalanceStoreFileName = "-lending-balance.data"
  public static let lendingDistributionBalanceStoreFileName = "-lending-distribution-balance.data"
  public static let customTokenStoreFileName = "custom-token.data"
  public static let etherscanTokenTransactionsStoreFileName = "-etherscan-token-transaction.data"
  public static let etherscanInternalTransactionsStoreFileName = "-etherscan-internal-transaction.data"
  public static let etherscanTransactionsStoreFileName = "-etherscan-transaction.data"
  public static let customFilterOptionFileName = "custom-filter-option.data"
  public static let marketingAssetsStoreFileName = "marketing-assets.data"
  public static let referralOverviewStoreFileName = "-referral-overview.data"
  public static let historyTransactionsStoreFileName = "-history-transaction.data"
  public static let notificationsStoreFileName = "notification.data"
  public static let loginTokenStoreFileName = "-login-token.data"
  public static let krytalHistoryStoreFileName = "-krytal-history.data"
  public static let coingeckoPricesStoreFileName = "coingecko-price.data"
  public static let acceptedTermKey = "accepted-terms-key"
  public static let lendingTokensStoreFileName = "lending-tokens.data"
  public static let platformWallet = KNEnvironment.default == .production ? "0x5250b8202AEBca35328E2c217C687E894d70Cd31" : "0x5250b8202AEBca35328E2c217C687E894d70Cd31"

  public static let ethMainnetPRC = CustomRPC(
    chainID: 1,
    name: "Mainnet",
    symbol: "Mainnet",
    endpoint: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://semi-node.kyber.network",
    endpointAlchemy: "https://eth-mainnet.alchemyapi.io/v2/" + KNSecret.alchemyKey,
    etherScanEndpoint: "https://etherscan.io/",
    ensAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
    wrappedAddress: "0x6172afc8c00c46e0d07ce3af203828198194620a",
    apiEtherscanEndpoint: "https://api.etherscan.io/"
  )
  
  public static let ethRoptenPRC = CustomRPC(
    chainID: 3,
    name: "Ropsten",
    symbol: "Ropsten",
    endpoint: "https://ropsten.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://semi-node.kyber.network",
    endpointAlchemy: "https://eth-ropsten.alchemyapi.io/v2/" + KNSecret.alchemyRopstenKey,
    etherScanEndpoint: "https://ropsten.etherscan.io/",
    ensAddress: "0x112234455c3a32fd11230c42e7bccd4a84e02010",
    wrappedAddress: "0x665d34f192f4940da4e859ff7768c0a80ed3ae10",
    apiEtherscanEndpoint: "https://api-ropsten.etherscan.io/"
  )
  
  public static let ethStaggingPRC = CustomRPC(
    chainID: 1,
    name: "Mainnet",
    symbol: "Mainnet",
    endpoint: "https://mainnet.infura.io/v3/" + KNSecret.infuraKey,
    endpointKyber: "https://semi-node.kyber.network",
    endpointAlchemy: "https://eth-mainnet.alchemyapi.io/v2/" + KNSecret.alchemyKey,
    etherScanEndpoint: "https://etherscan.io/",
    ensAddress: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e",
    wrappedAddress: "0x6172afc8c00c46e0d07ce3af203828198194620a",
    apiEtherscanEndpoint: "https://api.etherscan.io/"
  )
  
  public static let bscMainnetPRC = CustomRPC(
    chainID: 56,
    name: "MainnetBSC",
    symbol: "MainnetBSC",
    endpoint: "https://bsc-dataseed.binance.org/",
    endpointKyber: "https://bsc-dataseed1.defibit.io/",
    endpointAlchemy: "https://bsc-dataseed1.ninicoin.io/",
    etherScanEndpoint: "https://bscscan.com/",
    ensAddress: "",
    wrappedAddress: "0x465661625B3B96b102a49e07E2Eb31cC9F5cE58B",
    apiEtherscanEndpoint: "https://api.bscscan.com/"
  )
  
  public static let bscRoptenPRC = CustomRPC(
    chainID: 97,
    name: "RopstenBSC",
    symbol: "RopstenBSC",
    endpoint: "https://data-seed-prebsc-1-s1.binance.org:8545/",
    endpointKyber: "https://data-seed-prebsc-2-s1.binance.org:8545/",
    endpointAlchemy: "https://data-seed-prebsc-1-s2.binance.org:8545/",
    etherScanEndpoint: "https://testnet.bscscan.com/",
    ensAddress: "",
    wrappedAddress: "0x813718C50df497BC136d5d6dfc0E0aDA8AB0C93e",
    apiEtherscanEndpoint: "https://api-testnet.bscscan.com/"
  )
  
  public static let bnbAddress = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  public static let ethAddress = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
}
