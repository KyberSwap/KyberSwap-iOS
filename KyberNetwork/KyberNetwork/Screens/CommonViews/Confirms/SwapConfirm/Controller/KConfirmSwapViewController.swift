// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KConfirmSwapViewControllerDelegate: class {
  func kConfirmSwapViewController(_ controller: KConfirmSwapViewController, run event: KConfirmViewEvent)
}

class KConfirmSwapViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var fromAmountLabel: UILabel!
  @IBOutlet weak var toAmountLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var equivalentUSDValueLabel: UILabel!
  @IBOutlet weak var minAcceptableRateTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!

  @IBOutlet weak var firstSeparatorView: UIView!

  @IBOutlet weak var warningMessageLabel: UILabel!
  @IBOutlet weak var expectedRateLabel: UILabel!
  @IBOutlet weak var minAcceptableRateValueButton: UIButton!

  @IBOutlet weak var secondSeparatorView: UIView!

  @IBOutlet weak var transactionFeeETHLabel: UILabel!
  @IBOutlet weak var transactionFeeUSDLabel: UILabel!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  @IBOutlet weak var warningETHBalImageView: UIImageView!
  @IBOutlet weak var warningETHBalanceLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate var viewModel: KConfirmSwapViewModel
  weak var delegate: KConfirmSwapViewControllerDelegate?

  fileprivate var isConfirmed: Bool = false

  init(viewModel: KConfirmSwapViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSwapViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
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
    self.titleLabel.addLetterSpacing()

    self.fromAmountLabel.text = self.viewModel.leftAmountString
    self.fromAmountLabel.addLetterSpacing()
    self.toAmountLabel.text = self.viewModel.rightAmountString
    self.toAmountLabel.addLetterSpacing()

    self.firstSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.warningMessageLabel.text = self.viewModel.warningRateMessage
    self.expectedRateLabel.text = self.viewModel.displayEstimatedRate
    self.expectedRateLabel.addLetterSpacing()
    self.minAcceptableRateValueButton.setTitle(self.viewModel.minRateString, for: .normal)
    self.minAcceptableRateValueButton.setTitleColor(
      self.viewModel.warningMinAcceptableRateMessage == nil ? UIColor(red: 90, green: 94, blue: 103) : UIColor(red: 250, green: 101, blue: 102),
      for: .normal
    )
    self.minAcceptableRateValueButton.isEnabled = self.viewModel.warningMinAcceptableRateMessage != nil
    self.minAcceptableRateValueButton.semanticContentAttribute = .forceRightToLeft
    self.minAcceptableRateValueButton.setImage(
      self.viewModel.warningMinAcceptableRateMessage == nil ? nil : UIImage(named: "info_red_icon"),
      for: .normal
    )

    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeETHLabel.addLetterSpacing()
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionFeeUSDLabel.addLetterSpacing()
    transactionGasPriceLabel.text = viewModel.transactionGasPriceString
    transactionGasPriceLabel.addLetterSpacing()

    self.secondSeparatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.confirmButton.rounded(radius: style.buttonRadius(for: self.confirmButton.frame.height))
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.applyGradient()
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )

    self.toTextLabel.text = NSLocalizedString("transaction.to.text", value: "To", comment: "")
    self.minAcceptableRateTextLabel.text = NSLocalizedString("min.acceptable.rate", value: "Min Acceptable Rate", comment: "")
    self.transactionFeeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")
    self.transactionFeeTextLabel.addLetterSpacing()
    self.equivalentUSDValueLabel.text = self.viewModel.displayEquivalentUSDAmount

    let warningBalShown = self.viewModel.warningETHBalanceShown
    self.warningETHBalanceLabel.isHidden = !warningBalShown
    self.warningETHBalImageView.isHidden = !warningBalShown
    self.warningETHBalanceLabel.text = "After this swap you will not have enough ETH for further transactions.".toBeLocalised()

    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap", customAttributes: ["action": "back_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    self.delegate?.kConfirmSwapViewController(self, run: .cancel)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap", customAttributes: ["action": "screen_edge_pan_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
      self.delegate?.kConfirmSwapViewController(self, run: .cancel)
    }
  }

  @IBAction func tapMinAcceptableRateValue(_ sender: Any?) {
    guard let message = self.viewModel.warningMinAcceptableRateMessage else { return }
    self.showTopBannerView(
      with: "",
      message: message,
      icon: UIImage(named: "info_red_icon"),
      time: 2.0
    )
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap", customAttributes: ["action": "confirmed_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.exchange(self.viewModel.transaction))
    self.updateActionButtonsSendingSwap()
    self.delegate?.kConfirmSwapViewController(self, run: event)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap", customAttributes: ["action": "cancel_pressed_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    self.delegate?.kConfirmSwapViewController(self, run: .cancel)
  }

  func updateActionButtonsSendingSwap() {
    self.isConfirmed = true
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.backgroundColor = UIColor.clear
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
    self.confirmButton.applyGradient()
    self.isConfirmed = false
    self.confirmButton.isEnabled = true
    self.cancelButton.isHidden = false
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateCurrentMarketRate() {
    self.warningMessageLabel.text = self.viewModel.warningRateMessage
  }
}
