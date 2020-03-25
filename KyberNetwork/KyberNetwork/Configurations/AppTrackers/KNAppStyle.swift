// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNAppStyleType: String {
  case `default` = "Default"
  case new = "New"

  static var current: KNAppStyleType {
    return KNAppTracker.getAppStyleType()
  }

  var mainBackgroundColor: UIColor {
    return UIColor(red: 246, green: 247, blue: 250)
  }

  var swapFlowHeaderColor: UIColor {
    return UIColor.Kyber.merigold
  }

  var walletFlowHeaderColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var profileFlowHeaderColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var landingBackgroundColor: UIColor {
    return self == .default ? UIColor.Kyber.lightSeaGreen : UIColor.Kyber.blueGreen
  }

  var landingWelcomeDetailTextColor: UIColor {
    return self == .default ? UIColor(red: 174, green: 241, blue: 237) : UIColor.white
  }

  var landingCreateWalletBackgroundColor: UIColor {
    return UIColor.clear
  }

  var landingCreateWalletTitleColor: UIColor {
    return UIColor.Kyber.white
  }

  var landingImportWalletBackgroundColor: UIColor {
    return UIColor.clear
  }

  var landingImmportWalletTitleColor: UIColor {
    return UIColor.white
  }

  var pinBackgroundColor: UIColor {
    return self.mainBackgroundColor
  }

  var pinDigitBackgroundColor: UIColor {
    return UIColor.white
  }

  var pinHighlightedColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var createWalletHeaderBackgroundColor: UIColor {
    return self.walletFlowHeaderColor
  }

  var createWalletBackgroundColor: UIColor {
    return self.mainBackgroundColor
  }

  var createWalletButtonEnabledColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var createWalletButtonDisabledColor: UIColor {
    return UIColor(red: 225, green: 228, blue: 235)
  }

  var importWalletBackgroundColor: UIColor {
    return self.mainBackgroundColor
  }

  var importWalletHeaderBackgroundColor: UIColor {
    return self.walletFlowHeaderColor
  }

  var importWalletTypeButtonBackgroundColor: UIColor {
    return UIColor.Kyber.grayChateau
  }

  var importWalletButtonDisabledColor: UIColor {
    return UIColor(red: 225, green: 228, blue: 235)
  }

  var importWalletButtonEnabledColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var balanceBackgroundColor: UIColor {
    return self.mainBackgroundColor
  }

  var balanceHeaderBackgroundColor: UIColor {
    return self == .default ? self.walletFlowHeaderColor : UIColor.Kyber.blueGreen
  }

  var balanceBuyButtonBackgroundColor: UIColor {
    return UIColor.Kyber.shamrock
  }

  var balanceSellButtonBackgroundColor: UIColor {
    return UIColor.Kyber.blueGreen
  }

  var balanceSendButtonBackgroundColor: UIColor {
    return UIColor.Kyber.merigold
  }

  var balancePercentIncreaseColor: UIColor {
    return UIColor.Kyber.shamrock
  }

  var balancePercentDecreaseColor: UIColor {
    return UIColor.Kyber.strawberry
  }

  var balanceActionButtonBackgroundColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  var chartHeaderBackgroundColor: UIColor {
    return self.walletFlowHeaderColor
  }

  var chartBackgroundColor: UIColor {
    return self.mainBackgroundColor
  }

  var sendHeaderBackgroundColor: UIColor {
    return self.walletFlowHeaderColor
  }

  var swapHeaderBackgroundColor: UIColor {
    return self.swapFlowHeaderColor
  }

  var swapActionButtonBackgroundColor: UIColor {
    return self.swapFlowHeaderColor
  }

  var gasPriceSelectedColor: UIColor {
    return UIColor.Kyber.shamrock
  }

  var minRateColor: UIColor {
    return UIColor.Kyber.shamrock
  }

  var minRateThumColor: UIColor {
    return UIColor.Kyber.lightSeaGreen
  }

  func buttonRadius() -> CGFloat {
    return 5.0
  }

  func buttonTitle(with name: String) -> String {
    return self == .default ? name : name.uppercased()
  }

  var importButtonColor: UIColor {
    return self == .default ? UIColor.Kyber.grayChateau : UIColor.Kyber.importRed
  }
}
