// Copyright SIX DAY LLC. All rights reserved.

extension Array where Element: Equatable {
  var unique: [Element] {
    var uniqueValues = [Element]()
    forEach { element in
      if !uniqueValues.contains(element) {
        uniqueValues.append(element)
      }
    }
    return uniqueValues
  }
}

extension Array where Element: Hashable {
  var unique: [Element] {
    return Array(Set(self))
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
