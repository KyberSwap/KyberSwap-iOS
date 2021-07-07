// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import QRCodeReaderViewController

protocol KNImportSeedsViewControllerDelegate: class {
  func importSeedsViewControllerDidPressNext(sender: KNImportSeedsViewController, seeds: [String], name: String?)
  func importSeedsViewController(controller: KNImportSeedsViewController, send refCode: String)
  func importSeedsViewControllerDidSelectQRCode(controller: KNImportSeedsViewController)
}

class KNImportSeedsViewController: KNBaseViewController {

  weak var delegate: KNImportSeedsViewControllerDelegate?
  fileprivate let numberWords: Int = 12

  @IBOutlet weak var recoverSeedsLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var seedsTextField: UITextField!
  @IBOutlet weak var walletNameTextField: UITextField!
  @IBOutlet weak var wordsCountLabel: UILabel!
  @IBOutlet weak var qrcodeButton: UIButton!
  @IBOutlet weak var seedsFieldContainer: UIView!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var refCodeField: UITextField!
  @IBOutlet weak var containerRefCodeView: UIView!
  @IBOutlet weak var refCodeTitleLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.seedsTextField.delegate = self

    self.recoverSeedsLabel.text = NSLocalizedString("recover.with.seeds", value: "Recover with seeds", comment: "")
    self.recoverSeedsLabel.addLetterSpacing()
    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(
      "Connect".toBeLocalised(),
      for: .normal
    )
    self.nextButton.addTextSpacing()
    self.seedsTextField.placeholder = NSLocalizedString("enter.your.seeds", value: "Enter your seeds", comment: "")
    self.seedsTextField.addPlaceholderSpacing()
    self.walletNameTextField.placeholder = NSLocalizedString("name.of.your.wallet.optional", value: "Name of your wallet (optional)", comment: "")
    self.walletNameTextField.addPlaceholderSpacing()
    self.seedsFieldContainer.rounded(radius: 8)
    self.walletNameTextField.rounded(radius: 8)
    self.refCodeField.attributedPlaceholder = NSAttributedString(string: "Paste your Referral Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.resetUIs()
  }

  func resetUIs() {
    self.seedsTextField.text = ""
    self.wordsCountLabel.text = "\(NSLocalizedString("words.count", value: "Words Count", comment: "")): 0"
    self.wordsCountLabel.textColor = UIColor.Kyber.border
    self.wordsCountLabel.addLetterSpacing()
    self.walletNameTextField.text = ""
    self.updateNextButton()
  }

  fileprivate func updateNextButton() {
    let enabled: Bool = {
      guard let seeds = self.seedsTextField.text?.trimmed else { return false }
      var words = seeds.components(separatedBy: " ").map({ $0.trimmed })
      words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
      return words.count == self.numberWords
    }()
    self.nextButton.isEnabled = enabled
    if enabled {
      self.nextButton.alpha = 1
    } else {
      self.nextButton.alpha = 0.2
    }
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let reader = QRCodeReaderViewController()
    reader.delegate = self
    self.parent?.present(reader, animated: true, completion: nil)
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    if let text = self.refCodeField.text, !text.isEmpty {
      self.delegate?.importSeedsViewController(controller: self, send: text)
    }
    if let seeds = self.seedsTextField.text?.trimmed {
      guard Mnemonic.isValid(seeds) else {
        self.parent?.showErrorTopBannerMessage(
          with: NSLocalizedString("invalid.seeds", value: "Invalid Seeds", comment: ""),
          message: NSLocalizedString("please.check.your.seeds.again", value: "Please check your seeds again", comment: "")
        )
        return
      }
      var words = seeds.components(separatedBy: " ").map({ $0.trimmed })
      words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
      if words.count == self.numberWords {
        self.delegate?.importSeedsViewControllerDidPressNext(
          sender: self,
          seeds: words.map({ return String($0) }),
          name: self.walletNameTextField.text
        )
      } else {
        self.parent?.showErrorTopBannerMessage(
          with: NSLocalizedString("invalid.seeds", value: "Invalid Seeds", comment: ""),
          message: NSLocalizedString("seeds.should.have.exactly.12.words", value: "Seeds should have exactly 12 words", comment: "")
        )
      }
    } else {
      self.parent?.showErrorTopBannerMessage(
        with: NSLocalizedString("field.required", value: "Field Required", comment: ""),
        message: NSLocalizedString("please.check.your.input.data", value: "Please check your input data", comment: ""))
    }
  }
  
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.refCodeField.text = string
    }
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.delegate?.importSeedsViewControllerDidSelectQRCode(controller: self)
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeField.text = refCode
  }
}

extension KNImportSeedsViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if textField == self.seedsTextField {
      self.wordsCountLabel.text = "\(NSLocalizedString("words.count", value: "Words Count", comment: "")): 0"
      self.wordsCountLabel.textColor = UIColor.Kyber.border
      self.wordsCountLabel.addLetterSpacing()
      self.updateNextButton()
    }
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.seedsTextField {
      self.updateWordsCount()
    }
    return false
  }

  fileprivate func updateWordsCount() {
    guard let text = self.seedsTextField.text else { return }
    var words = text.trimmed.components(separatedBy: " ").map({ $0.trimmed })
    words = words.filter({ return !$0.replacingOccurrences(of: " ", with: "").isEmpty })
    self.wordsCountLabel.text = "\(NSLocalizedString("words.count", value: "Words Count", comment: "")): \(words.count)"
    let color = words.isEmpty || words.count == 12 ? UIColor.Kyber.border : UIColor.Kyber.strawberry
    self.wordsCountLabel.textColor = color
    self.wordsCountLabel.addLetterSpacing()
    self.updateNextButton()
  }
}

extension KNImportSeedsViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.seedsTextField.text = result
      self.updateWordsCount()
    }
  }
}
