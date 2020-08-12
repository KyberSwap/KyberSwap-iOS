// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct Constants {
    public static let keychainKeyPrefix = "com.kyberswap.ios"
    public static let transactionIsLost = "is_lost"
    public static let transactionIsCancel = "is_cancel"
    public static let isShowMigrationTutorial = "notify_migration"
    public static let isDoneShowQuickTutorialForBalanceView = "balance_tutorial_done"
    public static let isDoneShowQuickTutorialForSwapView = "swap_tutorial_done"
    public static let isDoneShowQuickTutorialForLimitOrderView = "lo_tutorial_done"
    public static let isDoneShowQuickTutorialForHistoryView = "history_tutorial_done"
    public static let kisShowQuickTutorialForLongPendingTx = "kisShowQuickTutorialForLongPendingTx"
    public static let klimitNumberOfTransactionInDB = 1000
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
}
