// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNBuyKNCViewController: KNBaseViewController {
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
    _ = self.validateDataIfNeeded()
  }

  func coordinatorMarketCachedDidUpdate() {
    self.viewModel.updateMarket()
  }

  fileprivate func showWarningWalletIsNotSupportedIfNeeded() -> Bool {
    if KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.viewModel.walletObject.address) != nil {
      // it is a promo code wallet
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", comment: ""),
        message: "You cannot submit order with promo code. Please use other wallets.".toBeLocalised(),
        time: 2.0
      )
      return true
    }
    return false
  }

  fileprivate func validateDataIfNeeded(isConfirming: Bool = false) -> Bool {
    
    if !isConfirming && (self.totalField.isEditing || self.amountField.isEditing) { return false }
    guard self.viewModel.from != self.viewModel.to else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Source token must be different from dest token".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard self.viewModel.isBalanceEnough else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: "Your balance is insufficent for the order. Please check your balance and your pending order".toBeLocalised()
      )
      return false
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Amount is too big. Limit order only support max 10 ETH equivalent order".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard !(self.viewModel.isAmountTooSmall && !self.viewModel.amountFrom.isEmpty && !self.viewModel.amountTo.isEmpty) else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Amount is too small. Limit order only support min 0.1 ETH equivalent order".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard !self.viewModel.isRateTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Your target rate should be greater than 0".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard !self.viewModel.isRateTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Your target rate is too high, should be at most 10 times of current rate".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    if isConfirming {
      if self.viewModel.amountFrom.isEmpty {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
          message: "Please enter an amount to continue".toBeLocalised(),
          time: 1.5
        )
        return false
      }
      if self.viewModel.amountTo.isEmpty || self.viewModel.targetPrice.isEmpty {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
          message: "Please enter your target rate to continue".toBeLocalised(),
          time: 1.5
        )
        return false
      }
      if self.showWarningWalletIsNotSupportedIfNeeded() { return false }
    }
    return true
  }
  
  fileprivate func validateUserHasSignedIn() -> Bool {
    if IEOUserStorage.shared.user == nil {
      // user not sign in
      self.tabBarController?.selectedIndex = 3
      KNAppTracker.updateShouldOpenLimitOrderAfterSignedIn(true)
      self.showWarningTopBannerMessage(
        with: "Sign in required".toBeLocalised(),
        message: "You must sign in to use Limit Order feature".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    return true
  }

  @IBAction func sumitButtonTapped(_ sender: UIButton) {
    if !self.validateUserHasSignedIn() { return }
    if !self.validateDataIfNeeded(isConfirming: true) { return }
    //TODO: show eth convert weth screen
    
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

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.validateDataIfNeeded()
    }
  }
}
