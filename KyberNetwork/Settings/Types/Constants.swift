// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct Constants {
    public static let keychainKeyPrefix = "com.kyberswap.ios"
    public static let transactionIsLost = "is_lost"
    public static let transactionIsCancel = "is_cancel"
}

public struct UnitConfiguration {
    public static let gasPriceUnit: EthereumUnit = .gwei
    public static let gasFeeUnit: EthereumUnit = .ether
}
