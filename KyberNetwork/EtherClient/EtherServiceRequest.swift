// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import APIKit
import JSONRPCKit

struct EtherServiceRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
    let batch: Batch

    typealias Response = Batch.Responses

    var baseURL: URL {
      // Change to KyberNetwork endpoint
      if let path = URL(string: KNGeneralProvider.shared.customRPC.endpoint + KNEnvironment.default.nodeEndpoint) {
        return path
      }
      let config = Config()
      return config.rpcURL
    }

    var method: HTTPMethod {
        return .post
    }

    var path: String {
        return ""
    }

    var parameters: Any? {
        return batch.requestObject
    }

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        return try batch.responses(from: object)
    }
}

struct EtherServiceKyberRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
  let batch: Batch

  typealias Response = Batch.Responses

  var baseURL: URL {
    // Change to KyberNetwork endpoint
    if let path = URL(string: KNGeneralProvider.shared.customRPC.endpointKyber + KNEnvironment.default.nodeEndpoint) {
      return path
    }
    let config = Config()
    return config.rpcURL
  }

  var method: HTTPMethod {
    return .post
  }

  var path: String {
    return ""
  }

  var parameters: Any? {
    return batch.requestObject
  }

  func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
    return try batch.responses(from: object)
  }
}

struct EtherServiceAlchemyRequest<Batch: JSONRPCKit.Batch>: APIKit.Request {
  let batch: Batch

  typealias Response = Batch.Responses

  var baseURL: URL {
    // Change to KyberNetwork endpoint
    if let path = URL(string: KNGeneralProvider.shared.customRPC.endpointAlchemy + KNEnvironment.default.nodeEndpoint) {
      return path
    }
    let config = Config()
    return config.rpcURL
  }

  var method: HTTPMethod {
    return .post
  }

  var path: String {
    return ""
  }

  var parameters: Any? {
    return batch.requestObject
  }

  func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
    return try batch.responses(from: object)
  }
}
