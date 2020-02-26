// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Result
import Moya

class KNPriceAlertCoordinator: NSObject {

  static let shared: KNPriceAlertCoordinator = KNPriceAlertCoordinator()
  let provider = MoyaProvider<UserInfoService>(plugins: [MoyaCacheablePlugin()])

  fileprivate var loadingTimer: Timer?

  func resume() {
    self.loadingTimer?.invalidate()
    self.startLoadingListPriceAlerts(nil)
    self.loadingTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.priceAlertLoadingInterval,
      repeats: true,
      block: { [weak self] timer in
        self?.startLoadingListPriceAlerts(timer)
      }
    )
  }

  func pause() {
    self.loadingTimer?.invalidate()
    self.loadingTimer = nil
  }

  func startLoadingListPriceAlerts(_ sender: Any?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.loadListPriceAlerts(accessToken) { [weak self] (_, error) in
      guard let _ = self else { return }
      if error == nil {
        KNNotificationUtil.postNotification(for: kUpdateListAlertsNotificationKey)
      }
    }
  }

  func loadListPriceAlerts(_ accessToken: String, completion: @escaping ([KNAlertObject], String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getListAlerts(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? true
              if success {
                let jsonArr = json["data"] as? [JSONDictionary] ?? []
                let alerts = jsonArr.map({ return KNAlertObject(json: $0) })
                KNAlertStorage.shared.updateAlertsFromServer(alerts)
                completion(alerts, nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion([], message)
              }
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

  func addNewAlert(accessToken: String, jsonData: JSONDictionary, completion: @escaping (String, String?) -> Void) {
    self.provider.request(.addNewAlert(accessToken: accessToken, jsonData: jsonData)) { [weak self] result in
      guard let _ = self else { return }
      DispatchQueue.main.async {
        switch result {
        case .success(let data):
          do {
            let _ = try data.filterSuccessfulStatusCodes()
            let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
            let success = json["success"] as? Bool ?? true
            if success {
              self?.startLoadingListPriceAlerts(nil)
              completion("", nil)
            } else {
              let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
              completion("", message)
            }
          } catch {
            completion("", NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
          }
        case .failure(let error):
          completion("", error.prettyError)
        }
      }
    }
  }

  func updateAlert(accessToken: String, jsonData: JSONDictionary, completion: @escaping (String, String?) -> Void) {
    self.provider.request(.updateAlert(accessToken: accessToken, jsonData: jsonData)) { [weak self] result in
      guard let _ = self else { return }
      DispatchQueue.main.async {
        switch result {
        case .success(let data):
          do {
            let _ = try data.filterSuccessfulStatusCodes()
            let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
            let success = json["success"] as? Bool ?? true
            if success {
              KNAlertStorage.shared.updateAlert(KNAlertObject(json: jsonData))
              self?.startLoadingListPriceAlerts(nil)
              completion("", nil)
            } else {
              let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
              completion("", message)
            }
          } catch {
            completion("", NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
          }
        case .failure(let error):
          completion("", error.prettyError)
        }
      }
    }
  }

  func removeAnAlert(accessToken: String, alertID: Int, completion: @escaping (String, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.removeAnAlert(accessToken: accessToken, alertID: alertID)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? true
              if success {
                KNAlertStorage.shared.deleteAlert(with: alertID)
                self?.startLoadingListPriceAlerts(nil)
                completion("", nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion("", message)
              }
            } catch {
              completion("", NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion("", error.prettyError)
          }
        }
      }
    }
  }

  func removeAllTriggeredAlerts(accessToken: String, completion: @escaping (String, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.deleteAllTriggerdAlerts(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? true
              if success {
                KNAlertStorage.shared.deleteAllTriggerd()
                self?.startLoadingListPriceAlerts(nil)
                completion("", nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion("", message)
              }
            } catch {
              completion("", NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion("", error.prettyError)
          }
        }
      }
    }
  }

  func loadLeaderBoardData(accessToken: String, completion: @escaping (JSONDictionary, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getLeaderBoardData(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let jsonData = try data.mapJSON() as? JSONDictionary ?? [:]
              completion(jsonData, nil)
            } catch {
              completion([:], NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion([:], error.prettyError)
          }
        }
      }
    }
  }

  func loadLatestCampaignResultData(accessToken: String, completion: @escaping (JSONDictionary, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getLatestCampaignResult(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let jsonData = try data.mapJSON() as? JSONDictionary ?? [:]
              completion(jsonData, nil)
            } catch {
              completion([:], NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion([:], error.prettyError)
          }
        }
      }
    }
  }

  func updateUserSignedInPushTokenWithRetry() {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken, let pushToken = KNAppTracker.getPushNotificationToken(), let userID = IEOUserStorage.shared.user?.userID else { return }
    if KNAppTracker.hasSentPushTokenRequest(userID: "\(userID)") { return }
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.addPushToken(accessToken: accessToken, pushToken: pushToken)) { [weak self] result in
        DispatchQueue.main.async {
          if case .failure = result {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
              self?.updateUserSignedInPushTokenWithRetry()
            })
          } else {
            KNAppTracker.updateHasSentPushTokenRequest(
              userID: "\(userID)",
              hasSent: true
            )
          }
        }
      }
    }
  }

  func getAlertMethods(accessToken: String, completion: @escaping (JSONDictionary, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getListAlertMethods(accessToken: accessToken)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? true
              if success {
                completion(json["data"] as? JSONDictionary ?? [:], nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion([:], message)
              }
            } catch {
              completion([:], NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion([:], error.prettyError)
          }
        }
      }
    }
  }

  func updateAlertMethods(accessToken: String, email: [JSONDictionary], telegram: [JSONDictionary], completion: @escaping (String, String?) -> Void) {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.setAlertMethods(accessToken: accessToken, email: email, telegram: telegram)) { [weak self] result in
        guard let _ = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            do {
              let _ = try data.filterSuccessfulStatusCodes()
              let json = try data.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let success = json["success"] as? Bool ?? true
              if success {
                completion("", nil)
              } else {
                let message = json["message"] as? String ?? NSLocalizedString("some.thing.went.wrong.please.try.again", value: "Something went wrong. Please try again", comment: "")
                completion("", message)
              }
            } catch {
              completion("", NSLocalizedString("can.not.decode.data", value: "Can not decode data", comment: ""))
            }
          case .failure(let error):
            completion("", error.prettyError)
          }
        }
      }
    }
  }
}
