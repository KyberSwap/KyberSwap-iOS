// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

//swiftlint:disable file_length
enum KWalletBalanceViewEvent {
  case openQRCode
  case selectToken(token: TokenObject)
  case buy(token: TokenObject)
  case sell(token: TokenObject)
  case send(token: TokenObject)
  case alert(token: TokenObject)
  case receiveToken
  case refreshData
  case buyETH
  case copyAddress
  case quickTutorial(step: Int, pointsAndRadius: [(CGPoint, CGFloat)])
  case checkShowGasWaring
}

protocol KWalletBalanceViewControllerDelegate: class {
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run event: KWalletBalanceViewEvent)
  func kWalletBalanceViewController(_ controller: KWalletBalanceViewController, run menuEvent: KNBalanceTabHamburgerMenuViewEvent)
}

class KWalletBalanceViewController: KNBaseViewController {

  fileprivate var isViewSetup: Bool = false

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var walletDataView: UIView!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var balanceValueLabel: UILabel!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var emptyStateView: UIView!
  @IBOutlet weak var emptyBalanceTextLabel: UILabel!

  @IBOutlet weak var hasPendingTxView: UIView!

  @IBOutlet weak var kyberListButton: UIButton!
  @IBOutlet weak var otherButton: UIButton!
  @IBOutlet weak var searchTextField: UITextField!

  @IBOutlet weak var currencyETHButton: UIButton!
  @IBOutlet weak var currencyETHCenterConstraint: NSLayoutConstraint!

  @IBOutlet weak var currencyUSDButton: UIButton!
  @IBOutlet weak var currencyUSDCenterConstraint: NSLayoutConstraint!

  @IBOutlet weak var change24hButton: UIButton!
  @IBOutlet weak var change24hCenterConstraint: NSLayoutConstraint!

  @IBOutlet weak var nameTextButton: UIButton!
  @IBOutlet weak var nameAndBalCenterConstraint: NSLayoutConstraint!

  @IBOutlet weak var tokensBalanceTableView: UITableView!
  @IBOutlet weak var bottomPaddingConstraintForTableView: NSLayoutConstraint!
  @IBOutlet weak var balanceDisplayControlButton: UIButton!
  @IBOutlet weak var hasUnreadNotification: UIView!
  @IBOutlet weak var buyETHButton: UIButton!

  lazy var refreshControl: UIRefreshControl = {
    let refresh = UIRefreshControl()
    refresh.tintColor = UIColor.Kyber.enygold
    return refresh
  }()

  fileprivate var viewModel: KWalletBalanceViewModel
  weak var delegate: KWalletBalanceViewControllerDelegate?
  var firstAnimatingCell: UITableViewCell?
  var secondAnimatingCell: UITableViewCell?

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    let viewModel = KNBalanceTabHamburgerMenuViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.wallet
    )
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    hamburgerVC.view.isHidden = true
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  init(viewModel: KWalletBalanceViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KWalletBalanceViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.notificationDidUpdate(_:)),
      name: name,
      object: nil
    )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
    if KNReachability.shared.previousStatus == .notReachable {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("please.check.your.internet.connection", value: "Please check your internet connection", comment: ""),
        time: 1.5
      )
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if NSObject.isNeedShowTutorial(for: Constants.isDoneShowQuickTutorialForBalanceView) {
      KNCrashlyticsUtil.logCustomEvent(withName: "tut_balance_show_quick_tutorial", customAttributes: nil)
      self.viewModel.currentTutorialStep = 1
      let event = KWalletBalanceViewEvent.quickTutorial(
        step: 1,
        pointsAndRadius: [(CGPoint(x: self.buyETHButton.frame.midX, y: self.buyETHButton.frame.midY), 65), (CGPoint(x: self.balanceValueLabel.frame.midX - 50, y: self.balanceValueLabel.frame.midY), 93)]
      )
      self.delegate?.kWalletBalanceViewController(self, run: event)
      self.viewModel.isShowingQuickTutorial = true
    } else {
      self.showGasWaringPopUpIfNeed()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  // MARK: Set up UIs
  fileprivate func setupUI() {
    self.bottomPaddingConstraintForTableView.constant = self.bottomPaddingSafeArea()
    self.hasUnreadNotification.rounded(radius: hasUnreadNotification.frame.height / 2)
    self.notificationDidUpdate(nil)
    self.setupHamburgerMenu()
    self.setupWalletBalanceHeaderView()
    self.setupDisplayDataType()
    self.setupTokensBalanceTableView()
    self.buyETHButton.rounded(color: .white, width: 1.0)
    let localisedString = String(format: "Buy %@".toBeLocalised(), "ETH")
    self.buyETHButton.setTitle(localisedString, for: .normal)
  }

  fileprivate func setupWalletBalanceHeaderView() {
    self.balanceTextLabel.text = NSLocalizedString("balance", value: "Balance", comment: "")
    self.balanceTextLabel.addLetterSpacing()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.openQRCodeViewPressed(_:)))
    self.walletDataView.addGestureRecognizer(tapGesture)

    self.balanceDisplayControlButton.setImage(
      UIImage(named: !self.viewModel.isBalanceShown ? "show_balance_icon" : "hide_balance_icon"),
      for: .normal
    )
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
  }

  fileprivate func setupHamburgerMenu() {
    self.hasPendingTxView.rounded(radius: self.hasPendingTxView.frame.height / 2.0)
    self.hamburgerMenu.hideMenu(animated: false)
  }

  fileprivate func setupDisplayDataType() {
    self.nameTextButton.setTitle(
      NSLocalizedString("name", value: "Name", comment: ""),
      for: .normal
    )
    self.updateDisplayedDataType()
    self.searchTextField.delegate = self
  }

  fileprivate func setupTokensBalanceTableView() {
    let nib = UINib(nibName: KNBalanceTokenTableViewCell.className, bundle: nil)
    self.tokensBalanceTableView.register(
      nib,
      forCellReuseIdentifier: KNBalanceTokenTableViewCell.kCellID
    )
    self.tokensBalanceTableView.delegate = self
    self.tokensBalanceTableView.dataSource = self
    self.tokensBalanceTableView.rowHeight = KNBalanceTokenTableViewCell.kCellHeight
    self.tokensBalanceTableView.reloadData()

    self.emptyBalanceTextLabel.text = self.viewModel.textNoMatchingTokens

    self.tokensBalanceTableView.refreshControl = self.refreshControl
    self.refreshControl.addTarget(self, action: #selector(self.userDidRefreshBalanceView(_:)), for: .valueChanged)
  }

  // MARK: Update UIs
  fileprivate func updateWalletInfoUI() {
    self.walletNameLabel.text = {
      let name = self.viewModel.wallet.name
      let address = "\(self.viewModel.wallet.address.lowercased().prefix(6))...\(self.viewModel.wallet.address.lowercased().suffix(4))"
      return "\(name) - \(address)"
    }()
    self.walletNameLabel.addLetterSpacing()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateWalletBalanceUI() {
    self.viewModel.updateDisplayDataSessonDidSwitch()
    self.balanceValueLabel.attributedText = self.viewModel.balanceDisplayAttributedString
    self.tokensBalanceTableView.isHidden = self.viewModel.displayedTokens.isEmpty
    self.emptyStateView.isHidden = !self.viewModel.displayedTokens.isEmpty
    guard self.viewModel.isShowingQuickTutorial == false else {
      return
    }
    self.tokensBalanceTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateDisplayedDataType() {
    self.nameTextButton.setAttributedTitle(self.viewModel.displayNameAndBalance, for: .normal)
    self.nameAndBalCenterConstraint.constant = self.viewModel.nameAndBalanceCenterXConstant
    self.currencyETHButton.setAttributedTitle(self.viewModel.displayETHCurrency, for: .normal)
    self.currencyETHCenterConstraint.constant = self.viewModel.currencyETHCenterXConstant
    self.currencyUSDButton.setAttributedTitle(self.viewModel.displayUSDCurrency, for: .normal)
    self.currencyUSDCenterConstraint.constant = self.viewModel.currencyUSDCenterXConstant
    self.change24hButton.setAttributedTitle(self.viewModel.displayChange24h, for: .normal)
    self.change24hCenterConstraint.constant = self.viewModel.change24hCenterXConstant

    self.kyberListButton.setTitleColor(self.viewModel.colorKyberListedButton, for: .normal)
    self.kyberListButton.setTitle(
      NSLocalizedString("kyber.listed", value: "Kyber Listed", comment: ""),
      for: .normal
    )
    self.otherButton.semanticContentAttribute = .forceRightToLeft
    self.otherButton.setTitleColor(self.viewModel.colorOthersButton, for: .normal)
    self.otherButton.setTitle(
      self.viewModel.otherButtonTitle,
      for: .normal
    )
    self.otherButton.setImage(
      self.viewModel.tabOption == .kyberListed ? UIImage(named: "arrow_drop_down") : UIImage(named: "arrow_drop_down_selected"),
      for: .normal
    )
    self.updateWalletBalanceUI()
    self.view.layoutIfNeeded()
  }

  // MARK: Actions handling

  @objc func openQRCodeViewPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_address_shown", customAttributes: nil)
    self.delegate?.kWalletBalanceViewController(self, run: .openQRCode)
  }

  @IBAction func menuButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_hamburger_menu", customAttributes: nil)
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func kyberListButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_kyber_listed_tokens", customAttributes: nil)
    if self.viewModel.updateDisplayTabOption(.kyberListed) {
      self.updateDisplayedDataType()
    }
  }

  @IBAction func otherButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_other_tokens", customAttributes: nil)
    let newOption: KTokenListType = {
      if self.viewModel.tabOption == .kyberListed { return self.viewModel.preExtraTabOption }
      return self.viewModel.tabOption == .favourite ? .others : .favourite
    }()
    if self.viewModel.updateDisplayTabOption(newOption) {
      self.updateDisplayedDataType()
    }
  }

  @IBAction func searchButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_search_token", customAttributes: nil)
    if !self.searchTextField.isFirstResponder { self.searchTextField.becomeFirstResponder() }
  }

  @IBAction func sortNameButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_sorted_name", customAttributes: nil)
    self.viewModel.updateTokenDisplayType(positionClicked: 1)
    self.tokensBalanceTableView.reloadData()
    self.updateDisplayedDataType()
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_token_sort",
                                     customAttributes: [
                                      "token_sort": self.viewModel.tokensDisplayType.displayString(),
                                      "list_type": self.viewModel.tabOption.displayString(),
                                      ]
                                    )
  }

  @IBAction func changeButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_balance", customAttributes: ["action": "sorted_change_24h"])
    self.viewModel.updateTokenDisplayType(positionClicked: 3)
    self.tokensBalanceTableView.reloadData()
    self.updateDisplayedDataType()
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_token_sort",
                                     customAttributes: [
                                      "token_sort": self.viewModel.tokensDisplayType.displayString(),
                                      "list_type": self.viewModel.tabOption.displayString(),
      ]
    )
  }

  @IBAction func copyButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_address_copied", customAttributes: nil)
    self.delegate?.kWalletBalanceViewController(self, run: .copyAddress)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @IBAction func currencyETHButtonPressed(_ sender: Any) {
    let newType: KWalletCurrencyType = .eth

    let isSwitched = self.viewModel.updateCurrencyType(newType)
    self.viewModel.updateTokenDisplayType(positionClicked: 2, isSwitched: isSwitched)
    self.updateDisplayedDataType()
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_token_sort",
                                     customAttributes: [
                                      "token_sort": self.viewModel.currencyType.rawValue,
                                      "list_type": self.viewModel.tabOption.displayString(),
                                      ]
                                    )
  }

  @IBAction func currencyUSDButtonPressed(_ sender: Any) {
    let newType: KWalletCurrencyType = .usd
    let isSwitched = self.viewModel.updateCurrencyType(newType)
    self.viewModel.updateTokenDisplayType(positionClicked: 2, isSwitched: isSwitched)
    self.updateDisplayedDataType()
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_token_sort",
                                     customAttributes: [
                                      "token_sort": self.viewModel.currencyType.rawValue,
                                      "list_type": self.viewModel.tabOption.displayString(),
                                      ]
                                    )
  }

  @IBAction func balanceDisplayControlButtonPressed(_ sender: Any) {
    self.viewModel.updateIsBalanceShown(!self.viewModel.isBalanceShown)
    self.balanceDisplayControlButton.setImage(
      UIImage(named: !self.viewModel.isBalanceShown ? "show_balance_icon" : "hide_balance_icon"),
      for: .normal
    )
    self.updateWalletBalanceUI()
    self.view.layoutIfNeeded()
  }

  @IBAction func notificationMenuButtonPressed(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "balanace_noti_flag", customAttributes: nil)
    self.delegate?.kWalletBalanceViewController(self, run: .selectNotifications)
  }

  @IBAction func buyETHButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_balance", customAttributes: ["action": "buy_eth_button_clicked"])
    self.delegate?.kWalletBalanceViewController(self, run: .buyETH)
  }

  override func quickTutorialNextAction() {
    self.dismissTutorialOverlayer()
    if self.viewModel.currentTutorialStep == 4 {
      KNCrashlyticsUtil.logCustomEvent(withName: "tut_balance_got_it_button_tapped", customAttributes: nil)
      self.viewModel.isShowingQuickTutorial = false
      NSObject.updateDoneTutorial(for: Constants.isDoneShowQuickTutorialForBalanceView)
      self.delegate?.kWalletBalanceViewController(self, run: .checkShowGasWaring)
      return
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "tut_balance_next_button_tapped", customAttributes: ["step": self.viewModel.currentTutorialStep])
    self.viewModel.currentTutorialStep += 1
    var pointsAndRadius: [(CGPoint, CGFloat)] = []
    let tableViewOrigin = self.tokensBalanceTableView.frame.origin
    let tableViewFrame = self.tokensBalanceTableView.frame.size
    switch self.viewModel.currentTutorialStep {
    case 2:
      pointsAndRadius = [(CGPoint(x: tableViewOrigin.x + 52, y: tableViewOrigin.y + 64 * 1.5), 90)]
    case 3:
      pointsAndRadius = [(CGPoint(x: tableViewOrigin.x + tableViewFrame.width - 118, y: tableViewOrigin.y + 64 * 1.5), 115)]
    case 4:
      pointsAndRadius = [(CGPoint(x: tableViewOrigin.x + 32, y: tableViewOrigin.y + 32), 60), (CGPoint(x: tableViewOrigin.x + tableViewFrame.width - 64, y: tableViewOrigin.y + 64 * 1.5), 133)]
      self.animateReviewCellActionForTutorial()
    default:
      break
    }
    let event = KWalletBalanceViewEvent.quickTutorial(
      step: self.viewModel.currentTutorialStep,
      pointsAndRadius: pointsAndRadius
    )
    self.delegate?.kWalletBalanceViewController(self, run: event)
  }

  override func quickTutorialContentLabelTapped() {
    if self.viewModel.currentTutorialStep == 1 {
      KNCrashlyticsUtil.logCustomEvent(withName: "tut_balance_buy_eth_tapped", customAttributes: nil)
      self.buyETHButtonTapped(UIButton())
    }
  }

  override func dismissTutorialOverlayer() {
    super.dismissTutorialOverlayer()
    if self.viewModel.currentTutorialStep == 4 {
      self.animateResetReviewCellActionForTutorial()
    }
  }

  func animateReviewCellActionForTutorial() {
    guard let firstCell = self.tokensBalanceTableView.cellForRow(at: IndexPath(row: 0, section: 0)),
      let secondCell = self.tokensBalanceTableView.cellForRow(at: IndexPath(row: 1, section: 0))
      else {
        return
    }
    self.firstAnimatingCell = firstCell
    self.secondAnimatingCell = secondCell
    let alertImageView = UIImageView(frame: CGRect(x: -64, y: 0, width: 64, height: 64))

    let buyLabel = UILabel(frame: CGRect(x: secondCell.bounds.size.width, y: 0, width: 64, height: 64))
    let sellLabel = UILabel(frame: CGRect(x: secondCell.bounds.size.width + 64, y: 0, width: 64, height: 64))
    let transferLabel = UILabel(frame: CGRect(x: secondCell.bounds.size.width + 64 * 2, y: 0, width: 64, height: 64))

    alertImageView.image = UIImage(named: "add_alert_icon")
    alertImageView.backgroundColor = UIColor(hex: "5A5E67")
    alertImageView.contentMode = .center
    alertImageView.tag = 100
    firstCell.addSubview(alertImageView)

    buyLabel.text = "buy".toBeLocalised()
    buyLabel.textAlignment = .center
    buyLabel.textColor = .white
    buyLabel.backgroundColor = UIColor.Kyber.marketGreen
    buyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    buyLabel.tag = 101
    secondCell.addSubview(buyLabel)

    sellLabel.text = "sell".toBeLocalised()
    sellLabel.textAlignment = .center
    sellLabel.textColor = .white
    sellLabel.backgroundColor = UIColor.Kyber.marketRed
    sellLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    sellLabel.tag = 102
    secondCell.addSubview(sellLabel)

    transferLabel.text = "transfer".toBeLocalised()
    transferLabel.textAlignment = .center
    transferLabel.textColor = .white
    transferLabel.backgroundColor = UIColor.Kyber.marketBlue
    transferLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    transferLabel.tag = 103
    secondCell.addSubview(transferLabel)

    UIView.animate(withDuration: 0.3) {
      firstCell.frame = CGRect(x: 64, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
      secondCell.frame = CGRect(x: secondCell.frame.origin.x - 64 * 3, y: secondCell.frame.origin.y, width: secondCell.frame.size.width, height: secondCell.frame.size.height)
    }
  }

  func animateResetReviewCellActionForTutorial() {
    guard let firstCell = self.firstAnimatingCell,
    let secondCell = self.secondAnimatingCell
      else {
        return
    }
    let alertImageView = firstCell.viewWithTag(100)
    let buyLabel = secondCell.viewWithTag(101)
    let sellLabel = secondCell.viewWithTag(102)
    let transferLabel = secondCell.viewWithTag(103)

    UIView.animate(withDuration: 0.3, animations: {
      firstCell.frame = CGRect(x: 0, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
      secondCell.frame = CGRect(x: secondCell.frame.origin.x + 64 * 3, y: secondCell.frame.origin.y, width: secondCell.frame.size.width, height: secondCell.frame.size.height)
    }) { _ in
      alertImageView?.removeFromSuperview()
      buyLabel?.removeFromSuperview()
      sellLabel?.removeFromSuperview()
      transferLabel?.removeFromSuperview()
      self.firstAnimatingCell = nil
      self.secondAnimatingCell = nil
    }
  }

  @objc func userDidRefreshBalanceView(_ sender: Any?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      // reload data
      self.delegate?.kWalletBalanceViewController(self, run: .refreshData)
      self.refreshControl.endRefreshing()
    }
  }

  @objc func notificationDidUpdate(_ sender: Any?) {
    let numUnread: Int = {
      if IEOUserStorage.shared.user == nil { return 0 }
      return KNNotificationCoordinator.shared.numberUnread
    }()
    self.update(notificationsCount: numUnread)
  }

  func update(notificationsCount: Int) {
    self.hasUnreadNotification.isHidden = notificationsCount == 0
  }
  
  fileprivate func showGasWaringPopUpIfNeed() {
    self.delegate?.kWalletBalanceViewController(self, run: .checkShowGasWaring)
  }
}

// MARK: Update from coordinator
extension KWalletBalanceViewController {
  func coordinatorUpdateSessionWithNewViewModel(_ viewModel: KWalletBalanceViewModel) {
    self.viewModel = viewModel
    self.updateWalletBalanceUI()
    self.updateWalletInfoUI()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.viewModel.wallet
    )
    self.hamburgerMenu.hideMenu(animated: false)
    self.kyberListButton.setTitleColor(self.viewModel.colorKyberListedButton, for: .normal)
    self.otherButton.setTitleColor(self.viewModel.colorOthersButton, for: .normal)
    self.otherButton.setImage(
      self.viewModel.tabOption == .kyberListed ? UIImage(named: "arrow_drop_down") : UIImage(named: "arrow_drop_down_selected"),
      for: .normal
    )
    let searchedText = self.searchTextField.text ?? ""
    self.viewModel.updateSearchText(searchedText)
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: viewModel.wallet.address) else { return }
    self.viewModel.updateWalletObject(currentWallet)
    self.updateWalletInfoUI()
    self.hamburgerMenu.update(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: currentWallet
    )
  }

  func coordinatorUpdateTokenObjects(_ tokenObjects: [TokenObject]) {
    if self.viewModel.updateTokenObjects(tokenObjects) {
      self.updateWalletBalanceUI()
    }
  }

  func coordinatorUpdateTokenBalances(_ balances: [String: Balance]) {
    if self.viewModel.updateTokenBalances(balances) {
      self.updateWalletBalanceUI()
    }
  }

  func coordinatorUpdateBalanceInETHAndUSD(ethBalance: BigInt, usdBalance: BigInt) {
    self.viewModel.updateBalanceInETHAndUSD(
      ethBalance: ethBalance,
      usdBalance: usdBalance
    )
    self.updateWalletBalanceUI()
    self.viewModel.exchangeRatesDataUpdated()
  }

  func coordinatorUpdatePendingTransactions(_ transactions: [KNTransaction]) {
    self.hamburgerMenu.update(transactions: transactions)
    self.hasPendingTxView.isHidden = transactions.isEmpty
  }

  func coordinatorSortedChange24h(with currencyType: KWalletCurrencyType) {
    // reset search text
    self.searchTextField.text = ""
    self.viewModel.updateSearchText("")
    // update: currency type, sorted change24h
    self.viewModel.updateTokenSortedChange24h(with: currencyType)
    // update Kyber listed/Other, Currency button
    self.updateDisplayedDataType()
  }
}

// MARK: Hamburger menu delegation
extension KWalletBalanceViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.kWalletBalanceViewController(self, run: event)
  }
}

// MARK: Table view delegate, datasource
extension KWalletBalanceViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    self.delegate?.kWalletBalanceViewController(self, run: .selectToken(token: tokenObject))
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_token_tapped", customAttributes: ["token_name": tokenObject.name])
  }
}

extension KWalletBalanceViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KNBalanceTokenTableViewCell.kCellID,
      for: indexPath
    ) as! KNBalanceTokenTableViewCell
    let row: Int = indexPath.row

    // Data for cell
    let tokenObject: TokenObject = self.viewModel.tokenObject(for: row)
    let trackerRate: KNTrackerRate? = self.viewModel.trackerRate(for: row)
    let balance: Balance? = self.viewModel.balance(for: tokenObject)

    let cellModel = KNBalanceTokenTableViewCellModel(
      token: tokenObject,
      trackerRate: trackerRate,
      balance: balance,
      currencyType: self.viewModel.currencyType,
      index: indexPath.row,
      isBalanceShown: self.viewModel.isBalanceShown
    )
    cell.updateCellView(with: cellModel)
    cell.delegate = self
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    let sendText = NSLocalizedString("transfer", value: "Transfer", comment: "")
    let sendAction = UITableViewRowAction(style: .default, title: sendText) { _, _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balanace_swipeleft_transfer", customAttributes: ["token_name": tokenObject.name])
      self.delegate?.kWalletBalanceViewController(self, run: .send(token: tokenObject))
    }
    sendAction.backgroundColor = UIColor.Kyber.marketBlue
    let sellText = NSLocalizedString("sell", value: "Sell", comment: "")
    let sellAction = UITableViewRowAction(style: .default, title: sellText) { _, _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balanace_swipeleft_sell", customAttributes: ["token_name": tokenObject.name])
      self.delegate?.kWalletBalanceViewController(self, run: .sell(token: tokenObject))
    }
    sellAction.backgroundColor = UIColor.Kyber.marketRed
    let buyText = NSLocalizedString("buy", value: "Buy", comment: "")
    let buyAction = UITableViewRowAction(style: .default, title: buyText) { _, _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "balanace_swipeleft_buy", customAttributes: ["token_name": tokenObject.name])
      self.delegate?.kWalletBalanceViewController(self, run: .buy(token: tokenObject))
    }
    buyAction.backgroundColor = UIColor.Kyber.marketGreen
    return tokenObject.isSupported ? [sendAction, sellAction, buyAction] : [sendAction]
  }

  @available(iOS 11.0, *)
  func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let tokenObject = self.viewModel.tokenObject(for: indexPath.row)
    if !tokenObject.isSupported { return nil }
    let alertAction = UIContextualAction(
      style: .normal,
      title: ""
    ) { (_, _, _) in
      tableView.reloadData()
      KNCrashlyticsUtil.logCustomEvent(withName: "balance_swiperight_alert", customAttributes: ["token_name": tokenObject.name])
      self.delegate?.kWalletBalanceViewController(self, run: .alert(token: tokenObject))
    }
    alertAction.image = UIImage(named: "add_alert_icon")
    alertAction.backgroundColor = UIColor(hex: "5A5E67")
    return UISwipeActionsConfiguration(actions: [alertAction])
  }
}

extension KWalletBalanceViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if textField == self.searchTextField {
      self.searchAmountTextFieldChanged()
    }
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text.replacingOccurrences(of: " ", with: "")
    if textField == self.searchTextField {
      self.searchAmountTextFieldChanged()
    }
    return false
  }

  fileprivate func searchAmountTextFieldChanged() {
    self.viewModel.updateSearchText((self.searchTextField.text ?? "").replacingOccurrences(of: " ", with: ""))
    self.updateWalletBalanceUI()
    KNCrashlyticsUtil.logCustomEvent(withName: "balance_search_token", customAttributes: nil)
  }
}

extension KWalletBalanceViewController: KNBalanceTokenTableViewCellDelegate {
  func balanceTokenTableViewCell(_ cell: KNBalanceTokenTableViewCell, updateFav token: TokenObject, isFav: Bool) {
    if self.viewModel.tabOption == .favourite {
      self.viewModel.createDisplayedData()
      self.updateWalletBalanceUI()
    }
    let message = isFav ? NSLocalizedString("Successfully added to your favorites", comment: "") : NSLocalizedString("Removed from your favorites", comment: "")
    self.showTopBannerView(with: "", message: message, time: 1.0)
    KNCrashlyticsUtil.logCustomEvent(withName: isFav ? "balance_favourite_added" : "balance_favourite_removed", customAttributes: ["token_name": token.name])
  }
}
