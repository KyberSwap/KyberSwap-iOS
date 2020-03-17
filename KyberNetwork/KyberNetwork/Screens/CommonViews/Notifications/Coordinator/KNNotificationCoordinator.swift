// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNNotificationCoordinator: NSObject {

  static let shared: KNNotificationCoordinator = KNNotificationCoordinator()
  let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])
  fileprivate(set) var numberUnread: Int = KNNotificationStorage.shared.notifications.filter({ return !$0.read }).count
  fileprivate(set) var pageCount: Int = 0
  fileprivate(set) var itemCount: Int = 0

  fileprivate var loadingTimer: Timer?

  func resume() {
    self.loadingTimer?.invalidate()
    self.startLoadingNotifications(nil)
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.notificationLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        self?.startLoadingNotifications(timer)
      }
    )
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingNotifications(_ sender: Any?) {
    if KNWalletStorage.shared.wallets.isEmpty { return }
    self.loadListNotifications(pageIndex: 0) { [weak self] (notifications, error) in
      guard let _ = self else { return }
      if error == nil {
        KNNotificationStorage.shared.updateNotificationsFromServer(notifications)
      }
    }
  }

  func loadListNotifications(pageIndex: Int, completion: @escaping ([KNNotification], String?) -> Void) {
    let accessToken = IEOUserStorage.shared.user?.accessToken
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getNotification(accessToken: accessToken, pageIndex: pageIndex)) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              if let pageInfo = json["paging_info"] as? JSONDictionary {
                self.numberUnread = pageInfo["unread_count"] as? Int ?? 0
                self.pageCount = pageInfo["page_count"] as? Int ?? 0
                self.itemCount = pageInfo["item_count"] as? Int ?? 0
              }
              if let jsonArr = json["data"] as? [JSONDictionary] {
                let notifications = jsonArr.map({ return KNNotification(json: $0) })
                completion(notifications, nil)
                return
              }
              let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
              completion([], message)
            } catch {
              completion([], NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion([], error.prettyError)
          }
        }
      }
    }
  }

  func markAsRead(ids: [Int], completion: @escaping (String?) -> Void) {
    if ids.isEmpty || IEOUserStorage.shared.user == nil {
      completion(nil)
      return
    }
    let accessToken = IEOUserStorage.shared.user?.accessToken
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.markAsRead(accessToken: accessToken, ids: ids)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? false
              if success {
                self?.startLoadingNotifications(nil)
                completion(nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion(message)
              }
            } catch {
              completion(NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion(error.prettyError)
          }
        }
      }
    }
  }

  func toggleSubscriptionTokens(state: Bool, completion: @escaping (String?) -> Void) {
    guard IEOUserStorage.shared.user != nil, let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion("You must sign in to use subscription token feature".toBeLocalised())
      return
    }
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.togglePriceNotification(accessToken: accessToken, state: state)) { (result) in
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? false
              if success {
                UserDefaults.standard.set(state, forKey: kSubcriptionTokenEnable)
                completion(nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion(message)
              }
            } catch {
              completion(NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion(error.prettyError)
          }
        }
      }
    }
  }

  func updateListSubscriptionTokens(symbols: [String], completion: @escaping (String?) -> Void) {
    guard IEOUserStorage.shared.user != nil, let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion("You must sign in to use subscription token feature".toBeLocalised())
      return
    }
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.updateListSubscriptionTokens(accessToken: accessToken, symbols: symbols)) { (result) in
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? false
              if success {
                completion(nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion(message)
              }
            } catch {
              completion(NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion(error.prettyError)
          }
        }
      }
    }
  }

  func getListSubcriptionTokens(completion: @escaping (String?, ([String], [String])?) -> Void) {
    guard IEOUserStorage.shared.user != nil, let accessToken = IEOUserStorage.shared.user?.accessToken else {
      completion("You must sign in to use subscription token feature".toBeLocalised(), nil)
      return
    }

    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getListSubscriptionTokens(accessToken: accessToken)) { (result) in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let json = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? false
              let data = json["data"] as? [[String: Any]] ?? []
              if success {
                var selected: [String] = []
                let symbols = data.map { (item) -> String in
                  guard let sym = item["symbol"] as? String else { return "" }
                  if let isSubcribed = item["subscribed"] as? NSNumber, isSubcribed.boolValue == true {
                    selected.append(sym)
                  }
                  return sym
                }
                completion(nil, (symbols, selected))
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion(message, nil)
              }
            } catch {
              completion(NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""), nil)
            }
          case .failure(let error):
            completion(error.prettyError, nil)
          }
        }
      }
    }
  }
}
