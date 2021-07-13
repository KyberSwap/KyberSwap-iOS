//
//  WithdrawConfirmPopupViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/8/21.
//

import UIKit
import BigInt

protocol WithdrawAndClaimConfirmPopupViewModel: class {
  var displayBalance: NSAttributedString { get }
  var displayValue: String { get }
  var symbol: String { get }
  var isWithdraw: Bool { get }
  var lendingBalance: LendingBalance? { get }
}

class ClaimConfirmPopupViewModel: WithdrawAndClaimConfirmPopupViewModel {
  var lendingBalance: LendingBalance? {
    return nil
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.unclaimed) ?? BigInt(0)
  }
  
  var displayBalance: NSAttributedString {
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimal, minFractionDigits: 0, maxFractionDigits: 6)
    return NSAttributedString(string: balanceString + " " + "COMP")
  }
  
  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    let price = tokenPrice.usd
    return self.balanceBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(self.balance.decimal)
  }

  var displayValue: String {
    let string = self.valueBigInt.string(decimals: self.balance.decimal, minFractionDigits: 0, maxFractionDigits: 6)
    return "$" + string
  }
  
  var symbol: String {
    return "comp_icon"
  }
  
  var isWithdraw: Bool {
    return false
  }
  
  let balance: LendingDistributionBalance
  
  init(balance: LendingDistributionBalance) {
    self.balance = balance
  }
}

class WithdrawConfirmPopupViewModel: WithdrawAndClaimConfirmPopupViewModel {
  var lendingBalance: LendingBalance? {
    return self.balance
  }

  var balance: LendingBalance
  
  init(balance: LendingBalance) {
    self.balance = balance
  }
  
  var isWithdraw: Bool {
    return true
  }
  
  var balanceBigInt: BigInt {
    return BigInt(self.balance.supplyBalance) ?? BigInt(0)
  }

  var displayBalance: NSAttributedString {
    let balanceString = self.balanceBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    let rateString = String(format: "%.2f", self.balance.supplyRate * 100)
    let amountAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let apyAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: "\(balanceString) \(self.balance.symbol) ", attributes: amountAttributes))
    attributedText.append(NSAttributedString(string: "\(rateString)% APY", attributes: apyAttributes))
    return attributedText
  }
  
  var valueBigInt: BigInt {
    guard let tokenPrice = KNTrackerRateStorage.shared.getPriceWithAddress(self.balance.address) else { return BigInt(0) }
    let price = tokenPrice.usd
    return self.balanceBigInt * BigInt(price * pow(10.0, 18.0)) / BigInt(10).power(18)
  }
  
  var displayValue: String {
    let string = self.valueBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: 6)
    return "$" + string
  }

  var symbol: String {
    return self.balance.symbol
  }
}

protocol WithdrawConfirmPopupViewControllerDelegate: class {
  func withdrawConfirmPopupViewControllerDidSelectFirstButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?)
  func withdrawConfirmPopupViewControllerDidSelectSecondButton(_ controller: WithdrawConfirmPopupViewController, balance: LendingBalance?)
}

class WithdrawConfirmPopupViewController: KNBaseViewController {
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let viewModel: WithdrawAndClaimConfirmPopupViewModel
  weak var delegate: WithdrawConfirmPopupViewControllerDelegate?
  
  init(viewModel: WithdrawAndClaimConfirmPopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WithdrawConfirmPopupViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.iconImageView.setSymbolImage(symbol: self.viewModel.symbol, size: CGSize(width: 17, height: 17))
    self.balanceLabel.attributedText = self.viewModel.displayBalance
    self.valueLabel.text = self.viewModel.displayValue
    self.firstButton.rounded(radius: 16)
    self.secondButton.rounded(radius: 16)
    if self.viewModel.isWithdraw {
      self.firstButton.setTitle("Withdraw".toBeLocalised(), for: .normal)
      self.secondButton.setTitle("Supply More".toBeLocalised(), for: .normal)
      
      self.firstButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
      self.firstButton.titleLabel?.font = UIFont.Kyber.bold(with: 15)
      self.firstButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
      
      self.secondButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
      self.secondButton.titleLabel?.font = UIFont.Kyber.bold(with: 15)
      self.secondButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
    } else {
      
      self.firstButton.setTitle("Cancel".toBeLocalised(), for: .normal)
      self.secondButton.setTitle("Claim Reward".toBeLocalised(), for: .normal)
      
      self.firstButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
      self.firstButton.titleLabel?.font = UIFont.Kyber.regular(with: 16)
      self.firstButton.backgroundColor = UIColor(named: "navButtonBgColor")
      
      self.secondButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
      self.secondButton.titleLabel?.font = UIFont.Kyber.bold(with: 15)
      self.secondButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
    }
  }

  @IBAction func firstButtonTapped(_ sender: Any) {
    self.delegate?.withdrawConfirmPopupViewControllerDidSelectFirstButton(self, balance: self.viewModel.lendingBalance)
  }
  
  @IBAction func secondButtonTapped(_ sender: Any) {
    self.delegate?.withdrawConfirmPopupViewControllerDidSelectSecondButton(self, balance: self.viewModel.lendingBalance)
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
}

extension WithdrawConfirmPopupViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 190
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
