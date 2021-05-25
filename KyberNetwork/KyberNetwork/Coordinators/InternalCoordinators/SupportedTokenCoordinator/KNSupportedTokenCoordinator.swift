// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya

class KNSupportedTokenCoordinator {

  static let shared = KNSupportedTokenCoordinator()
  fileprivate let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])

  fileprivate var timer: Timer?

  func resume() {
    self.fetchSupportedTokens()
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.minutes5,
      repeats: true,
      block: { [weak self] _ in
      self?.fetchSupportedTokens()
      }
    )
  }

  func pause() {
    self.timer?.invalidate()
  }

  fileprivate func fetchSupportedTokens() {
    DispatchQueue.global(qos: .background).async {
      self.provider.request(.getTokenList) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let response):
            do {
              _ = try response.filterSuccessfulStatusCodes()
              let respJSON: JSONDictionary = try response.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let jsonArr: [JSONDictionary] = respJSON["tokens"] as? [JSONDictionary] ?? []
              let tokenStruct = jsonArr.map { (item) -> Token in
                return Token(dictionary: item)
              }
              if tokenStruct.isEmpty {
                return
              }
              KNSupportedTokenStorage.shared.updateSupportedTokens(tokenStruct)
              KNNotificationUtil.postNotification(for: kSupportedTokenListDidUpdateNotificationKey)
            } catch let error {
              if isDebug { print("---- Supported Tokens: Cast reponse failed with error: \(error.prettyError) ----") }
            }
          case .failure(let error):
            if isDebug { print("---- Supported Tokens: Failed with error: \(error.prettyError)") }
          }
        }
      }
    }
  }
}
