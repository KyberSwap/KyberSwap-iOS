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
  
  public static let gasTokenAddress = KNEnvironment.default == .ropsten ? "0x0000000000b3F879cb30FE243b4Dfee438691c04" : "0x0000000000004946c0e9F43F4Dee607b0eF1fA1c"
  
  public static let tokenStoreFileName = "token.data"
  public static let balanceStoreFileName = "-balance.data"
  public static let customBalanceStoreFileName = "-custom-balance.data"
  public static let favedTokenStoreFileName = "faved-token.data"
  public static let lendingBalanceStoreFileName = "-lending-balance.data"
  public static let lendingDistributionBalanceStoreFileName = "-lending-distribution-balance.data"
  public static let customTokenStoreFileName = "custom-token.data"
  public static let etherscanTokenTransactionsStoreFileName = "-etherscan-token-transaction.data"
  public static let etherscanInternalTransactionsStoreFileName = "-etherscan-internal-transaction.data"
  public static let etherscanTransactionsStoreFileName = "-etherscan-transaction.data"
  public static let customFilterOptionFileName = "custom-filter-option.data"
  public static let marketingAssetsStoreFileName = "marketing-assets.data"
  public static let referralOverviewStoreFileName = "-referral-overview.data"
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
}
