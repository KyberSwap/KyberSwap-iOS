// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNCustomRPC {

  let customRPC: CustomRPC
  let networkAddress: String
  let authorizedAddress: String
  let tokenIEOAddress: String
  let reserveAddress: String
  let wrapperAddress: String
  let limitOrderAddress: String
  let etherScanEndpoint: String
  let enjinScanEndpoint: String
  let tradeTopic: String
  let ensAddress: String

  init(dictionary: JSONDictionary) {
    let chainID: Int = dictionary["networkId"] as? Int ?? 0
    let name: String = dictionary["chainName"] as? String ?? ""
    let symbol = name
    var endpoint: String
    var endpointKyber: String
    var endpointAlchemy: String
    if let connections: JSONDictionary = dictionary["connections"] as? JSONDictionary,
      let https: [JSONDictionary] = connections["http"] as? [JSONDictionary] {
      let endpointJSON: JSONDictionary = https.count > 1 ? https[1] : https[0]
      endpoint = (endpointJSON["endPoint"] as? String ?? "") + KNSecret.infuraKey
      endpointKyber = https[0]["endpoint"] as? String ?? endpoint
      endpointAlchemy = {
        if https.count > 2 {
          return (https[2]["endPoint"] as? String ?? endpoint) + KNSecret.alchemyKey
        }
        return endpoint
      }()
    } else {
      endpoint = (dictionary["endpoint"] as? String ?? "") + KNSecret.infuraKey
      endpointKyber = endpoint + KNSecret.infuraKey
      endpointAlchemy = endpoint + KNSecret.infuraKey
    }
    self.networkAddress = dictionary["network"] as? String ?? ""
    self.authorizedAddress = dictionary["authorize_contract"] as? String ?? ""
    self.tokenIEOAddress = dictionary["token_ieo"] as? String ?? ""
    self.reserveAddress = dictionary["reserve"] as? String ?? ""
    self.limitOrderAddress = dictionary["limit_order"] as? String ?? ""
    self.etherScanEndpoint = dictionary["ethScanUrl"] as? String ?? ""
    self.enjinScanEndpoint = dictionary["enjinx"] as? String ?? ""
    self.tradeTopic = dictionary["trade_topic"] as? String ?? ""
    self.ensAddress = dictionary["ens_address"] as? String ?? ""
    self.wrapperAddress = dictionary["wrapper"] as? String ?? ""
    self.customRPC = CustomRPC(
      chainID: chainID,
      name: name,
      symbol: symbol,
      endpoint: endpoint,
      endpointKyber: endpointKyber,
      endpointAlchemy: endpointAlchemy
    )
  }
}
