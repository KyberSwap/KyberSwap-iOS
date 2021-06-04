//
//  NotificationsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/2/21.
//

import UIKit

class NotificationsViewModel {
  var notifications: [NotificationItem] = []
  var dataSource: [NotificationCellViewModel] {
    var viewModels: [NotificationCellViewModel] = []
    self.notifications.forEach { (item) in
      let viewModel = NotificationCellViewModel(notification: item)
      viewModels.append(viewModel)
    }
    viewModels.sort { (left, right) -> Bool in
      return left.notification.id > right.notification.id
    }
    return viewModels
  }
}

class NotificationsViewController: KNBaseViewController {
  @IBOutlet weak var notificationTableView: UITableView!
  let viewModel: NotificationsViewModel = NotificationsViewModel()
  @IBOutlet weak var emptyView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: NotificationTableViewCell.className, bundle: nil)
    self.notificationTableView.register(nib, forCellReuseIdentifier: NotificationTableViewCell.cellID)
  }
  
  func coordinatorDidUpdateNotification(notifications: [NotificationItem]) {
    self.viewModel.notifications = notifications
    guard self.isViewLoaded else {
      return
    }
    self.updateUI()
  }
  
  fileprivate func updateUI() {
    self.emptyView.isHidden = !self.viewModel.dataSource.isEmpty
    self.notificationTableView.reloadData()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension NotificationsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: NotificationTableViewCell.cellID,
      for: indexPath
    ) as! NotificationTableViewCell
    cell.updateCell(viewModel: self.viewModel.dataSource[indexPath.row])
    return cell
  }
}

extension NotificationsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.openSafari(with: self.viewModel.dataSource[indexPath.row].notification.link)
  }
}
