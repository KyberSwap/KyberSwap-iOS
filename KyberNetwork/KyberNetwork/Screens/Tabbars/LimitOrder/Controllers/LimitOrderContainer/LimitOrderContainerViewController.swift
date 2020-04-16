// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNCreateLimitOrderViewEventV2 {
  case submitOrder(order: KNLimitOrder, confirmData: KNLimitOrderConfirmData?)
  case manageOrders
  case estimateFee(address: String, src: String, dest: String, srcAmount: Double, destAmount: Double)
  case getExpectedNonce(address: String, src: String, dest: String)
  case openConvertWETH(address: String, ethBalance: BigInt, amount: BigInt, pendingWETH: Double, order: KNLimitOrder, confirmData: KNLimitOrderConfirmData)
  case getRelatedOrders(address: String, src: String, dest: String, minRate: Double)
  case getPendingBalances(address: String)
  case changeMarket
  case openCancelSuggestOrder(header: [String], sections: [String: [KNOrderObject]], cancelOrder: KNOrderObject?, parent: UIViewController)
}

protocol LimitOrderContainerViewControllerDelegate: class {
  func kCreateLimitOrderViewController(_ controller: KNBaseViewController, run event: KNCreateLimitOrderViewEventV2)
  func kCreateLimitOrderViewController(_ controller: KNBaseViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

class LimitOrderContainerViewController: KNBaseViewController {
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var pagerIndicator: UIView!
  @IBOutlet weak var contentContainerView: UIView!
  @IBOutlet weak var buyToolBarButton: UIButton!
  @IBOutlet weak var sellToolBarButton: UIButton!
  @IBOutlet weak var pagerIndicatorCenterXContraint: NSLayoutConstraint!
  @IBOutlet weak var marketNameButton: UIButton!
  @IBOutlet weak var marketDetailLabel: UILabel!
  @IBOutlet weak var marketVolLabel: UILabel!
  @IBOutlet weak var hasPendingTxView: UIView!
  @IBOutlet weak var hasUnreadNotification: UIView!
  @IBOutlet weak var walletNameLabel: UILabel!

  fileprivate(set) var wallet: Wallet
  fileprivate(set) var walletObject: KNWalletObject

  lazy var hamburgerMenu: KNBalanceTabHamburgerMenuViewController = {
    let viewModel = KNBalanceTabHamburgerMenuViewModel(
      walletObjects: KNWalletStorage.shared.wallets,
      currentWallet: self.walletObject
    )
    let hamburgerVC = KNBalanceTabHamburgerMenuViewController(viewModel: viewModel)
    hamburgerVC.view.frame = self.view.bounds
    self.view.addSubview(hamburgerVC.view)
    self.addChildViewController(hamburgerVC)
    hamburgerVC.didMove(toParentViewController: self)
    hamburgerVC.delegate = self
    return hamburgerVC
  }()

  weak var delegate: LimitOrderContainerViewControllerDelegate?
  var currentIndex = 0
  fileprivate var isViewSetup: Bool = false

  private var pageController: UIPageViewController!
  private var pages: [KNCreateLimitOrderV2ViewController]
  private var currentMarket: KNMarket?

  init(wallet: Wallet) {
    self.wallet = wallet
    let addr = wallet.address.description
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: addr) ?? KNWalletObject(address: addr)
    let buyViewModel = KNCreateLimitOrderV2ViewModel(wallet: wallet)
    let sellViewModel = KNCreateLimitOrderV2ViewModel(wallet: wallet, isBuy: false)
    self.pages = [
      KNCreateLimitOrderV2ViewController(viewModel: buyViewModel),
      KNCreateLimitOrderV2ViewController(viewModel: sellViewModel),
    ]
    super.init(nibName: LimitOrderContainerViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    for vc in self.pages {
      vc.delegate = self.delegate
    }
    self.hasPendingTxView.rounded(radius: self.hasPendingTxView.frame.height / 2.0)
    self.hamburgerMenu.hideMenu(animated: false)
    self.hasUnreadNotification.rounded(radius: hasUnreadNotification.frame.height / 2)
    self.walletNameLabel.text = self.walletNameString
    
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
      self.setupPageController()
      self.currentMarket = KNRateCoordinator.shared.getMarketWith(name: "ETH_KNC")
      if let market = self.currentMarket {
        self.setupUI(market: market)
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func pagerButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      self.pageController.setViewControllers([pages.first!], direction: .reverse, animated: true, completion: nil)
      self.animatePagerIndicator(index: 1, delay: 0.3)
      self.currentIndex = 0
    } else {
      self.pageController.setViewControllers([pages.last!], direction: .forward, animated: true, completion: nil)
      self.animatePagerIndicator(index: 2, delay: 0.3)
      self.currentIndex = 1
    }
  }

  @IBAction func marketButtonTapped(_ sender: UIButton) {
    self.delegate?.kCreateLimitOrderViewController(self, run: .changeMarket)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    self.hamburgerMenu.gestureScreenEdgePanAction(sender)
  }

  @IBAction func hamburgerMenuButtonPressed(_ sender: Any) {
    self.hamburgerMenu.openMenu(animated: true)
  }

  @IBAction func notificationMenuButtonPressed(_ sender: UIButton) {
    delegate?.kCreateLimitOrderViewController(self, run: .selectNotifications)
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

  fileprivate func setupUI(market: KNMarket) {
    let pair = market.pair.components(separatedBy: "_")
    self.marketNameButton.setTitle("\(pair.last ?? "")/\(pair.first ?? "")", for: .normal)
    let displayTypeNormalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    ]
    let upAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 49, green: 203, blue: 158),
    ]

    let downAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 250, green: 101, blue: 102),
    ]
    let detailText = NSMutableAttributedString()
    let formatter = NumberFormatterUtil.shared.limitOrderFormatter
    let buySellText = NSAttributedString(string: "\(formatter.string(from: NSNumber(value: market.buyPrice)) ?? "") ~ \(formatter.string(from: NSNumber(value: market.sellPrice)) ?? "")", attributes: displayTypeNormalAttributes)
    let changeAttribute = market.change > 0 ? upAttributes : downAttributes
    let changeText = NSAttributedString(string: " \(formatter.string(from: NSNumber(value: fabs(market.change))) ?? "")%", attributes: changeAttribute)
    detailText.append(buySellText)
    detailText.append(changeText)
    self.marketDetailLabel.attributedText = detailText

    self.marketVolLabel.text = "Vol \(formatter.string(from: NSNumber(value: fabs(market.volume))) ?? "") \(pair.last ?? "")"
    self.buyToolBarButton.setTitle("\("Buy".toBeLocalised()) \(pair.last ?? "")", for: .normal)
    self.sellToolBarButton.setTitle("\("Sell".toBeLocalised()) \(pair.last ?? "")", for: .normal)
  }

  private func setupPageController() {
    self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    self.pageController.delegate = self
    self.pageController.view.backgroundColor = .clear
    self.pageController.view.frame = CGRect(
      x: 0,
      y: 0,
      width: self.contentContainerView.frame.width,
      height: self.contentContainerView.frame.height
    )
    self.addChildViewController(self.pageController)
    self.contentContainerView.addSubview(self.pageController.view)
    let initialVC = self.pages.first!
    self.pageController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
    self.pageController.didMove(toParentViewController: self)
  }

  fileprivate func animatePagerIndicator(index: NSInteger, delay: Double = 0) {
    let value = self.view.frame.size.width / 4
    self.pagerIndicatorCenterXContraint.constant = index == 1 ? -value : value
    UIView.animate(withDuration: 0.3, delay: delay, animations: {
      self.view.layoutIfNeeded()
    })
  }

  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    for vc in self.pages {
      vc.coordinatorUpdateTokenBalance(balances)
    }
  }

  func coordinatorUpdateEstimateFee(_ fee: Double, discount: Double, feeBeforeDiscount: Double, transferFee: Double) {
    self.pages[self.currentIndex].coordinatorUpdateEstimateFee(fee, discount: discount, feeBeforeDiscount: feeBeforeDiscount, transferFee: transferFee)
  }

  func coordinatorMarketCachedDidUpdate() {
    for vc in self.pages {
      vc.coordinatorMarketCachedDidUpdate()
    }
  }

  func coordinatorUpdateMarket(market: KNMarket) {
    self.currentMarket = market
    self.setupUI(market: market)
    for vc in self.pages {
      vc.coordinatorUpdateMarket(market: market)
    }
  }

  func coordinatorUpdatePendingBalances(address: String, balances: JSONDictionary) {
    for vc in self.pages {
      vc.coordinatorUpdatePendingBalances(address: address, balances: balances)
    }
  }

  func coordinatorUpdateListRelatedOrders(address: String, src: String, dest: String, minRate: Double, orders: [KNOrderObject]) {
    for vc in self.pages {
      vc.coordinatorUpdateListRelatedOrders(address: address, src: src, dest: dest, minRate: minRate, orders: orders)
    }
  }

  func coordinatorUnderstandCheckedInShowCancelSuggestOrder(source: UIViewController) {
    for vc in self.pages where vc == source {
      vc.coordinatorUnderstandCheckedInShowCancelSuggestOrder()
    }
  }

  func coordinatorDidUpdatePendingTransactions(_ transactions: [KNTransaction]) {
    self.hamburgerMenu.update(transactions: transactions)
    self.hasPendingTxView.isHidden = transactions.isEmpty
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.walletNameLabel.text = self.walletNameString
    for vc in self.pages {
      vc.coordinatorUpdateNewSession(wallet: wallet)
    }
  }

  var walletNameString: String {
    let addr = self.walletObject.address.lowercased()
    return "|  \(addr.prefix(10))...\(addr.suffix(8))"
  }
  
  func coordinatorUpdateWalletObjects() {
    self.walletObject = KNWalletStorage.shared.get(forPrimaryKey: self.walletObject.address) ?? self.walletObject
    self.walletNameLabel.text = self.walletNameString
  }
}

extension LimitOrderContainerViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

  }

  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard let viewController = previousViewControllers.first, completed == true else { return }
    if viewController == self.pages[1] {
      self.animatePagerIndicator(index: 1)
    } else if viewController == self.pages[0] {
      self.animatePagerIndicator(index: 2)
    }
  }
}

extension LimitOrderContainerViewController {
  func coordinatorDoneSubmittingOrder() {
    self.showSuccessTopBannerMessage(
      with: NSLocalizedString("success", value: "Success", comment: ""),
      message: "Your order have been submitted sucessfully to server. You can check the order in your order list.".toBeLocalised(),
      time: 1.5
    )
    // TODO: Update list related orders
    // self.listOrdersDidUpdate(nil)
    if #available(iOS 10.3, *) {
      KNAppstoreRatingManager.requestReviewIfAppropriate()
    }
  }
}

extension LimitOrderContainerViewController: KNBalanceTabHamburgerMenuViewControllerDelegate {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent) {
    self.delegate?.kCreateLimitOrderViewController(self, run: event)
  }
}
