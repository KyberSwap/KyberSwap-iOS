// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNListNotificationViewEvent {
  case openSwap(from: String, to: String)
  case openManageOrder
  case openSetting
}

protocol KNListNotificationViewControllerDelegate: class {
  func listNotificationViewController(_ controller: KNListNotificationViewController, run event: KNListNotificationViewEvent)
}

class KNListNotificationViewModel {
  var notifications: [KNNotification] = []
}

class KNListNotificationViewController: KNBaseViewController {

  let kCellID = "kListNotificationTableViewCell"

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var markAllReadButton: UIButton!

  @IBOutlet weak var listNotiTableView: UITableView!

  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var noNotificationsTextLabel: UILabel!
  @IBOutlet weak var settingButton: UIButton!

  fileprivate let viewModel = KNListNotificationViewModel()

  weak var delegate: KNListNotificationViewControllerDelegate?
  fileprivate var timer: Timer?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    let nib = UINib(nibName: KNNotificationTableViewCell.className, bundle: nil)
    self.listNotiTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.listNotiTableView.delegate = self
    self.listNotiTableView.dataSource = self
    self.listNotiTableView.rowHeight = 64.0
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadListNotifications()
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { [weak self] _ in
      self?.reloadListNotifications(false)
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func reloadListNotifications(_ isLoading: Bool = true) {
    if isLoading { self.displayLoading() }
    var errorMessage: String?
    var notifications: [KNNotification] = []
    let pageCount: Int = {
      if KNNotificationCoordinator.shared.pageCount > 0 { return KNNotificationCoordinator.shared.pageCount }
      return 1
    }()
    let group = DispatchGroup()
    for id in 0..<pageCount {
      group.enter()
      KNNotificationCoordinator.shared.loadListNotifications(pageIndex: id + 1) { [weak self] (notis, error) in
        guard let _ = self else {
          group.leave()
          return
        }
        if let err = error {
          KNCrashlyticsUtil.logCustomEvent(withName: "screen_notification", customAttributes: ["reload_error": err])
          errorMessage = err
        } else {
          notifications.append(contentsOf: notis)
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      if isLoading { self.hideLoading() }
      if let error = errorMessage {
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_notification", customAttributes: ["error": error])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: error,
          time: 1.5
        )
      } else {
        KNNotificationStorage.shared.updateNotificationsFromServer(notifications)
        self.listNotificationsDidUpdate(nil)
      }
    }
  }

  @objc func listNotificationsDidUpdate(_ sender: Any?) {
    self.viewModel.notifications = KNNotificationStorage.shared.notifications.map({ return $0.clone() }).sorted(by: { return $0.updatedDate > $1.updatedDate })
    self.emptyStateContainerView.isHidden = !self.viewModel.notifications.isEmpty
    self.listNotiTableView.isHidden = self.viewModel.notifications.isEmpty
    if !self.listNotiTableView.isHidden {
      self.listNotiTableView.reloadData()
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func markAllButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_notification", customAttributes: ["action": "mark_all_read"])
    let ids = KNNotificationStorage.shared.notifications.map({ return $0.id })
    self.displayLoading()
    KNNotificationCoordinator.shared.markAsRead(ids: ids) { [weak self] error in
      guard let `self` = self else { return }
      self.hideLoading()
      if let err = error {
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_notification", customAttributes: ["mark_read_error": err])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", comment: ""),
          message: err,
          time: 1.5
        )
      } else {
        self.reloadListNotifications()
      }
    }
  }
  
  @IBAction func settingButtonPressed(_ sender: Any) {
    self.delegate?.listNotificationViewController(self, run: .openSetting)
  }
  
}

extension KNListNotificationViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    let noti = self.viewModel.notifications[indexPath.row]
    if !noti.read {
      KNNotificationCoordinator.shared.markAsRead(ids: [noti.id]) { _ in
        let newNoti = noti.clone()
        newNoti.read = true
        KNNotificationStorage.shared.updateNotification(newNoti)
        self.listNotificationsDidUpdate(nil)
        self.reloadListNotifications(false)
      }
    }

    KNCrashlyticsUtil.logCustomEvent(withName: "screen_notification", customAttributes: ["action": "click_\(noti.label)"])

    if noti.scope == "personal" && noti.label == "alert" {
      // alert, open swap view
      if let data = noti.extraData, let base = data["base"] as? String, let token = data["token"] as? String {
        let from = base == "USD" ? "ETH" : token
        let to = base == "USD" ? "KNC" : "ETH"
        self.delegate?.listNotificationViewController(self, run: .openSwap(from: from, to: to))
        return
      }
    }

    if noti.scope == "personal" && noti.label == "limit_order" {
      // open manage order if user has logged in, otherwise open limit order popup if has data
      if IEOUserStorage.shared.user != nil {
        self.delegate?.listNotificationViewController(self, run: .openManageOrder)
        return
      }
      if let data = noti.extraData, self.openLimitOrderPopup(data: data) {
        return
      }
    }

    if noti.label == "new_listing" {
      if let data = noti.extraData, let token = data["token"] as? String {
        self.delegate?.listNotificationViewController(self, run: .openSwap(from: "ETH", to: token))
        return
      }
    }
    if !noti.link.isEmpty, let url = URL(string: noti.link), UIApplication.shared.canOpenURL(url) {
      self.openSafari(with: url)
      return
    }

    let alert = UIAlertController(title: noti.title, message: noti.content, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }

  fileprivate func openLimitOrderPopup(data: JSONDictionary) -> Bool {
    guard let orderID = data["order_id"] as? Int,
      let srcToken = data["src_token"] as? String,
      let destToken = data["dst_token"] as? String else { return false }
    let rate: Double = {
      if let value = data["min_rate"] as? Double { return value }
      if let valueStr = data["min_rate"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let amount: Double = {
      if let value = data["src_amount"] as? Double { return value }
      if let valueStr = data["src_amount"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let fee: Double = {
      if let value = data["fee"] as? Double { return value }
      if let valueStr = data["fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let transferFee: Double = {
      if let value = data["transfer_fee"] as? Double { return value }
      if let valueStr = data["transfer_fee"] as? String, let value = Double(valueStr) {
        return value
      }
      return 0.0
    }()
    let sender = data["sender"] as? String ?? ""
    let createdDate: Double = {
      if let value = data["created_at"] as? Double { return value }
      if let valueStr = data["created_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    let updatedDate: Double = {
      if let value = data["updated_at"] as? Double { return value }
      if let valueStr = data["updated_at"] as? String, let value = Double(valueStr) {
        return value
      }
      return Date().timeIntervalSince1970
    }()
    let receive = data["receive"] as? Double ?? 0.0
    let txHash = data["tx_hash"] as? String ?? ""

    let order = KNOrderObject(
      id: orderID,
      from: srcToken,
      to: destToken,
      amount: amount,
      price: rate,
      fee: fee + transferFee,
      nonce: "",
      sender: sender,
      createdDate: createdDate,
      filledDate: updatedDate,
      messages: "",
      txHash: txHash,
      stateValue: KNOrderState.filled.rawValue,
      actualDestAmount: receive
    )
    let controller = KNLimitOrderDetailsPopUp(order: order)
    controller.loadViewIfNeeded()
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .crossDissolve
    self.present(controller, animated: true, completion: nil)
    return true
  }
}

extension KNListNotificationViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.notifications.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNNotificationTableViewCell
    let noti = self.viewModel.notifications[indexPath.row]
    cell.updateCell(with: noti, index: indexPath.row)
    return cell
  }
}
