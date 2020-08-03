// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNManageOrdersViewModel {
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  let kPageSize: Int = 50
  fileprivate(set) var numberPages: Int = 1
  fileprivate(set) var orders: [KNOrderObject] = []
  fileprivate(set) var displayedOrders: [KNOrderObject] = []
  fileprivate(set) var displayHeaders: [String] = []
  fileprivate(set) var displaySections: [String: [KNOrderObject]] = [:]
  var cancelOrder: KNOrderObject?

  var isSelectingOpenOrders: Bool = true {
    didSet { self.updateDisplayOrders() }
  }

  var isDateDesc: Bool = true {
    didSet { self.updateDisplayOrders() }
  }

  var fromTime: TimeInterval {
    let months = -3
    if let date = Calendar.current.date(byAdding: .month, value: months, to: Date()) {
      return date.timeIntervalSince1970
    }
    return Date().timeIntervalSince1970 - Double(months * -1) * 30.0 * 24.0 * 60.0 * 60.0
  }

  var selectedPairs: [String]? {
    didSet { self.updateDisplayOrders() }
  }

  var selectedStates: [Int] = [0, 1, 2, 3, 4] {
    didSet { self.updateDisplayOrders() }
  }

  var selectedAddresses: [String]? {
    didSet { self.updateDisplayOrders() }
  }

  init(orders: [KNOrderObject]) {
    self.orders = orders
    self.cancelOrder = nil
    self.updateDisplayOrders()
  }

  fileprivate func updateDisplayOrders() {
    let fromTime = self.fromTime
    self.displayedOrders = self.orders.filter({
      if self.isSelectingOpenOrders { return $0.state == .open || $0.state == .inProgress }
      return $0.state == .cancelled || $0.state == .filled || $0.state == .invalidated
    }).filter({
      // filter pairs
      let pair = "\($0.srcTokenSymbol) ➞ \($0.destTokenSymbol)"
      return self.selectedPairs == nil || self.selectedPairs?.contains(pair) == true
    }).filter({
      // filter states
      return self.selectedStates.contains($0.stateValue) == true
    }).filter({
      // filter addresses
      var addr = $0.sender.lowercased()
      addr = "\(addr.prefix(6))...\(addr.suffix(4))"
      return self.selectedAddresses == nil || self.selectedAddresses?.contains(addr) == true
    }).filter({
      // filter date
      if $0.state == .open || $0.state == .inProgress || $0.state == .filled { return true }
      return $0.dateToDisplay.timeIntervalSince1970 >= fromTime
    }).sorted(by: {
      // sort
      if self.isDateDesc { return $0.dateToDisplay > $1.dateToDisplay }
      return $0.dateToDisplay < $1.dateToDisplay
    })
    self.displayHeaders = []
    self.displaySections = [:]
    self.displayedOrders.forEach({
      let date = self.displayDate(for: $0)
      if !self.displayHeaders.contains(date) {
        self.displayHeaders.append(date)
      }
    })
    self.displayedOrders.forEach { order in
      let date = self.displayDate(for: order)
      var orders: [KNOrderObject] = self.displaySections[date] ?? []
      orders.append(order)
      orders = orders.sorted(by: { return $0.dateToDisplay > $1.dateToDisplay })
      self.displaySections[date] = orders
    }
  }

  func updateOrders(_ orders: [KNOrderObject]) {
    self.orders = orders
    self.updateDisplayOrders()
    if orders.count == self.numberPages * kPageSize {
      self.numberPages += 1
      // increase number pages needed to be loaded
    }
  }

  func displayDate(for order: KNOrderObject) -> String {
    return dateFormatter.string(from: order.dateToDisplay)
  }
}

protocol KNManageOrdersViewControllerDelegate: class {
}

class KNManageOrdersViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var openOrderButton: UIButton!
  @IBOutlet weak var orderHistoryButton: UIButton!

  @IBOutlet weak var tutorialContainerView: UIView!
  @IBOutlet weak var swipeLeftToCancelLabel: UILabel!

  @IBOutlet weak var topPaddingCollectionView: NSLayoutConstraint!
  @IBOutlet weak var topPaddingSwipeToCancelButton: NSLayoutConstraint!

  @IBOutlet weak var orderCollectionView: UICollectionView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  @IBOutlet weak var bottomPaddingOrderCollectionViewConstraint: NSLayoutConstraint!

  @IBOutlet weak var faqButton: UIButton!
  @IBOutlet weak var closeFAQButton: UIButton!
  fileprivate var loadingTimer: Timer?

  lazy var refreshControl: UIRefreshControl = {
    let refresh = UIRefreshControl()
    refresh.tintColor = UIColor.Kyber.enygold
    return refresh
  }()

  fileprivate(set) var viewModel: KNManageOrdersViewModel
  weak var delegate: KNManageOrdersViewControllerDelegate?
  fileprivate(set) var filterVC: KNFilterLimitOrderViewController?

  init(viewModel: KNManageOrdersViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNManageOrdersViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    self.loadListOrders(isDisplayLoading: true)
    self.loadingTimer?.invalidate()
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: 15.0, repeats: true, block: { [weak self] _ in
        self?.loadListOrders()
      }
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = "Manage Orders".toBeLocalised()
    self.emptyStateLabel.text = "No order found".toBeLocalised()
    self.openOrderButton.setTitle("Open Orders".toBeLocalised(), for: .normal)
    self.orderHistoryButton.setTitle("Order History".toBeLocalised(), for: .normal)
    let nib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    self.orderCollectionView.register(nib, forCellWithReuseIdentifier: KNLimitOrderCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.orderCollectionView.register(
      headerNib,
      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
      withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID
    )
    self.orderCollectionView.delegate = self
    self.orderCollectionView.dataSource = self

    self.bottomPaddingOrderCollectionViewConstraint.constant = self.bottomPaddingSafeArea() + 12.0

    self.faqButton.setTitle("Orders are not filled? Click to see why".toBeLocalised(), for: .normal)
    self.faqButton.titleLabel?.numberOfLines = 2
    self.faqButton.titleLabel?.textAlignment = .center
    self.faqButton.titleLabel?.lineBreakMode = .byWordWrapping
    self.faqButton.rounded(radius: 4.0)

    self.tutorialContainerView.rounded(radius: 4.0)
    self.swipeLeftToCancelLabel.text = "Swipe left to cancel open order".toBeLocalised()
    let hideTut = !KNAppTracker.needShowCancelOpenOrderTutorial()
    self.updateCancelOrderTutorial(isHidden: hideTut)
    let hideFAQ = !KNAppTracker.needShowWonderWhyOrdersNotFilled()
    self.updateFAQButtonHidden(isHidden: hideFAQ)

    self.updateSelectOrdersType(isOpen: true)

    self.orderCollectionView.refreshControl = self.refreshControl
    self.refreshControl.addTarget(self, action: #selector(self.userDidRefreshBalanceView(_:)), for: .valueChanged)
  }

  fileprivate func updateSelectOrdersType(isOpen: Bool) {
    self.viewModel.isSelectingOpenOrders = isOpen
    self.openOrderButton.setTitleColor(isOpen ? UIColor(red: 254, green: 163, blue: 76) : UIColor(red: 46, green: 57, blue: 87), for: .normal)
    self.orderHistoryButton.setTitleColor(!isOpen ? UIColor(red: 254, green: 163, blue: 76) : UIColor(red: 46, green: 57, blue: 87), for: .normal)
    self.updateCollectionView()
  }

  fileprivate func updateCancelOrderTutorial(isHidden: Bool) {
    self.tutorialContainerView.isHidden = isHidden
    self.topPaddingSwipeToCancelButton.constant = {
      return self.faqButton.isHidden ? 12.0 : 60.0
    }()
    self.topPaddingCollectionView.constant = {
      if self.tutorialContainerView.isHidden && self.faqButton.isHidden { return 12.0 }
      if self.tutorialContainerView.isHidden { return 60.0 }
      if self.faqButton.isHidden { return 60.0 }
      return 108.0
    }()
    if isHidden {
      KNAppTracker.updateCancelOpenOrderTutorial()
    }
    self.view.updateConstraints()
  }

  fileprivate func updateFAQButtonHidden(isHidden: Bool) {
    self.faqButton.isHidden = isHidden
    self.closeFAQButton.isHidden = isHidden
    self.topPaddingSwipeToCancelButton.constant = {
      return self.faqButton.isHidden ? 12.0 : 60.0
    }()
    self.topPaddingCollectionView.constant = {
      if self.tutorialContainerView.isHidden && self.faqButton.isHidden { return 12.0 }
      if self.tutorialContainerView.isHidden { return 60.0 }
      if self.faqButton.isHidden { return 60.0 }
      return 108.0
    }()
    if isHidden {
      KNAppTracker.updateWonderWhyOrdersNotFilled()
    }
    self.view.updateConstraints()
  }

  fileprivate func updateCollectionView() {
    self.emptyStateLabel.isHidden = !self.viewModel.displayedOrders.isEmpty
    self.orderCollectionView.isHidden = self.viewModel.displayedOrders.isEmpty

    let faqHide = !KNAppTracker.needShowWonderWhyOrdersNotFilled()
    self.faqButton.isHidden = self.viewModel.displayedOrders.isEmpty || faqHide
    self.closeFAQButton.isHidden = self.faqButton.isHidden

    let swipeToCancelHide = !KNAppTracker.needShowCancelOpenOrderTutorial()
    self.tutorialContainerView.isHidden = self.viewModel.displayedOrders.isEmpty || swipeToCancelHide
    self.orderCollectionView.reloadData()
  }

  fileprivate func openFilterView() {
    let allPairs = self.viewModel.orders.map({ return "\($0.srcTokenSymbol) ➞ \($0.destTokenSymbol)" }).unique.sorted(by: { return $0 < $1 })
    let allAddresses = self.viewModel.orders
      .map({ (order) -> String in
        let addr = order.sender.lowercased()
        return "\(addr.prefix(6))...\(addr.suffix(4))"
      }).unique.sorted(by: { return $0 < $1 })
    let viewModel = KNFilterLimitOrderViewModel(
      isDateDesc: self.viewModel.isDateDesc,
      pairs: self.viewModel.selectedPairs,
      status: self.viewModel.selectedStates,
      addresses: self.viewModel.selectedAddresses,
      allPairs: allPairs,
      allAddresses: allAddresses
    )
    self.filterVC = KNFilterLimitOrderViewController(viewModel: viewModel)
    self.filterVC?.delegate = self
    self.filterVC?.loadViewIfNeeded()

    self.navigationController?.pushViewController(self.filterVC!, animated: true)
  }

  func updateListOrders(_ orders: [KNOrderObject]) {
    self.viewModel.updateOrders(orders)
    self.updateCollectionView()
  }

  func openHistoryOrders() {
    self.updateSelectOrdersType(isOpen: false)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_manager_cancel", customAttributes: nil)
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func openOrdersButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_manager_open_order_tapped", customAttributes: nil)
    self.updateSelectOrdersType(isOpen: true)
  }

  @IBAction func orderHistoryButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_manager_close_order_tapped", customAttributes: nil)
    self.updateSelectOrdersType(isOpen: false)
  }

  @IBAction func turnOffTutorialButtonPressed(_ sender: Any) {
    self.updateCancelOrderTutorial(isHidden: true)
  }

  @IBAction func turnOffFAQButtonPressed(_ sender: Any) {
    self.updateFAQButtonHidden(isHidden: true)
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_manager_filter", customAttributes: nil)
    self.openFilterView()
  }

  @IBAction func openFAQButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manageorder_faq_button_tapped", customAttributes: nil)
    let url = "\(KNEnvironment.default.kyberswapURL)/faq#I-submitted-the-limit-order-but-it-was-not-triggered-even-though-my-desired-price-was-hit"
    self.navigationController?.openSafari(with: url)
  }

  @objc func userDidRefreshBalanceView(_ sender: Any?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      // reload data
      self.refreshControl.endRefreshing()
      self.loadListOrders(isDisplayLoading: false)
    }
  }

  fileprivate func loadListOrders(isDisplayLoading: Bool = false) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else {
      self.navigationController?.popViewController(animated: true)
      return
    }
    if isDisplayLoading { self.displayLoading() }

    var orders: [KNOrderObject] = []
    var errorMessage: String?

    let group = DispatchGroup()
    for id in 0..<self.viewModel.numberPages {
      group.enter()
      KNLimitOrderServerCoordinator.shared.getListOrders(accessToken: accessToken, pageIndex: id + 1, pageSize: self.viewModel.kPageSize) { [weak self] result in
        guard let _ = self else {
          group.leave()
          return
        }
        switch result {
        case .success(let ords):
          ords.forEach({ or in
            if orders.first(where: { o -> Bool in return o.id == or.id }) == nil {
              orders.append(or)
            }
          })
        case .failure:
          KNCrashlyticsUtil.logCustomEvent(withName: "manageorder_list_order_fail_to_load", customAttributes: nil)
          errorMessage = "Can not load your orders right now".toBeLocalised()
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      if isDisplayLoading { self.hideLoading() }
      if errorMessage == nil {
        self.updateListOrders(orders.map({ return $0.clone() }))
      } else if let error = errorMessage, isDisplayLoading {
        let alert = UIAlertController(
          title: NSLocalizedString("error", value: "Error", comment: ""),
          message: error,
          preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("try.again", value: "Try Again", comment: ""), style: .default, handler: { _ in
          self.loadListOrders(isDisplayLoading: true)
        }))
      }
    }
  }
}

// MARK: Related orders
extension KNManageOrdersViewController: UICollectionViewDelegateFlowLayout {
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

extension KNManageOrdersViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    let order: KNOrderObject = {
      let orders = self.viewModel.displaySections[self.viewModel.displayHeaders[indexPath.section]] ?? []
      return orders[indexPath.row]
    }()
    if let cancelOrder = self.viewModel.cancelOrder, cancelOrder.id == order.id {
      self.viewModel.cancelOrder = nil
      collectionView.reloadItems(at: [indexPath])
    } else if order.state == .filled,
      let hash = order.txHash,
      let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint,
      let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.openSafari(with: url)
    } else if order.state == .open {
      self.openCancelOrder(order, completion: nil)
    }
  }
}

extension KNManageOrdersViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.displayHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let date = self.viewModel.displayHeaders[section]
    return self.viewModel.displaySections[date]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNLimitOrderCollectionViewCell.cellID,
      for: indexPath
      ) as! KNLimitOrderCollectionViewCell
    let order: KNOrderObject = {
      let orders = self.viewModel.displaySections[self.viewModel.displayHeaders[indexPath.section]] ?? []
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
    cell.updateCell(with: order, isReset: isReset, bgColor: color)
    cell.delegate = self
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID, for: indexPath) as! KNTransactionCollectionReusableView
      let headerText = self.viewModel.displayHeaders[indexPath.section]
      headerView.updateView(with: headerText)
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

extension KNManageOrdersViewController: KNLimitOrderCollectionViewCellDelegate {
  func limitOrderCollectionViewCell(_ cell: KNLimitOrderCollectionViewCell, cancelPressed order: KNOrderObject) {
    let date = self.viewModel.displayDate(for: order)
    guard let section = self.viewModel.displayHeaders.firstIndex(where: { $0 == date }),
      let row = self.viewModel.displaySections[date]?.firstIndex(where: { $0.id == order.id }) else {
        return // order not exist
    }
    self.openCancelOrder(order) {
      self.viewModel.cancelOrder = nil
      let indexPath = IndexPath(row: row, section: section)
      self.orderCollectionView.reloadItems(at: [indexPath])
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
    let extraPopUp = KNLimitOrderExtraTokenReceivedPopupViewController(order: order)
    extraPopUp.modalPresentationStyle = .overFullScreen
    extraPopUp.modalTransitionStyle = .crossDissolve
    extraPopUp.loadViewIfNeeded()
    self.present(extraPopUp, animated: true, completion: nil)
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

extension KNManageOrdersViewController: KNFilterLimitOrderViewControllerDelegate {
  func filterLimitOrderViewController(_ controller: KNFilterLimitOrderViewController, isDateDesc: Bool, pairs: [String]?, status: [Int], addresses: [String]?) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manageorder_filter_applied_pairs", customAttributes: ["pair": pairs?.joined(separator: ",") ?? "all"])
    self.viewModel.isDateDesc = isDateDesc
    self.viewModel.selectedPairs = pairs
    self.viewModel.selectedStates = status
    self.viewModel.selectedAddresses = addresses
    self.updateCollectionView()
  }
}

extension KNManageOrdersViewController: KNCancelOrderConfirmPopUpDelegate {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manageorder_cancel_order", customAttributes: nil)
    self.loadListOrders(isDisplayLoading: true)
  }
}
