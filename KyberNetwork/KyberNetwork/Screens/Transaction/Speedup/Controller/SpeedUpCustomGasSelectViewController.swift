// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum SpeedUpCustomGasSelectViewEvent {
  case done(transaction: InternalHistoryTransaction, newGasPrice: BigInt)
  case invaild
}

protocol SpeedUpCustomGasSelectDelegate: class {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent)
}

class SpeedUpCustomGasSelectViewController: KNBaseViewController {
  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var superFastGasPriceButton: UIButton!
  @IBOutlet weak var superFastGasPriceLabel: UILabel!
  @IBOutlet weak var fastGasPriceButton: UIButton!
  @IBOutlet weak var fastGasPriceLabel: UILabel!
  @IBOutlet weak var regularGasPriceButton: UIButton!
  @IBOutlet weak var regularGasPriceLabel: UILabel!
  @IBOutlet weak var slowGasPriceButton: UIButton!
  @IBOutlet weak var slowGasPriceLabel: UILabel!
  @IBOutlet weak var currentFeeLabel: UILabel!
  @IBOutlet weak var newFeeLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var mainTextTitle: UILabel!
  @IBOutlet weak var currentFeeTitleLabel: UILabel!
  @IBOutlet weak var newFeeTitleLabel: UILabel!
  @IBOutlet weak var gasPriceWarningMessageLabel: UILabel!
  @IBOutlet weak var superFastEstimateFeeLabel: UILabel!
  @IBOutlet weak var fastEstimateFeeLabel: UILabel!
  @IBOutlet weak var regularEstimateFeeLabel: UILabel!
  @IBOutlet weak var slowEstimateFeeLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!

  fileprivate let viewModel: SpeedUpCustomGasSelectViewModel
  weak var delegate: SpeedUpCustomGasSelectDelegate?
  let transitor = TransitionDelegate()

  init(viewModel: SpeedUpCustomGasSelectViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SpeedUpCustomGasSelectViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateUI()
    self.updateGasPriceUIs()
  }

  fileprivate func updateUI() {
    self.navigationTitleLabel.text = "Customize Gas".toBeLocalised()
    self.mainTextTitle.text = "Select.higher.tx.fee.to.accelerate".toBeLocalised()
    self.gasPriceWarningMessageLabel.text = "your.gas.must.be.10.percent.higher".toBeLocalised()
    self.currentFeeLabel.text = "Current fee".toBeLocalised()
    self.newFeeLabel.text = "New fee".toBeLocalised()
    self.doneButton.setTitle("done".toBeLocalised(), for: .normal)

    self.currentFeeLabel.text = self.viewModel.currentTransactionFeeETHString
    self.doneButton.rounded(radius: 16)
    self.superFastEstimateFeeLabel.text = self.viewModel.estimateFeeSuperFastString
    self.fastEstimateFeeLabel.text = self.viewModel.estimateFeeFastString
    self.regularEstimateFeeLabel.text = self.viewModel.estimateRegularFeeString
    self.slowEstimateFeeLabel.text = self.viewModel.estimateSlowFeeString
  }

  func updateGasPriceUIs() {
    self.superFastGasPriceLabel.attributedText = self.viewModel.superFastGasString
    self.fastGasPriceLabel.attributedText = self.viewModel.fastGasString
    self.regularGasPriceLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasPriceLabel.attributedText = self.viewModel.slowGasString

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasPriceButton.rounded(
      color: UIColor.Kyber.SWActivePageControlColor,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.superFastGasPriceButton.frame.height / 2.0
    )

    self.fastGasPriceButton.rounded(
      color: UIColor.Kyber.SWActivePageControlColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fastGasPriceButton.frame.height / 2.0
    )

    self.regularGasPriceButton.rounded(
      color: UIColor.Kyber.SWActivePageControlColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.regularGasPriceButton.frame.height / 2.0
    )

    self.slowGasPriceButton.rounded(
      color: UIColor.Kyber.SWActivePageControlColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasPriceButton.frame.height / 2.0
    )
    self.newFeeLabel.text = self.viewModel.getNewTransactionFeeETHString()
  }

  @IBAction func doneButtonTapped(_ sender: UIButton) {
    if self.viewModel.isNewGasPriceValid() {
      self.dismiss(animated: true) {
        self.delegate?.speedUpCustomGasSelectViewController(self, run: .done(transaction: self.viewModel.transaction, newGasPrice: self.viewModel.getNewTransactionGasPriceETH()))
      }
    } else {
      self.delegate?.speedUpCustomGasSelectViewController(self, run: .invaild)
    }
  }

  @IBAction func selectBoxButtonTapped(_ sender: UIButton) {
    guard let type = KNSelectedGasPriceType(rawValue: sender.tag) else { return }
    self.handleGasFeeChange(type)
  }

  func handleGasFeeChange(_ type: KNSelectedGasPriceType) {
    self.viewModel.updateSelectedType(type)
    self.updateGasPriceUIs()
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SpeedUpCustomGasSelectViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 543
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
