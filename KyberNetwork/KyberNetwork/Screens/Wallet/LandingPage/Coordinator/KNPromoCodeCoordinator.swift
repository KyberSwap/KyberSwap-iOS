// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import Moya

protocol KNPromoCodeCoordinatorDelegate: class {
  func promoCodeCoordinatorDidCreate(_ wallet: Wallet, expiredDate: TimeInterval, destinationToken: String?, destAddress: String?, name: String?)
}

class KNPromoCodeCoordinator: Coordinator {

  let navigationController: UINavigationController
  let keystore: Keystore
  var coordinators: [Coordinator] = []

  weak var delegate: KNPromoCodeCoordinatorDelegate?

  lazy var rootViewController: KNPromoCodeViewController = {
    let controller = KNPromoCodeViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  init(navigationController: UINavigationController, keystore: Keystore) {
    self.navigationController = navigationController
    self.keystore = keystore
  }

  func start() {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "start"])
    self.rootViewController.resetUI()
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }

  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

extension KNPromoCodeCoordinator: KNPromoCodeViewControllerDelegate {
  func promoCodeViewController(_ controller: KNPromoCodeViewController, promoCode: String, name: String) {
    let nonce: UInt = UInt(round(Date().timeIntervalSince1970 * 1000.0))
    self.rootViewController.displayLoading()
    let provider = MoyaProvider<ProfileService>(plugins: [MoyaCacheablePlugin()])
    DispatchQueue.global(qos: .background).async {
      provider.request(.promoCode(promoCode: promoCode, nonce: nonce), completion: { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          self.rootViewController.hideLoading()
          switch result {
          case .success(let resp):
            do {
              _ = try resp.filterSuccessfulStatusCodes()
              let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              if let data = json["data"] as? JSONDictionary {
                let privateKey = data["private_key"] as? String ?? ""
                let expiredDate: TimeInterval = {
                  let string = data["expired_date"] as? String ?? ""
                  return (DateFormatterUtil.shared.promoCodeDateFormatter.date(from: string) ?? Date()).timeIntervalSince1970
                }()
                let destinationToken = data["destination_token"] as? String ?? ""
                let isPayment = (data["type"] as? String ?? "").lowercased() == "payment"
                let destAddress: String? = {
                  if isPayment {
                    return data["receive_address"] as? String
                  }
                  return nil
                }()
                let isValidAddr = Address(string: destAddress ?? "") != nil
                if isPayment && !isValidAddr {
                  self.navigationController.showWarningTopBannerMessage(
                    with: NSLocalizedString("error", value: "Error", comment: ""),
                    message: NSLocalizedString("Promo code is invalid!", value: "Promo code is invalid!", comment: ""),
                    time: 1.5
                  )
                  return
                }
                self.rootViewController.displayLoading(text: NSLocalizedString("importing.wallet", value: "Importing wallet", comment: ""), animated: true)
                KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "check_code_success"])
                self.keystore.importWallet(type: ImportType.privateKey(privateKey: privateKey)) { [weak self] result in
                  guard let `self` = self else { return }
                  self.rootViewController.hideLoading()
                  switch result {
                  case .success(let wallet):
                    self.didSuccessUnlockPromoCode(
                      wallet: wallet,
                      name: name,
                      expiredDate: expiredDate,
                      destinationToken: destinationToken,
                      destAddress: destAddress
                    )
                  case .failure(let error):
                    self.navigationController.displayError(error: error)
                  }
                }
              } else {
                KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "check_code_data_error"])
                let error = json["error"] as? String ?? ""
                self.navigationController.showWarningTopBannerMessage(
                  with: NSLocalizedString("error", value: "Error", comment: ""),
                  message: NSLocalizedString(error, value: error, comment: ""),
                  time: 1.5
                )
              }
            } catch let error {
              KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "check_code_parse_error"])
              self.navigationController.displayError(error: error)
            }
          case .failure(let error):
            KNCrashlyticsUtil.logCustomEvent(withName: "screen_kybercode", customAttributes: ["action": "check_code_failed"])
            self.navigationController.displayError(error: error)
          }
        }
      })
    }
  }
  func promoCodeViewControllerDidClose() {
    self.stop()
  }

  fileprivate func didSuccessUnlockPromoCode(wallet: Wallet, name: String, expiredDate: TimeInterval, destinationToken: String, destAddress: String?) {
    let walletObject = KNWalletObject(
      address: wallet.address.description,
      name: name
    )
    KNWalletStorage.shared.add(wallets: [walletObject])
    let expiredString: String = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd MMM yyyy, HH:mm"
      return formatter.string(from: Date(timeIntervalSince1970: expiredDate))
    }()
    self.navigationController.showSuccessTopBannerMessage(
      with: NSLocalizedString("congratulations", value: "Congratulations!!!", comment: ""),
      message: String(format: NSLocalizedString("you.have.successfully.unlocked.your.promo.code", value: "You have successfully unlocked your Promo code. Please move all assets to your wallet by %@", comment: ""), expiredString),
      time: 5
    )
    self.delegate?.promoCodeCoordinatorDidCreate(
      wallet,
      expiredDate: expiredDate,
      destinationToken: destinationToken,
      destAddress: destAddress,
      name: name
    )
  }
}
