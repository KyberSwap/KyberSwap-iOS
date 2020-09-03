// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNSelectedGasPriceType: Int {
  case fast = 0
  case medium = 1
  case slow = 2
  case superFast = 3
  case custom
}

extension KNSelectedGasPriceType {
  func displayString() -> String {
    switch self {
    case .fast:
      return "fast"
    case .medium:
      return "regular"
    case .slow:
      return "slow"
    case .superFast:
      return "super fast"
    case .custom:
      return "custom"
    }
  }
}

enum KAdvancedSettingsViewEvent {
  case infoPressed
  case displayButtonPressed
  case gasPriceChanged(type: KNSelectedGasPriceType, value: BigInt)
  case minRatePercentageChanged(percent: CGFloat)
  case helpPressed
  case changeIsUsingReverseRouting(value: Bool)
  case reverseRoutingHelpPress
}

enum KAdvancedSettingsMinRateType {
  case threePercent
  case anyRate
  case custom(value: Double)
}

protocol KAdvancedSettingsViewDelegate: class {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent)
}

class KAdvancedSettingsViewModel: NSObject {

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()

  private let kGasPriceContainerHeight: CGFloat = 80.0
  private let kMinRateContainerHeight: CGFloat = 140.0
  private let kAdvancedSettingsHasMinRateHeight: CGFloat = 328.0
  private let kAdvancedSettingsNoMinRateHeight: CGFloat = 186.0

  fileprivate(set) var fast: BigInt = KNGasCoordinator.shared.fastKNGas
  fileprivate(set) var medium: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var slow: BigInt = KNGasCoordinator.shared.lowKNGas
  fileprivate(set) var superFast: BigInt = KNGasCoordinator.shared.superFastKNGas

  fileprivate(set) var selectedType: KNSelectedGasPriceType = .medium

  fileprivate(set) var isViewHidden: Bool = true
  fileprivate(set) var hasMinRate: Bool = true

  fileprivate(set) var minRateType: KAdvancedSettingsMinRateType = .threePercent
  fileprivate(set) var currentRate: Double = 0.0

  fileprivate(set) var pairToken: String = ""
  fileprivate(set) var isPromoWallet: Bool = false
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var isUsingReverseRouting: Bool = true
  fileprivate(set) var isAbleToUseReverseRouting: Bool = false

  init(hasMinRate: Bool, isPromo: Bool, gasLimit: BigInt) {
    self.hasMinRate = hasMinRate
    self.isPromoWallet = isPromo
    self.gasLimit = gasLimit
  }

  var advancedSettingsHeight: CGFloat {
    if self.isViewHidden { return 0.0 }
    let reverseRoutingSpace: CGFloat = self.isAbleToUseReverseRouting ? 46.0 : 0.0
    return self.hasMinRate ? kAdvancedSettingsHasMinRateHeight + reverseRoutingSpace : kAdvancedSettingsNoMinRateHeight + reverseRoutingSpace
  }

  var isGasPriceViewHidden: Bool { return self.isViewHidden }
  var gasPriceViewHeight: CGFloat { return self.isGasPriceViewHidden ? 0 : kGasPriceContainerHeight }

  var fastGasString: NSAttributedString {
    return self.attributedString(
      for: self.fast,
      text: NSLocalizedString("fast", value: "Fast", comment: "").uppercased()
    )
  }
  var mediumGasString: NSAttributedString {
    return self.attributedString(
      for: self.medium,
      text: NSLocalizedString("regular", value: "Regular", comment: "").uppercased()
    )
  }
  var slowGasString: NSAttributedString {
    return self.attributedString(
      for: self.slow,
      text: NSLocalizedString("slow", value: "Slow", comment: "").uppercased()
    )
  }
  var superFastGasString: NSAttributedString {
    return self.attributedString(
      for: self.superFast,
      text: NSLocalizedString("super.fast", value: "Super Fast", comment: "").uppercased()
    )
  }

  func attributedString(for gasPrice: BigInt, text: String) -> NSAttributedString {
    let gasPriceString: String = gasPrice.string(units: .gwei, minFractionDigits: 2, maxFractionDigits: 2)
    let gasPriceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let feeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: gasPriceString, attributes: gasPriceAttributes))
    attributedString.append(NSAttributedString(string: " \(text)", attributes: feeAttributes))
    return attributedString
  }

  var isMinRateViewHidden: Bool { return !self.hasMinRate || self.isViewHidden }
  var minRateViewHeight: CGFloat { return self.isMinRateViewHidden ? 0 : kMinRateContainerHeight }
  var minRateTypeInt: Int {
    switch self.minRateType {
    case .threePercent: return 0
    case .anyRate: return 1
    case .custom: return 2
    }
  }

  var minRatePercent: Double {
    switch self.minRateType {
    case .threePercent: return 3.0
    case .anyRate: return 100.0
    case .custom(let value): return value
    }
  }

  var minRateDisplay: String {
    let minRate = self.currentRate * (100.0 - self.minRatePercent) / 100.0
    return self.numberFormatter.string(from: NSNumber(value: minRate))?.displayRate() ?? "0"
  }

  var currentRateDisplay: String {
    return self.numberFormatter.string(from: NSNumber(value: self.currentRate))?.displayRate() ?? "0"
  }

  var estimateFeeSuperFastString: String {
    return self.formatFeeStringFor(gasPrice: self.superFast)
  }

  var estimateFeeFastString: String {
    return self.formatFeeStringFor(gasPrice: self.fast)
  }

  var estimateRegularFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.medium)
  }

  var estimateSlowFeeString: String {
    return self.formatFeeStringFor(gasPrice: self.slow)
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    return "~ \(feeString) ETH"
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    if self.isPromoWallet {
      let extraGas = KNGasConfiguration.extraGasPromoWallet
      self.fast = fast + extraGas
      self.medium = medium
      self.slow = slow
      self.superFast = superFast
    } else {
      self.fast = fast
      self.medium = medium
      self.slow = slow
      self.superFast = superFast
    }
  }

  func updateSelectedType(_ type: KNSelectedGasPriceType) {
    self.selectedType = type
  }

  func updatePairToken(_ value: String) {
    self.pairToken = value
  }

  func updateViewHidden(isHidden: Bool) { self.isViewHidden = isHidden }

  func updateMinRateType(_ type: KAdvancedSettingsMinRateType) {
    self.minRateType = type
  }

  func updateMinRateValue(_ value: Double, percent: Double) {
    self.currentRate = value
    if self.minRateTypeInt == 2 {
      self.minRateType = .custom(value: percent)
    }
  }

  func updateIsPromoWallet(_ isPromo: Bool) {
    self.isPromoWallet = isPromo
    self.updateSelectedType(.fast)
    self.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
  }

  func updateHasMinRate(hasMinRate: Bool) { self.hasMinRate = hasMinRate }

  var totalHeight: CGFloat {
    return 64.0 + self.advancedSettingsHeight
  }

  func updateGasLimit(value: BigInt) {
    self.gasLimit = value
  }

  func updateIsUsingReverseRouting(value: Bool) {
    self.isUsingReverseRouting = value
  }

  func updateIsAbleToUseReverseRouting(value: Bool) {
    self.isAbleToUseReverseRouting = value
  }
}

class KAdvancedSettingsView: XibLoaderView {

  @IBOutlet weak var displayViewButton: UIButton!

  @IBOutlet weak var advancedSettingsViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var advancedContainerView: UIView!

  @IBOutlet weak var gasPriceContainerView: UIView!
  @IBOutlet weak var gasFeeGweiTextLabel: UILabel!

  @IBOutlet weak var superFastGasButton: UIButton!
  @IBOutlet weak var superFastGasValueLabel: UILabel!

  @IBOutlet weak var fasGasValueLabel: UILabel!
  @IBOutlet weak var fasGasButton: UIButton!

  @IBOutlet weak var mediumGasValueLabel: UILabel!
  @IBOutlet weak var mediumGasButton: UIButton!

  @IBOutlet weak var slowGasValueLabel: UILabel!
  @IBOutlet weak var slowGasButton: UIButton!

  @IBOutlet weak var minRateContainerView: UIView!

  @IBOutlet weak var threePercentButton: UIButton!
  @IBOutlet weak var customButton: UIButton!

  @IBOutlet weak var threePercentTextLabel: UILabel!
  @IBOutlet weak var customTextLabel: UILabel!
  @IBOutlet weak var customRateTextField: UITextField!
  @IBOutlet weak var stillProceedIfRateGoesDownTextLabel: UILabel!
  @IBOutlet weak var transactionWillBeRevertedTextLabel: UILabel!
  @IBOutlet weak var superFastEstimateFeeLabel: UILabel!
  @IBOutlet weak var fastEstimateFeeLabel: UILabel!
  @IBOutlet weak var regularEstimateFeeLabel: UILabel!
  @IBOutlet weak var slowEstimateFeeLabel: UILabel!
  @IBOutlet weak var estimateFeeNoteLabel: UILabel!
  @IBOutlet weak var reserseRoutingCheckBoxContainer: UIView!
  @IBOutlet weak var enableReverseRoutingButton: UIButton!
  @IBOutlet weak var reverseRoutingInfoLabel: UILabel!

  fileprivate var isPromo: Bool = false
  fileprivate(set) var viewModel: KAdvancedSettingsViewModel!
  weak var delegate: KAdvancedSettingsViewDelegate?

  var isMinRateValid: Bool {
    if case .threePercent = self.viewModel.minRateType { return true }
    let custom = self.customRateTextField.text ?? ""
    return !custom.isEmpty
  }

  var height: CGFloat {
    if self.viewModel == nil { return 64.0 }
    return self.viewModel.totalHeight
  }

  var isExpanded: Bool { return !self.viewModel.isViewHidden }

  override func commonInit() {
    super.commonInit()
    self.displayViewButton.setTitle(
      NSLocalizedString("advanced.optional", value: "Advanced (optional)", comment: ""),
      for: .normal
    )
    self.estimateFeeNoteLabel.text = "Select higher gas price to accelerate your transaction processing time".toBeLocalised()
    self.gasFeeGweiTextLabel.text = NSLocalizedString("gas.fee.gwei", value: "GAS fee (Gwei)", comment: "")
    self.reverseRoutingInfoLabel.text = "Use reserve routing to enjoy gas savings".toBeLocalised()
    self.customRateTextField.delegate = self
    self.advancedContainerView.rounded(radius: 5.0)
    self.superFastGasButton.backgroundColor = .white
    self.fasGasButton.backgroundColor = .white
    self.mediumGasButton.backgroundColor = .white
    self.slowGasButton.backgroundColor = .white
    self.threePercentButton.backgroundColor = .white
    self.customButton.backgroundColor = .white

    let tapThreePercent = UITapGestureRecognizer(target: self, action: #selector(self.userTappedThreePercent(_:)))
    self.threePercentTextLabel.addGestureRecognizer(tapThreePercent)

    let tapCustom = UITapGestureRecognizer(target: self, action: #selector(self.userTappedCustomRate(_:)))
    self.customTextLabel.addGestureRecognizer(tapCustom)
  }

  func updateViewModel(_ viewModel: KAdvancedSettingsViewModel) {
    self.viewModel = viewModel
    self.viewModel.updateIsPromoWallet(isPromo)
    self.advancedSettingsViewHeightConstraint.constant = self.viewModel.advancedSettingsHeight
    self.advancedContainerView.isHidden = self.viewModel.isViewHidden
    self.updateGasPriceUIs()
    self.updateMinRateUIs()
  }

  func updateMinRateCustomErrorShown(_ isShown: Bool) {
    let borderColor = isShown ? UIColor.Kyber.strawberry : UIColor.Kyber.border
    self.customRateTextField.rounded(color: borderColor, width: 1.0, radius: 2.5)
  }

  fileprivate func updateGasPriceUIs() {
    if self.viewModel == nil { return }
    self.gasPriceContainerView.isHidden = self.viewModel.isGasPriceViewHidden

    self.superFastGasValueLabel.attributedText = self.viewModel.superFastGasString
    self.fasGasValueLabel.attributedText = self.viewModel.fastGasString
    self.mediumGasValueLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasValueLabel.attributedText = self.viewModel.slowGasString

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasButton.rounded(
      color: self.viewModel.selectedType == .superFast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.fasGasButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fasGasButton.frame.height / 2.0
    )

    self.mediumGasButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.mediumGasButton.frame.height / 2.0
    )

    self.slowGasButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasButton.frame.height / 2.0
    )

    self.updateConstraintsIfNeeded()
    self.layoutIfNeeded()
  }

  fileprivate func updateMinRateUIs() {
    if self.viewModel == nil { return }
    self.minRateContainerView.isHidden = self.viewModel.isMinRateViewHidden
    if self.minRateContainerView.isHidden { return }

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.threePercentButton.rounded(
      color: self.viewModel.minRateTypeInt == 0  ? selectedColor : normalColor,
      width: self.viewModel.minRateTypeInt == 0 ? selectedWidth : normalWidth,
      radius: self.threePercentButton.frame.height / 2.0
    )

    self.customButton.rounded(
      color: self.viewModel.minRateTypeInt == 2 ? selectedColor : normalColor,
      width: self.viewModel.minRateTypeInt == 2 ? selectedWidth : normalWidth,
      radius: self.customButton.frame.height / 2.0
    )

    self.customRateTextField.isEnabled = self.viewModel.minRateTypeInt == 2

    self.stillProceedIfRateGoesDownTextLabel.text = String(
      format: NSLocalizedString("still.proceed.if.rate.goes.down.by", value: "Still proceed if %@ goes down by:", comment: ""),
      self.viewModel.pairToken
    )
    self.transactionWillBeRevertedTextLabel.text = String(
      format: NSLocalizedString("transaction.will.be.reverted.if.rate.lower.than", value: "Transaction will be reverted if rate of %@ is lower than %@ (Current rate %@)", comment: ""),
      arguments: [self.viewModel.pairToken, self.viewModel.minRateDisplay, self.viewModel.currentRateDisplay]
    )
    self.updateMinRateCustomErrorShown(!self.isMinRateValid)
    self.updateConstraints()
    self.layoutSubviews()
  }

  fileprivate func updateIsUsingReverseRoutingCheckBox() {
    self.enableReverseRoutingButton.rounded(
      color: self.viewModel.isUsingReverseRouting ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.enableReverseRoutingButton.setImage(
      self.viewModel.isUsingReverseRouting ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
  }

  func updateIsUsingReverseRoutingStatus(value: Bool) {
    guard self.viewModel != nil else { return }
    self.viewModel.updateIsUsingReverseRouting(value: value)
    self.updateIsUsingReverseRoutingCheckBox()
  }

  func updatePairToken(_ value: String) {
    if self.viewModel == nil { return }
    self.viewModel.updatePairToken(value)
    self.updateGasPriceUIs()
  }

  func updateGasPrices(fast: BigInt, medium: BigInt, slow: BigInt, superFast: BigInt) {
    if self.viewModel == nil { return }
    self.viewModel.updateGasPrices(fast: fast, medium: medium, slow: slow, superFast: superFast)
    let gasPrice: BigInt = {
      switch self.viewModel.selectedType {
      case .fast: return self.viewModel.fast
      case .medium: return self.viewModel.medium
      case .slow: return self.viewModel.slow
      case .superFast: return self.viewModel.superFast
      default: return BigInt(0)
      }
    }()
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: self.viewModel.selectedType, value: gasPrice))
    self.updateGasPriceUIs()
  }

  func updateHasMinRate(_ hasMinRate: Bool) {
    if self.viewModel == nil { return }
    self.viewModel.updateHasMinRate(hasMinRate: hasMinRate)
    self.updateMinRateUIs()
  }

  func updateMinRate(_ value: Double, percent: Double) {
    if self.viewModel == nil { return }
    self.viewModel.updateMinRateValue(value, percent: percent)
    self.updateMinRateUIs()
  }

  func updateIsPromoWallet(_ isPromo: Bool) {
    self.isPromo = isPromo
    if self.viewModel == nil { return }
    self.viewModel.updateIsPromoWallet(isPromo)
    self.updateGasPriceUIs()
  }

  func updateGasLimit(_ value: BigInt) {
    self.viewModel.updateGasLimit(value: value)
    self.superFastEstimateFeeLabel.text = self.viewModel.estimateFeeSuperFastString
    self.fastEstimateFeeLabel.text = self.viewModel.estimateFeeFastString
    self.regularEstimateFeeLabel.text = self.viewModel.estimateRegularFeeString
    self.slowEstimateFeeLabel.text = self.viewModel.estimateSlowFeeString
  }

  func updateIsAbleToUseReverseRouting(value: Bool) -> Bool {
    guard value != self.viewModel.isAbleToUseReverseRouting else { return false }
    self.viewModel.updateIsAbleToUseReverseRouting(value: value)
    self.reserseRoutingCheckBoxContainer.isHidden = !self.viewModel.isAbleToUseReverseRouting
    return true
  }

  @IBAction func displayViewButtonPressed(_ sender: Any) {
    if self.viewModel == nil { return }
    let isHidden = !self.viewModel.isViewHidden
    KNCrashlyticsUtil.logCustomEvent(withName: isHidden ? "advanced_display_show" : "advanced_display_hide", customAttributes: nil)
    self.viewModel.updateViewHidden(isHidden: isHidden)

    self.advancedSettingsViewHeightConstraint.constant = self.viewModel.advancedSettingsHeight
    self.advancedContainerView.isHidden = self.viewModel.isViewHidden

    self.updateGasPriceUIs()
    self.updateMinRateUIs()
    self.delegate?.kAdvancedSettingsView(self, run: .displayButtonPressed)
  }

  @IBAction func superFastGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.superFast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .superFast, value: self.viewModel.superFast))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_super_fast", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func fastGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast, value: self.viewModel.fast))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_fast", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func mediumGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium, value: self.viewModel.medium))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_regular", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func slowGasButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow, value: self.viewModel.slow))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_slow", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func userTappedSuperFastFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.superFast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .superFast, value: self.viewModel.superFast))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_super_fast", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func userTappedFastFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.fast)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .fast, value: self.viewModel.fast))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_fast", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func userTappedMediumFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.medium)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .medium, value: self.viewModel.medium))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_regular", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func userTappedSlowFee(_ sender: Any) {
    self.viewModel.updateSelectedType(.slow)
    self.delegate?.kAdvancedSettingsView(self, run: .gasPriceChanged(type: .slow, value: self.viewModel.slow))
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_select_gas_slow", customAttributes: nil)
    self.updateGasPriceUIs()
  }

  @IBAction func threePercentButtonPressed(_ sender: Any) {
    self.viewModel.updateMinRateType(.threePercent)
    self.customRateTextField.text = ""
    self.customRateTextField.isEnabled = false
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
    self.updateMinRateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_slippage_rate_default", customAttributes: nil)
  }

  @objc func userTappedThreePercent(_ sender: Any) {
    self.threePercentButtonPressed(sender)
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_slippage_rate_default", customAttributes: nil)
  }

  @IBAction func customRateButtonPressed(_ sender: Any) {
    self.viewModel.updateMinRateType(.custom(value: 3.0))
    self.customRateTextField.text = "3.0"
    self.customRateTextField.isEnabled = true
    self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: 3.0))
    self.updateMinRateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_slippage_rate_custom", customAttributes: nil)
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.delegate?.kAdvancedSettingsView(self, run: .helpPressed)
  }

  @objc func userTappedCustomRate(_ sender: Any) {
    self.customRateButtonPressed(sender)
    KNCrashlyticsUtil.logCustomEvent(withName: "advanced_slippage_rate_custom", customAttributes: nil)
  }

  @IBAction func enableReverseRoutingTapped(_ sender: UIButton) {
    self.viewModel.updateIsUsingReverseRouting(value: !self.viewModel.isUsingReverseRouting)
    self.updateIsUsingReverseRoutingCheckBox()
    self.delegate?.kAdvancedSettingsView(self, run: .changeIsUsingReverseRouting(value: self.viewModel.isUsingReverseRouting))
  }

  @IBAction func reverseRoutingHelpButtonTapped(_ sender: UIButton) {
    self.delegate?.kAdvancedSettingsView(self, run: .reverseRoutingHelpPress)
  }
}

extension KAdvancedSettingsView: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let number = text.removeGroupSeparator()
    let value: Double? = number.isEmpty ? 0 : Double(number)
    let maxMinRatePercent: Double = 100.0
    if let val = value, val >= 0, val <= maxMinRatePercent {
      textField.text = text
      self.viewModel.updateMinRateType(.custom(value: val))
      self.updateMinRateUIs()
      self.delegate?.kAdvancedSettingsView(self, run: .minRatePercentageChanged(percent: CGFloat(val)))
    }
    return false
  }
}
