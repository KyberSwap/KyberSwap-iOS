// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmCancelTransactionPopUpDelegate: class {
  func didConfirmCancelTransactionPopup(_ controller: KNConfirmCancelTransactionPopUp, transaction: InternalHistoryTransaction)
}

struct KNConfirmCancelTransactionViewModel {
  let transaction: InternalHistoryTransaction

  init(transaction: InternalHistoryTransaction) {
    self.transaction = transaction
  }

  var transactionFeeETHString: String {
    let fee: BigInt? = {
      let gasPrice = self.transaction.transactionObject.gasPriceForCancelTransaction()
      return gasPrice * KNGasConfiguration.transferETHGasLimitDefault
    }()
    let feeString: String = fee?.displayRate(decimals: 18) ?? "---"
    return "\(feeString) ETH"
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
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  let transitor = TransitionDelegate()
  fileprivate let viewModel: KNConfirmCancelTransactionViewModel
  weak var delegate: KNConfirmCancelTransactionPopUpDelegate?

  init(viewModel: KNConfirmCancelTransactionViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNConfirmCancelTransactionPopUp.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.noButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.noButton.setTitle("No".toBeLocalised(), for: .normal)
    self.noButton.rounded(radius: 16)
    self.yesButton.setTitle("Yes".toBeLocalised(), for: .normal)
    self.yesButton.rounded(radius: 16)
    
    
    questionTitleLabel.text = "Attempt to Cancel?".toBeLocalised()
    titleLabel.text = "Cancellation Gas Fee".toBeLocalised()
    contentLabel.text = "sumitting.does.not.guarantee".toBeLocalised()
    ethFeeLabel.text = viewModel.transactionFeeETHString
    self.view.isUserInteractionEnabled = true
  }
  
  @IBAction func yesButtonTapped(_ sender: UIButton) {
    
    delegate?.didConfirmCancelTransactionPopup(self, transaction: viewModel.transaction)
    dismiss(animated: true, completion: nil)
  }

  @IBAction func noButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }
}

extension KNConfirmCancelTransactionPopUp: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 350
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
