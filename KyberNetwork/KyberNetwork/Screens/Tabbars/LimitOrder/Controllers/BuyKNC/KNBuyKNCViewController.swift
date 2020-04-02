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
  @IBOutlet weak var totalAmountLabel: UILabel!
  @IBOutlet weak var totalPriceLabel: UILabel!
  @IBOutlet weak var comparePriceLabel: UILabel!
  @IBOutlet weak var discountPecentLabel: UILabel!
  @IBOutlet weak var discountPercentContainerView: UIView!
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
    self.tokenAvailableLabel.text = self.viewModel.balanceText
  }

  fileprivate func updateFeeNotesUI() {
    guard isViewSetup else {
      return
    }
//    self.feeLabel.attributedText = self.viewModel.feeNoteAttributedString
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
    self.delegate?.kCreateLimitOrderViewController(nil, run: event)
  }

  fileprivate func updateEstimateFeeFromServer() {
    let event = KNCreateLimitOrderViewEvent.estimateFee(
      address: self.viewModel.walletObject.address,
      src: self.viewModel.from.contract,
      dest: self.viewModel.to.contract,
      srcAmount: Double(self.viewModel.amountFromBigInt) / pow(10.0, Double(self.viewModel.from.decimals)),
      destAmount: Double(self.viewModel.estimateAmountToBigInt) / pow(10.0, Double(self.viewModel.to.decimals))
    )
    self.delegate?.kCreateLimitOrderViewController(nil, run: event)
  }
}

extension KNBuyKNCViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if textField == self.priceField {
      self.viewModel.updateTargetPrice(text)
      self.comparePriceLabel.attributedText = self.viewModel.displayRateCompareAttributedString
    } else if textField == self.amountField {
      self.viewModel.updateAmount(text)
      self.updateFeeNotesUI()
    }
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == self.amountField {
      self.updateEstimateFeeFromServer()
    }
  }
}
