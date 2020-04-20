// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String, name: String?)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  private var isSecureText: Bool = true
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!
  @IBOutlet weak var privateKeyNoteLabel: UILabel!

  @IBOutlet weak var nextButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.enterPrivateKeyTextLabel.text = NSLocalizedString("your.private.key", value: "Your Private Key", comment: "")
    self.enterPrivateKeyTextLabel.addLetterSpacing()
    self.enterPrivateKeyTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 0))
    self.enterPrivateKeyTextField.rightViewMode = .always
    self.enterPrivateKeyTextField.delegate = self

    self.privateKeyNoteLabel.text = "*\(NSLocalizedString("private.key.has.to.be.64.characters", value: "Private key has to be 64 characters", comment: ""))"
    self.privateKeyNoteLabel.addLetterSpacing()

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
    self.enterPrivateKeyTextField.placeholder = NSLocalizedString("enter.or.scan.private.key", value: "Enter or scan private key", comment: "")
    self.enterPrivateKeyTextField.addPlaceholderSpacing()
    self.walletNameTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.addPlaceholderSpacing()

    self.resetUI()
  }

  func resetUI() {
    self.enterPrivateKeyTextField.text = ""
    self.walletNameTextField.text = ""
    self.isSecureText = true
    self.updateSecureTextEntry()

    self.updateNextButton()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.updateNextButton()
  }

  fileprivate func updateSecureTextEntry() {
    let secureTextImage = UIImage(named: !self.isSecureText ? "hide_secure_text" : "show_secure_text")
    self.secureTextButton.setImage(secureTextImage, for: .normal)
    self.enterPrivateKeyTextField.isSecureTextEntry = self.isSecureText
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      if let text = self.enterPrivateKeyTextField.text, text.count == 64 { return true }
      return false
    }()
    self.nextButton.isEnabled = enabled
    let noteColor: UIColor = {
      let text = self.enterPrivateKeyTextField.text ?? ""
      if enabled || text.isEmpty { return UIColor(red: 182, green: 186, blue: 185) }
      return UIColor.Kyber.strawberry
    }()
    self.privateKeyNoteLabel.textColor = noteColor
    if enabled { self.nextButton.applyGradient() }
  }

  @IBAction func qrCodeButtonPressed(_ sender: Any) {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.parent?.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.isSecureText = !self.isSecureText
    self.updateSecureTextEntry()
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    let privateKey: String = self.enterPrivateKeyTextField.text ?? ""
    self.delegate?.importPrivateKeyViewControllerDidPressNext(
      sender: self,
      privateKey: privateKey,
      name: self.walletNameTextField.text
    )
  }
}

extension KNImportPrivateKeyViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.enterPrivateKeyTextField {
      self.updateNextButton()
    }
    return false
  }
}

extension KNImportPrivateKeyViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.enterPrivateKeyTextField.text = result
      self.updateNextButton()
    }
  }
}
