//
//  LoginInfo.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/3/21.
//

import Foundation

// MARK: - LoginToken
struct LoginToken: Codable {
    let timestamp: Int
    let token: String
}

extension LoginToken {
  func isNeedUpdate() -> Bool {
    let date = Date(timeIntervalSince1970: TimeInterval(self.timestamp))
    return Date().hours(from: date) >= 12
  }
}
