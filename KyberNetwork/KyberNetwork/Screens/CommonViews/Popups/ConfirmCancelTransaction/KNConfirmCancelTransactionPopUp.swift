// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmCancelTransactionPopUpDelegate: class {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: Transaction)
}

struct KNConfirmCancelTransactionViewModel {
  let transaction: Transaction

  init(transaction: Transaction) {
    self.transaction = transaction
  }

  var transactionFeeETHString: String {
    if let cancelTransaction = transaction.makeCancelTransaction() {
      let fee: BigInt? = {
        guard let gasPrice = cancelTransaction.gasPrice, let gasLimit = cancelTransaction.gasLimit else { return nil }
        return gasPrice * gasLimit
      }()
      let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
      return "\(feeString) ETH"
    } else {
      return ""
    }
  }
}

class KNConfirmCancelTransactionPopUp: KNBaseViewController {
  @IBOutlet weak var questionTitleLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var ethFeeLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var containerView: UIView!
  fileprivate let viewModel: KNConfirmCancelTransactionViewModel
  weak var delegate: KNConfirmCancelTransactionPopUpDelegate?

  init(viewModel: KNConfirmCancelTransactionViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNConfirmCancelTransactionPopUp.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.noButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.noButton.frame.height / 2.0
    )
    self.noButton.setTitle("No".toBeLocalised(), for: .normal)
    self.yesButton.setTitle("Yes".toBeLocalised(), for: .normal)
    self.yesButton.rounded(radius: self.yesButton.frame.height / 2.0)
    self.yesButton.applyGradient()
    containerView.rounded(radius: 8.0)
    questionTitleLabel.text = "Attempt to Cancel?".toBeLocalised()
    titleLabel.text = "Cancellation Gas Fee".toBeLocalised()
    contentLabel.text = "sumitting.does.not.guarantee".toBeLocalised()
    ethFeeLabel.text = viewModel.transactionFeeETHString
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  @objc func tapOutSideToDismiss(_ tapGesture: UITapGestureRecognizer) {
    let loc = tapGesture.location(in: self.view)
    if loc.x < self.containerView.frame.minX
      || loc.x > self.containerView.frame.maxX
      || loc.y < self.containerView.frame.minY
      || loc.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func yesButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_yes_button_on_cancel_tx_confirm_popup", customAttributes: ["transactionHash": viewModel.transaction.id])
    delegate?.didConfirmCancelTransactionPopup(self, transaction: viewModel.transaction)
    dismiss(animated: true, completion: nil)
  }

  @IBAction func noButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_no_button_on_cancel_tx_confirm_popup", customAttributes: ["transactionHash": viewModel.transaction.id])
    dismiss(animated: true, completion: nil)
  }
}
