//
//  EarnConfirmViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/3/21.
//

import UIKit
import BigInt

struct EarnConfirmViewModel {
  let platform: LendingPlatformData
  let token: TokenData
  let amount: BigInt
  let gasPrice: BigInt
  let gasLimit: BigInt
  let transaction: SignTransaction
  let rawTransaction: TxObject
  
  var amountString: String {
    let amountString = self.amount.displayRate(decimals: self.token.decimals)
    return "\(amountString.prefix(15)) \(self.token.symbol)"
  }
  
  var toTokenSym: String {
    return self.platform.isCompound ? "c\(self.token.symbol)" : "a\(self.token.symbol)"
  }
  
  var toAmountString: String {
    let amountString = self.amount.displayRate(decimals: self.token.decimals)
    return "\(amountString.prefix(15)) \(self.toTokenSym)"
  }
  
  var depositAPYString: String {
    if self.platform.supplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.platform.supplyRate * 100.0) + "%"
    }
  }
  
  var distributionAPYString: String {
    if self.platform.distributionSupplyRate == 0 {
      return ""
    } else {
      return String(format: "%.2f", self.platform.distributionSupplyRate * 100.0) + "%"
    }
  }

  var netAPYString: String {
    return "+" + String(format: "%.2f", (self.platform.distributionSupplyRate + self.platform.supplyRate) * 100.0) + "%"
  }
  
  var transactionFee: BigInt {
    return self.gasPrice * self.gasLimit
  }

  var feeETHString: String {
    let string: String = self.transactionFee.displayRate(decimals: 18)
    return "\(string) ETH"
  }
  
  var feeUSDString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: KNSupportedTokenStorage.shared.ethToken) else { return "" }
    let usdRate: BigInt = KNRate.rateUSD(from: trackerRate).rate
    let value: BigInt = usdRate * self.transactionFee / BigInt(EthereumUnit.ether.rawValue)
    let valueString: String = value.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 1
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: self.gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
}

protocol EarnConfirmViewControllerDelegate: class {
  func earnConfirmViewController(_ controller: KNBaseViewController, didConfirm transaction: SignTransaction, amount: String, netAPY: String, platform: LendingPlatformData, historyTransaction: InternalHistoryTransaction)
}

class EarnConfirmViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var platformNameLabel: UILabel!
  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var platformIconImageView: UIImageView!
  @IBOutlet weak var depositAPYValueLabel: UILabel!
  @IBOutlet weak var netAPYValueLabel: UILabel!
  @IBOutlet weak var transactionFeeETHLabel: UILabel!
  @IBOutlet weak var transactionFeeUSDLabel: UILabel!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var compInfoMessageContainerView: UIView!
  @IBOutlet weak var depositAPYBottomContraint: NSLayoutConstraint!
  @IBOutlet weak var distributionAPYContainerView: UIView!
  @IBOutlet weak var framingIconContainerView: UIView!
  @IBOutlet weak var sendButtonTopContraint: NSLayoutConstraint!
  @IBOutlet weak var distributeAPYValueLabel: UILabel!
  
  weak var delegate: EarnConfirmViewControllerDelegate?
  
  let transitor = TransitionDelegate()
  let viewModel: EarnConfirmViewModel

  init(viewModel: EarnConfirmViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnConfirmViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupUI()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  fileprivate func setupUI() {
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
    self.cancelButton.rounded(color: UIColor(red: 35, green: 167, blue: 181), width: 1, radius: self.cancelButton.frame.size.height / 2)
    self.amountLabel.text = self.viewModel.amountString
    self.platformNameLabel.text = self.viewModel.platform.name
    if self.viewModel.platform.isCompound {
      self.framingIconContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 133
      self.compInfoMessageContainerView.isHidden = false
    } else {
      self.framingIconContainerView.isHidden = true
      self.sendButtonTopContraint.constant = 20
      self.compInfoMessageContainerView.isHidden = true
    }
    self.depositAPYValueLabel.text = self.viewModel.depositAPYString
    let distributeAPY = self.viewModel.distributionAPYString
    if distributeAPY.isEmpty {
      self.depositAPYBottomContraint.constant = 20
      self.distributionAPYContainerView.isHidden = true
    } else {
      self.depositAPYBottomContraint.constant = 45
      self.distributionAPYContainerView.isHidden = true
      self.distributeAPYValueLabel.text = self.viewModel.distributionAPYString
    }
    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
    self.netAPYValueLabel.text = self.viewModel.netAPYString
    
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      let historyTransaction = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.viewModel.token.symbol, toSymbol: self.viewModel.toTokenSym, transactionDescription: "\(self.viewModel.amountString) -> \(self.viewModel.toAmountString)", transactionDetailDescription: "", transactionObj: self.viewModel.transaction.toSignTransactionObject())
      historyTransaction.transactionSuccessDescription = "\(self.viewModel.amountString) with \(self.viewModel.netAPYString) APY"
      
      self.delegate?.earnConfirmViewController(self, didConfirm: self.viewModel.transaction, amount: self.viewModel.amountString, netAPY: self.viewModel.netAPYString, platform: self.viewModel.platform, historyTransaction: historyTransaction)
    }
    
  }
}

extension EarnConfirmViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.platform.isCompound ? 600 : 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
