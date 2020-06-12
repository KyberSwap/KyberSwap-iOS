// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustKeystore
import TrustCore
import QRCodeReaderViewController

enum KNNewContactViewEvent {
  case dismiss
  case send(address: String)
}

protocol KNNewContactViewControllerDelegate: class {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent)
}

class KNNewContactViewModel {

  fileprivate(set) var contact: KNContact
  fileprivate(set) var isEditing: Bool
  fileprivate(set) var address: Address?
  fileprivate(set) var addressString: String

  init(
    address: String, ens: String? = nil
  ) {
    if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: ens ?? "")
      self.isEditing = false
    }
    self.address = Address(string: address)
    self.addressString = ens ?? address
  }

  var title: String {
    return isEditing ? NSLocalizedString("edit.contact", value: "Edit Contact", comment: "") : NSLocalizedString("add.contact", value: "Add Contact", comment: "")
  }

  var displayEnsMessage: String? {
    if self.addressString.isEmpty { return nil }
    if self.address == nil { return "Invalid address or your ens is not mapped yet" }
    if Address(string: self.addressString) != nil { return nil }
    let address = self.address?.description ?? ""
    return "\(address.prefix(12))...\(address.suffix(10))"
  }

  var displayEnsMessageColor: UIColor {
    if self.address == nil { return UIColor.Kyber.strawberry }
    return UIColor.Kyber.blueGreen
  }

  func updateViewModel(address: String) {
    if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
      self.contact = contact
      self.isEditing = true
    } else {
      self.contact = KNContact(address: address.lowercased(), name: "")
      self.isEditing = false
    }
    self.addressString = address
    self.address = Address(string: address)
  }

  func updateAddressFromENS(name: String, ensAddr: Address?) {
    self.addressString = name
    self.address = ensAddr
    if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == (ensAddr?.description.lowercased() ?? "") }) {
      self.contact = contact
      self.isEditing = true
    } else if let addr = ensAddr {
      self.contact = KNContact(
        address: addr.description.lowercased(),
        name: self.contact.name.isEmpty ? name : self.contact.name
      )
      self.isEditing = false
    }
  }
}

class KNNewContactViewController: KNBaseViewController {

  weak var delegate: KNNewContactViewControllerDelegate?
  fileprivate var viewModel: KNNewContactViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var ensMessageLabel: UILabel!

  init(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNNewContactViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.nameTextField.becomeFirstResponder()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.deleteButton.setTitle(NSLocalizedString("delete.contact", value: "Delete Contact", comment: ""), for: .normal)
    self.sendButton.setTitle(NSLocalizedString("transfer", value: "Transfer", comment: ""), for: .normal)
    self.sendButton.setTitleColor(UIColor.Kyber.marketBlue, for: .normal)
    self.addressTextField.delegate = self
    self.nameTextField.placeholder = NSLocalizedString("name", value: "Name", comment: "")
    self.addressTextField.placeholder = NSLocalizedString("address", value: "Address", comment: "")
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.viewModel.title
    self.nameTextField.text = self.viewModel.contact.name
    self.addressTextField.text = self.viewModel.addressString
    self.deleteButton.isHidden = !self.viewModel.isEditing

    self.ensMessageLabel.text = self.viewModel.displayEnsMessage
    self.ensMessageLabel.textColor = self.viewModel.displayEnsMessageColor
    self.ensMessageLabel.isHidden = false
  }

  fileprivate func addressTextFieldDidChange() {
    if self.nameTextField.text == nil || self.nameTextField.text?.isEmpty == true {
      self.nameTextField.text = self.viewModel.contact.name
    }
    self.titleLabel.text = self.viewModel.title
    self.deleteButton.isHidden = !self.viewModel.isEditing

    self.ensMessageLabel.text = self.viewModel.displayEnsMessage
    self.ensMessageLabel.textColor = self.viewModel.displayEnsMessageColor
    self.ensMessageLabel.isHidden = false
  }

  func updateView(viewModel: KNNewContactViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact_save_button_tapped", customAttributes: nil)
    guard let name = self.nameTextField.text, !name.isEmpty else {
      self.showWarningTopBannerMessage(with: "", message: NSLocalizedString("contact.should.have.a.name", value: "Contact should have a name", comment: ""))
      return
    }
    guard let address = self.viewModel.address else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.address", value: "Invalid Address", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address.to.continue", value: "Please enter a valid address to continue", comment: "")
      )
      return
    }
    let contact = KNContact(address: address.description.lowercased(), name: name)
    KNContactStorage.shared.update(contacts: [contact])
    KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
    self.delegate?.newContactViewController(self, run: .dismiss)
  }

  @IBAction func deleteButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact_delete_btn_tapped", customAttributes: nil)
    let alertController = UIAlertController(
      title: "",
      message: NSLocalizedString("do.you.want.to.delete.this.contact", value: "Do you want to delete this contact?", comment: ""),
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [self.viewModel.contact])
      KNNotificationUtil.postNotification(for: kUpdateListContactNotificationKey)
      self.delegate?.newContactViewController(self, run: .dismiss)
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_contact_send_btn_tapped", customAttributes: nil)
    guard let address = Address(string: self.addressTextField.text ?? "") else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("invalid.address", value: "Invalid Address", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address.to.continue", value: "Please enter a valid address to continue", comment: ""),
        time: 2.0
      )
      return
    }
    self.delegate?.newContactViewController(self, run: .send(address: address.description))
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let qrcodeVC = QRCodeReaderViewController()
    qrcodeVC.delegate = self
    self.present(qrcodeVC, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.newContactViewController(self, run: .dismiss)
    }
  }
}

extension KNNewContactViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if textField == self.addressTextField {
      self.viewModel.updateViewModel(address: "")
      self.addressTextFieldDidChange()
      self.getEnsAddressFromName("")
    }
    return false
  }
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    if textField == self.addressTextField {
      self.viewModel.updateViewModel(address: text)
      self.addressTextFieldDidChange()
      self.getEnsAddressFromName(text)
    }
    return false
  }
}

extension KNNewContactViewController: QRCodeReaderDelegate {
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
      self.addressTextField.text = address
      self.viewModel.updateViewModel(address: address)
      self.addressTextFieldDidChange()
      self.getEnsAddressFromName(address)
    }
  }

  fileprivate func getEnsAddressFromName(_ name: String) {
    if Address(string: name) != nil { return }
    if !name.contains(".") {
      self.viewModel.updateAddressFromENS(name: name, ensAddr: nil)
      self.updateUI()
      return
    }
    DispatchQueue.global().async {
      KNGeneralProvider.shared.getAddressByEnsName(name.lowercased()) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if name != self.viewModel.addressString { return }
          if case .success(let addr) = result, let address = addr, address != Address(string: "0x0000000000000000000000000000000000000000") {
            self.viewModel.updateAddressFromENS(name: name, ensAddr: address)
          } else {
            self.viewModel.updateAddressFromENS(name: name, ensAddr: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
              self.getEnsAddressFromName(self.viewModel.addressString)
            }
          }
          self.updateUI()
        }
      }
    }
  }
}
