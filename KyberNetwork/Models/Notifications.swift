//
//  Notifications.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/2/21.
//

import Foundation

// MARK: - NotificationResponse
struct NotificationResponse: Codable {
    let timestamp: Int?
    let notifications: [NotificationItem]
    let nextBatchID: String?

    enum CodingKeys: String, CodingKey {
        case timestamp, notifications
        case nextBatchID = "nextBatchId"
    }
}

// MARK: - Notification
struct NotificationItem: Codable {
  let id: Int
  let createdAt, updatedAt: String
  let title: String
  let content: String
  let image, link: String
  
  var updateAtDate: Date {
    return DateFormatterUtil.shared.notificationDateFormatter.date(from: self.updatedAt) ?? Date()
  }
}
