// Copyright SIX DAY LLC. All rights reserved.

import Firebase

class KNVersionControlManager: NSObject {

  static let kLaunchAppCountForUpdateAppKey = "kLaunchAppCountForUpdateAppKey"

  // (bool, bool): isShow, isForce update
  static func shouldShowUpdateApp(completion: @escaping (Bool, Bool, String?, String?) -> Void) {
    let remoteConfig = RemoteConfig.remoteConfig()
    let settings = RemoteConfigSettings()
    remoteConfig.configSettings = settings

    let expirationDuration: TimeInterval = isDebug ? 60.0 : 15 * 60.0

    guard let currentVersion = Bundle.main.versionNumber else {
      fatalError("Expected to find a bundle version in the info dictionary")
    }

    print("Current version: " + currentVersion)

    remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
      if status == .success {
        remoteConfig.activate { (_, error) in
          if error == nil {
            let key: String = {
              if KNEnvironment.default == .production { return "version_update" }
              if KNEnvironment.default == .staging { return "version_update_staging" }
              return "version_update_dev"
            }()
            let data = remoteConfig.configValue(forKey: key).dataValue
            do {
              let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSONDictionary ?? [:]
              if let version = json["current_version"] as? String,
                let isForceUpdate = json["is_force_update"] as? Bool {
                let launchAppCount = json["launch_app_times"] as? Int ?? 0
                let title = json["title"] as? String
                let subtitle = json["subtitle"] as? String
                if String.isCurrentVersionHigher(currentVersion: currentVersion, compareVersion: version) {
                  completion(false, false, title, subtitle)
                  return
                }
                // there is new version
                if isForceUpdate {
                  completion(true, true, title, subtitle)
                  UserDefaults.standard.set(0, forKey: kLaunchAppCountForUpdateAppKey)
                  return
                }
                var launchedCounts = UserDefaults.standard.integer(forKey: kLaunchAppCountForUpdateAppKey)
                launchedCounts += 1
                UserDefaults.standard.set(launchedCounts, forKey: kLaunchAppCountForUpdateAppKey)
                if launchedCounts >= launchAppCount {
                  completion(true, false, title, subtitle)
                  // reset launch count
                  UserDefaults.standard.set(0, forKey: kLaunchAppCountForUpdateAppKey)
                } else {
                  completion(false, false, title, subtitle)
                }
              }
            } catch let error {
              print("Error: \(error.localizedDescription)")
            }
          } else {
            print("Config not fetched")
            print("Error: \(error?.localizedDescription ?? "No error available.")")
          }
        }
      } else {
        print("Config not fetched")
        print("Error: \(error?.localizedDescription ?? "No error available.")")
      }
    }
  }

}
