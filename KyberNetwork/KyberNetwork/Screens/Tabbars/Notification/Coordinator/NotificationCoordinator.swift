//
//  NotificationCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/2/21.
//

import Foundation
import Moya

class NotificationCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var cached: [NotificationItem]
  
  lazy var rootViewController: NotificationsViewController = {
    let controller = NotificationsViewController()
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.cached = Storage.retrieve(Constants.notificationsStoreFileName, as: [NotificationItem].self) ?? []
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    self.rootViewController.coordinatorDidUpdateNotification(notifications: self.cached)
    self.cached = []
    self.loadNotifications()
  }
  
  func stop() {
    
  }

  fileprivate func loadNotifications(batchId: String = "") {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getNotification(batchId: batchId, limit: 10)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(NotificationResponse.self, from: resp.data)
          self.cached.append(contentsOf: data.notifications)
          if let nextBatchId = data.nextBatchID {
            self.loadNotifications(batchId: nextBatchId)
          } else {
            self.rootViewController.coordinatorDidUpdateNotification(notifications: self.cached)
            Storage.store(self.cached, as: Constants.notificationsStoreFileName)
          }
        } catch let error {
          print("[Notification] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Notification] \(error.localizedDescription)")
      }
    }
  }
}
