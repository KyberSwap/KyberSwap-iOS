// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNBalanceTokenTableViewCellDelegate: class {
  func balanceTokenTableViewCell(_ cell: KNBalanceTokenTableViewCell, updateFav token: TokenObject, isFav: Bool)
}

struct KNBalanceTokenTableViewCellModel {
  let token: TokenObject
  let trackerRate: KNTrackerRate?
  let balance: Balance?
  let currencyType: KWalletCurrencyType
  let index: Int
  let isBalanceShown: Bool
  let isFav: Bool
  let rate: BigInt?

  init(
    token: TokenObject,
    trackerRate: KNTrackerRate?,
    balance: Balance?,
    currencyType: KWalletCurrencyType,
    index: Int,
    isBalanceShown: Bool
    ) {
    self.token = token
    self.trackerRate = trackerRate
    self.balance = balance
    self.currencyType = currencyType
    self.index = index
    self.isBalanceShown = isBalanceShown
    self.isFav = KNAppTracker.isTokenFavourite(token.contract.lowercased())

    let _rate: BigInt? = {
      if currencyType == .usd {
        if let rate = trackerRate {
          return KNRate.rateUSD(from: rate).rate
        }
        return nil
      }
      if let rate = trackerRate {
        return KNRate.rateETH(from: rate).rate
      }
      return nil
    }()
    self.rate = _rate
  }

  var isTokenLabelHidden: Bool {
    if token.shouldShowAsNew { return false }
    return true
  }

  var tokenLabelString: String {
    if token.shouldShowAsNew {
      return NSLocalizedString("new", value: "New", comment: "").uppercased()
    }
    return ""
  }

  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? .white : UIColor(red: 248, green: 249, blue: 255)
  }

  var displaySymbolAndNameAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let symbolAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedStringKey.kern: 0.0,
    ]
    attributedString.append(NSAttributedString(string: String(self.token.symbol.prefix(8)), attributes: symbolAttributes))
    return attributedString
  }

  var displayRateString: String {
    if (self.rate == nil || self.rate?.isZero == true) && token.isSupported {
      return "Maintenance".toBeLocalised()
    }
    return self.rate?.displayRate(decimals: 18) ?? "----"
  }

  var displayRateColor: UIColor {
    if (self.rate == nil || self.rate?.isZero == true) && token.isSupported {
      return UIColor(red: 90, green: 94, blue: 103)
    }
    return UIColor(red: 29, green: 48, blue: 58)
  }

  var displayRateFont: UIFont {
    if (self.rate == nil || self.rate?.isZero == true) && token.isSupported {
      return UIFont.Kyber.bold(with: 12)
    }
    return UIFont.Kyber.medium(with: 16)
  }

  var displayAmountHoldingsText: String {
    if !self.isBalanceShown { return "******" }
    let value = self.balance?.value.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 6))
    if let val = value, let double = Double(val.removeGroupSeparator()), double == 0 { return "0" }
    return value ?? "---"
  }

  fileprivate var displayBalanceValue: String {
    return self.currencyType == .usd ? self.displayBalanceInUSD : self.displayBalanceInETH
  }

  fileprivate var displayBalanceInUSD: String {
    if let amount = self.balance?.value, let trackerRate = self.trackerRate {
      let rate = KNRate.rateUSD(from: trackerRate)
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 0, maxFractionDigits: 6)
      return "~\(value.prefix(11)) \(self.currencyType.rawValue)"
    }
    return "---"
  }

  fileprivate var displayBalanceInETH: String {
    if let amount = self.balance?.value, let trackerRate = self.trackerRate {
      let rate = KNRate.rateETH(from: trackerRate)
      let value = (amount * rate.rate / BigInt(10).power(self.token.decimals)).string(units: .ether, minFractionDigits: 0, maxFractionDigits: 9)
      return "~\(value.prefix(11)) \(self.currencyType.rawValue)"
    }
    return "---"
  }

  var colorChange24h: UIColor {
    guard let tracker = self.trackerRate else { return UIColor.Kyber.grayChateau }
    let change: Double = {
      if self.currencyType == .eth { return tracker.changeETH24h }
      return tracker.changeUSD24h
    }()
    if change == 0 { return UIColor.Kyber.grayChateau }
    if change > 0 { return UIColor.Kyber.shamrock }
    return UIColor.Kyber.strawberry
  }

  var change24hString: String {
    guard let tracker = self.trackerRate else { return "---" }
    let change: Double = {
      if self.currencyType == .eth { return tracker.changeETH24h }
      return tracker.changeUSD24h
    }()
    let string = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
    return "\(string)%"
  }

  var change24hImage: UIImage? {
    guard let tracker = self.trackerRate else { return nil }
    let change: Double = {
      if self.currencyType == .eth { return tracker.changeETH24h }
      return tracker.changeUSD24h
    }()
    if change == 0 { return nil }
    if change > 0 { return UIImage(named: "change_up") }
    return UIImage(named: "change_down")
  }
}

class KNBalanceTokenTableViewCell: UITableViewCell {

  static let kCellID: String = "KNBalanceTokenTableViewCell"
  static let kCellHeight: CGFloat = 64

  @IBOutlet weak var newTextLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var amountHoldingsLabel: UILabel!
  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var change24h: UIButton!
  @IBOutlet weak var favIcon: UIButton!

  private(set) var isFav: Bool = false
  private(set) var viewModel: KNBalanceTokenTableViewCellModel?
  weak var delegate: KNBalanceTokenTableViewCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
    self.iconImageView.image = nil
    self.symbolLabel.text = ""
    self.rateLabel.text = ""
    self.amountHoldingsLabel.text = ""
    self.newTextLabel.text = NSLocalizedString("new", value: "New", comment: "").uppercased()
    self.iconImageView.rounded(radius: self.iconImageView.frame.width / 2.0)
  }

  func updateCellView(with viewModel: KNBalanceTokenTableViewCellModel) {
    self.viewModel = viewModel
    self.newTextLabel.isHidden = viewModel.isTokenLabelHidden
    self.newTextLabel.text = viewModel.tokenLabelString
    self.iconImageView.setTokenImage(
      token: viewModel.token,
      size: self.iconImageView.frame.size
    )
    self.symbolLabel.attributedText = viewModel.displaySymbolAndNameAttributedString
    self.rateLabel.text = viewModel.displayRateString
    self.rateLabel.textColor = viewModel.displayRateColor
    self.rateLabel.font = viewModel.displayRateFont
    self.rateLabel.addLetterSpacing()
    self.amountHoldingsLabel.text = viewModel.displayAmountHoldingsText
    self.amountHoldingsLabel.addLetterSpacing()
    self.backgroundColor = viewModel.backgroundColor

    self.change24h.setTitleColor(
      viewModel.colorChange24h,
      for: .normal
    )
    self.change24h.setTitle(
      viewModel.change24hString,
      for: .normal
    )
    self.change24h.setImage(viewModel.change24hImage, for: .normal)
    self.isFav = viewModel.isFav
    let favImg = self.isFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favIcon.setImage(favImg, for: .normal)
    self.layoutIfNeeded()
  }

  @IBAction func favIconButtonPressed(_ sender: Any) {
    self.isFav = !self.isFav
    KNAppTracker.updateFavouriteToken(
      self.viewModel?.token.contract.lowercased() ?? "",
      add: self.isFav
    )
    let favImg = self.isFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favIcon.setImage(favImg, for: .normal)
    if let token = self.viewModel?.token {
      self.delegate?.balanceTokenTableViewCell(self, updateFav: token, isFav: self.isFav)
    }
  }
}
