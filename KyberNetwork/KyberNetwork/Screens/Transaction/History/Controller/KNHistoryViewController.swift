// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
import BetterSegmentedControl

//swiftlint:disable file_length
enum KNHistoryViewEvent {
  case selectPendingTransaction(transaction: InternalHistoryTransaction)
  case selectCompletedTransaction(data: CompletedHistoryTransactonViewModel)
  case dismiss
  case cancelTransaction(transaction: InternalHistoryTransaction)
  case speedUpTransaction(transaction: InternalHistoryTransaction)
  case quickTutorial(pointsAndRadius: [(CGPoint, CGFloat)])
  case openEtherScanWalletPage
  case openKyberWalletPage
  case openWalletsListPopup
  case swap
}

protocol KNHistoryViewControllerDelegate: class {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent)
}

struct KNHistoryViewModel {
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  fileprivate(set) var tokens: [Token]

  fileprivate(set) var completedTxData: [String: [HistoryTransaction]] = [:]
  fileprivate(set) var completedTxHeaders: [String] = []

  fileprivate(set) var displayingCompletedTxData: [String: [CompletedHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingCompletedTxHeaders: [String] = []

  fileprivate(set) var pendingTxData: [String: [InternalHistoryTransaction]] = [:]
  fileprivate(set) var pendingTxHeaders: [String] = []

  fileprivate(set) var displayingPendingTxData: [String: [PendingInternalHistoryTransactonViewModel]] = [:]
  fileprivate(set) var displayingPendingTxHeaders: [String] = []

  fileprivate(set) var currentWallet: KNWalletObject

  fileprivate(set) var isShowingPending: Bool = true

  fileprivate(set) var filters: KNTransactionFilter!

  init(
    tokens: [Token] = EtherscanTransactionStorage.shared.getEtherscanToken(),
    currentWallet: KNWalletObject
    ) {
    self.tokens = tokens
    self.currentWallet = currentWallet
    self.isShowingPending = true
    self.filters = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      tokens: tokens.map({ return $0.symbol })
    )
    self.updateDisplayingData()
  }

  mutating func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  mutating func update(tokens: [Token]) {
    self.tokens = tokens
    self.filters = KNTransactionFilter(
      from: nil,
      to: nil,
      isSend: true,
      isReceive: true,
      isSwap: true,
      isApprove: true,
      isWithdraw: true,
      isTrade: true,
      isContractInteraction: true,
      tokens: tokens.map({ return $0.symbol })
    )
    self.updateDisplayingData()
  }

  mutating func update(pendingTxData: [String: [InternalHistoryTransaction]], pendingTxHeaders: [String]) {
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

  mutating func update(completedTxData: [String: [HistoryTransaction]], completedTxHeaders: [String]) {
    self.completedTxData = completedTxData
    self.completedTxHeaders = completedTxHeaders
    self.updateDisplayingData(isPending: false)
  }

  mutating func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.currentWallet = currentWallet
  }

  var isEmptyStateHidden: Bool {
    if self.isShowingPending { return !self.displayingPendingTxHeaders.isEmpty }
    return !self.displayingCompletedTxHeaders.isEmpty
  }

  var emptyStateIconName: String {
    return self.isShowingPending ? "no_pending_tx_icon" : "no_mined_tx_icon"
  }

  var emptyStateDescLabelString: String {
    let noPendingTx = NSLocalizedString("you.do.not.have.any.pending.transactions", value: "You do not have any pending transactions.", comment: "")
    let noCompletedTx = NSLocalizedString("you.do.not.have.any.completed.transactions", value: "You do not have any completed transactions.", comment: "")
    let noMatchingFound = NSLocalizedString("no.matching.data", value: "No matching data", comment: "")
    if self.isShowingPending {
      return self.pendingTxHeaders.isEmpty ? noPendingTx : noMatchingFound
    }
    return self.completedTxHeaders.isEmpty ? noCompletedTx : noMatchingFound
  }

  var isRateMightChangeHidden: Bool {
    return true //TODO: temp disable warning message
//    return !(self.isShowingPending && !self.pendingTxHeaders.isEmpty)
  }

  var transactionCollectionViewBottomPaddingConstraint: CGFloat {
    return self.isRateMightChangeHidden ? 0.0 : 192.0
  }

  var isTransactionCollectionViewHidden: Bool {
    return !self.isEmptyStateHidden
  }

  var numberSections: Int {
    if self.isShowingPending { return self.displayingPendingTxHeaders.count }
    return self.displayingCompletedTxHeaders.count
  }

  func header(for section: Int) -> String {
    let header: String = {
      if self.isShowingPending { return self.displayingPendingTxHeaders[section] }
      return self.displayingCompletedTxHeaders[section]
    }()
    return header
  }

  func numberRows(for section: Int) -> Int {
    let header = self.header(for: section)
    return (self.isShowingPending ? self.displayingPendingTxData[header]?.count : self.displayingCompletedTxData[header]?.count) ?? 0
  }

  func completedTransaction(for row: Int, at section: Int) -> CompletedHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingCompletedTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func pendingTransaction(for row: Int, at section: Int) -> PendingInternalHistoryTransactonViewModel? {
    let header = self.header(for: section)
    if let trans = self.displayingPendingTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  mutating func updateDisplayingData(isPending: Bool = true, isCompleted: Bool = true) {
    let fromDate = self.filters.from ?? Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    let toDate = self.filters.to ?? Date().addingTimeInterval(24.0 * 60.0 * 60.0)

    if isPending {
      self.displayingPendingTxHeaders = {
        let data = self.pendingTxHeaders.filter({
          let date = self.dateFormatter.date(from: $0) ?? Date()
          return date >= fromDate && date <= toDate
        })
        return data
      }()
      self.displayingPendingTxData = [:]
//      self.displayingPendingTxHeaders.forEach({
//        var txs = self.pendingTxData[$0] ?? []
//        txs = txs.filter({ return self.isTransactionIncluded($0) })
//        if !txs.isEmpty { self.displayingPendingTxData[$0] = txs }
//      })
//      self.displayingPendingTxHeaders = self.displayingPendingTxHeaders.filter({ return self.displayingPendingTxData[$0] != nil })
      //TODO: fileter data
      self.displayingPendingTxHeaders.forEach { (header) in
        let items = self.pendingTxData[header]?.map({ (item) -> PendingInternalHistoryTransactonViewModel in
          return PendingInternalHistoryTransactonViewModel(index: 0, transaction: item)
        })
        self.displayingPendingTxData[header] = items
      }
    }

    if isCompleted {
      self.displayingCompletedTxHeaders = {
        let data = self.completedTxHeaders.filter({
          let date = self.dateFormatter.date(from: $0) ?? Date()
          return date >= fromDate && date <= toDate
        })
        return data
      }()
      self.displayingCompletedTxData = [:]
      self.displayingCompletedTxHeaders.forEach { (header) in
        let items = self.completedTxData[header]?.filter({ return self.isCompletedTransactionIncluded($0) }).enumerated().map { (item) -> CompletedHistoryTransactonViewModel in
          return CompletedHistoryTransactonViewModel(data: item.1, index: item.0)
        } ?? []
        self.displayingCompletedTxData[header] = items
      }
    }
  }

  fileprivate func isTransactionIncluded(_ tx: Transaction) -> Bool {
    let type = tx.localizedOperations.first?.type ?? ""
    var isTokenIncluded: Bool = false
    if type == "exchange" {
      if !self.filters.isSwap { return false } // not swap
      isTokenIncluded = self.filters.tokens.contains(tx.localizedOperations.first?.symbol?.uppercased() ?? "") || self.filters.tokens.contains(tx.localizedOperations.first?.name?.uppercased() ?? "")
    } else {
      // not include send, but it is a send tx
      if !self.filters.isSend && tx.from.lowercased() == self.currentWallet.address.lowercased() { return false }
      // not include receive, but it is a receive tx
      if !self.filters.isReceive && tx.to.lowercased() == self.currentWallet.address.lowercased() { return false }
      let symbol = tx.localizedOperations.first?.symbol?.uppercased() ?? ""
      if symbol.isEmpty && ( tx.state == .error || tx.state == .failed ) { return true }
      isTokenIncluded = self.filters.tokens.contains(tx.localizedOperations.first?.symbol?.uppercased() ?? "")
    }
    return isTokenIncluded
  }
  
  fileprivate func isCompletedTransactionIncluded(_ tx: HistoryTransaction) -> Bool {
    let matchedTransfer = (tx.type == .transferETH || tx.type == .transferToken) && self.filters.isSend
    let matchedReceive = ( tx.type == .receiveETH || tx.type == .receiveToken) && self.filters.isReceive
    let matchedSwap = tx.type == .swap && self.filters.isSwap
    let matchedAppprove = tx.type == .allowance && self.filters.isApprove
    let matchedWithdraw = tx.type == .withdraw && self.filters.isWithdraw
    let matchedTrade = tx.type == .earn && self.filters.isTrade
    let matchedContractInteraction = tx.type == .contractInteraction && self.filters.isContractInteraction
    let matchedSelf = tx.type == .selfTransfer && tx.type == .transferETH
    let matchedType = matchedTransfer || matchedReceive || matchedSwap || matchedAppprove || matchedWithdraw || matchedTrade || matchedContractInteraction || matchedSelf
    var tokenMatched = true
    var transactionToken: [String] = []
    tx.tokenTransactions.forEach { (item) in
      if !transactionToken.contains(item.tokenSymbol) {
        transactionToken.append(item.tokenSymbol)
      }
    }
    if tx.type == .transferETH || tx.type == .receiveETH {
      tokenMatched = self.filters.tokens.contains("ETH")
    } else {
      tokenMatched = Set(transactionToken).isSubset(of: Set(self.filters.tokens))
    }
    
    return tokenMatched && matchedType
  }

  var normalAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.foregroundColor: UIColor.white,
  ]

  var selectedAttributes: [NSAttributedStringKey: Any] = [
    NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    NSAttributedStringKey.foregroundColor: UIColor.Kyber.enygold,
  ]

  mutating func updateFilters(_ filters: KNTransactionFilter) {
    self.filters = filters
    self.updateDisplayingData()
//    var json: JSONDictionary = [
//      "send": filters.isSend,
//      "receive": filters.isReceive,
//      "swap": filters.isSwap,
//      "approve": filters.isApprove,
//      "withdraw": filters.isWithdraw,
//      "trade": filters.isTrade,
//      "tokens": filters.tokens,
//    ]
//    if let date = filters.from { json["from"] = date.timeIntervalSince1970 }
//    if let date = filters.to { json["to"] = date.timeIntervalSince1970 }
    KNAppTracker.saveHistoryFilterData(filters)
  }

  var isShowingQuickTutorial: Bool = false

  var timeForLongPendingTx: Double {
    return KNEnvironment.default == .ropsten ? 30.0 : 300
  }

  var isShowQuickTutorialForLongPendingTx: Bool {
    return UserDefaults.standard.bool(forKey: Constants.kisShowQuickTutorialForLongPendingTx)
  }
}

class KNHistoryViewController: KNBaseViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate var viewModel: KNHistoryViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!

  @IBOutlet weak var emptyStateContainerView: UIView!

  @IBOutlet weak var rateMightChangeContainerView: UIView!
  @IBOutlet weak var ratesMightChangeTextLabel: UILabel!
  @IBOutlet weak var ratesMightChangeDescTextLabel: UILabel!
  @IBOutlet weak var bottomPaddingConstraintForRateMightChange: NSLayoutConstraint!

  @IBOutlet weak var transactionCollectionView: UICollectionView!
  @IBOutlet weak var transactionCollectionViewBottomConstraint: NSLayoutConstraint!
  fileprivate var quickTutorialTimer: Timer?
  var animatingCell: UICollectionViewCell?
  @IBOutlet weak var segmentedControl: BetterSegmentedControl!
  @IBOutlet weak var filterButton: UIButton!
  @IBOutlet weak var walletSelectButton: UIButton!
  @IBOutlet weak var swapNowButton: UIButton!
  
  init(viewModel: KNHistoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.quickTutorialTimer?.invalidate()
    self.quickTutorialTimer = nil
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIWhenDataDidChange()
  }

  fileprivate func showQuickTutorial() {
//    let collectionViewOrigin = self.transactionCollectionView.frame.origin
//    let collectionViewSize = self.transactionCollectionView.frame.size
//    let event = KNHistoryViewEvent.quickTutorial(pointsAndRadius: [(CGPoint(x: collectionViewOrigin.x + collectionViewSize.width - 77 * 1.5, y: collectionViewOrigin.y + 30 + 44), 115)])
//    self.delegate?.historyViewController(self, run: event)
//    self.animateReviewCellActionForTutorial()
//    self.viewModel.isShowingQuickTutorial = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
//    if !self.viewModel.pendingTxData.isEmpty && NSObject.isNeedShowTutorial(for: Constants.isDoneShowQuickTutorialForHistoryView) {
//      NSObject.updateDoneTutorial(for: Constants.isDoneShowQuickTutorialForHistoryView, duplicateCheck: true)
//      self.showQuickTutorial()
//      KNCrashlyticsUtil.logCustomEvent(withName: "tut_history_startup_quick_tutorial", customAttributes: nil)
//    }
//    if !self.viewModel.isShowQuickTutorialForLongPendingTx {
//      self.quickTutorialTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (_) in
//        if self.checkHavePendingTxOver5Min() && self.viewModel.isShowingQuickTutorial == false {
//          self.showQuickTutorial()
//          self.quickTutorialTimer?.invalidate()
//          self.quickTutorialTimer = nil
//          UserDefaults.standard.set(true, forKey: Constants.kisShowQuickTutorialForLongPendingTx)
//          KNCrashlyticsUtil.logCustomEvent(withName: "tut_history_show_after_over_5_min_tx", customAttributes: nil)
//        }
//      })
//    } else {
//      self.quickTutorialTimer?.invalidate()
//      self.quickTutorialTimer = nil
//    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.quickTutorialTimer?.invalidate()
    self.quickTutorialTimer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
  }

  fileprivate func setupUI() {
    KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_pending_tx", customAttributes: nil)
    self.setupNavigationBar()
    self.setupCollectionView()
    
    self.segmentedControl.segments = LabelSegment.segments(withTitles: ["completed".toBeLocalised().uppercased(), "pending".toBeLocalised().uppercased()],
                                                           normalFont: UIFont(name: "Lato-Bold", size: 8)!,
                                                           normalTextColor: UIColor(red: 226, green: 231, blue: 244),
                                                           selectedFont: UIFont(name: "Lato-Bold", size: 8)!,
                                                           selectedTextColor: UIColor.white
    )
    self.segmentedControl.setIndex(1)
    self.segmentedControl.addTarget(self, action: #selector(KNHistoryViewController.segmentedControlValueChanged(_:)), for: .valueChanged)
    self.filterButton.rounded(radius: 10)
    self.walletSelectButton.rounded(radius: self.walletSelectButton.frame.size.height / 2)
    self.walletSelectButton.setTitle(self.viewModel.currentWallet.address, for: .normal)
    self.swapNowButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.swapNowButton.frame.size.height / 2)
  }

  override func quickTutorialNextAction() {
    self.dismissTutorialOverlayer()
    self.animateResetReviewCellActionForTutorial()
    self.viewModel.isShowingQuickTutorial = false
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: "tut_history_got_it_button_tapped", customAttributes: nil)
  }

  fileprivate func animateReviewCellActionForTutorial() {
    guard let firstCell = self.transactionCollectionView.cellForItem(at: IndexPath(row: 0, section: 0)) else { return }
    let speedupLabel = UILabel(frame: CGRect(x: firstCell.frame.size.width, y: 0, width: 77, height: 60))
    let cancelLabel = UILabel(frame: CGRect(x: firstCell.frame.size.width + 77, y: 0, width: 77, height: 60))
    self.animatingCell = firstCell
    firstCell.clipsToBounds = false

    speedupLabel.text = "speed up".toBeLocalised()
    speedupLabel.textAlignment = .center
    speedupLabel.font = UIFont.Kyber.bold(with: 14)
    speedupLabel.backgroundColor = UIColor.Kyber.speedUpOrange
    speedupLabel.textColor = .white
    speedupLabel.tag = 101

    cancelLabel.text = "cancel".toBeLocalised()
    cancelLabel.textAlignment = .center
    cancelLabel.font = UIFont.Kyber.bold(with: 14)
    cancelLabel.backgroundColor = UIColor.Kyber.cancelGray
    cancelLabel.textColor = .white
    cancelLabel.tag = 102

    firstCell.contentView.addSubview(speedupLabel)
    firstCell.contentView.addSubview(cancelLabel)
    UIView.animate(withDuration: 0.3) {
      firstCell.frame = CGRect(x: firstCell.frame.origin.x - 77 * 2, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
    }
  }

  fileprivate func animateResetReviewCellActionForTutorial() {
    guard let firstCell = self.animatingCell else { return }
    let speedupLabel = firstCell.viewWithTag(101)
    let cancelLabel = firstCell.viewWithTag(102)
    UIView.animate(withDuration: 0.3, animations: {
      firstCell.frame = CGRect(x: 0, y: firstCell.frame.origin.y, width: firstCell.frame.size.width, height: firstCell.frame.size.height)
    }, completion: { _ in
      speedupLabel?.removeFromSuperview()
      cancelLabel?.removeFromSuperview()
      self.animatingCell = nil
    })
  }

  fileprivate func checkHavePendingTxOver5Min() -> Bool {
    var flag = false
    self.viewModel.pendingTxData.keys.forEach { (key) in
      self.viewModel.pendingTxData[key]?.forEach({ (tx) in
        if abs(tx.time.timeIntervalSinceNow) >= self.viewModel.timeForLongPendingTx {
          flag = true
        }
      })
    }

    return flag
  }

  fileprivate func setupNavigationBar() {
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
    //TODO: set address text for address select button
//    self.currentAddressLabel.text = self.viewModel.currentWallet.address.lowercased()
    self.updateDisplayTxsType(self.viewModel.isShowingPending)
  }

  fileprivate func setupCollectionView() {
    let nib = UINib(nibName: KNHistoryTransactionCollectionViewCell.className, bundle: nil)
    self.transactionCollectionView.register(nib, forCellWithReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.transactionCollectionView.register(headerNib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: KNTransactionCollectionReusableView.viewID)
    self.transactionCollectionView.delegate = self
    self.transactionCollectionView.dataSource = self

    self.ratesMightChangeTextLabel.text = NSLocalizedString("rates.might.change", value: "Rates might change", comment: "")
    self.ratesMightChangeDescTextLabel.text = NSLocalizedString("rates.for.token.swap.are.not.final.until.mined", value: "Rates for token swap are not final until swapping transactions are completed (mined)", comment: "")
    self.bottomPaddingConstraintForRateMightChange.constant = self.bottomPaddingSafeArea()
    self.updateUIWhenDataDidChange()
  }

  fileprivate func updateUIWhenDataDidChange() {
    guard self.viewModel.isShowingQuickTutorial == false else {
      return
    }
    self.emptyStateContainerView.isHidden = self.viewModel.isEmptyStateHidden

    self.rateMightChangeContainerView.isHidden = self.viewModel.isRateMightChangeHidden
    self.transactionCollectionView.isHidden = self.viewModel.isTransactionCollectionViewHidden
    self.transactionCollectionViewBottomConstraint.constant = self.viewModel.transactionCollectionViewBottomPaddingConstraint + self.bottomPaddingSafeArea()
    
    self.transactionCollectionView.reloadData()
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.historyViewController(self, run: .dismiss)
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: .swap)
  }

  fileprivate func updateDisplayTxsType(_ isShowPending: Bool) {
    self.viewModel.updateIsShowingPending(isShowPending)
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: self.viewModel.isShowingPending ? "txhistory_pending_tx" : "txhistory_mined_tx", customAttributes: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.historyViewController(self, run: .dismiss)
    }
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    let tokenSymbols: [String] = {
      return self.viewModel.tokens.map({ return $0.symbol })
    }()
    let viewModel = KNTransactionFilterViewModel(
      tokens: tokenSymbols,
      filter: self.viewModel.filters
    )
    let filterVC = KNTransactionFilterViewController(viewModel: viewModel)
    filterVC.loadViewIfNeeded()
    filterVC.delegate = self
    self.navigationController?.pushViewController(filterVC, animated: true)
  }

  @IBAction func emptyStateEtherScanButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openEtherScanWalletPage)
    KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_empty_state_etherscan_tapped", customAttributes: nil)
  }

  @IBAction func emptyStateKyberButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openKyberWalletPage)
    KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_empty_state_enjin_tapped", customAttributes: nil)
  }

  @objc func segmentedControlValueChanged(_ sender: BetterSegmentedControl) {
    self.viewModel.updateIsShowingPending(sender.index == 1)
    self.updateUIWhenDataDidChange()
  }

  @IBAction func walletSelectButtonTapped(_ sender: UIButton) {
    self.delegate?.historyViewController(self, run: KNHistoryViewEvent.openWalletsListPopup)
  }
}

extension KNHistoryViewController {
  func coordinatorUpdatePendingTransaction(
    data: [String: [InternalHistoryTransaction]],
    dates: [String],
    currentWallet: KNWalletObject
    ) {
    self.viewModel.update(pendingTxData: data, pendingTxHeaders: dates)
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateWalletObjects() {
    guard let currentWallet = KNWalletStorage.shared.get(forPrimaryKey: self.viewModel.currentWallet.address) else { return }
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdateTokens() {
    //TODO: handle update new token from etherscan
  }

  func coordinatorDidUpdateCompletedTransaction(sections: [String], data: [String: [HistoryTransaction]]) {
    self.viewModel.update(completedTxData: data, completedTxHeaders: sections)
    self.transactionCollectionView.reloadData()
  }

  func coordinatorUpdateNewSession(wallet: KNWalletObject) {
    self.viewModel.updateCurrentWallet(wallet)
    self.walletSelectButton.setTitle(wallet.address, for: .normal)
    self.viewModel.update(tokens: EtherscanTransactionStorage.shared.getEtherscanToken())
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    KNCrashlyticsUtil.logCustomEvent(withName: "txhistory_selected_tx", customAttributes: nil)
    if self.viewModel.isShowingPending {
      guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectPendingTransaction(transaction: transaction.internalTransaction))
    } else {
      guard let transaction = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectCompletedTransaction(data: transaction))
    }
  }
}

extension KNHistoryViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      return CGSize(
        width: collectionView.frame.width,
        height: KNHistoryTransactionCollectionViewCell.height
      )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 24
    )
  }
}

extension KNHistoryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.viewModel.numberSections
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows(for: section)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: KNHistoryTransactionCollectionViewCell.cellID, for: indexPath) as! KNHistoryTransactionCollectionViewCell
    cell.delegate = self
    if self.viewModel.isShowingPending {
      guard let model = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model)
    } else {
      guard let model = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      cell.updateCell(with: model)
    }
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.viewID, for: indexPath) as! KNTransactionCollectionReusableView
      headerView.updateView(with: self.viewModel.header(for: indexPath.section))
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}

extension KNHistoryViewController: KNTransactionFilterViewControllerDelegate {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply filter: KNTransactionFilter) {
    self.viewModel.updateFilters(filter)
    self.updateUIWhenDataDidChange()
  }
}

extension KNHistoryViewController: SwipeCollectionViewCellDelegate {
  func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard self.viewModel.isShowingPending else {
      return nil
    }
    guard orientation == .right else {
      return nil
    }
    guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section)  else { return nil }
    let speedUp = SwipeAction(style: .default, title: nil) { (_, _) in
      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_speedup", customAttributes: nil)
      self.delegate?.historyViewController(self, run: .speedUpTransaction(transaction: transaction.internalTransaction))
    }
    speedUp.hidesWhenSelected = true
    speedUp.title = NSLocalizedString("speed up", value: "Speed Up", comment: "").uppercased()
    speedUp.textColor = UIColor.Kyber.SWYellow
    speedUp.font = UIFont.Kyber.latoBold(with: 10)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 46))!
    speedUp.backgroundColor = UIColor(patternImage: resized)
    let cancel = SwipeAction(style: .destructive, title: nil) { _, _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "transaction_cancel", customAttributes: nil)
      self.delegate?.historyViewController(self, run: .cancelTransaction(transaction: transaction.internalTransaction))
    }

    cancel.title = NSLocalizedString("cancel", value: "Cancel", comment: "").uppercased()
    cancel.textColor = UIColor.Kyber.SWYellow
    cancel.font = UIFont.Kyber.latoBold(with: 10)
    cancel.backgroundColor = UIColor(patternImage: resized)
    return [cancel, speedUp]
  }

  func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .destructive
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
