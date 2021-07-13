//
//  AddWatchWalletViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/14/21.
//

import UIKit
import QRCodeReaderViewController
import TrustCore

class AddWatchWalletViewModel {
  fileprivate(set) var addressString: String = ""
  fileprivate(set) var isUsingEns: Bool = false
  var address: Address?
  var wallet: KNWalletObject? {
    didSet {
      if let unwrapped = self.wallet {
        self.updateAddress(unwrapped.address.lowercased())
      }
    }
  }

  func updateAddress(_ address: String) {
    self.addressString = address
    self.address = Address(string: address)
    if self.address != nil {
      self.isUsingEns = false
    }
  }

  func updateAddressFromENS(_ ens: String, ensAddr: Address?) {
    if ens == self.addressString {
      self.address = ensAddr
      self.isUsingEns = ensAddr != nil
    }
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
  
  var displayAddress: String? {
    //TODO: check case add existed address
    if self.address == nil { return self.addressString }
    if let contact = KNContactStorage.shared.contacts.first(where: { self.addressString.lowercased() == $0.address.lowercased() }) {
      return "\(contact.name) - \(self.addressString)"
    }
    return self.addressString
  }
  
  var displayTitle: String {
    if self.wallet == nil {
      return "Add watched wallet"
    } else {
      return "Edit watched wallet"
    }
  }
  
  var displayAddButtonTitle: String {
    if self.wallet == nil {
      return "Add"
    } else {
      return "Edit"
    }
  }
}

protocol AddWatchWalletViewControllerDelegate: class {
  func addWatchWalletViewController(_ controller: AddWatchWalletViewController, didAddAddress address: Address, name: String?)
  func addWatchWalletViewControllerDidClose(_ controller: AddWatchWalletViewController)
  func addWatchWalletViewControllerDidEdit(_ controller: AddWatchWalletViewController, wallet: KNWalletObject, address: Address, name: String?)
}

class AddWatchWalletViewController: UIViewController {
  @IBOutlet weak var walletLabelTextField: UITextField!
  @IBOutlet weak var walletAddressTextField: UITextField!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var addButton: UIButton!
  @IBOutlet weak var ensAddressLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  
  weak var delegate: AddWatchWalletViewControllerDelegate?

  let transitor = TransitionDelegate()
  let viewModel: AddWatchWalletViewModel
  
  init(viewModel: AddWatchWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: AddWatchWalletViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.cancelButton.rounded(radius: 16)
    self.addButton.rounded(radius: 16)
    self.titleLabel.text = self.viewModel.displayTitle
    self.walletLabelTextField.text = self.viewModel.wallet?.name
    self.walletAddressTextField.text = self.viewModel.wallet?.address
    self.addButton.setTitle(self.viewModel.displayAddButtonTitle, for: .normal)
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.addWatchWalletViewControllerDidClose(self)
    }
  }

  @IBAction func doneButtonTapped(_ sender: Any) {
    guard let address = self.viewModel.address else {
      self.showErrorTopBannerMessage(message: "Please enter address".toBeLocalised())
      return
    }
    if self.viewModel.wallet == nil {
      guard !KNWalletStorage.shared.checkAddressExisted(address) else {
        self.showErrorTopBannerMessage(message: "Address existed".toBeLocalised())
        return
      }
    }
    
    self.dismiss(animated: true) {
      if let unwrapped = self.viewModel.wallet {
        self.delegate?.addWatchWalletViewControllerDidEdit(self, wallet: unwrapped.clone(), address: address, name: self.walletLabelTextField.text)
      } else {
        self.delegate?.addWatchWalletViewController(self, didAddAddress: address, name: self.walletLabelTextField.text)
      }
    }
  }

  @IBAction func qrButtonTapped(_ sender: UIButton) {
    if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: self) {
      return
    }
    let qrcodeReaderVC: QRCodeReaderViewController = {
      let controller = QRCodeReaderViewController()
      controller.delegate = self
      return controller
    }()
    self.present(qrcodeReaderVC, animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
      self.delegate?.addWatchWalletViewControllerDidClose(self)
    })
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.contentView.endEditing(true)
  }

  fileprivate func getEnsAddressFromName(_ name: String) {
    if Address(string: name) != nil { return }
    if !name.contains(".") {
      self.viewModel.updateAddressFromENS(name, ensAddr: nil)
      self.updateUIAddressQRCode()
      return
    }
    DispatchQueue.main.async {
      KNGeneralProvider.shared.getAddressByEnsName(name.lowercased()) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if name != self.viewModel.addressString { return }
          if case .success(let addr) = result, let address = addr, address != Address(string: "0x0000000000000000000000000000000000000000") {
            self.viewModel.updateAddressFromENS(name, ensAddr: address)
          } else {
            self.viewModel.updateAddressFromENS(name, ensAddr: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + KNLoadingInterval.seconds30) {
              self.getEnsAddressFromName(self.viewModel.addressString)
            }
          }
          self.updateUIAddressQRCode()
        }
      }
    }
  }

  func updateUIAddressQRCode(isAddressChanged: Bool = true) {
    self.walletAddressTextField.text = self.viewModel.displayAddress
    self.updateUIEnsMessage()
    self.view.layoutIfNeeded()
  }

  func updateUIEnsMessage() {
    self.ensAddressLabel.isHidden = false
    self.ensAddressLabel.text = self.viewModel.displayEnsMessage
    self.ensAddressLabel.textColor = self.viewModel.displayEnsMessageColor
  }
}

extension AddWatchWalletViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 379
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension AddWatchWalletViewController: QRCodeReaderDelegate {
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

      let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
      self.viewModel.updateAddress(address)
      self.getEnsAddressFromName(address)
      self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    }
  }
}

extension AddWatchWalletViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.updateAddress("")
    self.updateUIAddressQRCode()
    self.getEnsAddressFromName("")
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.viewModel.updateAddress(text)
    self.updateUIEnsMessage()
    self.getEnsAddressFromName(text)
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.walletAddressTextField.text = self.viewModel.addressString
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.updateUIAddressQRCode()
    self.getEnsAddressFromName(self.viewModel.addressString)
  }
}
