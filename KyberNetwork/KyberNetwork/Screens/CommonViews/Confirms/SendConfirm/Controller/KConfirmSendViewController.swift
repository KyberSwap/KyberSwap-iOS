// Copyright SIX DAY LLC. All rights reserved.

import UIKit

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

    self.firstSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)
    self.secondSeparatorView.dashLine(width: 1, color: UIColor.Kyber.dashLine)

    self.amountToSendTextLabel.text = NSLocalizedString("amount.to.send", value: "Amount To Transfer", comment: "").uppercased()
    self.amountToSendTextLabel.addLetterSpacing()
    self.transactionFeeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")
    self.transactionFeeTextLabel.addLetterSpacing()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_transfer", customAttributes: ["action": "confirmed_\(self.viewModel.transaction.transferType.tokenObject().symbol)"])
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.transfer(self.viewModel.transaction))
    self.updateActionButtonsSendingTransfer()
    self.delegate?.kConfirmSendViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_transfer", customAttributes: ["action": "back_pressed_\(self.viewModel.transaction.transferType.tokenObject().symbol)"])
    self.delegate?.kConfirmSendViewController(self, run: .cancel)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_transfer", customAttributes: ["action": "screen_edge_pan\(self.viewModel.transaction.transferType.tokenObject().symbol)"])
      self.delegate?.kConfirmSendViewController(self, run: .cancel)
    }
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
}
