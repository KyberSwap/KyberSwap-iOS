// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Charts

class CustomAxisValueFormatter: NSObject, IAxisValueFormatter {
  var type: KNTokenChartType
  var origin: KNChartObject?

  init(_ type: KNTokenChartType) {
    self.type = type
    super.init()
  }

  func update(type: KNTokenChartType, origin: KNChartObject) {
    self.type = type
    self.origin = origin
  }

  func stringForValue(_ value: Double,
                      axis: AxisBase?) -> String {
    guard let first = origin else { return "" }
    var output = ""
    let timeStamp = value * (15.0 * 60.0) + Double(first.time)
    let date = Date(timeIntervalSince1970: timeStamp)
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EE"
    let hour = calendar.component(.hour, from: date)
    let minutes = calendar.component(.minute, from: date)
    let day = calendar.component(.day, from: date)
    let month = calendar.component(.month, from: date)
    let year = calendar.component(.year, from: date)
    switch self.type {
    case .day:
      output = "\(hour):\(minutes)"
    case .week:
      output = "\(hour):\(minutes) \(dateFormatter.string(from: date))"
    case .month:
      output = "\(hour):\(minutes) \(day)-\(month)"
    case .year, .all:
      output = "\(day)-\(month)-\(year)"
    }
    return output
  }
}
