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
  
  weak var delegate: AddTokenViewControllerDelegate?
  var token: Token?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let unwrapped = self.token {
      self.titleHeader.text = "Edit custom token".toBeLocalised()
      self.updateUI(unwrapped)
    } else {
      self.titleHeader.text = "Add custom token".toBeLocalised()
      self.addressField.text = ""
      self.symbolField.text = ""
      self.decimalsField.text = ""
    }
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.doneButton.removeSublayer(at: 0)
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
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
  }
}


