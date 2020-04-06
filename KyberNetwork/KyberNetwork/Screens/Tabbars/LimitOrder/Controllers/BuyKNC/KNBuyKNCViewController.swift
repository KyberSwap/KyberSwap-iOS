//
//  KNBuyKNCViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/25/20.
//

import UIKit
import BigInt

class KNBuyKNCViewController: KNBaseViewController {
  @IBOutlet weak var marketNameLabel: UIButton!
  @IBOutlet weak var priceField: UITextField!
  @IBOutlet weak var amountField: UITextField!
  @IBOutlet weak var tokenAvailableLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!
  @IBOutlet weak var beforeDiscountFeeLabel: UILabel!
  @IBOutlet weak var comparePriceLabel: UILabel!
  @IBOutlet weak var discountPecentLabel: UILabel!
  @IBOutlet weak var discountPercentContainerView: UIView!
  @IBOutlet weak var totalField: UITextField!
  @IBOutlet weak var buySellButton: UIButton!
  @IBOutlet var fromSymLabels: [UILabel]!
  @IBOutlet weak var toSymLabel: UILabel!

  fileprivate var updateFeeTimer: Timer?

  weak var delegate: KNCreateLimitOrderViewControllerDelegate?

  private let viewModel: KNBuyKNCViewModel
  fileprivate var isViewSetup: Bool = false

  init(viewModel: KNBuyKNCViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBuyKNCViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateFeeTimer?.invalidate()
    self.updateFeeTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.updateEstimateFeeFromServer()
      }
    )
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
  }

  fileprivate func setupUI() {
    self.viewModel.updateMarket()
    self.priceField.text = self.viewModel.targetPriceFromMarket
    self.viewModel.updateTargetPrice(self.viewModel.targetPriceFromMarket)
    self.tokenAvailableLabel.text = self.viewModel.balanceText
    self.toSymLabel.text = self.viewModel.toSymBol
    for label in self.fromSymLabels {
      label.text = self.viewModel.fromSymbol
    }
    if self.viewModel.isBuy {
      self.buySellButton.setTitle("\("Buy".toBeLocalised()) \(self.viewModel.toSymBol)", for: .normal)
    } else {
      self.buySellButton.setTitle("\("Sell".toBeLocalised()) \(self.viewModel.fromSymbol)", for: .normal)
      self.buySellButton.backgroundColor = UIColor.Kyber.red
    }
  }

  fileprivate func updateFeeNotesUI() {
    guard isViewSetup else {
      return
    }
    self.feeLabel.text = self.viewModel.displayFeeString
    self.beforeDiscountFeeLabel.attributedText = self.viewModel.beforeDiscountAttributeString
    self.beforeDiscountFeeLabel.isHidden = !self.viewModel.isShowingDiscount
    self.discountPercentContainerView.isHidden = !self.viewModel.isShowingDiscount
    self.discountPecentLabel.text = self.viewModel.displayDiscountPercentageString
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    if self.isViewSetup {
      self.tokenAvailableLabel.text = self.viewModel.balanceText
    }
  }

  func coordinatorUpdateEstimateFee(_ fee: Double, discount: Double, feeBeforeDiscount: Double, transferFee: Double) {
    self.viewModel.feePercentage = fee
    self.viewModel.discountPercentage = discount
    self.viewModel.feeBeforeDiscount = feeBeforeDiscount
    self.viewModel.transferFeePercent = transferFee
    self.updateFeeNotesUI()
  }

  fileprivate func updateEstimateRateFromNetwork(showWarning: Bool = false) {
    let amount: BigInt = {
      if self.viewModel.amountFromBigInt.isZero {
        return BigInt(0.001 * pow(10.0, Double(self.viewModel.from.decimals)))
      }
      return self.viewModel.amountFromBigInt
    }()
    let event = KNCreateLimitOrderViewEvent.estimateRate(
      from: self.viewModel.from,
      to: self.viewModel.to,
      amount: amount,
      showWarning: showWarning
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  fileprivate func updateEstimateFeeFromServer() {
    let event = KNCreateLimitOrderViewEvent.estimateFee(
      address: self.viewModel.walletObject.address,
      src: self.viewModel.from.contract,
      dest: self.viewModel.to.contract,
      srcAmount: self.viewModel.totalAmountDouble,
      destAmount: self.viewModel.amountToDouble
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  @IBAction func learnMoreButtonTapped(_ sender: UIButton) {
    let url = "\(KNEnvironment.default.profileURL)/faq#I-have-KNC-in-my-wallet-Do-I-get-any-discount-on-trading-fees"
    self.navigationController?.openSafari(with: url)
  }

  @IBAction func quickFillAmountButtonTapped(_ sender: UIButton) {
    self.updateEstimateFeeFromServer()
    switch sender.tag {
    case 1:
      let amountDisplay = self.viewModel.amountFromWithPercentage(25).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
      self.viewModel.updateAmountFrom(amountDisplay)
      self.totalField.text = amountDisplay
      self.amountField.text = self.viewModel.estimateAmountToString
      self.viewModel.updateAmountTo(self.viewModel.estimateAmountToString)
      self.updateFeeNotesUI()
    case 2:
      let amountDisplay = self.viewModel.amountFromWithPercentage(50).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
      self.viewModel.updateAmountFrom(amountDisplay)
      self.totalField.text = amountDisplay
      self.amountField.text = self.viewModel.estimateAmountToString
      self.viewModel.updateAmountTo(self.viewModel.estimateAmountToString)
      self.updateFeeNotesUI()
    case 3:
      let amountDisplay = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
      self.viewModel.updateAmountFrom(amountDisplay)
      self.totalField.text = amountDisplay
      self.amountField.text = self.viewModel.estimateAmountToString
      self.viewModel.updateAmountTo(self.viewModel.estimateAmountToString)
      self.updateFeeNotesUI()
    default:
      break
    }
  }
}

extension KNBuyKNCViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if textField == self.priceField {
      self.viewModel.updateTargetPrice(text)
      self.comparePriceLabel.attributedText = self.viewModel.displayRateCompareAttributedString
    } else if textField == self.amountField {
      self.viewModel.updateAmountTo(text)
      self.updateFeeNotesUI()
      self.totalField.text = self.viewModel.totalAmountString
    }
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == self.amountField {
      self.updateEstimateFeeFromServer()
    }
  }
}
