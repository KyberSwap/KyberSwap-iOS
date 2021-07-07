// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

protocol KNImportPrivateKeyViewControllerDelegate: class {
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String, name: String?)
  func importPrivateKeyViewController(controller: KNImportPrivateKeyViewController, send refCode: String)
  func importPrivateKeyControllerDidSelectQRCode(controller: KNImportPrivateKeyViewController)
}

class KNImportPrivateKeyViewController: KNBaseViewController {

  weak var delegate: KNImportPrivateKeyViewControllerDelegate?

  private var isSecureText: Bool = true
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var enterPrivateKeyTextLabel: UILabel!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var enterPrivateKeyTextField: UITextField!
  @IBOutlet weak var privateKeyNoteLabel: UILabel!
  @IBOutlet weak var privateKeyFieldContainer: UIView!

  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var refCodeField: UITextField!
  @IBOutlet weak var containerRefCodeView: UIView!
  @IBOutlet weak var refCodeTitleLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.enterPrivateKeyTextLabel.text = NSLocalizedString("your.private.key", value: "Your Private Key", comment: "")
    self.enterPrivateKeyTextLabel.addLetterSpacing()
    self.enterPrivateKeyTextField.delegate = self

    self.privateKeyNoteLabel.text = "*\(NSLocalizedString("private.key.has.to.be.64.characters", value: "Private key has to be 64 characters", comment: ""))"
    self.privateKeyNoteLabel.addLetterSpacing()

    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(
      NSLocalizedString("Connect", value: "Connect", comment: ""),
      for: .normal
    )
    self.nextButton.addTextSpacing()
    self.enterPrivateKeyTextField.placeholder = NSLocalizedString("enter.or.scan.private.key", value: "Enter or scan private key", comment: "")
    self.enterPrivateKeyTextField.addPlaceholderSpacing()
    self.walletNameTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.addPlaceholderSpacing()
    
    self.privateKeyFieldContainer.rounded(radius: 8)
    self.walletNameTextField.rounded(radius: 8)
    self.refCodeField.attributedPlaceholder = NSAttributedString(string: "Paste your Referral Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.resetUI()
  }

  func resetUI() {
    self.enterPrivateKeyTextField.text = ""
    self.walletNameTextField.text = ""
    self.isSecureText = true
    self.updateSecureTextEntry()

    self.updateNextButton()
  }

  fileprivate func updateSecureTextEntry() {
    let secureTextImage = UIImage(named: !self.isSecureText ? "hide_eye_icon" : "show_eye_icon")
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
    if enabled {
      self.nextButton.alpha = 1
    } else {
      self.nextButton.alpha = 0.2
    }
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
    if let text = self.refCodeField.text, !text.isEmpty {
      self.delegate?.importPrivateKeyViewController(controller: self, send: text)
    }
    let privateKey: String = self.enterPrivateKeyTextField.text ?? ""
    self.delegate?.importPrivateKeyViewControllerDidPressNext(
      sender: self,
      privateKey: privateKey,
      name: self.walletNameTextField.text
    )
  }
  
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.refCodeField.text = string
    }
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.delegate?.importPrivateKeyControllerDidSelectQRCode(controller: self)
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeField.text = refCode
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
