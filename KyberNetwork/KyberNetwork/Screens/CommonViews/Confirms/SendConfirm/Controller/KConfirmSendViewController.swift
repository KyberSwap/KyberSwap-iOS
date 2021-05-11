// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KConfirmViewEvent {
  case confirm(type: KNTransactionType, historyTransaction: InternalHistoryTransaction)
  case cancel
}

protocol KConfirmSendViewControllerDelegate: class {
  func kConfirmSendViewController(_ controller: KConfirmSendViewController, run event: KConfirmViewEvent)
}

class KConfirmSendViewController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var contactImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var sendAddressLabel: UILabel!

  @IBOutlet weak var sendAmountLabel: UILabel!
  @IBOutlet weak var sendAmountUSDLabel: UILabel!

  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  @IBOutlet weak var amountToSendTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  
  fileprivate let viewModel: KConfirmSendViewModel
  weak var delegate: KConfirmSendViewControllerDelegate?

  fileprivate var isConfirmed: Bool = false
  let transitor = TransitionDelegate()

  init(viewModel: KConfirmSendViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KConfirmSendViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
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
    if !self.isConfirmed {
      self.confirmButton.removeSublayer(at: 0)
      self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    }
  }

  fileprivate func setupUI() {
    self.titleLabel.text = self.viewModel.titleString

    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.sendAddressLabel.text = self.viewModel.address

    self.sendAmountLabel.text = self.viewModel.totalAmountString
    self.sendAmountUSDLabel.text = self.viewModel.usdValueString

    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    gasPriceTextLabel.text = viewModel.transactionGasPriceString

    self.confirmButton.rounded(radius: self.confirmButton.frame.size.height / 2)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.cancelButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.cancelButton.frame.size.height / 2)
    self.amountToSendTextLabel.text = NSLocalizedString("amount.to.send", value: "Amount To Transfer", comment: "")
    self.transactionFeeTextLabel.text = NSLocalizedString("Maximum gas fee", value: "Transaction Fee", comment: "")
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.confirmButton.isEnabled = false
    self.cancelButton.isEnabled = false
    var symbol = ""
    var type: HistoryModelType = .transferToken
    switch self.viewModel.transaction.transferType {
    case .ether:
      type = .transferETH
      symbol = "ETH"
    case .token(let token):
      type = .transferToken
      symbol = token.symbol
    }
    let historyTransaction = InternalHistoryTransaction(type: type, state: .pending, fromSymbol: symbol, toSymbol: nil, transactionDescription: "-\(self.viewModel.totalAmountString)", transactionDetailDescription: "", transactionObj: SignTransactionObject(value: "", from: "", to: "", nonce: 0, data: Data(), gasPrice: "", gasLimit: "", chainID: 0))
    historyTransaction.transactionSuccessDescription = "-\(self.viewModel.totalAmountString) to \(self.viewModel.shortAddress.lowercased())"
    let event = KConfirmViewEvent.confirm(type: KNTransactionType.transfer(self.viewModel.transaction), historyTransaction: historyTransaction)
    self.delegate?.kConfirmSendViewController(self, run: event)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kConfirmSendViewController(self, run: .cancel)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.kConfirmSendViewController(self, run: .cancel)
    }
  }

  @IBAction func helpGasFeeButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
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

extension KConfirmSendViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 400
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
