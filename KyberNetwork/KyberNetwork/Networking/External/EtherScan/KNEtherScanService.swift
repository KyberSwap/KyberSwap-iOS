// Copyright SIX DAY LLC. All rights reserved.

import Moya

let apiKey = KNSecret.etherscanAPIKey

enum KNEtherScanService {
  case getListTransactions(address: String, startBlock: Int)
  case getListTokenTransactions(address: String, startBlock: Int, page: Int, sort: String)
  case getListInternalTransactions(address: String, startBlock: Int)
}

extension KNEtherScanService: TargetType {
  var baseURL: URL {
    switch self {
    case .getListTransactions(let address, let startBlock):
      let baseURLString = "\(KNEnvironment.default.apiEtherScanEndpoint)api?module=account&action=txlist&address=\(address)&startblock=\(startBlock)&sort=desc&apikey=\(apiKey)"
      return URL(string: baseURLString)!
    case .getListTokenTransactions(let address, let startBlock, let page, let sort):
      let baseURLString = "\(KNEnvironment.default.apiEtherScanEndpoint)api?module=account&action=tokentx&address=\(address)&page=\(page)&offset=200&startblock=\(startBlock)&sort=\(sort)&apikey=\(apiKey)"
      return URL(string: baseURLString)!
    case .getListInternalTransactions(let address, let startBlock):
      let baseURLString = "\(KNEnvironment.default.apiEtherScanEndpoint)api?module=account&action=txlistinternal&address=\(address)&offset=200&startblock=\(startBlock)&sort=desc&apikey=\(apiKey)"
      return URL(string: baseURLString)!
    }
  }

  var path: String {
    return ""
  }

  var method: Moya.Method {
    return .get
  }

  var task: Task {
    return .requestPlain
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "content-type": "application/json",
    ]
  }
}
