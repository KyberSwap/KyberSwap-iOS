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
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = self.transactionFee * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
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
  
  var usdValueBigInt: BigInt {
    guard let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address) else { return BigInt(0) }
    let usd = self.amount * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(self.token.decimals)
    return usd
  }
  
  var displayUSDValue: String {
    return "~ \(self.usdValueBigInt.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)) USD"
  }
  
  var displayCompInfo: String {
    let apy = String(format: "%.6f", self.platform.distributionSupplyRate * 100.0)
    return "You will automatically earn COMP token (\(apy)% APY) for interacting with Compound (supply or borrow).\n\nOnce redeemed, COMP token can be swapped to any token."
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
  @IBOutlet weak var usdValueLabel: UILabel!
  @IBOutlet weak var compInfoLabel: UILabel!
  
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
  
  fileprivate func setupUI() {
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
    self.amountLabel.text = self.viewModel.amountString
    self.platformNameLabel.text = self.viewModel.platform.name
    if self.viewModel.platform.isCompound {
      self.framingIconContainerView.isHidden = false
      self.sendButtonTopContraint.constant = 160
      self.compInfoLabel.text = self.viewModel.displayCompInfo
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
      self.distributionAPYContainerView.isHidden = false
      self.distributeAPYValueLabel.text = self.viewModel.distributionAPYString
    }
    self.transactionFeeETHLabel.text = self.viewModel.feeETHString
    self.transactionFeeUSDLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
    self.netAPYValueLabel.text = self.viewModel.netAPYString
    self.tokenIconImageView.setSymbolImage(symbol: self.viewModel.token.symbol)
    self.usdValueLabel.text = self.viewModel.displayUSDValue
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 10
    )
  }
  
  @IBAction func apyHelpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "Positive APY means you will receive interest and negative means you will pay interest.".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      let historyTransaction = InternalHistoryTransaction(type: .earn, state: .pending, fromSymbol: self.viewModel.token.symbol, toSymbol: self.viewModel.toTokenSym, transactionDescription: "\(self.viewModel.amountString) -> \(self.viewModel.toAmountString)", transactionDetailDescription: "", transactionObj: self.viewModel.transaction.toSignTransactionObject())
      historyTransaction.transactionSuccessDescription = "\(self.viewModel.amountString) with \(self.viewModel.netAPYString.dropFirst()) APY"
      let earnTokenString = self.viewModel.platform.isCompound ? "c" + self.viewModel.token.symbol : "a" + self.viewModel.token.symbol
      historyTransaction.earnTransactionSuccessDescription = "You’ve received \(earnTokenString) token because you supplied \(self.viewModel.token.symbol) in \(self.viewModel.platform.name). Simply by holding \(earnTokenString) token, you will earn interest."
      self.delegate?.earnConfirmViewController(self, didConfirm: self.viewModel.transaction, amount: self.viewModel.amountString, netAPY: self.viewModel.netAPYString, platform: self.viewModel.platform, historyTransaction: historyTransaction)
    }
    
  }
}

extension EarnConfirmViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.platform.isCompound ? 650 : 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
