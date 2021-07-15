//
//  AddTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/1/21.
//

import UIKit
import TrustCore

enum AddTokenViewEvent {
  case openQR
  case done(address: String, symbol: String, decimals: Int)
  case doneEdit(address: String, newAddress: String, symbol: String, decimals: Int)
  case getSymbol(address: String)
}

protocol AddTokenViewControllerDelegate: class {
  func addTokenViewController(_ controller: AddTokenViewController, run event: AddTokenViewEvent)
}

class AddTokenViewController: KNBaseViewController {
  @IBOutlet weak var addressField: UITextField!
  @IBOutlet weak var symbolField: UITextField!
  @IBOutlet weak var decimalsField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var titleHeader: UILabel!
  @IBOutlet weak var blockchainField: UITextField!
  
  weak var delegate: AddTokenViewControllerDelegate?
  var token: Token?
  var tokenObject: TokenObject?
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let unwrapped = self.token {
      self.titleHeader.text = "Edit custom token".toBeLocalised()
      self.updateUI(unwrapped)
    } else {
      self.titleHeader.text = "Add custom token".toBeLocalised()
      if let unwrapped = self.tokenObject {
        self.addressField.text = unwrapped.address
        self.symbolField.text = unwrapped.symbol
        self.decimalsField.text = "\(unwrapped.decimals)"
      } else {
        self.addressField.text = ""
        self.symbolField.text = ""
        self.decimalsField.text = ""
      }
    }
    self.addressField.attributedPlaceholder = NSAttributedString(string: "Smart contract", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.symbolField.attributedPlaceholder = NSAttributedString(string: "Token symbol", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.decimalsField.attributedPlaceholder = NSAttributedString(string: "Decimals", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.blockchainField.text = KNGeneralProvider.shared.isEthereum ? "Ethereum" : "Binance Smart Chain"
  }
  
  fileprivate func updateUI(_ token: Token) {
    self.addressField.text = token.address
    self.symbolField.text = token.symbol
    self.decimalsField.text = "\(token.decimals)"
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.addressField.text = string
      self.delegate?.addTokenViewController(self, run: .getSymbol(address: string))
    }
  }

  @IBAction func qrButtonTapped(_ sender: UIButton) {
    self.delegate?.addTokenViewController(self, run: .openQR)
  }
  
  @IBAction func doneButtonTapped(_ sender: UIButton) {
    guard self.validateFields() else {
      return
    }
    if let unwrapped = self.token {
      self.delegate?.addTokenViewController(self, run: .doneEdit(address: unwrapped.address, newAddress: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6))
    } else {
      self.delegate?.addTokenViewController(self, run: .done(address: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6))
    }
  }
  
  fileprivate func validateFields() -> Bool {
    if let text = self.addressField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Address is empty")
      return false
    }
    if let text = self.symbolField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Symbol is empty")
      return false
    }
    if let text = self.decimalsField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Decimals is empty")
      return false
    }
    
    if let text = self.addressField.text, Address(string: text) == nil {
      self.showErrorTopBannerMessage(with: "", message: "Address isn't correct")
      return false
    }

    return true
  }
  
  func coordinatorDidUpdateQRCode(address: String) {
    self.addressField.text = address
    self.delegate?.addTokenViewController(self, run: .getSymbol(address: address))
  }
  
  func coordinatorDidUpdateToken(symbol: String, decimals: String) {
    self.symbolField.text = symbol
    self.decimalsField.text = decimals
  }
  
  func coordinatorDidUpdateTokenObject(_ token: TokenObject) {
    self.tokenObject = token
    guard self.isViewLoaded else {
      return
    }
    self.symbolField.text = token.symbol
    self.decimalsField.text = "\(token.decimals)"
    self.addressField.text = token.address
  }
}


