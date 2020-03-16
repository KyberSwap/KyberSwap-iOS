// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

public struct KNGasConfiguration {
  static let digixGasLimitDefault = BigInt(990_000)
  static let exchangeTokensGasLimitDefault = BigInt(990_000)
  static let exchangeETHTokenGasLimitDefault = BigInt(500_000)
  static let approveTokenGasLimitDefault = BigInt(160_000)
  static let transferTokenGasLimitDefault = BigInt(160_000)
  static let transferETHGasLimitDefault = BigInt(130_000)
  static let transferGasLimitDefault = BigInt(130_000)
  static let buytokenSaleByETHGasLimitDefault = BigInt(550_000)
  static let buyTokenSaleByTokenGasLimitDefault = BigInt(700_000)
  static let daiGasLimitDefault = BigInt(650_000)
  static let makerGasLimitDefault = BigInt(550_000)
  static let propyGasLimitDefault = BigInt(650_000)
  static let promotionTokenGasLimitDefault = BigInt(500_00)
  static let trueUSDTokenGasLimitDefault = BigInt(720_000)

  static let gasPriceDefault: BigInt = EtherNumberFormatter.full.number(from: "10", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMin: BigInt = EtherNumberFormatter.full.number(from: "5", units: UnitConfiguration.gasPriceUnit)!
  static let gasPriceMax: BigInt = EtherNumberFormatter.full.number(from: "200", units: UnitConfiguration.gasPriceUnit)!
  static let extraGasPromoWallet: BigInt = EtherNumberFormatter.full.number(from: "2", units: UnitConfiguration.gasPriceUnit)!

  static func specialGasLimitDefault(from: TokenObject, to: TokenObject) -> BigInt? {
    if from.extraData?.isGasFixed == true || to.extraData?.isGasFixed == true {
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
      if let gasLimit = from.extraData?.gasLimitDefault { return gasLimit }
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
      if let gasLimit = to.extraData?.gasLimitDefault { return gasLimit }
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
    let gasDefault: BigInt = {
      if let gasLimit = token.extraData?.gasLimitDefault { return gasLimit }
      if token.isETH { return transferETHGasLimitDefault }
      if token.isDGX { return digixGasLimitDefault }
      if token.isDAI { return daiGasLimitDefault }
      if token.isMKR { return makerGasLimitDefault }
      if token.isPRO { return propyGasLimitDefault }
      if token.isPT { return promotionTokenGasLimitDefault }
      if token.isTUSD { return trueUSDTokenGasLimitDefault }
      return transferTokenGasLimitDefault
    }()
    return gasDefault * BigInt(120) / BigInt(100)
  }
}
