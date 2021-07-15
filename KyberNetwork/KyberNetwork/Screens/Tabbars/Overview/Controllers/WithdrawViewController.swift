//
//  WithdrawViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/2/21.
//

import UIKit
import BigInt

class WithdrawViewModel {
  let platform: String
  let session: KNSession
  let balance: LendingBalance
  var withdrawableAmountBigInt: BigInt
  fileprivate(set) var gasPrice: BigInt = KNGasCoordinator.shared.standardKNGas
  fileprivate(set) var gasLimit: BigInt = KNGasConfiguration.earnGasLimitDefault
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  var amount: String = ""
  var isBearingTokenApproved: Bool = true
  var isUseGasToken: Bool = false
  var approvingTokenAddress: String?

  init(platform: String, session: KNSession, balance: LendingBalance) {
    self.platform = platform
    self.session = session
    self.balance = balance
    self.withdrawableAmountBigInt = BigInt(balance.supplyBalance) ?? BigInt(0)
  }
  
  var amountBigInt: BigInt {
    return self.amount.amountBigInt(decimals: self.balance.decimals) ?? BigInt(0)
  }
  
  var displayAmount: String {
    return self.amountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: self.balance.decimals)
  }
  
  var withdrawableAmountString: String {
    return self.withdrawableAmountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: self.balance.decimals)
  }
  
  var isAmountTooSmall: Bool {
    if self.balance.symbol == "ETH" { return false }
    return self.amountBigInt == BigInt(0)
  }

  var isAmountTooBig: Bool {
    return self.amountBigInt > self.withdrawableAmountBigInt
  }
  
  var allETHBalanceFee: BigInt {
    return self.gasPrice * self.gasLimit
  }
  
  var isEnoughFee: Bool {
    let ethBalance = BigInt(BalanceStorage.shared.balanceETH()) ?? BigInt(0)
    return ethBalance > self.transactionFee
  }
  
  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    default: return
    }
  }
  
  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }

  fileprivate func formatFeeStringFor(gasPrice: BigInt) -> String {
    let fee = gasPrice * self.gasLimit
    let feeString: String = fee.displayRate(decimals: 18)
    var typeString = ""
    switch self.selectedGasPriceType {
    case .superFast:
      typeString = "super.fast".toBeLocalised().uppercased()
    case .fast:
      typeString = "fast".toBeLocalised().uppercased()
    case .medium:
      typeString = "regular".toBeLocalised().uppercased()
    case .slow:
      typeString = "slow".toBeLocalised().uppercased()
    default:
      break
    }
    return "\(feeString) ETH (\(typeString))"
  }
  
  var gasFeeString: String {
    self.updateSelectedGasPriceType(self.selectedGasPriceType)
    return self.formatFeeStringFor(gasPrice: self.gasPrice)
  }
  
  var displayTitle: String {
    return "Withdraw".toBeLocalised() + " " + self.balance.symbol.uppercased()
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
  
  var displayWithdrawableAmount: String {
    return self.withdrawableAmountBigInt.string(decimals: self.balance.decimals, minFractionDigits: 0, maxFractionDigits: self.balance.decimals) + " " + self.balance.symbol.uppercased()
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

enum WithdrawViewEvent {
  case getWithdrawableAmount(platform: String, userAddress: String, tokenAddress: String)
  case buildWithdrawTx(platform: String, token: String, amount: String, gasPrice: String, useGasToken: Bool, historyTransaction: InternalHistoryTransaction)
  case updateGasLimit(platform: String, token: String, amount: String, gasPrice: String, useGasToken: Bool)
  case checkAllowance(tokenAddress: String)
  case sendApprove(tokenAddress: String, remain: BigInt, symbol: String)
  case openGasPriceSelect(gasLimit: BigInt, selectType: KNSelectedGasPriceType)
}

protocol WithdrawViewControllerDelegate: class {
  func withdrawViewController(_ controller: WithdrawViewController, run event: WithdrawViewEvent)
}

class WithdrawViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var amountFIeld: UITextField!
  @IBOutlet weak var ethFeeLabel: UILabel!
  @IBOutlet weak var usdFeeLabel: UILabel!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var withdrawButton: UIButton!
  @IBOutlet weak var withdrawableAmountLabel: UILabel!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var transactionGasPriceLabel: UILabel!
  
  let transitor = TransitionDelegate()
  let viewModel: WithdrawViewModel
  weak var delegate: WithdrawViewControllerDelegate?
  
  init(viewModel: WithdrawViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WithdrawViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.loadWithdrawableAmount()
    self.loadAllowance()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.updateUIforWithdrawButton()
    self.updateUIWithdrawableAmount()
    self.updateUIFee()
  }
  
  fileprivate func updateUIFee() {
    self.ethFeeLabel.text = self.viewModel.feeETHString
    self.usdFeeLabel.text = self.viewModel.feeUSDString
    self.transactionGasPriceLabel.text = self.viewModel.transactionGasPriceString
  }
  
  fileprivate func updateUIWithdrawableAmount() {
    self.withdrawableAmountLabel.text = self.viewModel.displayWithdrawableAmount
  }
  
  fileprivate func setupUI() {
    self.titleLabel.text = self.viewModel.displayTitle
    self.updateUIFee()
    self.updateUIWithdrawableAmount()
    self.tokenButton.setTitle(self.viewModel.balance.symbol.uppercased(), for: .normal)
    self.withdrawButton.rounded(radius: 16)
    self.updateUIforWithdrawButton()
    self.cancelButton.rounded(radius: 16)
  }
  
  fileprivate func loadWithdrawableAmount() {
    self.delegate?.withdrawViewController(self, run: .getWithdrawableAmount(platform: self.viewModel.platform, userAddress: self.viewModel.session.wallet.address.description, tokenAddress: self.viewModel.balance.address))
  }
  
  fileprivate func buildTx() {
    let description = "\(self.viewModel.displayAmount) \(self.viewModel.balance.interestBearingTokenSymbol) -> \(self.viewModel.displayAmount) \(self.viewModel.balance.symbol)"
    let historyTransaction = InternalHistoryTransaction(type: .withdraw, state: .pending, fromSymbol: self.viewModel.balance.symbol, toSymbol: self.viewModel.balance.interestBearingTokenSymbol, transactionDescription: description, transactionDetailDescription: "", transactionObj: SignTransactionObject(value: "",from: "", to: "", nonce: 0, data: Data(), gasPrice: "", gasLimit: "", chainID: 0))
    historyTransaction.transactionSuccessDescription = "\(self.viewModel.displayAmount) \(self.viewModel.balance.symbol)"
    
    self.delegate?.withdrawViewController(self, run: .buildWithdrawTx(platform: self.viewModel.platform, token: self.viewModel.balance.address, amount: self.viewModel.amountBigInt.description, gasPrice: self.viewModel.gasPrice.description, useGasToken: true, historyTransaction: historyTransaction))
  }
  
  fileprivate func loadAllowance() {
    self.delegate?.withdrawViewController(self, run: .checkAllowance(tokenAddress: self.viewModel.balance.interestBearingTokenAddress))
  }
  
  fileprivate func sendApprove() {
    self.delegate?.withdrawViewController(self, run: .sendApprove(tokenAddress: self.viewModel.balance.interestBearingTokenAddress.lowercased(), remain: BigInt(0), symbol: self.viewModel.balance.interestBearingTokenSymbol))
  }
  
  fileprivate func updateUIforWithdrawButton() {
    guard self.isViewLoaded else {
      return
    }
    if self.viewModel.isBearingTokenApproved {
      self.withdrawButton.setTitle("Withdraw".toBeLocalised(), for: .normal)
      self.withdrawButton.isEnabled = true
      self.withdrawButton.alpha = 1
    } else {
      self.withdrawButton.setTitle("Approve".toBeLocalised() + " " + self.viewModel.balance.interestBearingTokenSymbol.uppercased(), for: .normal)
      if self.viewModel.approvingTokenAddress == nil {
        self.withdrawButton.isEnabled = true
        self.withdrawButton.alpha = 1
      } else {
        self.withdrawButton.isEnabled = false
        self.withdrawButton.alpha = 0.2
      }
    }
  }
  
  fileprivate func updateGasLimit() {
    self.delegate?.withdrawViewController(self, run: .updateGasLimit(platform: self.viewModel.platform, token: self.viewModel.balance.address, amount: self.viewModel.amountBigInt.description, gasPrice: self.viewModel.gasPrice.description, useGasToken: true))
  }
  
  func coordinatorDidUpdateWithdrawableAmount(_ amount: String) {
    self.viewModel.withdrawableAmountBigInt = BigInt(amount) ?? BigInt(0)
    self.updateUIforWithdrawButton()
  }

  func coodinatorFailUpdateWithdrawableAmount() {
    self.loadWithdrawableAmount()
  }
  
  func coordinatorDidUpdateGasLimit(_ value: BigInt) {
    self.viewModel.gasLimit = value
    self.updateUIFee()
  }
  
  func coordinatorFailUpdateGasLimit() {
    self.updateGasLimit()
  }
  
  func coordinatorDidUpdateAllowance(token: String, allowance: BigInt) {
    if allowance.isZero {
      self.viewModel.isBearingTokenApproved = false
    } else {
      self.viewModel.isBearingTokenApproved = true
    }
    self.updateUIforWithdrawButton()
  }

  func coordinatorDidFailUpdateAllowance(token: String) {
    self.loadAllowance()
  }
  
  func coordinatorSuccessApprove(token: String) {
    self.viewModel.approvingTokenAddress = token
    self.viewModel.isBearingTokenApproved = false
    self.updateUIforWithdrawButton()
  }

  func coordinatorFailApprove(token: String) {
    self.showErrorMessage()
    self.viewModel.isBearingTokenApproved = false
    self.updateUIforWithdrawButton()
  }
  
  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateUIFee()
    self.updateGasLimit()
  }
  
  fileprivate func showErrorMessage() {
    self.showWarningTopBannerMessage(
      with: "",
      message: "Something went wrong, please try again later".toBeLocalised(),
      time: 2.0
    )
  }
  
  func coordinatorUpdateIsUseGasToken(_ status: Bool) {
    self.viewModel.isUseGasToken = status
  }
  
  @IBAction func withdrawButtonTapped(_ sender: UIButton) {
    if self.viewModel.isBearingTokenApproved {
      guard !self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) else { return }
      self.buildTx()
    } else {
      self.sendApprove()
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func selectGasPriceButtonTapped(_ sender: Any) {
    self.delegate?.withdrawViewController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType))
  }
  
  @IBAction func maxButtonTapped(_ sender: UIButton) {
    self.viewModel.amount = self.viewModel.withdrawableAmountString
    self.amountFIeld.text = self.viewModel.withdrawableAmountString
    self.updateGasLimit()
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.checkUpdateApproveButton()
  }
  
  fileprivate func checkUpdateApproveButton() {
    guard let tokenAddress = self.viewModel.approvingTokenAddress else {
      return
    }
    if EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty {
      self.viewModel.isBearingTokenApproved = true
      self.viewModel.approvingTokenAddress = nil
      self.updateUIforWithdrawButton()
      
    }
    let pending = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().filter({ (item) -> Bool in
      return item.transactionDetailDescription.lowercased() == tokenAddress.lowercased() && item.type == .allowance
    })
    if pending.isEmpty {
      self.viewModel.isBearingTokenApproved = true
      self.viewModel.approvingTokenAddress = nil
      self.updateUIforWithdrawButton()
    }
  }
}

extension WithdrawViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension WithdrawViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.amount = ""
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.amountFIeld, cleanedText.amountBigInt(decimals: self.viewModel.balance.decimals) == nil { return false }
    textField.text = cleanedText
        self.viewModel.amount = cleanedText
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    _ = self.showWarningInvalidAmountDataIfNeeded()
    self.updateGasLimit()
  }

  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming { return false }
    guard !self.viewModel.amount.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid input", comment: ""),
        message: NSLocalizedString("please.enter.an.amount.to.continue", value: "Please enter an amount to continue", comment: "")
      )
      return true
    }
    guard self.viewModel.isEnoughFee else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("Insufficient ETH for transaction", value: "Insufficient ETH for transaction", comment: ""),
        message: String(format: "Deposit more ETH or click Advanced to lower GAS fee".toBeLocalised(), self.viewModel.transactionFee.shortString(units: .ether, maxFractionDigits: 6))
      )
      return true
    }

    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: NSLocalizedString("amount.to.send.greater.than.zero", value: "Amount to transfer should be greater than zero", comment: "")
      )
      return true
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not be enough to make the transaction.", comment: "")
      )
      return true
    }
    return false
  }
}
