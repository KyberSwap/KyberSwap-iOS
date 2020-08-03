// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya
import JSONRPCKit
import APIKit
import BigInt
import TrustKeystore
import TrustCore

class KNGasCoordinator {

  static let shared: KNGasCoordinator = KNGasCoordinator()
  fileprivate let provider = MoyaProvider<KyberNetworkService>()

  static let kSavedDefaultGas = "kSavedDefaultGas"
  static let kSavedStandardGas = "kSavedStandardGas"
  static let kSavedLowGas = "kSavedLowGas"
  static let kSavedFastGas = "kSavedFastGas"
  static let kSavedMaxGas = "kSavedMaxGas"

  lazy var numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    return formatter
  }()

  var defaultKNGas: BigInt = KNGasConfiguration.gasPriceDefault
  var standardKNGas: BigInt = KNGasConfiguration.gasPriceDefault
  var lowKNGas: BigInt = KNGasConfiguration.gasPriceMin
  var fastKNGas: BigInt = KNGasConfiguration.gasPriceMax
  var superFastKNGas: BigInt {
    if fastKNGas < EtherNumberFormatter.full.number(from: "10", units: UnitConfiguration.gasPriceUnit)! {
      return EtherNumberFormatter.full.number(from: "20", units: UnitConfiguration.gasPriceUnit)! // Min fast gas
    }
    return min(fastKNGas * BigInt(2), self.maxKNGas)
  }

  var maxKNGas: BigInt = KNGasConfiguration.gasPriceMax

  fileprivate var knGasPriceFetchTimer: Timer?
  fileprivate var isLoadingGasPrice: Bool = false
  fileprivate var knMaxGasPriceFetchTimer: Timer?
  fileprivate var isLoadingMaxGasPrice: Bool = false
  fileprivate var lastGasPriceLoadedSuccessTimeStamp: TimeInterval = 0

  init() {}

  func resume() {
    self.loadMaxGasPrice()
    self.loadGasValues()
    knGasPriceFetchTimer?.invalidate()
    knMaxGasPriceFetchTimer?.invalidate()
    isLoadingGasPrice = false
    isLoadingMaxGasPrice = false
    fetchKNGasPrice(nil)
    fetchKNMaxGasPrice(nil)

    knGasPriceFetchTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.seconds30,
      target: self,
      selector: #selector(fetchKNGasPrice(_:)),
      userInfo: nil,
      repeats: true
    )

    knMaxGasPriceFetchTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.minutes10,
      target: self,
      selector: #selector(fetchKNMaxGasPrice(_:)),
      userInfo: nil,
      repeats: true
    )
  }

  func pause() {
    knGasPriceFetchTimer?.invalidate()
    knGasPriceFetchTimer = nil
    isLoadingGasPrice = true
    knMaxGasPriceFetchTimer?.invalidate()
    knGasPriceFetchTimer = nil
    isLoadingMaxGasPrice = true
  }

  @objc func fetchKNGasPrice(_ sender: Timer?) {
    if isLoadingGasPrice { return }
    isLoadingGasPrice = true
    DispatchQueue.global(qos: .background).async {
      KNInternalProvider.shared.getKNCachedGasPrice { [weak self] (result) in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.isLoadingGasPrice = false
          if case .success(let data) = result {
            try? self.updateGasPrice(dataJSON: data)
          } else {
            if Date().timeIntervalSince1970 - self.lastGasPriceLoadedSuccessTimeStamp >= KNLoadingInterval.minutes5 {
              self.fetchGasPriceFromNode()
            }
          }
        }
      }
    }
  }

  @objc func fetchKNMaxGasPrice(_ sender: Timer?) {
    if isLoadingMaxGasPrice { return }
    isLoadingMaxGasPrice = true
    DispatchQueue.global(qos: .background).async {
      KNInternalProvider.shared.getKNCachedMaxGasPrice { [weak self] (result) in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.isLoadingMaxGasPrice = false
          if case .success(let data) = result {
            self.updateMaxGasPrice(dataJSON: data)
          }
        }
      }
    }
  }

  func fetchGasPriceFromNode() {
    KNGeneralProvider.shared.getGasPrice { (result) in
      switch result {
      case .success(let gasPrice):
        guard let value = BigInt(gasPrice.drop0x, radix: 16) else { return }
        self.defaultKNGas = min(value, self.maxKNGas)
        self.lowKNGas = min(self.defaultKNGas * BigInt(10) / BigInt(12), self.maxKNGas)
        self.fastKNGas = min(self.defaultKNGas * BigInt(12) / BigInt(10), self.maxKNGas)
        self.standardKNGas = min(self.defaultKNGas, self.maxKNGas)
        self.lastGasPriceLoadedSuccessTimeStamp = Date().timeIntervalSince1970
        self.saveGasValues()
      default:
        break
      }
    }
  }

  fileprivate func updateGasPrice(dataJSON: JSONDictionary) throws {
    guard let data = dataJSON["data"] as? JSONDictionary else { return }
    let stringDefault: String = data["default"] as? String ?? ""
    let updateKNGas = stringDefault.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.defaultKNGas
    self.defaultKNGas = min(updateKNGas, self.maxKNGas)
    let stringLow: String = data["low"] as? String ?? ""
    let updateLowKNGas = stringLow.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.lowKNGas
    self.lowKNGas = min(updateLowKNGas, self.maxKNGas)
    let stringStandard: String = data["standard"] as? String ?? ""
    let updateStandardKNGas = stringStandard.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.standardKNGas
    self.standardKNGas = min(updateStandardKNGas, self.maxKNGas)
    let stringFast: String = data["fast"] as? String ?? ""
    let updateFastKNGas = stringFast.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.fastKNGas
    self.fastKNGas = min(updateFastKNGas, self.maxKNGas)
    KNNotificationUtil.postNotification(for: kGasPriceDidUpdateNotificationKey)
    self.lastGasPriceLoadedSuccessTimeStamp = Date().timeIntervalSince1970
    self.saveGasValues()
  }

  fileprivate func updateMaxGasPrice(dataJSON: JSONDictionary) {
    guard let data = dataJSON["data"] as? String else { return }
    self.maxKNGas = BigInt(data) ?? self.maxKNGas
    self.saveMaxGasPrice()
  }

  fileprivate func saveGasValues() {
    UserDefaults.standard.set(self.defaultKNGas.description, forKey: KNGasCoordinator.kSavedDefaultGas)
    UserDefaults.standard.set(self.standardKNGas.description, forKey: KNGasCoordinator.kSavedStandardGas)
    UserDefaults.standard.set(self.lowKNGas.description, forKey: KNGasCoordinator.kSavedLowGas)
    UserDefaults.standard.set(self.fastKNGas.description, forKey: KNGasCoordinator.kSavedFastGas)
  }

  fileprivate func loadGasValues() {
    guard let defaultGasString = UserDefaults.standard.string(forKey: KNGasCoordinator.kSavedDefaultGas),
      let defaultGasBigInt = BigInt(defaultGasString)
      else {
      return
    }
    guard let standartGasString = UserDefaults.standard.string(forKey: KNGasCoordinator.kSavedStandardGas),
      let standartGasBigInt = BigInt(standartGasString)
      else {
      return
    }
    guard let lowGasString = UserDefaults.standard.string(forKey: KNGasCoordinator.kSavedLowGas),
      let lowGasBigInt = BigInt(lowGasString)
      else {
      return
    }
    guard let fastGasString = UserDefaults.standard.string(forKey: KNGasCoordinator.kSavedFastGas),
      let fastGasBigInt = BigInt(fastGasString)
      else {
      return
    }
    self.defaultKNGas = defaultGasBigInt
    self.standardKNGas = standartGasBigInt
    self.lowKNGas = lowGasBigInt
    self.fastKNGas = fastGasBigInt
  }

  fileprivate func saveMaxGasPrice() {
    UserDefaults.standard.set(self.maxKNGas.description, forKey: KNGasCoordinator.kSavedMaxGas)
  }

  fileprivate func loadMaxGasPrice() {
    guard let maxGasString = UserDefaults.standard.string(forKey: KNGasCoordinator.kSavedMaxGas),
      let maxGasBigInt = BigInt(maxGasString)
      else {
      return
    }
    self.maxKNGas = maxGasBigInt
  }
}
