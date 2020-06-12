// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNImportJSONViewControllerDelegate: class {
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String, name: String?)
}

class KNImportJSONViewController: KNBaseViewController {

  weak var delegate: KNImportJSONViewControllerDelegate?
  fileprivate var jsonData: String = ""

  lazy var buttonAttributes: [NSAttributedStringKey: Any] = {
    return [
      NSAttributedStringKey.foregroundColor: UIColor.black,
      NSAttributedStringKey.kern: 0.0,
    ]
  }()

  @IBOutlet weak var nameWalletTextField: UITextField!
  @IBOutlet weak var importJSONButton: UIButton!
  @IBOutlet weak var enterPasswordTextField: UITextField!
  @IBOutlet weak var secureTextButton: UIButton!

  @IBOutlet weak var nextButton: UIButton!
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
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text" : "show_secure_text"), for: .normal)

    self.updateNextButton()
  }

  fileprivate func setupUI() {
    self.importJSONButton.rounded(
      color: UIColor.Kyber.border,
      width: 1,
      radius: self.importJSONButton.frame.height / 2.0
    )
    self.enterPasswordTextField.delegate = self

    let style = KNAppStyleType.current
    self.nextButton.rounded(radius: style.buttonRadius())
    self.nextButton.setBackgroundColor(
      style.importWalletButtonDisabledColor,
      forState: .disabled
    )
    self.nextButton.setTitle(
      NSLocalizedString("import.wallet", value: "Import Wallet", comment: ""),
      for: .normal
    )
    self.nextButton.addTextSpacing()
    self.enterPasswordTextField.placeholder = NSLocalizedString("enter.password.to.decrypt", value: "Enter Password to Decrypt", comment: "")
    self.enterPasswordTextField.addPlaceholderSpacing()
    self.nameWalletTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.nameWalletTextField.addPlaceholderSpacing()
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text" : "show_secure_text"), for: .normal)

    self.resetUIs()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.updateNextButton()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      guard let password = self.enterPasswordTextField.text else { return false }
      return !password.isEmpty && !self.jsonData.isEmpty
    }()
    self.nextButton.isEnabled = enabled
    if enabled { self.nextButton.applyGradient() }
  }

  @IBAction func importJSONButtonPressed(_ sender: Any) {
    self.showDocumentPicker()
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.enterPasswordTextField.isSecureTextEntry = !self.enterPasswordTextField.isSecureTextEntry
    self.secureTextButton.setImage(UIImage(named: !self.enterPasswordTextField.isSecureTextEntry ? "hide_secure_text" : "show_secure_text"), for: .normal)
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let password: String = self.enterPasswordTextField.text ?? ""
    self.delegate?.importJSONViewControllerDidPressNext(
      sender: self,
      json: self.jsonData,
      password: password,
      name: self.nameWalletTextField.text
    )
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
