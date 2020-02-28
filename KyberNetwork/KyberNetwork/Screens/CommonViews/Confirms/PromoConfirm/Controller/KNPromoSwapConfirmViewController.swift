// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNPromoSwapConfirmViewControllerDelegate: class {
  func promoCodeSwapConfirmViewControllerDidBack()
  func promoCodeSwapConfirmViewController(_ controller: KNPromoSwapConfirmViewController, transaction: KNDraftExchangeTransaction, destAddress: String)
}

class KNPromoSwapConfirmViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var yourWalletTextLabel: UILabel!
  @IBOutlet weak var walletDescLabel: UILabel!
  @IBOutlet weak var transferFundsIcon: UIImageView!
  @IBOutlet weak var transferFundsMessageLabel: UILabel!

  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var fromValueLabel: UILabel!
  @IBOutlet weak var swapAndSendTextLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var toValueLabel: UILabel!

  @IBOutlet weak var receiveTextLabel: UILabel!
  @IBOutlet weak var receiveValueLabel: UILabel!
  @IBOutlet weak var receiveIcon: UIImageView!

  @IBOutlet weak var topPaddingSecondSeparatorViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var transactionFeeValueLabel: UILabel!
  @IBOutlet weak var transactionFeeInUSDLabel: UILabel!

  @IBOutlet weak var topPaddingFirstSeparatorViewConstraint: NSLayoutConstraint!
  @IBOutlet var separatorViews: [UIView]!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var bottomPaddingCancelButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var transactionGasPriceLabel: UILabel!
  fileprivate let viewModel: KNPromoSwapConfirmViewModel

  fileprivate var isConfirmed: Bool = false

  weak var delegate: KNPromoSwapConfirmViewControllerDelegate?

  init(viewModel: KNPromoSwapConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNPromoSwapConfirmViewController.className, bundle: nil)
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
    self.separatorViews.forEach({
      $0.backgroundColor = .clear
      $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    })
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    if !self.isConfirmed {
      self.confirmButton.removeSublayer(at: 0)
      self.confirmButton.applyGradient()
    }
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.yourWalletTextLabel.text = NSLocalizedString("Your Wallet", comment: "")

    self.walletDescLabel.text = self.viewModel.walletAddress

    let transferFundsMessage = NSLocalizedString("After swapping, please transfer your token to your personal wallet before %@", comment: "")
    self.transferFundsMessageLabel.text = String(
      format: NSLocalizedString(transferFundsMessage, value: transferFundsMessage, comment: ""),
      self.viewModel.expireDateDisplay
    )

    self.swapAndSendTextLabel.text = NSLocalizedString("Swap and Send to the Organizer", comment: "")

    self.fromTextLabel.text = NSLocalizedString("from", value: "From", comment: "")
    self.fromValueLabel.text = self.viewModel.leftAmountString

    self.toTextLabel.text = NSLocalizedString("to", value: "To", comment: "")
    self.toValueLabel.text = self.viewModel.rightAmountString

    self.receiveTextLabel.text = NSLocalizedString("receive", value: "Receive", comment: "")
    self.receiveValueLabel.text = NSLocalizedString("1 Gift", comment: "")

    if self.viewModel.isPayment {
      self.walletDescLabel.isHidden = true
      self.transferFundsIcon.isHidden = true
      self.transferFundsMessageLabel.isHidden = true
      self.swapAndSendTextLabel.isHidden = false
      self.receiveTextLabel.isHidden = false
      self.receiveValueLabel.isHidden = false
      self.receiveIcon.isHidden = false
      self.yourWalletTextLabel.text = NSLocalizedString("You are swapping to receive a gift", comment: "")
      self.topPaddingFirstSeparatorViewConstraint.constant = 20.0
      self.topPaddingSecondSeparatorViewConstraint.constant = 140.0
    } else {
      self.walletDescLabel.isHidden = false
      self.transferFundsIcon.isHidden = false
      self.transferFundsMessageLabel.isHidden = false
      self.swapAndSendTextLabel.isHidden = true
      self.receiveTextLabel.isHidden = true
      self.receiveValueLabel.isHidden = true
      self.receiveIcon.isHidden = true
      self.yourWalletTextLabel.text = NSLocalizedString("Your Wallet", comment: "")
      self.topPaddingFirstSeparatorViewConstraint.constant = 112.0
      self.topPaddingSecondSeparatorViewConstraint.constant = 32.0
    }

    self.transactionFeeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")
    self.transactionFeeTextLabel.addLetterSpacing()
    self.transactionFeeValueLabel.text = self.viewModel.feeETHString
    self.transactionFeeInUSDLabel.text = self.viewModel.feeUSDString
    transactionGasPriceLabel.text = viewModel.transactionGasPriceString

    self.confirmButton.setTitle(NSLocalizedString("confirm", value: "Confirm", comment: ""), for: .normal)
    self.confirmButton.rounded(radius: KNAppStyleType.current.buttonRadius(for: self.confirmButton.frame.height))
    self.confirmButton.applyGradient()

    self.cancelButton.setTitle(NSLocalizedString("cancel", value: "Cancel", comment: ""), for: .normal)

    self.separatorViews.forEach({
      $0.backgroundColor = .clear
      $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    })

    self.bottomPaddingCancelButtonConstraint.constant = 32.0 + self.bottomPaddingSafeArea()
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.promoCodeSwapConfirmViewControllerDidBack()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap_promo", customAttributes: ["action": "back_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap_promo", customAttributes: ["action": "confirmed_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    self.updateActionButtonsSendingSwap()
    self.delegate?.promoCodeSwapConfirmViewController(
      self,
      transaction: self.viewModel.transaction,
      destAddress: self.viewModel.destWallet
    )
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_confirm_swap_promo", customAttributes: ["action": "cancel_pressed_\(self.viewModel.transaction.from.symbol)_\(self.viewModel.transaction.to.symbol)"])
    self.delegate?.promoCodeSwapConfirmViewControllerDidBack()
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
}
