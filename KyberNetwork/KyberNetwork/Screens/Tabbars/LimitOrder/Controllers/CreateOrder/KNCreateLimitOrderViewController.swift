// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length
import UIKit
import BigInt

enum KNCreateLimitOrderViewEvent {
  case searchToken(from: TokenObject, to: TokenObject, isSource: Bool, pendingBalances: JSONDictionary)
  case estimateRate(from: TokenObject, to: TokenObject, amount: BigInt, showWarning: Bool)
  case submitOrder(order: KNLimitOrder)
  case manageOrders
  case estimateFee(address: String, src: String, dest: String, srcAmount: Double, destAmount: Double)
  case getExpectedNonce(address: String, src: String, dest: String)
  case openConvertWETH(address: String, ethBalance: BigInt, amount: BigInt, pendingWETH: Double, order: KNLimitOrder)
  case getRelatedOrders(address: String, src: String, dest: String, minRate: Double)
  case getPendingBalances(address: String)
}

protocol KNCreateLimitOrderViewControllerDelegate: class {
  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNCreateLimitOrderViewEvent)
  func kCreateLimitOrderViewController(_ controller: KNCreateLimitOrderViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

class KNCreateLimitOrderViewController: KNBaseViewController {

  let kCancelOrdersCollectionViewCellID: String = "kCancelOrdersCollectionViewCellID"

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var limitOrderTextLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var hasPendingTxView: UIView!

  @IBOutlet weak var tokenDateContainerView: UIView!
  @IBOutlet weak var fromTokenButton: UIButton!
  @IBOutlet weak var fromTokenInfoButton: UIButton!
  @IBOutlet weak var fromAmountTextField: UITextField!
  @IBOutlet weak var toTokenButton: UIButton!
  @IBOutlet weak var toAmountTextField: UITextField!

  @IBOutlet weak var sourceBalanceTextLabel: UILabel!
  @IBOutlet weak var sourceBalanceValueLabel: UILabel!

  @IBOutlet var percentageButtons: [UIButton]!

  @IBOutlet weak var rateContainerView: UIView!

  @IBOutlet weak var rateOfTextLabel: UILabel!
  @IBOutlet weak var pairTokensLabel: UILabel!
  @IBOutlet weak var targetRateTextField: UITextField!

  @IBOutlet weak var currentRateLabel: UILabel!
  @IBOutlet weak var compareMarketRateLabel: UILabel!
  @IBOutlet weak var marketRateButton: UIButton!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeNoteLabel: UILabel!
  @IBOutlet weak var suggestBuyTopPaddingConstraint: NSLayoutConstraint!
  @IBOutlet weak var discountPercentLabel: UILabel!
  @IBOutlet weak var suggestBuyTokenButton: UIButton!
  @IBOutlet weak var loadingFeeIndicator: UIActivityIndicatorView!

  @IBOutlet weak var submitOrderButton: UIButton!

  @IBOutlet weak var relatedOrdersContainerView: UIView!
  @IBOutlet weak var relatedOrderContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var relatedOrderTextLabel: UILabel!
  @IBOutlet weak var relatedManageOrderButton: UIButton!

  @IBOutlet weak var manageOrdersButton: UIButton!

  @IBOutlet weak var cancelRelatedOrdersView: UIView!
  @IBOutlet weak var warningMessageLabel: UILabel!
  @IBOutlet weak var whyButton: UIButton!
  @IBOutlet weak var selectUnderstandButton: UIButton!
  @IBOutlet weak var iunderstandButton: UIButton!
  @IBOutlet weak var cancelOrdersCollectionView: UICollectionView!
  @IBOutlet weak var confirmCancelButton: UIButton!
  @IBOutlet weak var noCancelButton: UIButton!
  @IBOutlet weak var cancelOrdersCollectionViewHeightConstraint: NSLayoutConstraint!

  fileprivate var isViewSetup: Bool = false
  fileprivate var isErrorMessageEnabled: Bool = false
  fileprivate var isUnderStand: Bool = false
  fileprivate var viewModel: KNCreateLimitOrderViewModel
  weak var delegate: KNCreateLimitOrderViewControllerDelegate?
  fileprivate var updateFeeTimer: Timer?

  @IBOutlet var submitButtonBottomPaddingToRelatedOrderViewConstraint: NSLayoutConstraint!
  @IBOutlet var submitButtonBottomPaddingToContainerViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var scrollViewBottomPaddingConstraints: NSLayoutConstraint!

  @IBOutlet weak var relatedOrderCollectionView: UICollectionView!
  @IBOutlet weak var targetReverseRateLabel: UILabel!

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    let viewModel = KNBalanceTabHamburgerMenuViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: "All Balance".toBeLocalised(),
      rightBtnTitle: NSLocalizedString("done", value: "Done", comment: ""),
      barTintColor: UIColor.Kyber.enygold,
      delegate: self)
  }()

  init(viewModel: KNCreateLimitOrderViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNCreateLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.submitOrderButton.applyGradient()
    self.setupUI()
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
    self.isErrorMessageEnabled = true
    self.updateEstimateRateFromNetwork(showWarning: false)

    self.listOrdersDidUpdate(nil)
    self.updateRelatedOrdersFromServer()
    self.updatePendingBalancesFromServer()
    self.updateEstimateFeeFromServer(isShowingIndicator: true)

    self.updateFeeTimer?.invalidate()
    self.updateFeeTimer = Timer.scheduledTimer(
      withTimeInterval: 10.0,
      repeats: true,
      block: { [weak self] _ in
        self?.updateEstimateFeeFromServer()
        self?.updateRelatedOrdersFromServer()
        self?.updatePendingBalancesFromServer()
      }
    )

    if self.tabBarController?.selectedIndex == 2 {
      self.checkAddressEligible(nil)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
    self.submitOrderButton.removeSublayer(at: 0)
    self.submitOrderButton.applyGradient()
    self.confirmCancelButton.removeSublayer(at: 0)
    self.confirmCancelButton.applyGradient()
    self.percentageButtons.forEach { $0.addShadow() }
    self.marketRateButton.addShadow()

    self.tokenDateContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
    self.rateContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 4),
      opacity: 0.16,
      radius: 16
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isErrorMessageEnabled = false
    self.view.endEditing(true)
    self.updateFeeTimer?.invalidate()
    self.updateFeeTimer = nil
  }

  fileprivate func setupUI() {
    self.walletNameLabel.text = self.viewModel.walletNameString

    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.border)
    self.separatorView.backgroundColor = .clear
    self.submitOrderButton.rounded(radius: self.submitOrderButton.frame.height / 2.0)
    self.submitOrderButton.setTitle("Submit Order".toBeLocalised(), for: .normal)

    self.rateOfTextLabel.text = "Rate of".toBeLocalised()
    self.tokenDateContainerView.rounded(radius: 4.0)
    self.fromAmountTextField.text = ""
    self.fromAmountTextField.adjustsFontSizeToFitWidth = true
    self.fromAmountTextField.inputAccessoryView = self.toolBar
    self.fromAmountTextField.delegate = self

    self.toAmountTextField.text = ""
    self.toAmountTextField.adjustsFontSizeToFitWidth = true
    self.toAmountTextField.inputAccessoryView = self.toolBar
    self.toAmountTextField.delegate = self

    let tapBalanceGesture = UITapGestureRecognizer(target: self, action: #selector(self.balanceLabelTapped(_:)))
    self.sourceBalanceValueLabel.isUserInteractionEnabled = true
    self.sourceBalanceValueLabel.addGestureRecognizer(tapBalanceGesture)

    self.rateContainerView.rounded(radius: 4.0)
    self.targetRateTextField.text = ""
    self.targetRateTextField.adjustsFontSizeToFitWidth = true
    self.targetRateTextField.delegate = self

    self.percentageButtons.forEach({ $0.rounded(radius: 2.5) })

    self.marketRateButton.setTitle("Market Rate".toBeLocalised(), for: .normal)
    self.marketRateButton.titleLabel?.numberOfLines = 2
    self.marketRateButton.titleLabel?.textAlignment = .center
    self.marketRateButton.rounded(radius: 2.5)
    self.marketRateButton.addShadow()
    self.feeTextLabel.text = "\(NSLocalizedString("fee", value: "Fee", comment: "")):"
    self.discountPercentLabel.rounded(radius: self.discountPercentLabel.frame.height / 2.0)

    self.relatedOrderTextLabel.text = "Related Orders".toBeLocalised().uppercased()
    self.relatedManageOrderButton.setTitle("Manage Your Orders".toBeLocalised(), for: .normal)
    self.manageOrdersButton.setTitle("Manage Your Orders".toBeLocalised(), for: .normal)

    self.updateTokensView(updatedFrom: true, updatedTo: true)

    self.scrollViewBottomPaddingConstraints.constant = self.bottomPaddingSafeArea()

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
    self.relatedOrderCollectionView.delegate = self
    self.relatedOrderCollectionView.dataSource = self
    self.updateRelatedOrdersView()

    if let rate = self.viewModel.rateFromNode ?? self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.string(
        decimals: self.viewModel.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(8, self.viewModel.to.decimals)
      ).removeGroupSeparator()
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
      self.viewModel.updateFocusTextField(2)
    }
    // Update hamburger menu
    self.hasPendingTxView.rounded(radius: self.hasPendingTxView.frame.height / 2.0)
    self.hamburgerMenu.hideMenu(animated: false)

    let tapCurrentRate = UITapGestureRecognizer(target: self, action: #selector(self.currentRateDidTapped(_:)))
    self.currentRateLabel.addGestureRecognizer(tapCurrentRate)
    self.currentRateLabel.isUserInteractionEnabled = true

    self.warningMessageLabel.text = "By submitting this order, you also CANCEL the following orders:".toBeLocalised()
    self.whyButton.setTitle("Why?".toBeLocalised(), for: .normal)
    self.iunderstandButton.setTitle("I understand".toBeLocalised(), for: .normal)
    self.confirmCancelButton.setTitle("OK".toBeLocalised(), for: .normal)
    self.confirmCancelButton.rounded(
      radius: self.confirmCancelButton.frame.height / 2.0
    )
    self.confirmCancelButton.applyGradient()
    self.noCancelButton.setTitle("Change Rate".toBeLocalised(), for: .normal)
    self.cancelRelatedOrdersView.isHidden = true
    self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
    let nib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.cancelOrdersCollectionView.register(nib, forCellWithReuseIdentifier: kCancelOrdersCollectionViewCellID)
    self.cancelOrdersCollectionView.register(
      headerNib,
      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
      withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID
    )
    self.cancelOrdersCollectionView.delegate = self
    self.cancelOrdersCollectionView.dataSource = self

    self.checkAddressEligible(nil)
  }

  @IBAction func fromTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "from_token_b tn_clicked"])
    let event = KNCreateLimitOrderViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: true,
      pendingBalances: self.viewModel.pendingBalances
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  @IBAction func fromTokenInfoButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "from_token_info_btn_clicked"])
    self.showTopBannerView(
      with: "",
      message: "ETH* represents the sum of ETH & WETH for easy reference".toBeLocalised(),
      icon: UIImage(named: "info_blue_icon"),
      time: 3.0
    )
  }

  @IBAction func toTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "to_token_btn_clicked"])
    let event = KNCreateLimitOrderViewEvent.searchToken(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSource: false,
      pendingBalances: self.viewModel.pendingBalances
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  @IBAction func swapTokensButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "swap_2_tokens_btn_clicked"])
    if self.viewModel.to.isETH && self.viewModel.weth == nil {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "WETH (instead of ETH) is required to set a Limit Order to buy a token".toBeLocalised(),
        time: 2.0
      )
      return
    }
    if self.viewModel.from.isWETH && (self.viewModel.to.isETH || self.viewModel.to.isWETH) {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Source token must be different from dest token".toBeLocalised(),
        time: 1.5
      )
      return
    }
    self.viewModel.swapTokens()
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.updateTokensView()

    if let rate = self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.string(
        decimals: self.viewModel.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(8, self.viewModel.to.decimals)
      ).removeGroupSeparator()
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
    }

    self.listOrdersDidUpdate(nil)
    self.updateRelatedOrdersFromServer()

    self.updateEstimateRateFromNetwork(showWarning: true)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @IBAction func hamburgerMenuButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "hamburger_menu_pressed"])
    self.view.endEditing(true)
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func firstPercentageButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "25_percent_clicked"])
    let amountDisplay = self.viewModel.amountFromWithPercentage(25).string(
      decimals: self.viewModel.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.viewModel.from.decimals, 6)
    ).removeGroupSeparator()
    self.viewModel.updateAmount(amountDisplay, isSource: true)
    self.fromAmountTextField.text = amountDisplay
    self.viewModel.updateFocusTextField(0)
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
  }

  @IBAction func secondPercentageButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "50_percent_clicked"])
    let amountDisplay = self.viewModel.amountFromWithPercentage(50).string(
      decimals: self.viewModel.from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.viewModel.from.decimals, 6)
    ).removeGroupSeparator()
    self.viewModel.updateAmount(amountDisplay, isSource: true)
    self.fromAmountTextField.text = amountDisplay
    self.viewModel.updateFocusTextField(0)
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
  }

  @IBAction func thirdPercentageButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "100_percent_clicked"])
    self.keyboardSwapAllButtonPressed(sender)
  }

  @IBAction func suggestBuyTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "suggest_buy_clicked"])
    let url = "\(KNEnvironment.default.profileURL)/faq#I-have-KNC-in-my-wallet-Do-I-get-any-discount-on-trading-fees"
    self.navigationController?.openSafari(with: url)
  }

  @IBAction func submitOrderButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "submit_order_clicked"])
    if !self.validateUserHasSignedIn() { return }
    if !self.validateDataIfNeeded(isConfirming: true) { return }
    if self.showShouldCancelOtherOrdersIfNeeded() { return }
    if self.showConvertETHToWETHIfNeeded() { return }
    self.submitOrderDidVerifyData()
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
        targetRate: self.viewModel.targetRateBigInt,
        fee: Int(round(self.viewModel.feePercentage * 1000000)), // fee send to server is multiple with 10^6
        transferFee: Int(round(self.viewModel.transferFeePercent * 1000000)), // fee send to server is multiple with 10^6,
        nonce: self.viewModel.nonce ?? ""
      )
      self.delegate?.kCreateLimitOrderViewController(self, run: .submitOrder(order: order))
    }
  }

  @IBAction func manageOrderButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "manage_order_btn_clicked"])
    if !self.validateUserHasSignedIn() { return }
    self.delegate?.kCreateLimitOrderViewController(self, run: .manageOrders)
  }

  @objc func listOrdersDidUpdate(_ sender: Any?) {
    let orders = self.viewModel.relatedOrders.map({ return $0.clone() })
    let relatedOrders = orders.filter({
      return $0.sender.lowercased() == self.viewModel.walletObject.address.lowercased()
      && $0.srcTokenSymbol.lowercased() == self.viewModel.from.symbol.lowercased()
      && $0.destTokenSymbol.lowercased() == self.viewModel.to.symbol.lowercased()
      && ($0.state == .open || $0.state == .inProgress)
    })
    self.viewModel.updateRelatedOrders(relatedOrders)

    if !self.cancelRelatedOrdersView.isHidden {
      if self.viewModel.cancelSuggestOrders.isEmpty {
        self.cancelRelatedOrdersView.isHidden = true
        self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
        self.rateContainerView.rounded(radius: 4.0)
      } else {
        self.cancelOrdersCollectionView.reloadData()
      }
    }

    self.updateRelatedOrdersView()
    self.view.layoutIfNeeded()
  }

  @objc func keyboardSwapAllButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["type": "swap_all_btn_clicked"])
    self.view.endEditing(true)
    self.fromAmountTextField.text = self.viewModel.allFromTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.fromAmountTextField.text ?? "", isSource: true)
    self.viewModel.updateFocusTextField(0)
    self.updateTokensView()
    self.updateViewAmountDidChange()
    _ = self.validateDataIfNeeded()
    self.viewModel.isUseAllBalance = true
    self.view.layoutIfNeeded()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.view.layoutIfNeeded()
  }

  @objc func balanceLabelTapped(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "balance_label_tapped"])
    self.keyboardSwapAllButtonPressed(sender)
  }

  @IBAction func marketRateButtonPressed(_ sender: Any) {
    self.currentRateDidTapped(sender)
  }

  @objc func currentRateDidTapped(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "current_rate_label_tapped"])
    guard let rate = self.viewModel.rateFromNode else { return }
    let rateDisplay = rate.displayRate(decimals: self.viewModel.to.decimals).removeGroupSeparator()
    self.targetRateTextField.text = rateDisplay
    self.viewModel.updateTargetRate(rateDisplay)
    self.viewModel.updateFocusTextField(2)
    self.updateViewAmountDidChange()
  }

  @IBAction func confirmCancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "continue_cancelling_btn_clicked"])
    UIView.animate(withDuration: 0.16) {
      self.cancelRelatedOrdersView.isHidden = true
      self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
      self.updateRelatedOrdersView()
      self.rateContainerView.rounded(radius: 4.0)
      self.scrollContainerView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
      if self.showConvertETHToWETHIfNeeded() { return }
      self.submitOrderDidVerifyData()
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func noCancelButtonPressed(_ sender: Any?) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "change_rate_btn_clicked"])
    UIView.animate(withDuration: 0.16) {
      self.cancelRelatedOrdersView.isHidden = true
      self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
      self.updateRelatedOrdersView()
      self.rateContainerView.rounded(radius: 4.0)
      self.scrollContainerView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
      if sender != nil {
        self.targetRateTextField.becomeFirstResponder()
      }
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func reasonCancellingOrderButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "cancelling_why_btn_clicked"])
    let url = "\(KNEnvironment.default.profileURL)/faq#can-I-submit-multiple-limit-orders-for-same-token-pair"
    self.navigationController?.openSafari(with: url)
  }

  @IBAction func underStandButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "undertand_checked"])
    self.isUnderStand = !self.isUnderStand
    self.selectUnderstandButton.rounded(
      color: self.isUnderStand ? UIColor.clear : UIColor.Kyber.border,
      width: self.isUnderStand ? 0.0 : 1.0,
      radius: 2.5
    )
    self.selectUnderstandButton.setImage(
      self.isUnderStand ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.confirmCancelButton.isEnabled = self.isUnderStand
    self.confirmCancelButton.alpha = self.isUnderStand ? 1.0 : 0.5
  }
}

// MARK: Update UIs
extension KNCreateLimitOrderViewController {
  // Update related order view, hide or show related orders
  fileprivate func updateRelatedOrdersView() {
    if !self.cancelRelatedOrdersView.isHidden {
      self.submitButtonBottomPaddingToContainerViewConstraint.isActive = true
      self.submitButtonBottomPaddingToContainerViewConstraint.constant = 88.0
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.isActive = false
      self.relatedOrdersContainerView.isHidden = true
      self.manageOrdersButton.isHidden = false
      self.view.layoutIfNeeded()
      return
    }

    let numberOrders = self.viewModel.relatedOrders.count
    if numberOrders > 0 {
      self.submitButtonBottomPaddingToContainerViewConstraint.isActive = false
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.isActive = true
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.constant = 32.0
      let orderCellHeight = KNLimitOrderCollectionViewCell.kLimitOrderNormalHeight // height + bottom padding
      let headerCellHeight = CGFloat(44.0)
      let numberHeaders = self.viewModel.relatedHeaders.count
      self.relatedOrderContainerViewHeightConstraint.constant = 32.0 + CGFloat(numberOrders) * orderCellHeight + CGFloat(numberHeaders) * headerCellHeight // top padding + collection view height
      self.relatedOrdersContainerView.isHidden = false
      self.manageOrdersButton.isHidden = true
      self.relatedOrderCollectionView.reloadData()
    } else {
      self.submitButtonBottomPaddingToContainerViewConstraint.isActive = true
      self.submitButtonBottomPaddingToContainerViewConstraint.constant = 88.0
      self.submitButtonBottomPaddingToRelatedOrderViewConstraint.isActive = false
      self.relatedOrdersContainerView.isHidden = true
      self.manageOrdersButton.isHidden = false
    }
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.view.layoutIfNeeded()
  }

  // Update current martket rate with rate from node or cached
  fileprivate func updateCurrentMarketRateUI() {
    self.currentRateLabel.text = "\(self.viewModel.displayCurrentExchangeRate)"
    self.compareMarketRateLabel.attributedText = self.viewModel.displayRateCompareAttributedString
    self.targetReverseRateLabel.text = viewModel.displayTargetExchangeRate
  }

  // Update fee when source amount changed
  fileprivate func updateFeeNotesUI() {
    self.feeNoteLabel.attributedText = self.viewModel.feeNoteAttributedString
    self.discountPercentLabel.isHidden = !self.viewModel.isShowingDiscount
    self.discountPercentLabel.text = self.viewModel.displayDiscountPercentageString
    self.suggestBuyTopPaddingConstraint.constant = self.viewModel.suggestBuyTopPadding
    self.suggestBuyTokenButton.titleLabel?.numberOfLines = 2
    self.suggestBuyTokenButton.titleLabel?.lineBreakMode = .byTruncatingTail
    self.suggestBuyTokenButton.setAttributedTitle(self.viewModel.suggestBuyText, for: .normal)
  }

  // Call update estimate rate from node
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

  fileprivate func updateEstimateFeeFromServer(isShowingIndicator: Bool = false) {
    let event = KNCreateLimitOrderViewEvent.estimateFee(
      address: self.viewModel.walletObject.address,
      src: self.viewModel.from.contract,
      dest: self.viewModel.to.contract,
      srcAmount: Double(self.viewModel.amountFromBigInt) / pow(10.0, Double(self.viewModel.from.decimals)),
      destAmount: Double(self.viewModel.amountToBigInt) / pow(10.0, Double(self.viewModel.to.decimals))
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
    if isShowingIndicator {
      self.loadingFeeIndicator.startAnimating()
      self.loadingFeeIndicator.isHidden = false
    }
  }

  fileprivate func updateRelatedOrdersFromServer() {
    let event = KNCreateLimitOrderViewEvent.getRelatedOrders(
      address: self.viewModel.walletObject.address.lowercased(),
      src: self.viewModel.from.contract.lowercased(),
      dest: self.viewModel.to.contract.lowercased(),
      minRate: 0.0
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  fileprivate func updatePendingBalancesFromServer() {
    let event = KNCreateLimitOrderViewEvent.getPendingBalances(
      address: self.viewModel.walletObject.address.lowercased()
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  fileprivate func updateExpectedNonceFromServer() {
    let event = KNCreateLimitOrderViewEvent.getExpectedNonce(
      address: self.viewModel.walletObject.address,
      src: self.viewModel.from.contract,
      dest: self.viewModel.to.contract
    )
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }

  /*
   Update tokens view when either from or to tokens changed
   - updatedFrom: true if from token is changed
   - updatedTo: true if to token is changed
   */
  func updateTokensView(updatedFrom: Bool = true, updatedTo: Bool = true) {
    if updatedFrom {
      self.fromTokenButton.setAttributedTitle(
        self.viewModel.tokenButtonAttributedText(isSource: true),
        for: .normal
      )
      self.fromTokenButton.setTokenImage(
        token: self.viewModel.from.isWETH ? self.viewModel.eth : self.viewModel.from,
        size: self.viewModel.defaultTokenIconImg?.size
      )
      self.sourceBalanceTextLabel.text = self.viewModel.balanceTextString
      self.fromTokenInfoButton.isHidden = !(self.viewModel.from.isETH || self.viewModel.from.isWETH)
    }
    if updatedTo {
      self.toTokenButton.setAttributedTitle(
        self.viewModel.tokenButtonAttributedText(isSource: false),
        for: .normal
      )
      self.toTokenButton.setTokenImage(
        token: self.viewModel.to.isWETH ? self.viewModel.eth : self.viewModel.to,
        size: self.viewModel.defaultTokenIconImg?.size
      )
    }
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.pairTokensLabel.text = "\(self.viewModel.fromSymbol) ➞ \(self.viewModel.toSymbol)"

    self.updateCurrentMarketRateUI()
    self.updateFeeNotesUI()

    self.updateViewAmountDidChange()
    self.updateRelatedOrdersView()

    self.view.layoutIfNeeded()
  }
}

// MARK: Data validation
extension KNCreateLimitOrderViewController {
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

  fileprivate func validateDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && !self.isErrorMessageEnabled || !self.hamburgerMenu.view.isHidden { return false }
    if !isConfirming && (self.fromAmountTextField.isEditing || self.toAmountTextField.isEditing) { return false }
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
      if self.viewModel.amountTo.isEmpty || self.viewModel.targetRate.isEmpty {
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

  fileprivate func showShouldCancelOtherOrdersIfNeeded() -> Bool {
    if self.viewModel.cancelSuggestOrders.isEmpty { return false }
    self.rateContainerView.rounded(
      color: UIColor(red: 239, green: 129, blue: 2),
      width: 1.0,
      radius: 4.0
    )
    self.cancelRelatedOrdersView.isHidden = false
    self.cancelOrdersCollectionView.reloadData()

    let orderHeight = KNLimitOrderCollectionViewCell.kLimitOrderNormalHeight
    let headerHeight = CGFloat(44.0)
    let numberHeaders = self.viewModel.cancelSuggestHeaders.count
    let numberOrders = self.viewModel.cancelSuggestOrders.count
    self.cancelOrdersCollectionViewHeightConstraint.constant = orderHeight * CGFloat(numberOrders) + headerHeight * CGFloat(numberHeaders)

    self.isUnderStand = false
    self.selectUnderstandButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.selectUnderstandButton.setImage(
      nil,
      for: .normal
    )
    self.confirmCancelButton.isEnabled = false
    self.confirmCancelButton.alpha = 0.5

    self.scrollContainerView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    self.updateRelatedOrdersView()

    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "show_suggest_cancel_orders"])
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
        targetRate: self.viewModel.targetRateBigInt,
        fee: Int(round(self.viewModel.feePercentage * 1000000)), // fee send to server is multiple with 10^6
        transferFee: Int(round(self.viewModel.transferFeePercent * 1000000)), // fee send to server is multiple with 10^6
        nonce: self.viewModel.nonce ?? ""
      )
      let event = KNCreateLimitOrderViewEvent.openConvertWETH(
        address: self.viewModel.walletObject.address,
        ethBalance: self.viewModel.balances[self.viewModel.eth.contract]?.value ?? BigInt(0),
        amount: self.viewModel.minAmountToConvert,
        pendingWETH: self.viewModel.pendingBalances["WETH"] as? Double ?? 0.0,
        order: order
      )
      self.delegate?.kCreateLimitOrderViewController(self, run: event)
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "show_convert_eth_weth"])
      return true
    }
    return false
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

  @objc func checkAddressEligible(_ sender: Any?) {
    if self.tabBarController?.selectedIndex != 2 { return }
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    let address = self.viewModel.walletObject.address
    KNLimitOrderServerCoordinator.shared.checkEligibleAddress(accessToken: accessToken, address: address) { [weak self] result in
      guard let `self` = self else { return }
      if case .success(let eligile) = result, !eligile {
        // not eligible
        self.showWarningTopBannerMessage(
          with: "",
          message: "This address has been used by another account. Please place order with other address.".toBeLocalised(),
          time: 2.0
        )
      }
    }
  }
}

// MARK: Update from coordinator
extension KNCreateLimitOrderViewController {
  /*
   Update new session when current wallet is changed, update all UIs
   */
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.updateWallet(wallet)
    self.walletNameLabel.text = self.viewModel.walletNameString
    self.fromAmountTextField.text = ""
    self.toAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateTargetRate("")
    self.updateTokensView()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    self.hamburgerMenu.hideMenu(animated: false)
    // auto fill current rate
    if let rate = self.viewModel.rateFromNode ?? self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.string(
        decimals: self.viewModel.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(8, self.viewModel.to.decimals)
      ).removeGroupSeparator()
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
    }
    self.updateViewAmountDidChange()
    self.noCancelButtonPressed(nil)

    self.listOrdersDidUpdate(nil)
    self.updateEstimateFeeFromServer(isShowingIndicator: true)
    self.updateRelatedOrdersFromServer()
    self.updatePendingBalancesFromServer()

    if self.tabBarController?.selectedIndex == 2 {
      self.checkAddressEligible(nil)
    }
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateWalletObjects() {
    self.viewModel.updateWalletObject()
    self.walletNameLabel.text = self.viewModel.walletNameString
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.walletObject
    )
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.view.layoutIfNeeded()
  }

  /*
   Update estimate rate, check if the from, to, amount are all the same as current value in the model
   Update UIs according to new values
   */
  func coordinatorDidUpdateEstimateRate(from: TokenObject, to: TokenObject, amount: BigInt, rate: BigInt, slippageRate: BigInt) {
    let updated = self.viewModel.updateExchangeRate(
      for: from,
      to: to,
      amount: amount,
      rate: rate,
      slippageRate: slippageRate
    )
    if updated { self.updateCurrentMarketRateUI() }
    self.view.layoutIfNeeded()
  }

  /*
   Update selected token
   - token: New selected token
   - isSource: true if selected token is from, otherwise it is to
   Update UIs according to new values
   */
  func coordinatorUpdateSelectedToken(_ token: TokenObject, isSource: Bool, isWarningShown: Bool = true) {
    if isSource, !self.fromTokenButton.isEnabled { return }
    if !isSource, !self.toTokenButton.isEnabled { return }
    if isSource, self.viewModel.from == token { return }
    if !isSource, self.viewModel.to == token { return }
    if self.viewModel.from.isWETH, !isSource, token.isETH || token.isWETH {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Source token must be different from dest token".toBeLocalised(),
        time: 1.5
      )
      return
    }
    if isSource, token.isETH {
      if let wethToken = self.viewModel.weth {
        self.viewModel.updateSelectedToken(wethToken, isSource: isSource)
      } else {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
          message: "WETH (instead of ETH) is required to set a Limit Order to buy a token".toBeLocalised(),
          time: 2.0
        )
        return
      }
    } else if token.isETH, let wethToken = self.viewModel.weth {
      self.viewModel.updateSelectedToken(wethToken, isSource: isSource)
    } else {
      self.viewModel.updateSelectedToken(token, isSource: isSource)
    }
    if isSource && self.viewModel.focusTextFieldTag == 0 {
      self.viewModel.updateAmount("", isSource: isSource)
      self.fromAmountTextField.text = ""
    } else if !isSource && self.viewModel.focusTextFieldTag == 1 {
      self.viewModel.updateAmount("", isSource: isSource)
      self.toAmountTextField.text = ""
    }
    // support for promo wallet
    let isUpdatedTo: Bool = !isSource
    self.updateTokensView(updatedFrom: isSource, updatedTo: isUpdatedTo)
    if (self.viewModel.from == self.viewModel.to || (self.viewModel.from.isWETH && self.viewModel.to.isETH)) && isWarningShown {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("unsupported", value: "Unsupported", comment: ""),
        message: "Source token must be different from dest token".toBeLocalised(),
        time: 1.5
      )
    }
    // auto fill current rate
    if let rate = self.viewModel.rateFromNode ?? self.viewModel.cachedProdRate, !rate.isZero {
      let rateString = rate.string(
        decimals: self.viewModel.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(8, self.viewModel.to.decimals)
      ).removeGroupSeparator()
      self.targetRateTextField.text = rateString
      self.viewModel.updateTargetRate(rateString)
      self.viewModel.updateFocusTextField(2)
    }
    self.updateViewAmountDidChange()

    if !self.cancelRelatedOrdersView.isHidden {
      self.cancelRelatedOrdersView.isHidden = true
      self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
      self.rateContainerView.rounded(radius: 4.0)
    }

    self.listOrdersDidUpdate(nil)
    self.updateRelatedOrdersFromServer()

    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "select_token_\(token.symbol)"])

    self.view.layoutIfNeeded()
  }

  /*
   Show transaction status after user confirmed transaction
   */
  func coordinatorExchangeTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.viewModel.updateAmount("", isSource: true)
    self.viewModel.updateAmount("", isSource: false)
    self.viewModel.updateTargetRate("")
    self.toAmountTextField.text = ""
    self.fromAmountTextField.text = ""
    self.targetRateTextField.text = ""
    self.updateCurrentMarketRateUI()
    self.view.layoutIfNeeded()
  }

  func coordinatorTrackerRateDidUpdate() {
    self.updateCurrentMarketRateUI()
  }

  func coordinatorUpdateProdCachedRates() {
    self.viewModel.updateProdCachedRate()
    self.updateCurrentMarketRateUI()
  }

  func coordinatorUpdateComparedRateFromNode(from: TokenObject, to: TokenObject, rate: BigInt) {
    if self.viewModel.from == from, self.viewModel.to == to {
      self.viewModel.updateProdCachedRate(rate)
      self.updateCurrentMarketRateUI()
    }
  }

  func coordinatorDidUpdatePendingTransactions(_ transactions: [KNTransaction]) {
    self.hamburgerMenu.update(transactions: transactions)
    self.hasPendingTxView.isHidden = transactions.isEmpty
    self.view.layoutIfNeeded()
  }

  func coordinatorDoneSubmittingOrder() {
    self.showSuccessTopBannerMessage(
      with: NSLocalizedString("success", value: "Success", comment: ""),
      message: "Your order have been submitted sucessfully to server. You can check the order in your order list.".toBeLocalised(),
      time: 1.5
    )
    self.listOrdersDidUpdate(nil)
    if #available(iOS 10.3, *) {
      KNAppstoreRatingManager.requestReviewIfAppropriate()
    }
  }

  func coordinatorUpdateEstimateFee(_ fee: Double, discount: Double, feeBeforeDiscount: Double, transferFee: Double) {
    self.viewModel.feePercentage = fee
    self.viewModel.discountPercentage = discount
    self.viewModel.feeBeforeDiscount = feeBeforeDiscount
    self.viewModel.transferFeePercent = transferFee
    self.updateFeeNotesUI()
    self.loadingFeeIndicator.stopAnimating()
    self.loadingFeeIndicator.isHidden = true
  }

  func coordinatorUpdateListRelatedOrders(address: String, src: String, dest: String, minRate: Double, orders: [KNOrderObject]) {
    if address.lowercased() == self.viewModel.walletObject.address.lowercased()
      && src.lowercased() == self.viewModel.from.contract.lowercased()
      && dest.lowercased() == self.viewModel.to.contract.lowercased() {
      self.viewModel.updateRelatedOrders(orders)
      if !self.cancelRelatedOrdersView.isHidden {
        if self.viewModel.cancelSuggestOrders.isEmpty {
          self.cancelRelatedOrdersView.isHidden = true
          self.cancelOrdersCollectionViewHeightConstraint.constant = 0.0
          self.rateContainerView.rounded(radius: 4.0)
        } else {
          self.cancelOrdersCollectionView.reloadData()
        }
      }
      self.updateRelatedOrdersView()
      self.view.layoutIfNeeded()
    }
  }

  func coordinatorUpdatePendingBalances(address: String, balances: JSONDictionary) {
    self.viewModel.updatePendingBalances(balances, address: address)
    self.sourceBalanceValueLabel.text = self.viewModel.balanceText
    self.view.layoutIfNeeded()
  }
}

// MARK: UITextField delegation
extension KNCreateLimitOrderViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    self.viewModel.updateFocusTextField(textField.tag)
    textField.text = ""
    if textField == self.fromAmountTextField || textField == self.toAmountTextField {
      self.viewModel.updateAmount("", isSource: textField == self.fromAmountTextField)
    } else if textField == self.targetRateTextField {
      self.viewModel.updateTargetRate("")
    }
    self.updateViewAmountDidChange()
    self.updateEstimateRateFromNetwork(showWarning: true)
    if textField == self.fromAmountTextField {
      self.viewModel.isUseAllBalance = false
    }
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).cleanStringToNumber()

    // from amount text field
    if textField == self.fromAmountTextField && text.amountBigInt(decimals: self.viewModel.from.decimals) == nil { return false }

    // to amount text field
    if (textField == self.toAmountTextField || textField == self.targetRateTextField ) && text.amountBigInt(decimals: self.viewModel.to.decimals) == nil { return false }

    // validate if amount is less than 1B
    let double: Double = {
      if textField == self.fromAmountTextField {
        let bigInt = Double(text.amountBigInt(decimals: self.viewModel.from.decimals) ?? BigInt(0))
        return Double(bigInt) / pow(10.0, Double(self.viewModel.from.decimals))
      }
      let bigInt = Double(text.amountBigInt(decimals: self.viewModel.to.decimals) ?? BigInt(0))
      return Double(bigInt) / pow(10.0, Double(self.viewModel.to.decimals))
    }()
    if double > 1e9 && (textField.text?.count ?? 0) < text.count { return false } // more than 1B tokens

    textField.text = text

    self.viewModel.updateFocusTextField(textField.tag)

    if textField == self.fromAmountTextField {
      self.viewModel.updateAmount(text, isSource: true)
    } else if textField == self.toAmountTextField {
      self.viewModel.updateAmount(text, isSource: false)
    } else if textField == self.targetRateTextField {
      self.viewModel.updateTargetRate(text)
    }

    self.updateViewAmountDidChange()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.fromAmountTextField {
      self.viewModel.isUseAllBalance = false
    }
    self.viewModel.updateFocusTextField(textField.tag)
    self.updateViewAmountDidChange()
    if !self.cancelRelatedOrdersView.isHidden {
      self.noCancelButtonPressed(nil)
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.viewModel.updateFocusTextField(textField.tag)
    self.updateEstimateRateFromNetwork(showWarning: true)
    self.updateViewAmountDidChange()
    self.updateEstimateFeeFromServer(isShowingIndicator: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      _ = self.validateDataIfNeeded()
    }
  }

  fileprivate func updateViewAmountDidChange() {
    if self.viewModel.shouldAmountToChange {
      // Focusing from and target text field
      let amountTo = self.viewModel.estimateAmountToBigInt
      let amountToString = amountTo.isZero ? "" : amountTo.string(
        decimals: self.viewModel.to.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.to.decimals, 6)
      ).removeGroupSeparator()
      self.toAmountTextField.text = amountToString
      self.viewModel.updateAmount(amountToString, isSource: false)
    } else if self.viewModel.shouldTargetRateChange {
      // Focusing from and to text field
      let targetRate = self.viewModel.estimateTargetRateBigInt
      let rateDisplay = targetRate.isZero ? "" : targetRate.displayRate(decimals: self.viewModel.to.decimals).removeGroupSeparator()
      self.targetRateTextField.text = rateDisplay
      self.viewModel.updateTargetRate(rateDisplay)
    } else {
      // Focusing to and target text field
      let amountFrom = self.viewModel.estimateAmountFromBigInt
      let amountFromString = amountFrom.isZero ? "" : amountFrom.string(
        decimals: self.viewModel.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.viewModel.from.decimals, 6)
      ).removeGroupSeparator()
      self.fromAmountTextField.text = amountFromString
      self.viewModel.updateAmount(amountFromString, isSource: true)
    }
    self.updateFeeNotesUI()
    self.updateEstimateRateFromNetwork(showWarning: false)
    self.updateEstimateFeeFromServer(isShowingIndicator: true)
    self.view.layoutIfNeeded()
  }
}

// MARK: Hamburger Menu Delegate
extension KNCreateLimitOrderViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }
}

// MARK: Toolbar delegate
extension KNCreateLimitOrderViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardSwapAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}

// MARK: Related orders
extension KNCreateLimitOrderViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNLimitOrderCollectionViewCell.kLimitOrderNormalHeight
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 44
    )
  }
}

extension KNCreateLimitOrderViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    if collectionView == self.cancelOrdersCollectionView { return }
    let order: KNOrderObject = self.viewModel.relatedOrders[indexPath.row]
    if let cancelOrder = self.viewModel.cancelOrder, cancelOrder.id == order.id {
      self.viewModel.cancelOrder = nil
      collectionView.reloadItems(at: [indexPath])
    } else if order.state == .open {
      self.openCancelOrder(order, completion: nil)
    }
  }
}

extension KNCreateLimitOrderViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return collectionView == self.relatedOrderCollectionView ? self.viewModel.relatedHeaders.count : self.viewModel.cancelSuggestHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if collectionView == self.relatedOrderCollectionView {
      let date = self.viewModel.relatedHeaders[section]
      return self.viewModel.relatedSections[date]?.count ?? 0
    }
    let date = self.viewModel.cancelSuggestHeaders[section]
    return self.viewModel.cancelSuggestSections[date]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell: KNLimitOrderCollectionViewCell = {
      if collectionView == self.relatedOrderCollectionView {
        // related orders
        return collectionView.dequeueReusableCell(
          withReuseIdentifier: KNLimitOrderCollectionViewCell.cellID,
          for: indexPath
          ) as! KNLimitOrderCollectionViewCell
      }
      // suggest cancel
      return collectionView.dequeueReusableCell(
        withReuseIdentifier: kCancelOrdersCollectionViewCellID,
        for: indexPath
        ) as! KNLimitOrderCollectionViewCell
    }()
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
      hasAction: collectionView == self.relatedOrderCollectionView,
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
        if collectionView == self.relatedOrderCollectionView {
          return self.viewModel.relatedHeaders[indexPath.section]
        }
        return self.viewModel.cancelSuggestHeaders[indexPath.section]
      }()
      headerView.updateView(with: headerText)
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

extension KNCreateLimitOrderViewController: KNLimitOrderCollectionViewCellDelegate {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject) {
    let date = self.viewModel.displayDate(for: order)
    guard let section = self.viewModel.relatedHeaders.firstIndex(where: { $0 == date }),
      let row = self.viewModel.relatedSections[date]?.firstIndex(where: { $0.id == order.id }) else {
      return // order not exist
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "open_cancel_order"])
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

extension KNCreateLimitOrderViewController: KNCancelOrderConfirmPopUpDelegate {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_limit_order", customAttributes: ["action": "confirm_cancel"])
    self.listOrdersDidUpdate(nil)
    self.updateRelatedOrdersFromServer()
    self.updatePendingBalancesFromServer()
  }
}
