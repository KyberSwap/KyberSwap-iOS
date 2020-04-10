// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNCreateLimitOrderV2ViewController: KNBaseViewController {
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

  weak var delegate: LimitOrderContainerViewControllerDelegate?

  private let viewModel: KNCreateLimitOrderV2ViewModel
  fileprivate var isViewSetup: Bool = false

  init(viewModel: KNCreateLimitOrderV2ViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNCreateLimitOrderV2ViewController.className, bundle: nil)
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

  fileprivate func bindMarketData() {
    self.priceField.text = self.viewModel.targetPriceFromMarket
    self.viewModel.updateTargetPrice(self.viewModel.targetPriceFromMarket)
    self.tokenAvailableLabel.text = "\(self.viewModel.balanceText) \(self.viewModel.fromSymbol)"
    self.toSymLabel.text = self.viewModel.isBuy ? self.viewModel.toSymBol : self.viewModel.fromSymbol
    for label in self.fromSymLabels {
      label.text = self.viewModel.isBuy ? self.viewModel.fromSymbol : self.viewModel.toSymBol
    }
    if self.viewModel.isBuy {
      self.buySellButton.setTitle("\("Buy".toBeLocalised()) \(self.viewModel.toSymBol)", for: .normal)
    } else {
      self.buySellButton.setTitle("\("Sell".toBeLocalised()) \(self.viewModel.fromSymbol)", for: .normal)
      self.buySellButton.backgroundColor = UIColor.Kyber.red
    }
  }

  fileprivate func setupUI() {
    self.viewModel.updateMarket()
    self.bindMarketData()
    self.buySellButton.rounded(radius: 5)
  }

  func coordinatorUpdateMarket(market: KNMarket) {
    self.viewModel.updatePair(name: market.pair)
    guard isViewSetup else {
      return
    }
    self.bindMarketData()
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
      self.tokenAvailableLabel.text = "\(self.viewModel.balanceText) \(self.viewModel.fromSymbol)"
    }
  }

  func coordinatorUpdateEstimateFee(_ fee: Double, discount: Double, feeBeforeDiscount: Double, transferFee: Double) {
    self.viewModel.feePercentage = fee
    self.viewModel.discountPercentage = discount
    self.viewModel.feeBeforeDiscount = feeBeforeDiscount
    self.viewModel.transferFeePercent = transferFee
    self.updateFeeNotesUI()
  }

  fileprivate func updateEstimateFeeFromServer() {
    let event = KNCreateLimitOrderViewEventV2.estimateFee(
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
    var amountDisplay = ""
    switch sender.tag {
    case 1:
      amountDisplay = self.viewModel.amountFromWithPercentage(25).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
    case 2:
      amountDisplay = self.viewModel.amountFromWithPercentage(50).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
    case 3:
      amountDisplay = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
    default:
      break
    }
    if self.viewModel.isBuy {
      self.viewModel.updateAmountFrom(amountDisplay)
      self.totalField.text = amountDisplay
      self.amountField.text = self.viewModel.amountTo
    } else {
      self.viewModel.updateAmountFrom(amountDisplay)
      self.amountField.text = amountDisplay
      self.totalField.text = self.viewModel.amountTo
    }
    self.updateFeeNotesUI()
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
        message: "Your target price should be greater than 0".toBeLocalised(),
        time: 1.5
      )
      return false
    }
    guard !self.viewModel.isRateTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: "Your target price is too high, should be at most 10 times of current price".toBeLocalised(),
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
          message: "Please enter your target price to continue".toBeLocalised(),
          time: 1.5
        )
        return false
      }
      if self.viewModel.targetPriceBigInt == BigInt(0) {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
          message: "Please enter a valid target price to continue".toBeLocalised(),
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
    //TODO: show cancel suggestion if needed
    if showConvertETHToWETHIfNeeded() { return }
    self.submitOrderDidVerifyData()
  }

  fileprivate func showConvertETHToWETHIfNeeded() -> Bool {
    if !self.viewModel.isConvertingETHToWETHNeeded { return false }
    let amount: BigInt = {
      if !self.viewModel.from.isWETH && self.viewModel.isUseAllBalance { return self.viewModel.availableBalance }
      return self.viewModel.amountFromBigInt
    }()
    if case .real(let account) = self.viewModel.wallet.type {
      let order = KNLimitOrder(
        from: self.viewModel.from,
        to: self.viewModel.to,
        account: account,
        sender: self.viewModel.wallet.address,
        srcAmount: amount,
        targetRate: self.viewModel.targetPriceBigInt,
        fee: Int(round(self.viewModel.feePercentage * 1000000)), // fee send to server is multiple with 10^6
        transferFee: Int(round(self.viewModel.transferFeePercent * 1000000)), // fee send to server is multiple with 10^6
        nonce: "",
        isBuy: self.viewModel.isBuy
      )
      let confirmData = KNLimitOrderConfirmData(
        price: self.viewModel.targetPrice,
        amount: self.viewModel.isBuy ? self.viewModel.amountTo : self.viewModel.amountFrom,
        totalAmount: self.viewModel.isBuy ? self.viewModel.amountFrom : self.viewModel.amountTo,
        livePrice: self.viewModel.targetPriceFromMarket
      )
      let event = KNCreateLimitOrderViewEventV2.openConvertWETH(
        address: self.viewModel.walletObject.address,
        ethBalance: self.viewModel.balances[self.viewModel.eth.contract]?.value ?? BigInt(0),
        amount: self.viewModel.minAmountToConvert,
        pendingWETH: self.viewModel.pendingBalances["WETH"] as? Double ?? 0.0,
        order: order,
        confirmData: confirmData
      )
      self.delegate?.kCreateLimitOrderViewController(self, run: event)
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "show_convert_eth_weth"])
      return true
    }
    return false
  }

  fileprivate func submitOrderDidVerifyData() {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["info": "order_did_verify"])
    let amount: BigInt = {
      if !self.viewModel.from.isWETH && self.viewModel.isUseAllBalance { return self.viewModel.availableBalance }
      return self.viewModel.amountFromBigInt
    }()
    if case .real(let account) = self.viewModel.wallet.type {
      let order = KNLimitOrder(
        from: self.viewModel.from,
        to: self.viewModel.to,
        account: account,
        sender: self.viewModel.wallet.address,
        srcAmount: amount,
        targetRate: self.viewModel.targetPriceBigInt,
        fee: Int(round(self.viewModel.feePercentage * 1000000)), // fee send to server is multiple with 10^6
        transferFee: Int(round(self.viewModel.transferFeePercent * 1000000)), // fee send to server is multiple with 10^6,
        nonce: "",
        isBuy: self.viewModel.isBuy
      )
      let confirmData = KNLimitOrderConfirmData(
        price: self.viewModel.targetPrice,
        amount: self.viewModel.isBuy ? self.viewModel.amountTo : self.viewModel.amountFrom,
        totalAmount: self.viewModel.isBuy ? self.viewModel.amountFrom : self.viewModel.amountTo,
        livePrice: self.viewModel.targetPriceFromMarket
      )
      self.delegate?.kCreateLimitOrderViewController(self, run: .submitOrder(order: order, confirmData: confirmData))
    }
  }

  @IBAction func manageOrderButtonPressed(_ sender: Any) {
    self.delegate?.kCreateLimitOrderViewController(self, run: .manageOrders)
  }
}

extension KNCreateLimitOrderV2ViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()
    if textField == self.priceField {
      self.viewModel.updateTargetPrice(text)
      self.comparePriceLabel.attributedText = self.viewModel.displayRateCompareAttributedString
      self.totalField.text = self.viewModel.isBuy ? self.viewModel.amountFrom : self.viewModel.amountTo
    } else if textField == self.amountField {
      if self.viewModel.isBuy {
        self.viewModel.updateAmountTo(text)
        self.totalField.text = self.viewModel.amountFrom
      } else {
        self.viewModel.updateAmountFrom(text)
        self.totalField.text = self.viewModel.amountTo
      }
      self.updateFeeNotesUI()
    } else if textField == self.totalField {
      if self.viewModel.isBuy {
        self.viewModel.updateAmountFrom(text)
        self.amountField.text = self.viewModel.amountTo
      } else {
        self.viewModel.updateAmountTo(text)
        self.amountField.text = self.viewModel.amountFrom
      }
      self.updateFeeNotesUI()
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
