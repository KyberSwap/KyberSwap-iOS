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
  @IBOutlet weak var warningMessage: UILabel!
  
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


  fileprivate func setupUI() {

    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.sendAddressLabel.text = self.viewModel.address

    self.sendAmountLabel.text = self.viewModel.totalAmountString
    self.sendAmountUSDLabel.text = self.viewModel.usdValueString

    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    gasPriceTextLabel.text = viewModel.transactionGasPriceString

    self.confirmButton.rounded(radius: 16)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.cancelButton.setTitle(
      NSLocalizedString("cancel", value: "Cancel", comment: ""),
      for: .normal
    )
    self.cancelButton.rounded(radius: 16)
    self.amountToSendTextLabel.text = NSLocalizedString("amount.to.send", value: "Amount To Transfer", comment: "")
    self.transactionFeeTextLabel.text = NSLocalizedString("Maximum gas fee", value: "Transaction Fee", comment: "")
    let chain = KNGeneralProvider.shared.isEthereum ? "Ethereum" : "Binance Smart Chain"
    self.warningMessage.text = "Please sure that this address supports \(chain) network. You will lose your assets if this address doesn't support \(chain) compatible retrieval"
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.confirmButton.isEnabled = false
    self.cancelButton.isEnabled = false
    var symbol = ""
    var type: HistoryModelType = .transferToken
    switch self.viewModel.transaction.transferType {
    case .ether:
      type = .transferETH
      symbol = KNGeneralProvider.shared.quoteToken
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
    return 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
