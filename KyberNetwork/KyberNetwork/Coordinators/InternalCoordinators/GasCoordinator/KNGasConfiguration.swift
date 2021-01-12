// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

public struct KNGasConfiguration {
  static let digixGasLimitDefault = BigInt(1_140_000)
  static let exchangeTokensGasLimitDefault = BigInt(1_140_000)
  static let exchangeETHTokenGasLimitDefault = BigInt(884_000)
  static let approveTokenGasLimitDefault = BigInt(160_000)
  static let transferTokenGasLimitDefault = BigInt(180_000)
  static let transferETHGasLimitDefault = BigInt(120_000)
  static let buytokenSaleByETHGasLimitDefault = BigInt(550_000)
  static let buyTokenSaleByTokenGasLimitDefault = BigInt(700_000)
  static let daiGasLimitDefault = BigInt(884_000)
  static let makerGasLimitDefault = BigInt(884_000)
  static let propyGasLimitDefault = BigInt(884_000)
  static let promotionTokenGasLimitDefault = BigInt(884_000)
  static let trueUSDTokenGasLimitDefault = BigInt(870_000)
  static let transferSpecialTokenGasLimitDefault = BigInt(400_000)

  static let gasPriceDefault: BigInt = EtherNumberFormatter.full.number(from: "50", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMin: BigInt = EtherNumberFormatter.full.number(from: "20", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMax: BigInt = EtherNumberFormatter.full.number(from: "150", units: UnitConfiguration.gasPriceUnit)!
  static let extraGasPromoWallet: BigInt = EtherNumberFormatter.full.number(from: "2", units: UnitConfiguration.gasPriceUnit)!

  static func specialGasLimitDefault(from: TokenObject, to: TokenObject) -> BigInt? {
    if from.isGasFixed == true || to.isGasFixed == true {
      return self.calculateDefaultGasLimit(from: from, to: to)
    }
    return nil
  }

  static func calculateDefaultGasLimit(from: TokenObject, to: TokenObject) -> BigInt {
    if from == to {
      // normal transfer
      if from.isETH { return transferETHGasLimitDefault }
      return calculateDefaultGasLimitTransfer(token: from)
    }
    let gasSrcToETH: BigInt = {
      if let gasLimit = from.gasLimitDefault { return gasLimit }
      if from.isETH { return BigInt(0) }
      if from.isDGX { return digixGasLimitDefault }
      if from.isDAI { return daiGasLimitDefault }
      if from.isMKR { return makerGasLimitDefault }
      if from.isPRO { return propyGasLimitDefault }
      if from.isPT { return promotionTokenGasLimitDefault }
      if from.isTUSD { return trueUSDTokenGasLimitDefault }
      return exchangeETHTokenGasLimitDefault
    }()
    let gasETHToDest: BigInt = {
      if let gasLimit = to.gasLimitDefault { return gasLimit }
      if to.isETH { return BigInt(0) }
      if to.isDGX { return digixGasLimitDefault }
      if to.isDAI { return daiGasLimitDefault }
      if to.isMKR { return makerGasLimitDefault }
      if to.isPRO { return propyGasLimitDefault }
      if to.isPT { return promotionTokenGasLimitDefault }
      if to.isTUSD { return trueUSDTokenGasLimitDefault }
      return exchangeETHTokenGasLimitDefault
    }()
    return gasSrcToETH + gasETHToDest
  }

  static func calculateDefaultGasLimitTransfer(token: TokenObject) -> BigInt {
    if token.isCOMP || token.isAAVE || token.isBZRX {
      return transferSpecialTokenGasLimitDefault
    }
    return token.isETH ? transferETHGasLimitDefault : transferTokenGasLimitDefault
  }
}
