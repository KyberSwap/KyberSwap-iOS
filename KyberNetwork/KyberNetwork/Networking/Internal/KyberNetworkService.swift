// Copyright SIX DAY LLC. All rights reserved.


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

enum KyberNetworkService: String {
  case getRate = "/token_price?currency=ETH"
  case getCachedRate = "/rate"
  case getRateUSD = "/token_price?currency=USD"
  case getHistoryOneColumn = "/getHistoryOneColumn"
  case getLatestBlock = "/latestBlock"
  case getKyberEnabled = "/kyberEnabled"
  case getMaxGasPrice = "/maxGasPrice"
  case getGasPrice = "/gasPrice"
  case supportedToken = ""
}

extension KyberNetworkService: TargetType {

  var baseURL: URL {
    let baseURLString: String = {
      if case .getCachedRate = self {
        return KNEnvironment.default.cachedRateURL
      }
      if case .supportedToken = self {
        return KNEnvironment.default.supportedTokenEndpoint
      }
      if case .getRate = self { return "\(KNEnvironment.default.kyberAPIEnpoint)\(self.rawValue)" }
      if case .getRateUSD = self { return "\(KNEnvironment.default.kyberAPIEnpoint)\(self.rawValue)" }
      if KNEnvironment.default == .staging { return KNSecret.internalStagingEndpoint }
      return KNSecret.internalCachedEndpoint
    }()
    return URL(string: baseURLString)!
  }

  var path: String {
    if case .getRate = self { return "" }
    if case .getRateUSD = self { return "" }
    return self.rawValue
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
      "client": "com.kyberswap.ios.new",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
  }
}

enum KNTrackerService {
  case getChartHistory(symbol: String, resolution: String, from: Int64, to: Int64, rateType: String)
  case getRates
  case swapSuggestion(address: String, tokens: JSONDictionary)
  case getGasLimit(src: String, dest: String, amount: Double)
  case getSourceAmount(src: String, dest: String, amount: Double)
  case getTokenVolumne
}

extension KNTrackerService: TargetType {
  var baseURL: URL {
    let baseURLString = KNEnvironment.internalTrackerEndpoint
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
      "client": "com.kyberswap.ios.new",
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
    }
  }

  var path: String { return "" }

  var method: Moya.Method {
    switch self {
    case .getListAlerts, .getListAlertMethods, .getLeaderBoardData, .getLatestCampaignResult, .getNotification, .getPreScreeningWallet: return .get
    case .removeAnAlert, .deleteAllTriggerdAlerts: return .delete
    case .addPushToken, .updateAlert: return .patch
    case .markAsRead: return .put
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
    case .getListAlerts, .removeAnAlert, .getListAlertMethods, .getLeaderBoardData, .getLatestCampaignResult, .getNotification, .deleteAllTriggerdAlerts:
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
    }
  }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    var json: [String: String] = [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.new",
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
    }
    return json
  }
}

enum LimitOrderService {
  case getOrders(accessToken: String, pageIndex: Int, pageSize: Int)
  case createOrder(accessToken: String, order: KNLimitOrder, signedData: Data)
  case cancelOrder(accessToken: String, id: String)
  case getNonce(accessToken: String)
  case getFee(accessToken: String?, address: String, src: String, dest: String, srcAmount: Double, destAmount: Double)
  case checkEligibleAddress(accessToken: String, address: String)
  case getRelatedOrders(accessToken: String, address: String, src: String, dest: String, rate: Double)
  case pendingBalance(accessToken: String, address: String)
}

extension LimitOrderService: MoyaCacheable {
  var cachePolicy: MoyaCacheablePolicy { return .reloadIgnoringLocalAndRemoteCacheData }
  var httpShouldHandleCookies: Bool { return false }
}

extension LimitOrderService: TargetType {
  var baseURL: URL {
    let baseString = KNAppTracker.getKyberProfileBaseString()
    switch self {
    case .getOrders(_, let pageIndex, let pageSize):
      return URL(string: "\(baseString)/api/orders?page_index=\(pageIndex)&page_size=\(pageSize)&sort=desc")!
    case .createOrder:
      return URL(string: "\(baseString)/api/orders")!
    case .cancelOrder(_, let id):
      return URL(string: "\(baseString)/api/orders/\(id)/cancel")!
    case .getNonce:
      return URL(string: "\(baseString)/api/orders/nonce")!
    case .getFee(_, let address, let src, let dest, let srcAmount, let destAmount):
      return URL(string: "\(baseString)/api/orders/fee?user_addr=\(address)&src=\(src)&dst=\(dest)&src_amount=\(srcAmount)&dst_amount=\(destAmount)")!
    case .checkEligibleAddress(_, let address):
      return URL(string: "\(baseString)/api/orders/eligible_address?user_addr=\(address)")!
    case .getRelatedOrders(_, let address, let src, let dest, let rate):
      return URL(string: "\(baseString)/api/orders/related_orders?user_addr=\(address)&src=\(src)&dst=\(dest)&min_rate=\(rate)")!
    case .pendingBalance(_, let address):
      return URL(string: "\(baseString)/api/orders/pending_balances?user_addr=\(address)")!
    }
  }

  var path: String { return "" }

  var method: Moya.Method {
    switch self {
    case .getOrders, .getFee, .getNonce, .checkEligibleAddress, .getRelatedOrders, .pendingBalance: return .get
    case .cancelOrder: return .put
    case .createOrder: return .post
    }
  }

  var task: Task {
    switch self {
    case .getOrders, .cancelOrder, .getNonce, .checkEligibleAddress, .pendingBalance, .getFee, .getRelatedOrders:
      return .requestPlain
    case .createOrder(_, let order, let signedData):
      let json: JSONDictionary = [
        "user_address": order.sender.description.lowercased(),
        "nonce": order.nonce,
        "src_token": order.from.contract.lowercased(),
        "dest_token": order.to.contract.lowercased(),
        "dest_address": order.sender.description.lowercased(),
        "src_amount": order.srcAmount.hexEncoded,
        "min_rate": (order.targetRate * BigInt(10).power(18 - order.to.decimals)).hexEncoded,
        "fee": BigInt(order.fee).hexEncoded,
        "signature": signedData.hexEncoded,
      ]
      let data = try! JSONSerialization.data(withJSONObject: json, options: [])
      return .requestData(data)
    }
  }

  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    var json: [String: String] = [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.new",
      "client-build": Bundle.main.buildNumber ?? "",
    ]
    switch self {
    case .getOrders(let accessToken, _, _):
      json["Authorization"] = accessToken
    case .createOrder(let accessToken, _, _):
      json["Authorization"] = accessToken
    case .cancelOrder(let accessToken, _):
      json["Authorization"] = accessToken
    case .getNonce(let accessToken):
      json["Authorization"] = accessToken
    case .checkEligibleAddress(let accessToken, _):
      json["Authorization"] = accessToken
    case .getRelatedOrders(let accessToken, _, _, _, _):
      json["Authorization"] = accessToken
    case .pendingBalance(let accessToken, _):
      json["Authorization"] = accessToken
    case .getFee(let accessToken, _, _, _, _, _):
      if let accessToken = accessToken { json["Authorization"] = accessToken }
    }
    return json
  }
}

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
    }
  }
  var sampleData: Data { return Data() }
  var headers: [String: String]? {
    if case .updatePassword(_, _, _, let authenToken) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.new",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    if case .getUserInfo(let authenToken) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.new",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    if case .transferConsent(let authenToken, _) = self {
      return [
        "content-type": "application/json",
        "client": "com.kyberswap.ios.new",
        "client-build": Bundle.main.buildNumber ?? "",
        "Authorization": authenToken,
      ]
    }
    return [
      "content-type": "application/json",
      "client": "com.kyberswap.ios.new",
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
      "client": "com.kyberswap.ios.new",
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
        "client": "com.kyberswap.ios.new",
        "client-build": Bundle.main.buildNumber ?? "",
      ]
    }
    return json
  }
}
