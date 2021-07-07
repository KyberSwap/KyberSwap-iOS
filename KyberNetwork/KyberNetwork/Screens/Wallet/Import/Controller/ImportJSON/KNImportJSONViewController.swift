// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportJSONViewControllerDelegate: class {
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String, name: String?)
  func importJSONViewController(controller: KNImportJSONViewController, send refCode: String)
  func importJSONControllerDidSelectQRCode(controller: KNImportJSONViewController)
}

class KNImportJSONViewController: KNBaseViewController {

  weak var delegate: KNImportJSONViewControllerDelegate?
  fileprivate var jsonData: String = ""

  lazy var buttonAttributes: [NSAttributedStringKey: Any] = {
    return [
      NSAttributedStringKey.foregroundColor: UIColor(named: "normalTextColor")!,
      NSAttributedStringKey.kern: 0.0,
    ]
  }()

  @IBOutlet weak var nameWalletTextField: UITextField!
  @IBOutlet weak var importJSONButton: UIButton!
  @IBOutlet weak var enterPasswordTextField: UITextField!
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var passwordFieldContainer: UIView!

  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var refCodeField: UITextField!
  @IBOutlet weak var containerRefCodeView: UIView!
  @IBOutlet weak var refCodeTitleLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  func resetUIs() {
    let attributedString: NSAttributedString = {
      return NSAttributedString(
        string: NSLocalizedString("import.your.keystore.file", value: "Import your Keystore file", comment: ""),
        attributes: self.buttonAttributes
      )
    }()
    self.jsonData = ""
    self.importJSONButton.setAttributedTitle(attributedString, for: .normal)
    self.nameWalletTextField.text = ""
    self.enterPasswordTextField.text = ""
    self.enterPasswordTextField.isSecureTextEntry = true
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_eye_icon" : "show_eye_icon"), for: .normal)

    self.updateNextButton()
  }

  fileprivate func setupUI() {
    self.importJSONButton.rounded(
      color: UIColor(named: "normalTextColor")!,
      width: 1,
      radius: 16
    )
    self.enterPasswordTextField.delegate = self
    self.passwordFieldContainer.rounded(radius: 8)
    self.nameWalletTextField.rounded(radius: 8)

    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(
      NSLocalizedString("Connect", value: "Connect", comment: ""),
      for: .normal
    )
    self.nextButton.addTextSpacing()
    self.enterPasswordTextField.placeholder = NSLocalizedString("enter.password.to.decrypt", value: "Enter Password to Decrypt", comment: "")
    self.enterPasswordTextField.addPlaceholderSpacing()
    self.nameWalletTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.nameWalletTextField.addPlaceholderSpacing()
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text_blue" : "show_secure_text_blue"), for: .normal)
    self.refCodeField.attributedPlaceholder = NSAttributedString(string: "Paste your Referral Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.resetUIs()
  }


  fileprivate func updateNextButton() {
    let enabled: Bool = {
      guard let password = self.enterPasswordTextField.text else { return false }
      return !password.isEmpty && !self.jsonData.isEmpty
    }()
    self.nextButton.isEnabled = enabled
    if enabled {
      self.nextButton.alpha = 1
    } else {
      self.nextButton.alpha = 0.2
    }
  }

  @IBAction func importJSONButtonPressed(_ sender: Any) {
    self.showDocumentPicker()
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.enterPasswordTextField.isSecureTextEntry = !self.enterPasswordTextField.isSecureTextEntry
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text_blue" : "show_secure_text_blue"), for: .normal)
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    if let text = self.refCodeField.text, !text.isEmpty {
      self.delegate?.importJSONViewController(controller: self, send: text)
    }
    let password: String = self.enterPasswordTextField.text ?? ""
    self.delegate?.importJSONViewControllerDidPressNext(
      sender: self,
      json: self.jsonData,
      password: password,
      name: self.nameWalletTextField.text
    )
  }
  
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.refCodeField.text = string
    }
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.delegate?.importJSONControllerDidSelectQRCode(controller: self)
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeField.text = refCode
  }
}

// MARK: Update from coordinator
extension KNImportJSONViewController {
  fileprivate func showDocumentPicker() {
    let controller: TrustDocumentPickerViewController = {
      let types = ["public.text", "public.content", "public.item", "public.data"]
      let vc = TrustDocumentPickerViewController(
        documentTypes: types,
        in: .import
      )
      vc.delegate = self
      vc.modalPresentationStyle = .formSheet
      return vc
    }()
    self.present(controller, animated: true, completion: nil)
  }
}

extension KNImportJSONViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    if controller.documentPickerMode == UIDocumentPickerMode.import {
      if let text = try? String(contentsOfFile: url.path) {
        self.jsonData = text
        let name = url.lastPathComponent
        UIView.transition(
          with: self.importJSONButton,
          duration: 0.32,
          options: .transitionFlipFromTop,
          animations: {
            let attributedString: NSAttributedString = {
              return NSAttributedString(
                string: name,
                attributes: self.buttonAttributes
              )
            }()
            self.importJSONButton.setAttributedTitle(attributedString, for: .normal)
            self.updateNextButton()
          }, completion: nil
        )
      } else {
        self.parent?.showErrorTopBannerMessage(
          with: "",
          message: NSLocalizedString("can.not.get.data.from.your.file", value: "Can not get data from your file.", comment: "")
        )
      }
    }
  }
}

extension KNImportJSONViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.enterPasswordTextField {
      self.updateNextButton()
    }
    return false
  }
}
