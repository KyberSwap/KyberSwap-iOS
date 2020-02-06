// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import MBProgressHUD

enum KNBalanceTabHamburgerMenuViewEvent {
  case select(wallet: KNWalletObject)
  case selectAddWallet
  case selectSendToken
  case selectAllTransactions
  case selectPromoCode
  case selectNotifications
  case selectWalletConnect
}

protocol KNBalanceTabHamburgerMenuViewControllerDelegate: class {
  func balanceTabHamburgerMenuViewController(_ controller: KNBalanceTabHamburgerMenuViewController, run event: KNBalanceTabHamburgerMenuViewEvent)
}

struct KNBalanceTabHamburgerMenuViewModel {

  var pendingTransactions: [KNTransaction] = []
  var wallets: [KNWalletObject]
  var currentWallet: KNWalletObject

  init(
    walletObjects: [KNWalletObject],
    currentWallet: KNWalletObject,
    transactions: [KNTransaction] = []) {
    self.wallets = walletObjects
    self.currentWallet = currentWallet
    self.pendingTransactions = transactions
  }

  func wallet(at row: Int) -> KNWalletObject {
    return self.wallets[row]
  }

  var numberWalletRows: Int {
    return self.wallets.count
  }

  var walletCellRowHeight: CGFloat {
    return 66.0
  }

  var walletTableViewHeight: CGFloat {
    return min(270.0, self.walletCellRowHeight * CGFloat(self.numberWalletRows))
  }

  var tableHeightScrollEnabled: Bool {
    return self.walletCellRowHeight * CGFloat(self.numberWalletRows) > 270.0
  }

  mutating func update(wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = wallets
    self.currentWallet = currentWallet
  }

  func transaction(at row: Int) -> KNTransaction? {
    if row >= self.pendingTransactions.count { return nil }
    return self.pendingTransactions[row]
  }

  var numberTransactions: Int {
    return min(self.pendingTransactions.count, 2)
  }

  var isTransactionTableHidden: Bool {
    return self.numberTransactions == 0
  }

  mutating func update(transactions: [KNTransaction]) {
    self.pendingTransactions = transactions
  }
}

class KNBalanceTabHamburgerMenuViewController: KNBaseViewController {

  fileprivate let kWalletTableViewCellID: String = "kKNBalanceTabHamburgerMenuTableViewCellID"
  fileprivate let kPendingTableViewCellID: String = "kPendingTableViewCellID"

  @IBOutlet weak var tabToDismissView: UIView!
  @IBOutlet weak var pendingTransactionContainerView: UIView!
  @IBOutlet weak var allTransactionButton: UIButton!
  @IBOutlet weak var numberPendingTxLabel: UILabel!

  @IBOutlet weak var promoCodeContainerView: UIView!
  @IBOutlet weak var promoCodeTextLabel: UILabel!
  @IBOutlet weak var mywalletsTextLabel: UILabel!
  @IBOutlet weak var hamburgerView: UIView!
  @IBOutlet weak var walletListTableView: UITableView!
  @IBOutlet weak var walletListTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var walletConnectLabel: UILabel!
  @IBOutlet weak var walletConnectView: UIView!

  @IBOutlet weak var notificationsTextLabel: UILabel!
  @IBOutlet weak var unreadNotiLabel: UILabel!
  @IBOutlet weak var notificationContainerView: UIView!

  @IBOutlet weak var sendTokenButton: UIButton!
  @IBOutlet weak var hamburgerMenuViewTrailingConstraint: NSLayoutConstraint!

  @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
  fileprivate var screenEdgePanRecognizer: UIScreenEdgePanGestureRecognizer?
  fileprivate var longPressTimer: Timer?

  fileprivate var viewModel: KNBalanceTabHamburgerMenuViewModel
  weak var delegate: KNBalanceTabHamburgerMenuViewControllerDelegate?

  init(viewModel: KNBalanceTabHamburgerMenuViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBalanceTabHamburgerMenuViewController.className, bundle: nil)
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
    self.setupUI()

    let name = Notification.Name(kUpdateListNotificationsKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.notificationDidUpdate(_:)),
      name: name,
      object: nil
    )
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    self.view.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.backgroundViewTap(_:)))
    self.tabToDismissView.addGestureRecognizer(tapGesture)

    self.walletListTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletListTableView.rowHeight = self.viewModel.walletCellRowHeight
    self.walletListTableView.delegate = self
    self.walletListTableView.dataSource = self
    self.walletListTableViewHeightConstraint.constant = viewModel.walletTableViewHeight
    self.walletListTableView.isScrollEnabled = self.viewModel.tableHeightScrollEnabled

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressedWalletTableView(_:)))
    self.walletListTableView.addGestureRecognizer(longPressGesture)
    self.walletListTableView.isUserInteractionEnabled = true

    self.numberPendingTxLabel.rounded(radius: self.numberPendingTxLabel.frame.height / 2.0)
    self.numberPendingTxLabel.text = "0"
    self.numberPendingTxLabel.isHidden = true

    self.sendTokenButton.setTitle(
      NSLocalizedString("send.token", value: "Transfer token", comment: "").uppercased(),
      for: .normal
    )
    self.sendTokenButton.setTitleColor(
      UIColor.Kyber.enygold,
      for: .normal
    )

    self.allTransactionButton.setTitle(
      NSLocalizedString("transactions", value: "Transactions", comment: "").uppercased(),
      for: .normal
    )

    self.notificationsTextLabel.text = NSLocalizedString("notifications", value: "Notifications", comment: "").uppercased()
    self.unreadNotiLabel.rounded(radius: self.unreadNotiLabel.frame.height / 2.0)
    self.unreadNotiLabel.text = "0"
    self.unreadNotiLabel.isHidden = true

    let notiTappedGesture = UITapGestureRecognizer(target: self, action: #selector(self.notificationsTapped(_:)))
    self.notificationContainerView.addGestureRecognizer(notiTappedGesture)
    self.notificationContainerView.isUserInteractionEnabled = true

    self.promoCodeTextLabel.text = NSLocalizedString("kybercode", value: "KyberCode", comment: "").uppercased()
    let promoTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.promoCodeTapped(_:)))
    self.promoCodeContainerView.addGestureRecognizer(promoTapGesture)

    let walletConnectGesture = UITapGestureRecognizer(target: self, action: #selector(self.walletConnectTapped(_:)))
    self.walletConnectView.addGestureRecognizer(walletConnectGesture)

    self.mywalletsTextLabel.text = NSLocalizedString("my.wallets", value: "My wallet(s)", comment: "").uppercased()
    self.update(transactions: self.viewModel.pendingTransactions)

    self.view.layoutIfNeeded()
  }

  // MARK: Update from coordinator
  func updateCurrentWallet(_ currentWallet: KNWalletObject) {
    self.update(
      walletObjects: self.viewModel.wallets,
      currentWallet: currentWallet
    )
  }

  func update(walletObjects: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: walletObjects, currentWallet: currentWallet)
    self.walletListTableViewHeightConstraint.constant = viewModel.walletTableViewHeight
    self.walletListTableView.isScrollEnabled = self.viewModel.tableHeightScrollEnabled
    self.walletListTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  func update(transactions: [KNTransaction]) {
    self.viewModel.update(transactions: transactions)
    self.numberPendingTxLabel.text = "\(transactions.count)"
    self.numberPendingTxLabel.isHidden = transactions.isEmpty
  }

  func update(notificationsCount: Int) {
    self.unreadNotiLabel.text = "\(notificationsCount)"
    self.unreadNotiLabel.isHidden = notificationsCount == 0
  }

  func openMenu(animated: Bool, completion: (() -> Void)? = nil) {
    self.view.isHidden = false
    self.hamburgerMenuViewTrailingConstraint.constant = 0
    self.notificationDidUpdate(nil)
    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.view.alpha = 1
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.screenEdgePanRecognizer?.isEnabled = false
      self.panGestureRecognizer.isEnabled = true
      self.walletListTableView.reloadData()
      completion?()
    })
  }

  func hideMenu(animated: Bool, completion: (() -> Void)? = nil) {
    self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration, animations: {
      self.view.alpha = 0
      self.view.layoutIfNeeded()
    }, completion: { _ in
      self.screenEdgePanRecognizer?.isEnabled = true
      self.panGestureRecognizer.isEnabled = false
      self.view.isHidden = true
      completion?()
    })
  }

  @objc func promoCodeTapped(_ sender: Any?) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectPromoCode)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "kybercode"])
  }

  @objc func notificationsTapped(_ sender: Any?) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectNotifications)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "notifications"])
  }

  @objc func walletConnectTapped(_ sender: Any?) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectWalletConnect)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "wallet_connect"])
  }

  @objc func backgroundViewTap(_ recognizer: UITapGestureRecognizer) {
    let point = recognizer.location(in: self.view)
    if point.x <= self.view.frame.width - self.hamburgerView.frame.width {
      self.hideMenu(animated: true)
    }
  }

  @IBAction func addWalletButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectAddWallet)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "add_wallet"])
  }

  @IBAction func sendTokenButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectSendToken)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "send_token"])
  }

  @IBAction func allTransactionButtonPressed(_ sender: Any) {
    self.hideMenu(animated: true) {
      self.delegate?.balanceTabHamburgerMenuViewController(self, run: .selectAllTransactions)
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_hamburger_menu", customAttributes: ["action": "transaction"])
  }

  @objc func handleLongPressedWalletTableView(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] _ in
            guard let strongSelf = self else { return }
            let touch = sender.location(in: strongSelf.walletListTableView)
            guard let indexPath = strongSelf.walletListTableView.indexPathForRow(at: touch) else { return }
            if indexPath.row >= strongSelf.viewModel.wallets.count { return }
            let wallet = strongSelf.viewModel.wallet(at: indexPath.row)
            UIPasteboard.general.string = wallet.address

            strongSelf.showMessageWithInterval(
              message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
            )
            strongSelf.longPressTimer?.invalidate()
            strongSelf.longPressTimer = nil
        })
    }
    if sender.state == .ended {
        if longPressTimer != nil {
            longPressTimer?.fire()
        }
    }
  }

  func gestureScreenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if self.screenEdgePanRecognizer == nil { self.screenEdgePanRecognizer = sender }
    switch sender.state {
    case .began:
      self.view.isHidden = false
      self.view.alpha = 0
    case .changed:
      let translationX = -sender.translation(in: sender.view).x
      if -self.hamburgerView.frame.width + translationX >= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = 0
        self.view.alpha = 1
      } else if translationX < 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
        self.view.alpha = 0
      } else {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width + translationX
        let ratio = translationX / self.hamburgerView.frame.width
        self.view.alpha = ratio
      }
      self.view.layoutIfNeeded()
    default:
      if self.hamburgerMenuViewTrailingConstraint.constant < -self.hamburgerView.frame.width / 2 {
        self.hideMenu(animated: true)
      } else {
        self.openMenu(animated: true)
      }
    }
  }

  @IBAction func gesturePanActionRecognized(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      //do nothing here
      if isDebug { print("Pan gesture began") }
    case .changed:
      let translationX = sender.translation(in: sender.view).x
      if translationX <= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = 0
        self.view.alpha = 1
      } else if self.hamburgerView.frame.width - translationX <= 0 {
        self.hamburgerMenuViewTrailingConstraint.constant = -self.hamburgerView.frame.width
        self.view.alpha = 0
      } else {
        self.hamburgerMenuViewTrailingConstraint.constant = -translationX
        let ratio = (self.hamburgerView.frame.width - translationX) / self.hamburgerView.frame.width
        self.view.alpha = ratio
      }
      self.view.layoutIfNeeded()
    default:
      if self.hamburgerMenuViewTrailingConstraint.constant < -self.hamburgerView.frame.width / 2 {
        self.hideMenu(animated: true)
      } else {
        self.openMenu(animated: true)
      }
    }
  }

  @objc func notificationDidUpdate(_ sender: Any?) {
    let numUnread: Int = {
      if IEOUserStorage.shared.user == nil { return 0 }
      return KNNotificationCoordinator.shared.numberUnread
    }()
    self.update(notificationsCount: numUnread)
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let wallet = self.viewModel.wallet(at: indexPath.row)
    self.hideMenu(animated: true) {
      if wallet != self.viewModel.currentWallet {
        self.delegate?.balanceTabHamburgerMenuViewController(self, run: .select(wallet: wallet))
      }
    }
  }
}

extension KNBalanceTabHamburgerMenuViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberWalletRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
    cell.textLabel?.isUserInteractionEnabled = false
    let wallet = self.viewModel.wallet(at: indexPath.row)
    cell.tintColor = UIColor.Kyber.shamrock
    cell.textLabel?.attributedText = {
      let attributedString = NSMutableAttributedString()
      let nameAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
        NSAttributedStringKey.kern: 0.0,
        ]
      let addressAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
        NSAttributedStringKey.kern: 0.0,
        ]
      attributedString.append(NSAttributedString(string: "    \(wallet.name)", attributes: nameAttributes))
      let address: String = "         \(wallet.address.lowercased().prefix(8))...\(wallet.address.lowercased().suffix(6))"
      attributedString.append(NSAttributedString(string: "\n\(address)", attributes: addressAttributes))
      return attributedString
    }()
    cell.textLabel?.numberOfLines = 2
    cell.backgroundColor = {
      return indexPath.row % 2 == 0 ? UIColor(red: 242, green: 243, blue: 246) : UIColor.Kyber.whisper
    }()
    cell.accessoryType = wallet.address.lowercased() == self.viewModel.currentWallet.address.lowercased() ? .checkmark : .none
    return cell
  }
}
