// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length
import Moya
import CryptoSwift
import BigInt

protocol MoyaCacheable {
  typealias MoyaCacheablePolicy = URLRequest.CachePolicy
  var cachePolicy: MoyaCacheablePolicy { get }
  var httpShouldHandleCookies: Bool { get }
}

final class MoyaCacheablePlugin: PluginType {
  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    if let moyaCachableProtocol = target as? MoyaCacheable {
      var cachableRequest = request
      cachableRequest.cachePolicy = moyaCachableProtocol.cachePolicy
      cachableRequest.httpShouldHandleCookies = moyaCachableProtocol.httpShouldHandleCookies
      return cachableRequest
    }
    return request
  }
}

enum KyberNetworkService {
  case getRate
  case getCachedRate
  case getRateUSD
  case getHistoryOneColumn
  case getLatestBlock
  case getKyberEnabled
  case getMaxGasPrice
  case getGasPrice
  case supportedToken
  case getReferencePrice(sym: String)
}

extension KyberNetworkService: TargetType {

  var baseURL: URL {
    let baseURLString: String = {
      switch self {
      case .getRate:
        return "\(KNEnvironment.default.kyberAPIEnpoint)/token_price?currency=ETH"
      case .getCachedRate:
        return KNEnvironment.default.cachedRateURL
      case .getRateUSD:
        return "\(KNEnvironment.default.kyberAPIEnpoint)/token_price?currency=USD"
      case .getHistoryOneColumn:
        return "\(KNEnvironment.default.cachedURL)/getHistoryOneColumn"
      case .getLatestBlock:
        return "\(KNEnvironment.default.cachedURL)/latestBlock"
      case .getKyberEnabled:
        return "\(KNEnvironment.default.cachedURL)/kyberEnabled"
      case .getMaxGasPrice:
        return "\(KNEnvironment.default.cachedURL)/maxGasPrice"
      case .getGasPrice:
        return "\(KNEnvironment.default.cachedURL)/gasPrice"
      case .supportedToken:
        return "https://dev-krystal-api.knstats.com/v1/token/tokenList"
//        return KNEnvironment.default.supportedTokenEndpoint
      case .getReferencePrice(sym: let sym):
        return "\(KNEnvironment.default.cachedURL)/refprice?base=\(sym)&quote=ETH"
      }
    }()
    return URL(string: baseURLString)!
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
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum KNTrackerService {
  case getChartHistory(symbol: String, resolution: String, from: Int64, to: Int64, rateType: String)
  case getRates
  case swapSuggestion(address: String, tokens: JSONDictionary)
  case getGasLimit(src: String, dest: String, amount: Double)
  case getExpectedRate(src: String, dest: String, amount: String)
  case getSourceAmount(src: String, dest: String, amount: Double)
  case getTokenVolumne
}

extension KNTrackerService: TargetType {
  var baseURL: URL {
    let baseURLString = KNEnvironment.default.kyberAPIEnpoint
    switch self {
    case .getChartHistory(let symbol, let resolution, let from, let to, let rateType):
      let url = "\(KNSecret.getChartHistory)?symbol=\(symbol)&resolution=\(resolution)&from=\(from)&to=\(to)&rateType=\(rateType)"
      return URL(string: baseURLString + url)!
    case .getRates:
      return URL(string: baseURLString + KNSecret.getChange)!
    case .swapSuggestion:
      return URL(string: KNSecret.swapSuggestionURL)!
    case .getGasLimit(let src, let dest, let amount):
      return URL(string: "\(KNEnvironment.default.gasLimitEnpoint)/gas_limit?source=\(src)&dest=\(dest)&amount=\(amount)")!
    case .getExpectedRate(let src, let dest, let amount):
      return URL(string: "\(KNEnvironment.default.expectedRateEndpoint)/expectedRate?source=\(src)&dest=\(dest)&sourceAmount=\(amount)")!
    case .getSourceAmount(let src, let dest, let amount):
      let base = KNEnvironment.default.cachedSourceAmountRateURL
      let url = "/quote_amount?base=\(dest)&quote=\(src)&base_amount=\(amount)&type=buy"
      return URL(string: base + url)!
    case .getTokenVolumne:
      return URL(string: "\(baseURLString)/market")!
    }
  }

  var path: String {
    return ""
  }

  var method: Moya.Method {
    if case .swapSuggestion = self { return .post }
    return .get
  }

  var task: Task {
    switch self {
    case .swapSuggestion(let address, let tokens):
      var json: JSONDictionary = [
        "wallet_id": address,
      ]
      if !tokens.isEmpty { json["tokens"] = tokens }
      print(json)
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    default:
      return .requestPlain
    }
  }

  var sampleData: Data {
    return Data() // sample data for UITest
  }

  var headers: [String: String]? {
    return [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum UserInfoService {
  case addPushToken(accessToken: String, pushToken: String)
  case addNewAlert(accessToken: String, jsonData: JSONDictionary)
  case removeAnAlert(accessToken: String, alertID: Int)
  case getListAlerts(accessToken: String)
  case updateAlert(accessToken: String, jsonData: JSONDictionary)
  case getListAlertMethods(accessToken: String)
  case setAlertMethods(accessToken: String, email: [JSONDictionary], telegram: [JSONDictionary])
  case getLeaderBoardData(accessToken: String)
  case getLatestCampaignResult(accessToken: String)
  case sendTxHash(authToken: String, txHash: String)
  case getNotification(accessToken: String?, pageIndex: Int)
  case markAsRead(accessToken: String?, ids: [Int])
  case getPreScreeningWallet(address: String)
  case deleteAllTriggerdAlerts(accessToken: String)
  case getListSubscriptionTokens(accessToken: String)
  case togglePriceNotification(accessToken: String, state: Bool)
  case updateListSubscriptionTokens(accessToken: String, symbols: [String])
  case updateUserPlayerId(accessToken: String, playerId: String)
  case getListFavouriteMarket(accessToken: String)
  case updateMarketFavouriteStatus(accessToken: String, base: String, quote: String, status: Bool)
  case getPlatformFee
  case getMobileBanner
  case getSwapHint(from: String, to: String, amount: String?)
}

extension UserInfoService: MoyaCacheable {
  var cachePolicy: MoyaCacheablePolicy { return .reloadIgnoringLocalAndRemoteCacheData }
  var httpShouldHandleCookies: Bool { return false }
}

extension UserInfoService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
    switch self {
    case .addPushToken:
      return URL(string: "\(baseString)/api/update_push_token")!
    case .addNewAlert, .getListAlerts:
      return URL(string: "\(baseString)/api/alerts")!
    case .updateAlert(_, let jsonData):
      let id = jsonData["id"] as? Int ?? 0
      return URL(string: "\(baseString)/api/alerts/\(id)")!
    case .removeAnAlert(_, let alertID):
      return URL(string: "\(baseString)/api/alerts/\(alertID)")!
    case .getListAlertMethods:
      return URL(string: "\(baseString)/api/get_alert_methods")!
    case .setAlertMethods:
      return URL(string: "\(baseString)/api/update_alert_methods")!
    case .getLeaderBoardData:
      return URL(string: "\(baseString)/api/alerts/ranks")!
    case .getLatestCampaignResult:
      return URL(string: "\(baseString)/api/alerts/campaign_prizes")!
    case .sendTxHash:
      return URL(string: "\(baseString)\(KNSecret.sendTxHashURL)")!
    case .getNotification(_, let pageIndex):
      return URL(string: "\(baseString)/api/notifications?page_index=\(pageIndex)&page_size=10")!
    case .markAsRead:
      return URL(string: "\(baseString)/api/notifications/mark_as_read")!
    case .getPreScreeningWallet(let address):
      return URL(string: "\(baseString)/api/wallet/screening?wallet=\(address)")!
    case .deleteAllTriggerdAlerts:
      return URL(string: "\(baseString)/api/alerts/delete_triggered")!
    case .getListSubscriptionTokens:
      return URL(string: "\(baseString)/api/users/subscription_tokens")!
    case .togglePriceNotification:
      return URL(string: "\(baseString)/api/users/toggle_price_noti")!
    case .updateListSubscriptionTokens:
      return URL(string: "\(baseString)/api/users/subscription_tokens")!
    case .updateUserPlayerId:
      return URL(string: "\(baseString)/api/users/player_id")!
    case .updateMarketFavouriteStatus:
      return URL(string: "\(baseString)/api/orders/favorite_pair")!
    case .getListFavouriteMarket:
      return URL(string: "\(baseString)/api/orders/favorite_pairs")!
    case .getPlatformFee:
      return URL(string: "\(baseString)/api/swap_fee")!
    case .getMobileBanner:
      return URL(string: "\(baseString)/api/mobile_banners")!
    case .getSwapHint:
      return URL(string: "\(baseString)/api/swap_hint")!
    }
  }

  var path: String { return "" }

  var method: Moya.Method {
    switch self {
    case .getListAlerts, .getListAlertMethods, .getLeaderBoardData, .getLatestCampaignResult, .getNotification, .getPreScreeningWallet, .getListSubscriptionTokens, .getListFavouriteMarket, .getPlatformFee, .getMobileBanner, .getSwapHint: return .get
    case .removeAnAlert, .deleteAllTriggerdAlerts: return .delete
    case .addPushToken, .updateAlert, .togglePriceNotification: return .patch
    case .markAsRead, .updateMarketFavouriteStatus: return .put
    default: return .post
    }
  }

  var task: Task {
    switch self {
    case .addPushToken(_, let pushToken):
      let json: JSONDictionary = [
        "push_token_mobile": pushToken,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .addNewAlert(_, let jsonData):
      var json: JSONDictionary = jsonData
      json["id"] = nil
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .updateAlert(_, let jsonData):
      var json: JSONDictionary = jsonData
      json["id"] = nil
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .setAlertMethods(_, let email, let telegram):
      var json: JSONDictionary = [:]
      if !email.isEmpty { json["emails"] = email }
      if let tele = telegram.first { json["telegram"] = tele }
      print(json)
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getListAlerts, .removeAnAlert, .getListAlertMethods, .getLeaderBoardData, .getLatestCampaignResult, .getNotification, .deleteAllTriggerdAlerts, .getListSubscriptionTokens, .getListFavouriteMarket, .getPlatformFee, .getMobileBanner:
      return .requestPlain
    case .getPreScreeningWallet:
      return .requestPlain
    case .sendTxHash(_, let txHash):
      let json: JSONDictionary = [
        "tx_hash": txHash,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .markAsRead(_, let ids):
      let json: JSONDictionary = [
        "ids": ids,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .togglePriceNotification(_, let state):
      let json = ["price_noti": state]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .updateListSubscriptionTokens(_, let symbols):
      let json = ["list_token_symbol": symbols]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .updateUserPlayerId(_, let playerId):
      let json: JSONDictionary = [
        "player_id": playerId,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .updateMarketFavouriteStatus(_, let base, let quote, let status):
      let json: JSONDictionary = [
        "base": base,
        "quote": quote,
        "status": status,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getSwapHint(let from, let to, let amount):
      var json: JSONDictionary = [
        "src": from,
        "dst": to,
      ]
      if let amountNotNil = amount {
        json["amount"] = amountNotNil
      }
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    }
  }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    var json: [String: String] = [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
    switch self {
    case .addPushToken(let accessToken, _):
      json["Authorization"] = accessToken
    case .addNewAlert(let accessToken, _):
      json["Authorization"] = accessToken
    case .updateAlert(let accessToken, _):
      json["Authorization"] = accessToken
    case .setAlertMethods(let accessToken, _, _):
      json["Authorization"] = accessToken
    case .getListAlerts(let accessToken):
      json["Authorization"] = accessToken
    case .removeAnAlert(let accessToken, _):
      json["Authorization"] = accessToken
    case .getListAlertMethods(let accessToken):
      json["Authorization"] = accessToken
    case .getLeaderBoardData(let accessToken):
      json["Authorization"] = accessToken
    case .getLatestCampaignResult(let accessToken):
      json["Authorization"] = accessToken
    case .sendTxHash(let accessToken, _):
      json["Authorization"] = accessToken
    case .getNotification(let accessToken, _):
      if let token = accessToken { json["Authorization"] = token }
    case .markAsRead(let accessToken, _):
      if let token = accessToken { json["Authorization"] = token }
    case .getPreScreeningWallet:
      break
    case .deleteAllTriggerdAlerts(let accessToken):
      json["Authorization"] = accessToken
    case .getListSubscriptionTokens(let accessToken):
      json["Authorization"] = accessToken
    case .togglePriceNotification(let accessToken, _):
      json["Authorization"] = accessToken
    case .updateListSubscriptionTokens(let accessToken, _):
      json["Authorization"] = accessToken
    case .updateUserPlayerId(let accessToken, _):
      json["Authorization"] = accessToken
    case .getListFavouriteMarket(let accessToken):
      json["Authorization"] = accessToken
    case .updateMarketFavouriteStatus(let accessToken, _, _, _):
      json["Authorization"] = accessToken
    case .getPlatformFee, .getMobileBanner, .getSwapHint:
      break
    }
    return json
  }
}

//enum LimitOrderService {
//  case getOrders(accessToken: String, pageIndex: Int, pageSize: Int)
//  case createOrder(accessToken: String, order: KNLimitOrder, signedData: Data)
//  case cancelOrder(accessToken: String, id: String)
//  case getNonce(accessToken: String)
//  case getFee(accessToken: String?, address: String, src: String, dest: String, srcAmount: Double, destAmount: Double)
//  case checkEligibleAddress(accessToken: String, address: String)
//  case getRelatedOrders(accessToken: String, address: String, src: String, dest: String, rate: Double)
//  case pendingBalance(accessToken: String, address: String)
//  case getMarkets
//}
//
//extension LimitOrderService: MoyaCacheable {
//  var cachePolicy: MoyaCacheablePolicy { return .reloadIgnoringLocalAndRemoteCacheData }
//  var httpShouldHandleCookies: Bool { return false }
//}

//extension LimitOrderService: TargetType {
//  var baseURL: URL {
//    let baseString = KNAppTracker.getKyberProfileBaseString()
//    switch self {
//    case .getOrders(_, let pageIndex, let pageSize):
//      return URL(string: "\(baseString)/api/orders?page_index=\(pageIndex)&page_size=\(pageSize)&sort=desc")!
//    case .createOrder:
//      return URL(string: "\(baseString)/api/orders")!
//    case .cancelOrder(_, let id):
//      return URL(string: "\(baseString)/api/orders/\(id)/cancel")!
//    case .getNonce:
//      return URL(string: "\(baseString)/api/orders/nonce")!
//    case .getFee(_, let address, let src, let dest, let srcAmount, let destAmount):
//      return URL(string: "\(baseString)/api/orders/fee?user_addr=\(address)&src=\(src)&dst=\(dest)&src_amount=\(srcAmount)&dst_amount=\(destAmount)")!
//    case .checkEligibleAddress(_, let address):
//      return URL(string: "\(baseString)/api/orders/eligible_address?user_addr=\(address)")!
//    case .getRelatedOrders(_, let address, let src, let dest, let rate):
//      return URL(string: "\(baseString)/api/orders/related_orders?user_addr=\(address)&src=\(src)&dst=\(dest)&min_rate=\(rate)")!
//    case .pendingBalance(_, let address):
//      return URL(string: "\(baseString)/api/orders/pending_balances?user_addr=\(address)")!
//    case .getMarkets:
//      let base = KNEnvironment.default.cachedSourceAmountRateURL
//      return URL(string: base + "/pairs/market")!
//    }
//  }
//
//  var path: String { return "" }
//
//  var method: Moya.Method {
//    switch self {
//    case .getOrders, .getFee, .getNonce, .checkEligibleAddress, .getRelatedOrders, .pendingBalance, .getMarkets: return .get
//    case .cancelOrder: return .put
//    case .createOrder: return .post
//    }
//  }
//
//  var task: Task {
//    switch self {
//    case .getOrders, .cancelOrder, .getNonce, .checkEligibleAddress, .pendingBalance, .getFee, .getRelatedOrders, .getMarkets:
//      return .requestPlain
//    case .createOrder(_, let order, let signedData):
//      var json: JSONDictionary = [
//        "user_address": order.sender.description.lowercased(),
//        "nonce": order.nonce,
//        "src_token": order.from.contract.lowercased(),
//        "dest_token": order.to.contract.lowercased(),
//        "dest_address": order.sender.description.lowercased(),
//        "src_amount": order.srcAmount.hexEncoded,
//        "min_rate": (order.targetRate * BigInt(10).power(18 - order.to.decimals)).hexEncoded,
//        "fee": BigInt(order.fee).hexEncoded,
//        "signature": signedData.hexEncoded,
//      ]
//      if let isBuy = order.isBuy {
//        json["side_trade"] = isBuy ? "buy" : "sell"
//      }
//      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
//      return .requestData(data)
//    }
//  }
//
//  var sampleData: Data { return Data() }
//  var headers: [String: String]? {
//    var json: [String: String] = [
//      "content-type": "application/json",
//      "client": "com.kyberswap.ios.bvi",
//      "client-build": Bundle.main.buildNumber ?? "",
//    ]
//    switch self {
//    case .getOrders(let accessToken, _, _):
//      json["Authorization"] = accessToken
//    case .createOrder(let accessToken, _, _):
//      json["Authorization"] = accessToken
//    case .cancelOrder(let accessToken, _):
//      json["Authorization"] = accessToken
//    case .getNonce(let accessToken):
//      json["Authorization"] = accessToken
//    case .checkEligibleAddress(let accessToken, _):
//      json["Authorization"] = accessToken
//    case .getRelatedOrders(let accessToken, _, _, _, _):
//      json["Authorization"] = accessToken
//    case .pendingBalance(let accessToken, _):
//      json["Authorization"] = accessToken
//    case .getFee(let accessToken, _, _, _, _, _):
//      if let accessToken = accessToken { json["Authorization"] = accessToken }
//    case .getMarkets:
//      break
//    }
//    return json
//  }
//}

enum NativeSignInUpService {
  case signUpEmail(email: String, password: String, name: String, isSubs: Bool)
  case signInEmail(email: String, password: String, twoFA: String?)
  case resetPassword(email: String)
  case signInSocial(type: String, email: String, name: String, photo: String, accessToken: String, secret: String?, twoFA: String?)
  case confirmSignUpSocial(type: String, email: String, name: String, photo: String, isSubs: Bool, accessToken: String, secret: String?)
  case updatePassword(email: String, oldPassword: String, newPassword: String, authenToken: String)
  case getUserAuthToken(email: String, password: String)
  case refreshToken(refreshToken: String)
  case getUserInfo(authToken: String)
  case transferConsent(authToken: String, answer: String)
  case signInWithApple(name: String, userId: String, idToken: String, isSignUp: Bool)
  case confirmSignInWithApple(name: String, userId: String, idToken: String, isSignUp: Bool, isSubs: Bool)
}

extension NativeSignInUpService: MoyaCacheable {
  var cachePolicy: MoyaCacheablePolicy { return .reloadIgnoringLocalAndRemoteCacheData }
  var httpShouldHandleCookies: Bool { return false }
}

extension NativeSignInUpService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
    let endpoint: String = {
      switch self {
      case .signUpEmail: return KNSecret.signUpURL
      case .signInEmail: return KNSecret.signInURL
      case .resetPassword: return KNSecret.resetPassURL
      case .signInSocial: return KNSecret.signInSocialURL
      case .confirmSignUpSocial: return KNSecret.confirmSignUpSocialURL
      case .updatePassword: return KNSecret.updatePasswordURL
      case .getUserAuthToken: return KNSecret.getAuthTokenURL
      case .refreshToken: return KNSecret.refreshTokenURL
      case .getUserInfo: return KNSecret.getUserInfoURL
      case .transferConsent: return KNSecret.transferConsentURL
      case .signInWithApple, .confirmSignInWithApple: return KNSecret.signInWithAppleURL
      }
    }()
    return URL(string: "\(baseString)\(endpoint)")!
  }

  var path: String { return "" }

  var method: Moya.Method {
    switch self {
    case .updatePassword: return .patch
    case .getUserInfo: return .get
    default: return .post
    }
  }

  var task: Task {
    switch self {
    case .signUpEmail(let email, let password, let name, let isSubs):
      let json: JSONDictionary = [
        "email": email,
        "password": password,
        "password_confirmation": password,
        "display_name": name,
        "subscription": isSubs,
        "photo_url": "",
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .signInEmail(let email, let password, let twoFA):
      var json: JSONDictionary = [
        "email": email,
        "password": password,
      ]
      if let token = twoFA { json["two_factor_code"] = token }
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .resetPassword(let email):
      let json: JSONDictionary = [
        "email": email,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .signInSocial(let type, let email, let name, let photo, let accessToken, let secret, let twoFA):
      var json: JSONDictionary = [
        "type": type,
        "email": email,
        "display_name": name,
        "photo_url": photo,
        "access_token": accessToken,
        "oauth_token": accessToken,
      ]
      if let secret = secret { json["oauth_token_secret"] = secret }
      if let token = twoFA { json["two_factor_code"] = token }
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .confirmSignUpSocial(let type, let email, let name, let photo, let isSubs, let accessToken, let secret):
      var json: JSONDictionary = [
        "type": type,
        "email": email,
        "display_name": name,
        "subscription": isSubs,
        "photo_url": photo,
        "access_token": accessToken,
        "oauth_token": accessToken,
        "confirm_signup": true,
      ]
      if let secret = secret { json["oauth_token_secret"] = secret }
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .updatePassword(let email, let oldPassword, let newPassword, _):
      let json: JSONDictionary = [
        "email": email,
        "current_password": oldPassword,
        "password_confirmation": newPassword,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getUserAuthToken(let email, let password):
      let json: JSONDictionary = [
        "email": email,
        "password": password,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .getUserInfo:
      return .requestPlain
    case .refreshToken(let refreshToken):
      let json: JSONDictionary = [
        "refresh_token": refreshToken,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .transferConsent(_, let answer):
      let json: JSONDictionary = [
        "transfer_permission": answer,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .signInWithApple(let name, let userId, let idToken, let isSignUp):
      let json: JSONDictionary = [
        "type": isSignUp ? "sign_up" : "sign_in",
        "id_token": idToken,
        "user_identity": userId,
        "display_name": name,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .confirmSignInWithApple(let name, let userId, let idToken, let isSignUp, let isSub):
      let json: JSONDictionary = [
        "type": isSignUp ? "sign_up" : "sign_in",
        "id_token": idToken,
        "user_identity": userId,
        "display_name": name,
        "subscription": isSub,
        "confirm_signup": true,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    }
  }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    if case .updatePassword(_, _, _, let authenToken) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.bvi",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    if case .getUserInfo(let authenToken) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.bvi",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    if case .transferConsent(let authenToken, _) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.bvi",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    return [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum ProfileService {
  case personalInfo(
    accessToken: String,
    firstName: String, middleName: String, lastName: String,
    nativeFullName: String,
    gender: Bool, dob: String, nationality: String,
    residentialAddress: String, country: String, city: String, zipCode: String,
    proofAddress: String, proofAddressImageData: Data,
    sourceFund: String,
    occupationCode: String?, industryCode: String?, taxCountry: String?, taxIDNo: String?
  )
  case identityInfo(
    accessToken: String,
    documentType: String, documentID: String,
    issueDate: String?, expiryDate: String?,
    docFrontImage: Data, docBackImage: Data?, docHoldingImage: Data
  )
  case submitKYC(accessToken: String)
  case resubmitKYC(accessToken: String)
  case promoCode(promoCode: String, nonce: UInt)

  var apiPath: String {
    switch self {
    case .personalInfo: return KNSecret.personalInfoEndpoint
    case .identityInfo: return KNSecret.identityInfoEndpoint
    case .submitKYC: return KNSecret.submitKYCEndpoint
    case .resubmitKYC: return KNSecret.resubmitKYC
    case .promoCode: return ""
    }
  }
}

extension ProfileService: MoyaCacheable {
  var cachePolicy: MoyaCacheablePolicy { return .reloadIgnoringLocalAndRemoteCacheData }
  var httpShouldHandleCookies: Bool { return false }
}

extension ProfileService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
    if case .promoCode(let promoCode, let nonce) = self {
      let path = "\(KNSecret.promoCode)?code=\(promoCode)&isInternalApp=True&nonce=\(nonce)"
      return URL(string: "\(baseString)/api\(path)")!
    }
    return URL(string: "\(baseString)/api")!
  }

  var path: String { return self.apiPath }
  var method: Moya.Method {
    if case .promoCode = self { return .get }
    return .post
  }
  var task: Task {
    switch self {
    case .personalInfo(
      _,
      let firstName,
      let middleName,
      let lastName,
      let nativeFullName,
      let gender,
      let dob,
      let nationality,
      let residentialAddress,
      let country,
      let city,
      let zipCode,
      let proofAddress,
      let proofAddressImageData,
      let sourceFund,
      let occupationCode,
      let industryCode,
      let taxCountry,
      let taxIDNo):
      var json: JSONDictionary = [
        "first_name": firstName,
        "middle_name": middleName,
        "last_name": lastName,
        "native_full_name": nativeFullName,
        "gender": gender,
        "dob": dob,
        "nationality": nationality,
        "residential_address": residentialAddress,
        "country": country,
        "city": city,
        "zip_code": zipCode,
        "document_proof_address": proofAddress,
        "photo_proof_address": "data:image/jpeg;base64,\(proofAddressImageData.base64EncodedString())",
        "source_fund": sourceFund,
      ]
      if let code = occupationCode {
        json["occupation_code"] = code
      }
      if let code = industryCode {
        json["industry_code"] = code
      }
      if let taxCountry = taxCountry {
        json["tax_residency_country"] = taxCountry
      }
      json["have_tax_identification"] = taxIDNo != nil
      json["tax_identification_number"] = taxIDNo ?? ""
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .identityInfo(_, let documentType, let documentID, let issueDate, let expiryDate, let docFrontImage, let docBackImage, let docHoldingImage):
      var json: JSONDictionary = [
        "document_type": documentType,
        "document_id": documentID,
        "document_issue_date": issueDate ?? "",
        "document_expiry_date": expiryDate ?? "",
        "photo_identity_front_side": "data:image/jpeg;base64,\(docFrontImage.base64EncodedString())",
        "photo_selfie": "data:image/jpeg;base64,\(docHoldingImage.base64EncodedString())",
      ]
      if let docBackImage = docBackImage {
        json["photo_identity_back_side"] = "data:image/jpeg;base64,\(docBackImage.base64EncodedString())"
      }
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    case .resubmitKYC, .submitKYC, .promoCode:
      return .requestPlain
    }
  }

  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    var json: [String: String] = [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.bvi",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
    switch self {
    case .personalInfo(
      let accessToken, _, _, _, _, _, _, _, _,
      _, _, _, _, _, _, _, _, _, _):
      json["Authorization"] = accessToken
    case .identityInfo(let accessToken, _, _, _, _, _, _, _):
      json["Authorization"] = accessToken
    case .submitKYC(let accessToken):
      json["Authorization"] = accessToken
    case .resubmitKYC(let accessToken):
      json["Authorization"] = accessToken
    case .promoCode(let promoCode, let nonce):
      let key: String = {
        if KNEnvironment.default == .production || KNEnvironment.default == .mainnetTest {
          return KNSecret.promoCodeProdSecretKey
        }
        return KNSecret.promoCodeDevSecretKey
      }()
      let string = "code=\(promoCode)&isInternalApp=True&nonce=\(nonce)"
      let hmac = try! HMAC(key: key, variant: .sha512)
      let hash = try! hmac.authenticate(string.bytes).toHexString()
      return [
        "Content-Type": "application/x-www-form-urlencoded",
        "signed": hash,
        "client": "com.kyberswap.ios.bvi",
        "client-build": Bundle.main.buildNumber ?? "",
      ]
    }
    return json
  }
}

enum KrytalService {
  case getBestPath(src: String, dst: String, srcAmount: String)
  case getHint(path: [JSONDictionary])
  case getExpectedRate(src: String, dst: String, srcAmount: String, hint: String, isCaching: Bool)
  case getAllRates(src: String, dst: String, srcAmount: String)
  case buildSwapTx(address: String, src: String, dst: String, srcAmount: String, minDstAmount: String, gasPrice: String, nonce: Int, hint: String, useGasToken: Bool)
  case getGasLimit(src: String, dst: String, srcAmount: String, hint: String)
  case getGasPrice
  case getRefPrice(src: String, dst: String)
  case getTokenList
  case getLendingOverview
  case buildSwapAndDepositTx(lendingPlatform: String, userAddress: String, src: String, dest: String, srcAmount: String, minDestAmount: String, gasPrice: String, nonce: Int, hint: String, useGasToken: Bool)
  case getLendingBalance(address: String)
  case getLendingDistributionBalance(lendingPlatform: String, address: String)
  case getWithdrawableAmount(platform: String, userAddress: String, token: String)
  case buildWithdrawTx(platform: String, userAddress: String, token: String, amount: String, gasPrice: String, nonce: Int, useGasToken: Bool)
  case getMarketingAssets
  case getReferralOverview(address: String, accessToken: String)
  case registerReferrer(address: String, referralCode: String, signature: String)
  case getRewardHistory(address: String, from: Int, to: Int, offset: Int, limit: Int, accessToken: String)
  case buildClaimTx(address: String, nonce: Int)
  case getNotification(batchId: String, limit: Int = 20)
  case login(address: String, timestamp: Int, signature: String)
  case getClaimHistory(address: String, accessToken: String)
  case claimReward(address: String, amount: Double, accessToken: String)
}

extension KrytalService: TargetType {
  var baseURL: URL {
    switch self {
    case .getHint(let path):
      var urlComponents = URLComponents(string: KNEnvironment.default.krystalEndpoint + "/v1/swap/buildHint")!
      var queryItems: [URLQueryItem] = []
      path.forEach { (element) in
        let id = element["id"] as? String ?? ""
        let value = element["split_value"] as? NSNumber ?? NSNumber(0)
        let idItem = URLQueryItem(name: "id", value: id)
        let valueItem = URLQueryItem(name: "split_value", value: value.description)
        queryItems.append(idItem)
        queryItems.append(valueItem)
      }
      urlComponents.queryItems = queryItems
      return urlComponents.url!
    default:
      return URL(string: KNEnvironment.default.krystalEndpoint)!
    }
  }

  var path: String {
    switch self {
    case .getBestPath:
      return "/v1/swap/bestPath"
    case .getHint:
      return ""
    case .getExpectedRate:
      return "/v1/swap/expectedRate"
    case .getAllRates:
      return "/v1/swap/allRates"
    case .buildSwapTx:
      return "/v1/swap/buildTx"
    case .getGasPrice:
      return "/v1/swap/gasPrice"
    case .getGasLimit:
      return "/v1/swap/gasLimit"
    case .getRefPrice:
      return "/v1/market/refPrice"
    case .getTokenList:
      return "/v1/token/tokenList"
    case .getLendingOverview:
      return "/v1/lending/overview"
    case .buildSwapAndDepositTx:
      return "/v1/swap/buildSwapAndDepositTx"
    case .getLendingBalance:
      return "/v1/lending/balance"
    case .getLendingDistributionBalance:
      return "/v1/lending/distributionBalance"
    case .getWithdrawableAmount:
      return "/v1/lending/withdrawableAmount"
    case .buildWithdrawTx:
      return "/v1/lending/buildWithdrawTx"
    case .getMarketingAssets:
      return "/v1/mkt/assets"
    case .getReferralOverview:
      return "/v1/account/referralOverview"
    case .registerReferrer:
      return "/v1/account/registerReferrer"
    case .getRewardHistory:
      return "/v1/account/rewardHistory"
    case .buildClaimTx:
      return "/v1/lending/buildClaimTx"
    case .getNotification:
      return "/v1/notification/list"
    case .login:
      return "/v1/login"
    case .getClaimHistory:
      return "/v1/account/claimHistory"
    case .claimReward:
      return "/v1/account/claimReward"
    }
  }

  var method: Moya.Method {
    switch self {
    case .registerReferrer, .login:
      return .post
    default:
      return .get
    }
  }

  var sampleData: Data {
    return Data()
  }

  var task: Task {
    switch self {
    case .getBestPath(let src, let dst, let srcAmount):
      let json: JSONDictionary = [
        "src": src,
        "dest": dst,
        "srcAmount": srcAmount
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getHint:
      return .requestPlain
    case .getExpectedRate(let src, let dst, let srcAmount, let hint, let isCaching):
      let json: JSONDictionary = [
        "src": src,
        "dest": dst,
        "srcAmount": srcAmount,
        "hint": hint,
        "isCaching": isCaching,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getAllRates(let src, let dst, let srcAmount):
      let json: JSONDictionary = [
        "src": src,
        "dest": dst,
        "srcAmount": srcAmount,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .buildSwapTx(let address, let src, let dst, let srcAmount, let minDstAmount, let gasPrice, let nonce, let hint, let useGasToken):
      let json: JSONDictionary = [
        "userAddress": address,
        "src": src,
        "dest": dst,
        "srcAmount": srcAmount,
        "minDestAmount": minDstAmount,
        "gasPrice": gasPrice,
        "nonce": nonce,
        "hint": hint,
        "platformWallet": "0x9a68f7330A3Fe9869FfAEe4c3cF3E6BBef1189Da",
        "useGasToken": useGasToken,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getGasPrice:
      return .requestPlain
    case .getGasLimit(let src, let dst, let srcAmount, let hint):
      let json: JSONDictionary = [
        "src": src,
        "dest": dst,
        "srcAmount": srcAmount,
        "hint": hint,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getRefPrice(let src, let dst):
      let json: JSONDictionary = [
        "src": src,
        "dest": dst,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getTokenList, .getLendingOverview:
      return .requestPlain
    case .buildSwapAndDepositTx(let lendingPlatform, let userAddress, let src, let dest, let srcAmount, let minDestAmount, let gasPrice, let nonce, let hint, let useGasToken):
      let json: JSONDictionary = [
        "lendingPlatform": lendingPlatform,
        "userAddress": userAddress,
        "src": src,
        "dest": dest,
        "srcAmount": srcAmount,
        "minDestAmount": minDestAmount,
        "gasPrice": gasPrice,
        "nonce": nonce,
        "hint": hint,
        "platformWallet": "0x9a68f7330A3Fe9869FfAEe4c3cF3E6BBef1189Da",
        "useGasToken": useGasToken,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getLendingBalance(address: let address):
      let json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getLendingDistributionBalance(lendingPlatform: let lendingPlatform, address: let address):
      let json: JSONDictionary = [
        "address": address,
        "lendingPlatform": lendingPlatform
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getWithdrawableAmount(platform: let platform, userAddress: let userAddress, token: let token):
      let json: JSONDictionary = [
        "lendingPlatform": platform,
        "userAddress": userAddress,
        "token": token
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .buildWithdrawTx(platform: let platform, userAddress: let userAddress, token: let token, amount: let amount, gasPrice: let gasPrice, nonce: let nonce, useGasToken: let useGasToken):
      let json: JSONDictionary = [
        "lendingPlatform": platform,
        "token": token,
        "amount": amount,
        "gasPrice": gasPrice,
        "nonce": nonce,
        "useGasToken": useGasToken,
        "userAddress": userAddress
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getMarketingAssets:
      return .requestPlain
    case .getReferralOverview(address: let address, _):
      let json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .registerReferrer(address: let address, referralCode: let referralCode, signature: let signature):
      let json: JSONDictionary = [
        "address": address,
        "referralCode": referralCode,
        "signature": signature
      ]
      return .requestParameters(parameters: json, encoding: JSONEncoding.default)
    case .getRewardHistory(address: let address, from: let from, to: let to, offset: let offset, limit: let limit, _):
      let json: JSONDictionary = [
        "address": address,
        "from": from,
        "to": to,
        "offset": offset,
        "limit": limit
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .buildClaimTx(address: let address, nonce: let nonce):
      let json: JSONDictionary = [
        "lendingPlatform": "Compound",
        "address": address,
        "gasPrice": KNGasCoordinator.shared.fastKNGas.description,
        "nonce": nonce
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getNotification(batchId: let batchId, limit: let limit):
      let json: JSONDictionary = [
        "batchId": batchId,
        "limit": limit
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .login(address: let address, timestamp: let timestamp, signature: let signature):
      let json: JSONDictionary = [
        "address": address,
        "timestamp": timestamp,
        "signature": signature
      ]
      return .requestParameters(parameters: json, encoding: JSONEncoding.default)
    case .getClaimHistory(address: let address, _):
      let json: JSONDictionary = [
        "address": address
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .claimReward(address: let address, amount: let amount, _):
      let json: JSONDictionary = [
        "address": address,
        "amount": amount
      ]
      return .requestParameters(parameters: json, encoding: JSONEncoding.default)
    }
  }

  var headers: [String: String]? {
    switch self {
    case .getReferralOverview( _ , let accessToken):
      return ["Authorization" : "Bearer \(accessToken)"]
    case .getRewardHistory(_ , _, _ , _ , _ , let accessToken):
      return ["Authorization" : "Bearer \(accessToken)"]
    case .getClaimHistory( _, let accessToken):
      return ["Authorization" : "Bearer \(accessToken)"]
    case .claimReward(_ , _, let accessToken):
      return ["Authorization" : "Bearer \(accessToken)"]
    default:
      return nil
    }
  }
}


enum CoinGeckoService {
  case getChartData(address: String, from: Int, to: Int)
  case getTokenDetailInfo(address: String)
  case getPriceETH
  case getPriceTokens(addresses: [String])
}

extension CoinGeckoService: TargetType {
  var baseURL: URL {
    return URL(string: "https://api.coingecko.com/api")!
  }

  var path: String {
    switch self {
    case .getChartData(let address, _ , _):
      return address.lowercased() == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" ? "/v3/coins/ethereum/market_chart/range" : "/v3/coins/ethereum/contract/\(address)/market_chart/range"
    case .getTokenDetailInfo(address: let address):
      return address.lowercased() == "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" ? "/v3/coins/ethereum" : "/v3/coins/ethereum/contract/\(address)"
    case .getPriceETH:
      return "/v3/simple/price"
    case .getPriceTokens:
      return "/v3/simple/token_price/ethereum"
      
    }
  }
  
  var method: Moya.Method {
    return .get
  }
  
  var sampleData: Data {
    return Data()
  }
  
  var task: Task {
    switch self {
    case .getChartData( _, let from , let to):
      let json: JSONDictionary = [
        "vs_currency": "usd",
        "from": from,
        "to": to,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getTokenDetailInfo:
      let json: JSONDictionary = [
        "localization": false,
        "tickers": false,
        "market_data": true,
        "community_data": false,
        "developer_data": false,
        "sparkline": false,
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getPriceETH:
      let json: JSONDictionary = [
        "ids": "ethereum",
        "vs_currencies": "eth,usd,btc",
        "include_market_cap": "true",
        "include_24hr_vol": "true",
        "include_24hr_change": "true",
        "include_last_updated_at": "true",
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    case .getPriceTokens(addresses: let addresses):
      let json: JSONDictionary = [
        "contract_addresses": addresses.joined(separator: ","),
        "vs_currencies": "eth,usd,btc",
        "include_market_cap": "true",
        "include_24hr_vol": "true",
        "include_24hr_change": "true",
        "include_last_updated_at": "true",
      ]
      return .requestParameters(parameters: json, encoding: URLEncoding.queryString)
    }
  }
  
  var headers: [String : String]? {
   return nil
  }
}
