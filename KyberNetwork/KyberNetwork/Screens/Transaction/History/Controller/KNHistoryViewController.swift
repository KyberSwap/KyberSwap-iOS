// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit
//swiftlint:disable empty_count
enum KNHistoryViewEvent {
  case selectTransaction(transaction: Transaction)
  case dismiss
  case cancelTransaction(transaction: Transaction)
  case speedUpTransaction(transaction: Transaction)
}

protocol KNHistoryViewControllerDelegate: class {
  func historyViewController(_ controller: KNHistoryViewController, run event: KNHistoryViewEvent)
}

struct KNHistoryViewModel {
  fileprivate lazy var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()

  fileprivate(set) var tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens

  fileprivate(set) var completedTxData: [String: [Transaction]] = [:]
  fileprivate(set) var completedTxHeaders: [String] = []

  fileprivate(set) var displayingCompletedTxData: [String: [Transaction]] = [:]
  fileprivate(set) var displayingCompletedTxHeaders: [String] = []

  fileprivate(set) var pendingTxData: [String: [Transaction]] = [:]
  fileprivate(set) var pendingTxHeaders: [String] = []

  fileprivate(set) var displayingPendingTxData: [String: [Transaction]] = [:]
  fileprivate(set) var displayingPendingTxHeaders: [String] = []

  fileprivate(set) var currentWallet: KNWalletObject

  fileprivate(set) var isShowingPending: Bool = true

  fileprivate(set) var filters: KNTransactionFilter!

  init(
    tokens: [TokenObject] = KNSupportedTokenStorage.shared.supportedTokens,
    completedTxData: [String: [Transaction]],
    completedTxHeaders: [String],
    pendingTxData: [String: [Transaction]],
    pendingTxHeaders: [String],
    currentWallet: KNWalletObject
    ) {
    self.tokens = tokens
    self.completedTxData = completedTxData
    self.completedTxHeaders = completedTxHeaders
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.currentWallet = currentWallet
    self.isShowingPending = true
    if let filter = KNAppTracker.getLastHistoryFilterData() {
      self.filters = filter
    } else {
      self.filters = KNTransactionFilter(
        from: nil,
        to: nil,
        isSend: true,
        isReceive: true,
        isSwap: true,
        tokens: tokens.map({ return $0.symbol.uppercased() })
      )
    }
    self.updateDisplayingData()
  }

  mutating func updateIsShowingPending(_ isShowingPending: Bool) {
    self.isShowingPending = isShowingPending
  }

  mutating func update(tokens: [TokenObject]) {
    self.tokens = tokens
    if let filter = KNAppTracker.getLastHistoryFilterData() {
      self.filters = filter
    } else {
      self.filters = KNTransactionFilter(
        from: nil,
        to: nil,
        isSend: true,
        isReceive: true,
        isSwap: true,
        tokens: tokens.map({ return $0.symbol.uppercased() })
      )
    }
    self.updateDisplayingData()
  }

  mutating func update(pendingTxData: [String: [Transaction]], pendingTxHeaders: [String]) {
    self.pendingTxData = pendingTxData
    self.pendingTxHeaders = pendingTxHeaders
    self.updateDisplayingData(isCompleted: false)
  }

  mutating func update(completedTxData: [String: [Transaction]], completedTxHeaders: [String]) {
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
    return !(self.isShowingPending && !self.pendingTxHeaders.isEmpty)
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

  func completedTransaction(for row: Int, at section: Int) -> Transaction? {
    let header = self.header(for: section)
    if let trans = self.displayingCompletedTxData[header], trans.count >= row {
      return trans[row]
    }
    return nil
  }

  func pendingTransaction(for row: Int, at section: Int) -> Transaction? {
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
      self.displayingPendingTxHeaders.forEach({
        var txs = self.pendingTxData[$0] ?? []
        txs = txs.filter({ return self.isTransactionIncluded($0) })
        if !txs.isEmpty { self.displayingPendingTxData[$0] = txs }
      })
      self.displayingPendingTxHeaders = self.displayingPendingTxHeaders.filter({ return self.displayingPendingTxData[$0] != nil })
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
      self.displayingCompletedTxHeaders.forEach({
        var txs = self.completedTxData[$0] ?? []
        txs = txs.filter({ return self.isTransactionIncluded($0) })
        if !txs.isEmpty { self.displayingCompletedTxData[$0] = txs }
      })
      self.displayingCompletedTxHeaders = self.displayingCompletedTxHeaders.filter({ return self.displayingCompletedTxData[$0] != nil })
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
      isTokenIncluded = self.filters.tokens.contains(tx.localizedOperations.first?.symbol?.uppercased() ?? "")
    }
    return isTokenIncluded
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
    var json: JSONDictionary = [
      "send": filters.isSend,
      "receive": filters.isReceive,
      "swap": filters.isSwap,
      "tokens": filters.tokens,
    ]
    if let date = filters.from { json["from"] = date.timeIntervalSince1970 }
    if let date = filters.to { json["to"] = date.timeIntervalSince1970 }
    KNAppTracker.saveHistoryFilterData(json: json)
  }
}

class KNHistoryViewController: KNBaseViewController {

  weak var delegate: KNHistoryViewControllerDelegate?
  fileprivate var viewModel: KNHistoryViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var transactionsTextLabel: UILabel!

  @IBOutlet weak var currentAddressLabel: UILabel!
  @IBOutlet weak var currentAddressContainerView: UIView!
  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var emptyStateDescLabel: UILabel!

  @IBOutlet weak var rateMightChangeContainerView: UIView!
  @IBOutlet weak var ratesMightChangeTextLabel: UILabel!
  @IBOutlet weak var ratesMightChangeDescTextLabel: UILabel!
  @IBOutlet weak var bottomPaddingConstraintForRateMightChange: NSLayoutConstraint!

  @IBOutlet weak var pendingButton: UIButton!
  @IBOutlet weak var completedButton: UIButton!

  @IBOutlet weak var transactionCollectionView: UICollectionView!
  @IBOutlet weak var transactionCollectionViewBottomConstraint: NSLayoutConstraint!

  init(viewModel: KNHistoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_tx_history", customAttributes: ["action": "pending_tx"])
    self.setupNavigationBar()
    self.setupCollectionView()
  }

  fileprivate func setupNavigationBar() {
    let style = KNAppStyleType.current
    self.transactionsTextLabel.text = NSLocalizedString("transactions", value: "Transactions", comment: "")
    self.view.backgroundColor = style.mainBackgroundColor
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.pendingButton.setTitle(NSLocalizedString("pending", value: "Pending", comment: ""), for: .normal)
    self.completedButton.setTitle(NSLocalizedString("completed", value: "Completed", comment: ""), for: .normal)
    self.currentAddressLabel.text = self.viewModel.currentWallet.address.lowercased()
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
    self.emptyStateContainerView.isHidden = self.viewModel.isEmptyStateHidden
    self.emptyStateDescLabel.text = self.viewModel.emptyStateDescLabelString

    let isShowingPending = self.viewModel.isShowingPending
    self.pendingButton.setTitleColor(isShowingPending ? UIColor(red: 254, green: 163, blue: 76) : UIColor(red: 46, green: 57, blue: 87), for: .normal)
    self.completedButton.setTitleColor(!isShowingPending ? UIColor(red: 254, green: 163, blue: 76) : UIColor(red: 46, green: 57, blue: 87), for: .normal)

    self.rateMightChangeContainerView.isHidden = self.viewModel.isRateMightChangeHidden
    self.transactionCollectionView.isHidden = self.viewModel.isTransactionCollectionViewHidden
    self.transactionCollectionViewBottomConstraint.constant = self.viewModel.transactionCollectionViewBottomPaddingConstraint + self.bottomPaddingSafeArea()
    let isAddressHidden = self.viewModel.isTransactionCollectionViewHidden
    self.currentAddressLabel.isHidden = isAddressHidden
    self.currentAddressContainerView.isHidden = isAddressHidden
    self.currentAddressLabel.text = self.viewModel.currentWallet.address
    self.transactionCollectionView.reloadData()
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraintsIfNeeded()
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.historyViewController(self, run: .dismiss)
  }

  fileprivate func updateDisplayTxsType(_ isShowPending: Bool) {
    self.viewModel.updateIsShowingPending(isShowPending)
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_tx_history", customAttributes: ["action": self.viewModel.isShowingPending ? "pending_tx" : "mined_tx"])
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.historyViewController(self, run: .dismiss)
    }
  }

  @IBAction func filterButtonPressed(_ sender: Any) {
    let tokenSymbols: [String] = {
      return self.viewModel.tokens.sorted(by: {
        if $0.isSupported && !$1.isSupported { return true }
        if !$0.isSupported && $1.isSupported { return false }
        return $0.value > $1.value
      }).map({ return $0.symbol })
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

  @IBAction func pendingButtonPressed(_ sender: Any) {
    self.viewModel.updateIsShowingPending(true)
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_tx_history", customAttributes: ["action": self.viewModel.isShowingPending ? "pending_tx" : "mined_tx"])
  }

  @IBAction func completedButtonPressed(_ sender: Any) {
    self.viewModel.updateIsShowingPending(false)
    self.updateUIWhenDataDidChange()
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_tx_history", customAttributes: ["action": self.viewModel.isShowingPending ? "pending_tx" : "mined_tx"])
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateCompletedTransactions(
    data: [String: [Transaction]],
    dates: [String],
    currentWallet: KNWalletObject
    ) {
    self.viewModel.update(completedTxData: data, completedTxHeaders: dates)
    self.viewModel.updateCurrentWallet(currentWallet)
    self.updateUIWhenDataDidChange()
  }

  func coordinatorUpdatePendingTransaction(
    data: [String: [Transaction]],
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

  func coordinatorUpdateTokens(_ tokens: [TokenObject]) {
    self.viewModel.update(tokens: tokens)
  }
}

extension KNHistoryViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_tx_history", customAttributes: ["action": "selected_tx"])
    if self.viewModel.isShowingPending {
      guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
    } else {
      guard let transaction = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return }
      self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
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
      height: 44
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
    cell.actionDelegate = self
    if self.viewModel.isShowingPending {
      guard let tx = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      let model = KNHistoryTransactionCollectionViewModel(
        transaction: tx,
        ownerAddress: self.viewModel.currentWallet.address,
        ownerWalletName: self.viewModel.currentWallet.name,
        index: indexPath.row
      )
      cell.updateCell(with: model)
    } else {
      guard let tx = self.viewModel.completedTransaction(for: indexPath.row, at: indexPath.section) else { return cell }
      let model = KNHistoryTransactionCollectionViewModel(
        transaction: tx,
        ownerAddress: self.viewModel.currentWallet.address,
        ownerWalletName: self.viewModel.currentWallet.name,
        index: indexPath.row
      )
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

extension KNHistoryViewController: KNHistoryTransactionCollectionViewCellDelegate {
  func historyTransactionCollectionViewCell(_ cell: KNHistoryTransactionCollectionViewCell, openDetails transaction: Transaction) {
    self.delegate?.historyViewController(self, run: .selectTransaction(transaction: transaction))
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
    guard let transaction = self.viewModel.pendingTransaction(for: indexPath.row, at: indexPath.section), transaction.type == .normal else { return nil }
    let speedUp = SwipeAction(style: .default, title: nil) { (_, _) in
      KNCrashlyticsUtil.logCustomEvent(withName: "select_speedup_transaction", customAttributes: ["transactionHash": transaction.id])
      self.delegate?.historyViewController(self, run: .speedUpTransaction(transaction: transaction))
    }
    speedUp.hidesWhenSelected = true
    speedUp.title = NSLocalizedString("speed up", value: "Speed Up", comment: "")
    speedUp.font = UIFont.Kyber.semiBold(with: 14)
    speedUp.backgroundColor = UIColor.Kyber.speedUpOrange
    let cancel = SwipeAction(style: .destructive, title: nil) { _, _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "select_cancel_transaction", customAttributes: ["transactionHash": transaction.id])
      self.delegate?.historyViewController(self, run: .cancelTransaction(transaction: transaction))
    }
    cancel.title = NSLocalizedString("cancel", value: "Cancel", comment: "")
    cancel.font = UIFont.Kyber.semiBold(with: 14)
    cancel.backgroundColor = UIColor.Kyber.cancelGray
    return [cancel, speedUp]
  }
  func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .destructive
    options.maximumButtonWidth = 96.0
    return options
  }
}
