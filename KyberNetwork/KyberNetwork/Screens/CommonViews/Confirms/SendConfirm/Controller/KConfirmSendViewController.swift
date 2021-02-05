// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KConfirmViewEvent {
  case confirm(type: KNTransactionType)
  case cancel
}

protocol KConfirmSendViewControllerDelegate: class {
  func kConfirmSendViewController(_ controller: KConfirmSendViewController, run event: KConfirmViewEvent)
}

class KConfirmSendViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var contactImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var sendAddressLabel: UILabel!

  @IBOutlet weak var firstSeparatorView: UIView!
  @IBOutlet weak var secondSeparatorView: UIView!

  @IBOutlet weak var sendAmountLabel: UILabel!
  @IBOutlet weak var sendAmountUSDLabel: UILabel!

  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  @IBOutlet weak var amountToSendTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var gasWarningTextLabel: UILabel!
  @IBOutlet weak var gasWarningContainerView: UIView!
  @IBOutlet weak var confirmButtonTopContraint: NSLayoutConstraint!
  fileprivate var isViewSetup: Bool = false

  fileprivate let viewModel: KConfirmSendViewModel
  weak var delegate: KConfirmSendViewControllerDelegate?

  fileprivate var isConfirmed: Bool = false
  init(viewModel: KConfirmSendViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSendViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.firstSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    if !self.isConfirmed {
      self.confirmButton.removeSublayer(at: 0)
      self.confirmButton.applyGradient()
    }
  }

  fileprivate func setupUI() {
    let style = KNAppStyleType.current
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.titleLabel.text = self.viewModel.titleString

    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.contactNameLabel.addLetterSpacing()
    self.sendAddressLabel.text = self.viewModel.address
    self.sendAddressLabel.addLetterSpacing()

    self.sendAmountLabel.text = self.viewModel.totalAmountString
    self.sendAmountLabel.addLetterSpacing()
    self.sendAmountUSDLabel.text = self.viewModel.usdValueString
    self.sendAmountUSDLabel.addLetterSpacing()

    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeETHLabel.addLetterSpacing()
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.feeUSDLabel.addLetterSpacing()
    gasPriceTextLabel.text = viewModel.transactionGasPriceString
    gasPriceTextLabel.addLetterSpacing()

    self.confirmButton.rounded(radius: style.buttonRadius())
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.applyGradient()
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )

    self.firstSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)

    self.amountToSendTextLabel.text = NSLocalizedString("amount.to.send", value: "Amount To Transfer", comment: "").uppercased()
    self.amountToSendTextLabel.addLetterSpacing()
    self.transactionFeeTextLabel.text = NSLocalizedString("Maximum gas fee", value: "Transaction Fee", comment: "")
    self.transactionFeeTextLabel.addLetterSpacing()
    self.updateGasWarningUI()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transferconfirm_confirm_tapped",
                                     customAttributes: [
                                      "token": self.viewModel.transaction.transferType.tokenObject().symbol,
                                      "amount": self.viewModel.totalAmountString,
                                      "gas_fee": self.viewModel.transactionFeeETHString,
      ]
    )
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.transfer(self.viewModel.transaction))
    self.updateActionButtonsSendingTransfer()
    self.delegate?.kConfirmSendViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transferconfirm_confirm_cancel",
                                     customAttributes: [
                                      "token": self.viewModel.transaction.transferType.tokenObject().symbol,
                                      "amount": self.viewModel.totalAmountString,
                                      "gas_fee": self.viewModel.transactionFeeETHString,
      ]
    )
    self.delegate?.kConfirmSendViewController(self, run: .cancel)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_transfer", customAttributes: ["action": "screen_edge_pan\(self.viewModel.transaction.transferType.tokenObject().symbol)"])
      self.delegate?.kConfirmSendViewController(self, run: .cancel)
    }
  }

  @IBAction func helpGasFeeButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transferconfirm_gas_fee_info_tapped", customAttributes: nil)
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }

  func updateActionButtonsSendingTransfer() {
    self.isConfirmed = true
    self.confirmButton.backgroundColor = UIColor.clear
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.setTitle("\(NSLocalizedString("in.progress", value: "In Progress", comment: "")) ...", for: .normal)
    self.confirmButton.setTitleColor(
      UIColor.Kyber.enygold,
      for: .normal
    )
    self.confirmButton.isEnabled = false
    self.cancelButton.isHidden = true
  }

  func resetActionButtons() {
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.setTitleColor(UIColor.white, for: .normal)
    self.isConfirmed = false
    self.confirmButton.applyGradient()
    self.confirmButton.isEnabled = true
    self.cancelButton.isHidden = false
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
  }

  fileprivate func updateGasWarningUI() {
    guard self.isViewSetup else {
      return
    }
    let currentGasPrice = self.viewModel.transaction.gasPrice ?? KNGasCoordinator.shared.fastKNGas
    let gasLimit: BigInt = self.viewModel.transaction.gasLimit ?? KNGasConfiguration.exchangeTokensGasLimitDefault
    var limit = UserDefaults.standard.double(forKey: Constants.gasWarningValueKey)
    if limit <= 0 { limit = 200 }
    let limitBigInit = EtherNumberFormatter.full.number(from: limit.description, units: UnitConfiguration.gasPriceUnit)!
    let isShowWarning = (currentGasPrice > limitBigInit) && !self.viewModel.isCloseGasWarningPopup
    self.confirmButtonTopContraint.constant = isShowWarning ? 88 : 32
    self.gasWarningContainerView.isHidden = !isShowWarning
    if isShowWarning {
      let estFee = currentGasPrice * gasLimit
      let feeString: String = estFee.displayRate(decimals: 18)
      let warningText = String(format: "High network congestion. Please double check gas fee (~%@ ETH) before confirmation.".toBeLocalised(), feeString)
      self.gasWarningTextLabel.text = warningText
    }
  }

  func coordinatorUpdateGasWaringLimit() {
    self.updateGasWarningUI()
  }

  @IBAction func closeGasWarningPopupTapped(_ sender: UIButton) {
    self.viewModel.saveCloseGasWarningState()
    self.updateGasWarningUI()
  }
}
