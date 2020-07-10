// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

//swiftlint:disable file_length
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
  @IBOutlet weak var relatedOrdersContainerView: UIView!
  @IBOutlet weak var relatedOrderContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var relatedOrderTextLabel: UILabel!
  @IBOutlet weak var relatedManageOrderButton: UIButton!
  @IBOutlet weak var relatedOrderCollectionView: UICollectionView!
  @IBOutlet weak var mainManagerOrderButtonHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var mainManageOrdersButton: UIButton!

  @IBOutlet weak var priceTextLabel: UILabel!
  @IBOutlet weak var amountTextLabel: UILabel!
  @IBOutlet weak var availableBalanceTextLabel: UILabel!
  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var totalTextLabel: UILabel!
  @IBOutlet weak var learnMoreButton: UIButton!
  @IBOutlet weak var containerScrollView: UIScrollView!

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
    self.updatePendingBalancesFromServer()
    self.updateRelatedOrdersFromServer()
    self.updateFeeTimer?.invalidate()
    self.updateFeeTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.updateEstimateFeeFromServer()
        self?.updatePendingBalancesFromServer()
        self?.updateRelatedOrdersFromServer()
      }
    )
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
    self.updateFeeTimer?.invalidate()
    self.updateFeeTimer = nil
  }

  fileprivate func bindMarketData() {
    self.priceField.text = self.viewModel.targetPriceFromMarket
    self.viewModel.updateTargetPrice(self.viewModel.targetPriceFromMarket)
    self.feeLabel.text = self.viewModel.displayFeeString
    self.tokenAvailableLabel.text = "\(self.viewModel.balanceText) \(self.viewModel.fromSymbol)"
    self.toSymLabel.text = self.viewModel.isBuy ? self.viewModel.toSymBol : self.viewModel.fromSymbol
    for label in self.fromSymLabels {
      label.text = self.viewModel.isBuy ? self.viewModel.fromSymbol : self.viewModel.toSymBol
    }
    if self.viewModel.isBuy {
      let localisedString = String(format: "Buy %@".toBeLocalised(), self.viewModel.toSymBol)
      self.buySellButton.setTitle(localisedString, for: .normal)
      self.buySellButton.backgroundColor = UIColor.Kyber.marketGreen
    } else {
      let localisedString = String(format: "Sell %@".toBeLocalised(), self.viewModel.fromSymbol)
      self.buySellButton.setTitle(localisedString, for: .normal)
      self.buySellButton.backgroundColor = UIColor.Kyber.marketRed
    }
  }

  fileprivate func setupUI() {
    self.viewModel.updateMarket()
    self.bindMarketData()
    self.buySellButton.rounded(radius: 5)
    self.discountPercentContainerView.rounded(radius: 5)
    let orderCellNib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.relatedOrderCollectionView.register(
      orderCellNib,
      forCellWithReuseIdentifier: KNLimitOrderCollectionViewCell.cellID
    )
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.relatedOrderCollectionView.register(
      headerNib,
      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
      withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID
    )
    self.priceTextLabel.text = "Price".toBeLocalised().uppercased()
    self.amountTextLabel.text = "Amount".toBeLocalised().uppercased()
    self.totalTextLabel.text = "Total".toBeLocalised().uppercased()
    self.availableBalanceTextLabel.text = "Available Balance".toBeLocalised().uppercased()
    self.feeTextLabel.text = NSLocalizedString("fee", value: "Fee", comment: "")
    self.learnMoreButton.setTitle("Learn more".toBeLocalised(), for: .normal)
    self.mainManageOrdersButton.setTitle("Manage Orders".toBeLocalised(), for: .normal)
    self.relatedManageOrderButton.setTitle("Manage Orders".toBeLocalised(), for: .normal)
    self.relatedOrderTextLabel.text = "Related Orders".toBeLocalised().uppercased()
    self.updateRelatedOrdersView()
  }

  func coordinatorUpdateMarket(market: KNMarket) {
    guard self.viewModel.updatePair(name: market.pair) else {
      return
    }
    self.resetAmountAndTotalField()
    guard isViewSetup else {
      return
    }
    self.bindMarketData()
    self.comparePriceLabel.attributedText = NSMutableAttributedString()
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

  func coordinatorDoneSubmittingOrder() {
    // update data new order has been submitted successfully
    self.updateRelatedOrdersView()
    self.updateRelatedOrdersFromServer()
    self.updatePendingBalancesFromServer()
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
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_learnmore", customAttributes: nil)
    let url = "\(KNEnvironment.default.profileURL)/faq#I-have-KNC-in-my-wallet-Do-I-get-any-discount-on-trading-fees"
    self.navigationController?.openSafari(with: url)
  }

  @IBAction func quickFillAmountButtonTapped(_ sender: UIButton) {
    self.updateEstimateFeeFromServer()
    var amountDisplay = ""
    switch sender.tag {
    case 1:
      KNCrashlyticsUtil.logCustomEvent(withName: "lo_25_percent_tapped", customAttributes: nil)
      amountDisplay = self.viewModel.amountFromWithPercentage(25).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
    case 2:
      KNCrashlyticsUtil.logCustomEvent(withName: "lo_50_percent_tapped", customAttributes: nil)
      amountDisplay = self.viewModel.amountFromWithPercentage(50).string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
    case 3:
      KNCrashlyticsUtil.logCustomEvent(withName: "lo_100_percent_tapped", customAttributes: nil)
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
    KNCrashlyticsUtil.logCustomEvent(withName: self.viewModel.isBuy ? "lo_buy_tapped" : "lo_sell_tapped",
                                     customAttributes: ["current_pair": self.viewModel.currentPair,
                                                        "src_amount": self.viewModel.amountFrom,
                                                        "des_amount": self.viewModel.amountTo,
                                                        "lo_price": self.viewModel.targetPrice,
      ]
    )
    if !self.validateUserHasSignedIn() { return }
    if !self.validateDataIfNeeded(isConfirming: true) { return }
    if self.showShouldCancelOtherOrdersIfNeeded() { return }
    if showConvertETHToWETHIfNeeded() { return }
    self.submitOrderDidVerifyData()
  }

  fileprivate func showShouldCancelOtherOrdersIfNeeded() -> Bool {
    if self.viewModel.cancelSuggestOrders.isEmpty { return false }
    let event = KNCreateLimitOrderViewEventV2.openCancelSuggestOrder(
      header: self.viewModel.cancelSuggestHeaders,
      sections: self.viewModel.cancelSuggestSections,
      cancelOrder: self.viewModel.cancelOrder,
      parent: self
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
    return true
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
      KNCrashlyticsUtil.logCustomEvent(withName: "lo_show_convert_eth_weth", customAttributes: nil)
      return true
    }
    return false
  }

  fileprivate func submitOrderDidVerifyData() {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_order_did_verify", customAttributes: nil)
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
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_manager_orders_tapped", customAttributes: nil)
    self.delegate?.kCreateLimitOrderViewController(self, run: .manageOrders)
  }

  fileprivate func updatePendingBalancesFromServer() {
    let event = KNCreateLimitOrderViewEventV2.getPendingBalances(
      address: self.viewModel.walletObject.address.lowercased()
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  func coordinatorUpdatePendingBalances(address: String, balances: JSONDictionary) {
    self.viewModel.updatePendingBalances(balances, address: address)
    guard self.isViewSetup else {
      return
    }
    self.tokenAvailableLabel.text = "\(self.viewModel.balanceText) \(self.viewModel.fromSymbol)"
    self.view.layoutIfNeeded()
  }

  fileprivate func updateRelatedOrdersFromServer() {
    let event = KNCreateLimitOrderViewEventV2.getRelatedOrders(
      address: self.viewModel.walletObject.address.lowercased(),
      src: self.viewModel.from.contract.lowercased(),
      dest: self.viewModel.to.contract.lowercased(),
      minRate: 0.0
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  func coordinatorUpdateListRelatedOrders(address: String, src: String, dest: String, minRate: Double, orders: [KNOrderObject]) {
    if address.lowercased() == self.viewModel.walletObject.address.lowercased()
    && src.lowercased() == self.viewModel.from.contract.lowercased()
      && dest.lowercased() == self.viewModel.to.contract.lowercased() {
      self.viewModel.updateRelatedOrders(orders)
      self.updateRelatedOrdersView()
    }
  }
  fileprivate func updateRelatedOrdersView() {
    guard self.isViewSetup else { return }
    let numberOrders = self.viewModel.relatedOrders.count
    if numberOrders > 0 {
      let orderCellHeight = KNLimitOrderCollectionViewCell.kLimitOrderCellHeight // height + bottom padding
      let headerCellHeight = CGFloat(44.0)
      let numberHeaders = self.viewModel.relatedHeaders.count
      self.relatedOrderContainerViewHeightConstraint.constant = 32.0 + CGFloat(numberOrders) * orderCellHeight + CGFloat(numberHeaders) * headerCellHeight // top padding + collection view height
      self.mainManagerOrderButtonHeightContraint.constant = 0
      self.mainManageOrdersButton.isHidden = true
      self.relatedOrdersContainerView.isHidden = false
      self.relatedOrderCollectionView.reloadData()
    } else {
      self.relatedOrdersContainerView.isHidden = true
      self.relatedOrderCollectionView.reloadData()
      self.relatedOrderContainerViewHeightConstraint.constant = 0
      self.mainManagerOrderButtonHeightContraint.constant = 45
      self.mainManageOrdersButton.isHidden = false
    }
  }

  func coordinatorUnderstandCheckedInShowCancelSuggestOrder() {
    if showConvertETHToWETHIfNeeded() { return }
    self.submitOrderDidVerifyData()
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    guard self.isViewSetup else { return }
    self.priceField.text = self.viewModel.targetPriceFromMarket
    self.totalField.text = ""
    self.amountField.text = ""
    self.tokenAvailableLabel.text = "\(self.viewModel.balanceText) \(self.viewModel.fromSymbol)"
  }

  func coordinatorFinishConfirmOrder() {
    self.resetAmountAndTotalField()
  }

  fileprivate func resetAmountAndTotalField() {
    self.viewModel.updateAmountTo("")
    self.viewModel.updateAmountFrom("")
    guard self.isViewSetup else { return }
    self.amountField.text = ""
    self.totalField.text = ""
    self.feeLabel.text = self.viewModel.displayFeeString
  }

  @IBAction func marketPriceButtonTapped(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_fill_market_price_tapped", customAttributes: nil)
    self.priceField.text = self.viewModel.targetPriceFromMarket
    self.viewModel.updateTargetPrice(self.viewModel.targetPriceFromMarket)
    self.comparePriceLabel.attributedText = self.viewModel.displayRateCompareAttributedString
    self.totalField.text = self.viewModel.isBuy ? self.viewModel.amountFrom : self.viewModel.amountTo
  }

  func containerEventTapPriceLabel() {
    guard self.isViewSetup else { return }
    self.marketPriceButtonTapped(self)
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
    textField.text = text
    self.updateEstimateFeeFromServer()
    return false
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateEstimateFeeFromServer()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.validateDataIfNeeded()
    }
  }
}

extension KNCreateLimitOrderV2ViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
  }
}

extension KNCreateLimitOrderV2ViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.relatedHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let date = self.viewModel.relatedHeaders[section]
    return self.viewModel.relatedSections[date]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
    withReuseIdentifier: KNLimitOrderCollectionViewCell.cellID,
    for: indexPath
    ) as! KNLimitOrderCollectionViewCell
    let order: KNOrderObject = {
      if collectionView == self.relatedOrderCollectionView {
        let date = self.viewModel.relatedHeaders[indexPath.section]
        let orders: [KNOrderObject] = self.viewModel.relatedSections[date] ?? []
        return orders[indexPath.row]
      }
      let date = self.viewModel.cancelSuggestHeaders[indexPath.section]
      let orders: [KNOrderObject] = self.viewModel.cancelSuggestSections[date] ?? []
      return orders[indexPath.row]
    }()
    let isReset: Bool = {
      if let cancelBtnOrder = self.viewModel.cancelOrder {
        return cancelBtnOrder.id != order.id
      }
      return true
    }()
    let color: UIColor = {
      return indexPath.row % 2 == 0 ? UIColor.white : UIColor(red: 246, green: 247, blue: 250)
    }()
    cell.updateCell(
      with: order,
      isReset: isReset,
      hasAction: order.state == .open,
      bgColor: color
    )
    cell.delegate = self
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID, for: indexPath) as! KNTransactionCollectionReusableView
      let headerText: String = {
        return self.viewModel.relatedHeaders[indexPath.section]
      }()
      headerView.updateView(with: headerText)
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

// MARK: Related orders
extension KNCreateLimitOrderV2ViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNLimitOrderCollectionViewCell.kLimitOrderCellHeight
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 44
    )
  }
}

extension KNCreateLimitOrderV2ViewController: KNLimitOrderCollectionViewCellDelegate {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject) {
    let date = self.viewModel.displayDate(for: order)
    guard let section = self.viewModel.relatedHeaders.firstIndex(where: { $0 == date }),
      let row = self.viewModel.relatedSections[date]?.firstIndex(where: { $0.id == order.id }) else {
      return // order not exist
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_open_cancel_order", customAttributes: nil)
    self.openCancelOrder(order) {
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: row, section: section)
      self.relatedOrderCollectionView.reloadItems(at: [indexPath])
    }
  }

  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, showWarning order: KNOrderObject) {
    self.showTopBannerView(
      with: "",
      message: order.messages,
      icon: UIImage(named: "warning_icon"),
      time: 2.5
    )
  }

  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, showExtraExplain order: KNOrderObject) {
    // This case won't happend as it is only for filled order with extra amount
  }

  fileprivate func openCancelOrder(_ order: KNOrderObject, completion: (() -> Void)?) {
   let cancelOrderVC = KNCancelOrderConfirmPopUp(order: order)
   cancelOrderVC.loadViewIfNeeded()
   cancelOrderVC.modalTransitionStyle = .crossDissolve
   cancelOrderVC.modalPresentationStyle = .overFullScreen
   cancelOrderVC.delegate = self
   self.present(cancelOrderVC, animated: true, completion: completion)
  }
}

extension KNCreateLimitOrderV2ViewController: KNCancelOrderConfirmPopUpDelegate {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_confirm_cancel", customAttributes: nil)
    self.updateRelatedOrdersFromServer()
    self.updatePendingBalancesFromServer()
  }
}
