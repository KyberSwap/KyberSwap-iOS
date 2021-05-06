//
//  AddTokenCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/1/21.
//

import Foundation
import QRCodeReaderViewController

class AddTokenCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  private(set) var session: KNSession
  
  lazy var rootViewController: AddTokenViewController = {
    let controller = AddTokenViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var listTokenViewController: CustomTokenListViewController = {
    let controller = CustomTokenListViewController()
    controller.delegate = self
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }
  
  func start(showList: Bool = false, token: Token? = nil) {
    if showList {
      self.navigationController.pushViewController(self.listTokenViewController, animated: true)
    } else {
      self.rootViewController.token = token
      self.navigationController.pushViewController(self.rootViewController, animated: true)
    }
  }
  
  func stop() {
    self.navigationController.popViewController(animated: true)
  }
  
  func coordinatorDidUpdateTokenObject(_ token: TokenObject) {
    self.rootViewController.coordinatorDidUpdateTokenObject(token)
  }
}

extension AddTokenCoordinator: AddTokenViewControllerDelegate {
  func addTokenViewController(_ controller: AddTokenViewController, run event: AddTokenViewEvent) {
    switch event {
    case .openQR:
      if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: controller) {
        return
      }
      let qrcodeReaderVC: QRCodeReaderViewController = {
        let controller = QRCodeReaderViewController()
        controller.delegate = self
        return controller
      }()
      controller.present(qrcodeReaderVC, animated: true, completion: nil)
    case .done(let address, let symbol, let decimals):
      let tokenDict: JSONDictionary = ["address": address, "symbol": symbol, "decimals": decimals]
      let token = Token(dictionary: tokenDict)
      if KNSupportedTokenStorage.shared.isTokenSaved(token) {
        self.showErrorTopBannerMessage(with: "Fail", message: "Token is already added")
      } else {
        KNSupportedTokenStorage.shared.saveCustomToken(token)
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: NSLocalizedString("New token has been added successfully!", comment: ""),
          time: 1.0
        )
        self.listTokenViewController.coordinatorDidUpdateTokenList()
        self.navigationController.popViewController(animated: true)
      }
    case .doneEdit(address: let address, newAddress: let newAddress, symbol: let symbol, decimals: let decimals):
      KNSupportedTokenStorage.shared.editCustomToken(address: address, newAddress: newAddress, symbol: symbol, decimal: decimals)
      self.showSuccessTopBannerMessage(
        with: NSLocalizedString("success", value: "Success", comment: ""),
        message: NSLocalizedString("New token has been edited successfully!", comment: ""),
        time: 1.0
      )
      self.listTokenViewController.coordinatorDidUpdateTokenList()
      self.navigationController.popViewController(animated: true)
    case .getSymbol(address: let address):
      var tokenSymbol = ""
      var tokenDecimal = ""
      let group = DispatchGroup()
      group.enter()
      KNGeneralProvider.shared.getTokenSymbol(address: address) { (result) in
        switch result {
        case .success(let symbol):
          tokenSymbol = symbol
        case .failure(let error):
          print("[Custom token][Errror] \(error.description)")
        }
        group.leave()
      }
      group.enter()
      KNGeneralProvider.shared.getTokenDecimals(address: address) { (result) in
        switch result {
        case .success(let decimals):
          tokenDecimal = decimals
        case .failure(let error):
          print("[Custom token][Errror] \(error.description)")
        }
        group.leave()
      }
      
      group.notify(queue: .main) {
        self.rootViewController.coordinatorDidUpdateToken(symbol: tokenSymbol, decimals: tokenDecimal)
      }
    }
  }
}

extension AddTokenCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      self.rootViewController.coordinatorDidUpdateQRCode(address: address)
    }
  }
}

extension AddTokenCoordinator: CustomTokenListViewControllerDelegate {
  func customTokenListViewController(_ controller: CustomTokenListViewController, run event: CustomTokenListViewEvent) {
    switch event {
    case .edit(token: let token):
      self.start(showList: false, token: token)
    case .delete(token: let token):
      KNSupportedTokenStorage.shared.deleteCustomToken(address: token.address)
      self.listTokenViewController.coordinatorDidUpdateTokenList()
    case .add:
      self.start()
    }
  }
}
