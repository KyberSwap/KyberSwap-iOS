// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNAlertTableViewEvent {
  case select(alert: KNAlertObject)
  case delete(alert: KNAlertObject)
  case edit(alert: KNAlertObject)
  case update(height: CGFloat)
  case deleteAll
}

protocol KNAlertTableViewDelegate: class {
  func alertTableView(_ tableView: UITableView, run event: KNAlertTableViewEvent)
}

class KNAlertTableView: XibLoaderView {

  @IBOutlet weak var alertTableView: UITableView!
  let kAlertTableViewCellID: String = "kAlertTableViewCellID"
  let kAlertHeaderTableViewID: String = "kAlertHeaderTableViewID"

  fileprivate var alerts: [KNAlertObject] = []
  fileprivate var activeAlerts: [KNAlertObject] = []
  fileprivate var triggeredAlerts: [KNAlertObject] = []
  fileprivate var isFull: Bool = false

  override func commonInit() {
    super.commonInit()
    let nib = UINib(nibName: KNAlertTableViewCell.className, bundle: nil)
    self.alertTableView.register(nib, forCellReuseIdentifier: kAlertTableViewCellID)
    let headerNib = UINib(nibName: KNListAlertHeaderView.className, bundle: nil)
    self.alertTableView.register(headerNib, forHeaderFooterViewReuseIdentifier: kAlertHeaderTableViewID)
    self.alertTableView.rowHeight = KNAlertTableViewCell.height
    self.alertTableView.delegate = self
    self.alertTableView.dataSource = self

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.updateListAlerts(_:)),
      name: NSNotification.Name(rawValue: kUpdateListAlertsNotificationKey),
      object: nil
    )
  }

  weak var delegate: KNAlertTableViewDelegate?

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kUpdateListAlertsNotificationKey),
      object: nil
    )
  }

  func updateScrolling(isEnabled: Bool) {
    self.alertTableView.isScrollEnabled = isEnabled
    self.alertTableView.showsVerticalScrollIndicator = isEnabled
    self.alertTableView.showsHorizontalScrollIndicator = isEnabled
  }

  @objc func updateListAlerts(_ sender: Notification?) {
    self.updateView(with: KNAlertStorage.shared.alerts, isFull: self.isFull)
  }

  func updateView(with alerts: [KNAlertObject], isFull: Bool = false) {
    self.isFull = isFull
    self.alerts = alerts.sorted(by: { (alert1, alert2) in
      // active always show first, sorted by created time
      // inactive always show last, sorted by updated time
      if alert1.state == .active && alert2.state == .active {
        return alert1.updatedDate > alert2.updatedDate
      }
      if alert1.state == .active { return true }
      if alert2.state == .active { return false }
      return alert1.updatedDate > alert2.updatedDate
    })
    if !isFull { self.alerts = Array(self.alerts.prefix(2)) }
    if self.isFull {
      self.activeAlerts = self.alerts.filter({ return $0.state == .active })
      self.triggeredAlerts = self.alerts.filter({ return $0.state != .active })
    }
    let height: CGFloat = {
      if !isFull { return self.alertTableView.rowHeight * CGFloat(self.alerts.count) }
      if self.triggeredAlerts.isEmpty { return self.alertTableView.rowHeight * CGFloat(self.activeAlerts.count) }
      return self.alertTableView.rowHeight * CGFloat(self.alerts.count) + 40.0 // triggered section height
    }()
    self.alertTableView.reloadData()
    self.delegate?.alertTableView(
      self.alertTableView,
      run: .update(height: height)
    )
  }
}

extension KNAlertTableView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let alerts: KNAlertObject = {
      if !self.isFull { return self.alerts[indexPath.row] }
      if indexPath.section == 0 {
        // either active or triggered depends on number active alerts
        if self.activeAlerts.isEmpty { return self.triggeredAlerts[indexPath.row] }
        return self.activeAlerts[indexPath.row]
      }
      // triggered section
      return self.triggeredAlerts[indexPath.row]
    }()
    if alerts.state == .triggered { // select a triggered alert -> delete only
      self.delegate?.alertTableView(
        tableView,
        run: .delete(alert: alerts)
      )
    } else {
      self.delegate?.alertTableView(
        tableView,
        run: .select(alert: alerts)
      )
    }
  }
}

extension KNAlertTableView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    if !self.isFull { return 1 }
    let numSections: Int = {
      if self.activeAlerts.isEmpty && self.triggeredAlerts.isEmpty { return 0 }
      if !self.activeAlerts.isEmpty && !self.triggeredAlerts.isEmpty { return 2 }
      return 1
    }()
    return numSections
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if !self.isFull { return self.alerts.count }
    if self.activeAlerts.isEmpty && self.triggeredAlerts.isEmpty { return 0 }
    if !self.activeAlerts.isEmpty && !self.triggeredAlerts.isEmpty {
      return section == 0 ? self.activeAlerts.count : self.triggeredAlerts.count
    }
    return self.activeAlerts.isEmpty ? self.triggeredAlerts.count : self.activeAlerts.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.0
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if !self.isFull { return 0.0 }
    if self.triggeredAlerts.isEmpty { return 0.0 }
    if !self.activeAlerts.isEmpty && section == 0 { return 0.0 }
    return 40.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if !self.isFull { return nil }
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: kAlertHeaderTableViewID) as! KNListAlertHeaderView //Note: add new button section view
    let backgroundView = UIView(frame: view.bounds)
    backgroundView.backgroundColor = UIColor(red: 239, green: 239, blue: 239)
    view.backgroundView = backgroundView
    if self.activeAlerts.isEmpty || section == 1 {
      view.updateText(NSLocalizedString("Triggered", comment: "").uppercased())
      view.updateDeleteButtonText {
        self.delegate?.alertTableView(
          tableView,
          run: .deleteAll
        )
      }
    } else {
      view.updateText(NSLocalizedString("Active", comment: "").uppercased())
    }
    return view
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kAlertTableViewCellID, for: indexPath) as! KNAlertTableViewCell
    let alert: KNAlertObject = {
      if !self.isFull { return self.alerts[indexPath.row] }
      if indexPath.section == 0 {
        // either active or triggered depends on number active alerts
        if self.activeAlerts.isEmpty { return self.triggeredAlerts[indexPath.row] }
        return self.activeAlerts[indexPath.row]
      }
      // triggered section
      return self.triggeredAlerts[indexPath.row]
    }()
    cell.updateCell(with: alert, index: indexPath.row)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let alert: KNAlertObject = {
      if !self.isFull { return self.alerts[indexPath.row] }
      if indexPath.section == 0 {
        // either active or triggered depends on number active alerts
        if self.activeAlerts.isEmpty { return self.triggeredAlerts[indexPath.row] }
        return self.activeAlerts[indexPath.row]
      }
      // triggered section
      return self.triggeredAlerts[indexPath.row]
    }()
    let edit = UITableViewRowAction(style: .normal, title: NSLocalizedString("edit", value: "Edit", comment: "")) { (_, _) in
      self.delegate?.alertTableView(
        tableView,
        run: .edit(alert: alert)
      )
    }
    edit.backgroundColor = UIColor.Kyber.blueGreen
    let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("delete", value: "Delete", comment: "")) { (_, _) in
      self.delegate?.alertTableView(
        tableView,
        run: .delete(alert: alert)
      )
    }
    delete.backgroundColor = UIColor.Kyber.strawberry
    if alert.state == .triggered { return [delete] }
    return [delete, edit]
  }
}
