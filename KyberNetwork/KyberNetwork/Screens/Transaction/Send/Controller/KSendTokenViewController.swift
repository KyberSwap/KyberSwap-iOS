// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustKeystore
import TrustCore
import Result
import QRCodeReaderViewController

enum KSendTokenViewEvent {
  case back
  case searchToken(selectedToken: TokenObject)
  case estimateGas(transaction: UnconfirmedTransaction)
  case setGasPrice(gasPrice: BigInt, gasLimit: BigInt)
  case send(transaction: UnconfirmedTransaction, ens: String?)
  case addContact(address: String, ens: String?)
  case contactSelectMore
}

protocol KSendTokenViewControllerDelegate: class {
  func kSendTokenViewController(_ controller: KSendTokenViewController, run event: KSendTokenViewEvent)
}

//swiftlint:disable file_length
class KSendTokenViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var tokenContainerView: UIView!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var balanceTextLabel: UILabel!
  @IBOutlet weak var tokenBalanceLabel: UILabel!
  @IBOutlet weak var equivalentUSDLabel: UILabel!

  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var advancedSettingsView: KAdvancedSettingsView!
  @IBOutlet weak var heightConstraintAdvancedSettingsView: NSLayoutConstraint!

  @IBOutlet weak var moreContactButton: UIButton!
  @IBOutlet weak var recentContactView: UIView!
  @IBOutlet weak var recentContactLabel: UILabel!
  @IBOutlet weak var recentContactTableView: KNContactTableView!
  @IBOutlet weak var recentContactHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var recentContactTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var ensAddressLabel: UILabel!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var newContactButton: UIButton!
  @IBOutlet weak var bottomPaddingConstraintForScrollView: NSLayoutConstraint!

  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false

  lazy var toolBar: KNCustomToolbar = {
    return KNCustomToolbar(
      leftBtnTitle: NSLocalizedString("send.all", value: "Transfer All", comment: ""),
      rightBtnTitle: NSLocalizedString("done", value: "Done", comment: ""),
      delegate: self
    )
  }()

  lazy var style: KNAppStyleType = {
    return KNAppStyleType.current
  }()

  weak var delegate: KSendTokenViewControllerDelegate?
  fileprivate let viewModel: KNSendTokenViewModel
  fileprivate var estGasTimer: Timer?

  init(viewModel: KNSendTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KSendTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if self.recentContactTableView != nil {
      self.recentContactTableView.removeNotificationObserve()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.sendButton.applyGradient()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.tokenContainerView.addShadow(
      color: UIColor.black.withAlphaComponent(0.6),
      offset: CGSize(width: 0, height: 7),
      opacity: 0.32,
      radius: 32
    )
    self.advancedSettingsView.layoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.sendButton.removeSublayer(at: 0)
    self.sendButton.applyGradient()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
    self.isViewDisappeared = false
    self.updateUIAddressQRCode()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.estGasTimer?.invalidate()
    self.estGasTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.defaultLoadingInterval,
      repeats: true,
      block: { [weak self] _ in
        self?.shouldUpdateEstimatedGasLimit(nil)
      }
    )
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.estGasTimer?.invalidate()
  }

  fileprivate func setupUI() {
    self.setupNavigationView()
    self.setupTokenView()
    self.setupAdvancedSettingsView()
    self.setupRecentContact()
    self.setupAddressTextField()
    self.setupSendButton()

    self.bottomPaddingConstraintForScrollView.constant = self.bottomPaddingSafeArea()
  }

  func removeObserveNotification() {
    if self.recentContactTableView != nil {
      self.recentContactTableView.removeNotificationObserve()
    }
  }

  fileprivate func setupNavigationView() {
    self.navTitleLabel.text = self.viewModel.navTitle
  }

  fileprivate func setupTokenView() {
    self.tokenContainerView.rounded(radius: 4.0)
    self.tokenButton.titleLabel?.numberOfLines = 2
    self.tokenButton.titleLabel?.lineBreakMode = .byWordWrapping

    self.amountTextField.text = nil
    self.amountTextField.adjustsFontSizeToFitWidth = true
    self.amountTextField.delegate = self
    self.amountTextField.inputAccessoryView = self.toolBar

    self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount

    self.tokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)

    self.balanceTextLabel.text = self.viewModel.balanceText
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
    let tapBalanceGesture = UITapGestureRecognizer(target: self, action: #selector(self.tokenBalanceLabelTapped(_:)))
    self.tokenBalanceLabel.addGestureRecognizer(tapBalanceGesture)
  }

  fileprivate func setupRecentContact() {
    self.recentContactView.isHidden = true
    self.recentContactTableView.delegate = self
    self.recentContactTableView.updateScrolling(isEnabled: false)
    self.recentContactTableView.shouldUpdateContacts(nil)
    self.moreContactButton.setTitleColor(
      UIColor.Kyber.enygold,
      for: .normal
    )
    self.moreContactButton.setTitle(
      NSLocalizedString("more", value: "More", comment: ""),
      for: .normal
    )
  }

  fileprivate func setupAdvancedSettingsView() {
    // TODO: Do we need to check if it is a promo wallet here?
    let viewModel = KAdvancedSettingsViewModel(hasMinRate: false, isPromo: false)
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    viewModel.updateViewHidden(isHidden: true)
    self.advancedSettingsView.updateViewModel(viewModel)
    self.heightConstraintAdvancedSettingsView.constant = self.advancedSettingsView.height
    self.advancedSettingsView.delegate = self
    self.view.setNeedsUpdateConstraints()
    self.view.updateConstraints()
  }

  fileprivate func setupAddressTextField() {
    self.ensAddressLabel.isHidden = true
    self.recentContactLabel.text = NSLocalizedString("recent.contact", value: "Recent Contact", comment: "")
    self.addressTextField.placeholder = self.viewModel.placeHolderEnterAddress
    self.addressTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
    self.addressTextField.leftViewMode = .always
    self.addressTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 0))
    self.addressTextField.rightViewMode = .always
    self.addressTextField.delegate = self
    self.addressTextField.text = self.viewModel.displayAddress
    self.newContactButton.setTitle(
      NSLocalizedString("add.contact", value: "Add contact", comment: ""),
      for: .normal
    )
    self.newContactButton.setTitleColor(
      UIColor.Kyber.enygold,
      for: .normal
    )
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.ensAddressDidTapped(_:)))
    self.ensAddressLabel.addGestureRecognizer(tapGesture)
    self.ensAddressLabel.isUserInteractionEnabled = true
  }

  fileprivate func setupSendButton() {
    self.sendButton.rounded(radius: self.style.buttonRadius(for: self.sendButton.frame.height))
    self.sendButton.setTitle(
      NSLocalizedString("Transfer Now", value: "Transfer Now", comment: ""),
      for: .normal
    )
  }

  fileprivate func updateAdvancedSettingsView() {
    self.advancedSettingsView.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    self.view.layoutIfNeeded()
  }

  @objc func tokenBalanceLabelTapped(_ sender: Any) {
    self.keyboardSendAllButtonPressed(sender)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .back)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "search_token"])
    self.delegate?.kSendTokenViewController(self, run: .searchToken(selectedToken: self.viewModel.from))
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_\(self.viewModel.from.symbol)"])
    if self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) { return }
    if self.showWarningInvalidAddressIfNeeded() { return }
    if KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == (self.viewModel.address?.description.lowercased() ?? "") }) != nil {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_to_contact"])
    } else {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_not_in_contact"])
    }
    let event = KSendTokenViewEvent.send(
      transaction: self.viewModel.unconfirmTransaction,
      ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil
    )
    sendButton.isEnabled = false
    self.delegate?.kSendTokenViewController(self, run: event)
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "scan_qr_code"])
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

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.kSendTokenViewController(self, run: .back)
    }
  }

  @IBAction func recentContactMoreButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "recent_contact_more"])
    self.delegate?.kSendTokenViewController(self, run: .contactSelectMore)
  }

  @IBAction func newContactButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "new_contact_button"])
    let event = KSendTokenViewEvent.addContact(
      address: self.viewModel.address?.description ?? "",
      ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil
    )
    self.delegate?.kSendTokenViewController(self, run: event)
  }

  @objc func keyboardSendAllButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_all"])
    self.amountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.amountTextField.text ?? "")
    self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
    self.amountTextField.resignFirstResponder()
    self.amountTextField.textColor = self.viewModel.amountTextColor
    self.shouldUpdateEstimatedGasLimit(nil)
    if self.viewModel.from.isETH {
      self.showSuccessTopBannerMessage(
        with: "",
        message: NSLocalizedString("a.small.amount.of.eth.is.used.for.transaction.fee", value: "A small amount of ETH will be used for transaction fee", comment: ""),
        time: 1.5
      )
    }
    self.viewModel.isSendAllBalanace = true
    self.view.layoutIfNeeded()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
  }

  @objc func ensAddressDidTapped(_ sender: Any?) {
    if let addr = self.viewModel.address?.description,
      let url = URL(string: "\(KNEnvironment.default.etherScanIOURLString)address/\(addr)") {
      self.openSafari(with: url)
    }
  }

  fileprivate func shouldUpdateEstimatedGasLimit(_ sender: Any?) {
    let event = KSendTokenViewEvent.estimateGas(transaction: self.viewModel.unconfirmTransaction)
    self.delegate?.kSendTokenViewController(self, run: event)
  }

  /*
   Return true if amount is invalid and a warning message is shown,
   false otherwise
   */
  fileprivate func showWarningInvalidAmountDataIfNeeded(isConfirming: Bool = false) -> Bool {
    if !isConfirming && self.isViewDisappeared { return false }
    if isConfirming {
      guard self.viewModel.isHavingEnoughETHForFee else {
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("Insufficient ETH for transaction", value: "Insufficient ETH for transaction", comment: ""),
          message: NSLocalizedString("Deposit more ETH or click Advanced to lower GAS fee", value: "Deposit more ETH or click Advanced to lower GAS fee", comment: "")
        )
        return true
      }
    }
    guard !self.viewModel.amount.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid input", comment: ""),
        message: NSLocalizedString("please.enter.an.amount.to.continue", value: "Please enter an amount to continue", comment: "")
      )
      return true
    }
    guard !self.viewModel.isAmountTooSmall else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.amount", value: "Invalid amount", comment: ""),
        message: NSLocalizedString("amount.to.send.greater.than.zero", value: "Amount to transfer should be greater than zero", comment: "")
      )
      return true
    }
    guard !self.viewModel.isAmountTooBig else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("amount.too.big", value: "Amount too big", comment: ""),
        message: NSLocalizedString("balance.not.enough.to.make.transaction", value: "Balance is not be enough to make the transaction.", comment: "")
      )
      return true
    }
    return false
  }

  /*
   Return true if address is invalid and a warning message is shown,
   false otherwise
   */
  fileprivate func showWarningInvalidAddressIfNeeded() -> Bool {
    if self.isViewDisappeared { return false }
    guard self.viewModel.isAddressValid else {
      self.showWarningTopBannerMessage(
        with: "Invalid Address/ENS".toBeLocalised(),
        message: "Please enter a valid address/ens to transfer".toBeLocalised()
      )
      return true
    }
    return false
  }
}

// MARK: Update UIs
extension KSendTokenViewController {
  func updateUIFromTokenDidChange() {
    self.viewModel.updateAmount("")
    self.amountTextField.text = ""
    self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
    self.tokenButton.setTokenImage(
      token: self.viewModel.from,
      size: self.viewModel.defaultTokenIconImg?.size
    )
    self.tokenButton.setAttributedTitle(self.viewModel.tokenButtonAttributedText, for: .normal)
    self.updateUIBalanceDidChange()
  }

  func updateUIBalanceDidChange() {
    self.tokenBalanceLabel.text = self.viewModel.displayBalance
    self.balanceTextLabel.text = self.viewModel.balanceText
    if !self.amountTextField.isEditing {
      self.amountTextField.textColor = self.viewModel.amountTextColor
    }
    self.view.layoutIfNeeded()
  }

  func updateUIAddressQRCode() {
    self.addressTextField.text = self.viewModel.displayAddress
    self.newContactButton.setTitle(self.viewModel.newContactTitle, for: .normal)
    self.shouldUpdateEstimatedGasLimit(nil)
    self.updateUIEnsMessage()
    self.view.layoutIfNeeded()
  }

  func updateUIEnsMessage() {
    self.ensAddressLabel.isHidden = false
    self.ensAddressLabel.text = self.viewModel.displayEnsMessage
    self.ensAddressLabel.textColor = self.viewModel.displayEnsMessageColor
  }
}

// MARK: Update from coordinator
extension KSendTokenViewController {
  func coordinatorDidUpdateSendToken(_ from: TokenObject, balance: Balance?) {
    if from.isPromoToken {
      self.showWarningTopBannerMessage(
        with: "",
        message: NSLocalizedString("can.not.transfer.this.token", value: "Can not transfer this token", comment: ""),
        time: 1.5
      )
      return
    }
    self.viewModel.updateSendToken(from: from, balance: balance)
    self.updateUIFromTokenDidChange()
  }

  func coordinatorUpdateBalances(_ balances: [String: Balance]) {
    self.viewModel.updateBalance(balances)
    self.updateUIBalanceDidChange()
  }

  /*
   Result from sending exchange token
   */
  func coordinatorSendTokenDidReturn(result: Result<String, AnyError>) {
    if case .failure(let error) = result {
      self.displayError(error: error)
    }
  }

  /*
   Show transaction status after user confirmed transaction
   */
  func coordinatorSendTokenUserDidConfirmTransaction() {
    // Reset exchange amount
    self.amountTextField.text = ""
    self.viewModel.updateAmount("")
    self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
    self.shouldUpdateEstimatedGasLimit(nil)
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, amount: BigInt) {
    self.viewModel.updateEstimatedGasLimit(gasLimit, from: from, amount: amount)
    self.updateAdvancedSettingsView()
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.updateAdvancedSettingsView()
  }

  func coordinatorUpdateIsPromoWallet(_ isPromo: Bool) {
    self.advancedSettingsView.updateIsPromoWallet(isPromo)
  }

  func coordinatorDidSelectContact(_ contact: KNContact) {
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode()
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }

  func coordinatorSend(to address: String) {
    self.viewModel.updateAddress(address)
    self.updateUIAddressQRCode()
    if let contact = KNContactStorage.shared.contacts.first(where: { return address.lowercased() == $0.address.lowercased() }) {
      KNContactStorage.shared.updateLastUsed(contact: contact)
    }
  }

  func coordinatorUpdateTrackerRate() {
    self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
  }
}

// MARK: UITextFieldDelegate
extension KSendTokenViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.viewModel.updateAmount("")
      self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
      self.view.layoutIfNeeded()
    } else {
      self.viewModel.updateAddress("")
      self.updateUIAddressQRCode()
      self.getEnsAddressFromName("")
    }
    self.shouldUpdateEstimatedGasLimit(nil)
    self.viewModel.isSendAllBalanace = false
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    let cleanedText = text.cleanStringToNumber()
    if textField == self.amountTextField, cleanedText.amountBigInt(decimals: self.viewModel.from.decimals) == nil { return false }
    if textField == self.amountTextField {
      textField.text = cleanedText
      self.viewModel.updateAmount(cleanedText)
      self.equivalentUSDLabel.text = self.viewModel.displayEquivalentUSDAmount
    } else {
      textField.text = text
      self.viewModel.updateAddress(text)
      self.updateUIEnsMessage()
      self.getEnsAddressFromName(text)
    }
    self.shouldUpdateEstimatedGasLimit(nil)
    self.view.layoutIfNeeded()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isSendAllBalanace = false
    self.amountTextField.textColor = UIColor.Kyber.enygold
    if textField == self.addressTextField {
      self.addressTextField.text = self.viewModel.addressString
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    self.amountTextField.textColor = self.viewModel.amountTextColor
    if textField == self.addressTextField {
      self.updateUIAddressQRCode()
      self.getEnsAddressFromName(self.viewModel.addressString)
    } else {
      _ = self.showWarningInvalidAmountDataIfNeeded()
    }
  }

  fileprivate func getEnsAddressFromName(_ name: String) {
    if Address(string: name) != nil { return }
    if !name.contains(".") {
      self.viewModel.updateAddressFromENS(name, ensAddr: nil)
      self.updateUIAddressQRCode()
      return
    }
    DispatchQueue.global().async {
      KNGeneralProvider.shared.getAddressByEnsName(name.lowercased()) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          if name != self.viewModel.addressString { return }
          if case .success(let addr) = result, let address = addr, address != Address(string: "0x0000000000000000000000000000000000000000") {
            self.viewModel.updateAddressFromENS(name, ensAddr: address)
          } else {
            self.viewModel.updateAddressFromENS(name, ensAddr: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
              self.getEnsAddressFromName(self.viewModel.addressString)
            }
          }
          self.updateUIAddressQRCode()
        }
      }
    }
  }
}

extension KSendTokenViewController: QRCodeReaderDelegate {
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
      self.viewModel.updateAddress(address)
      self.getEnsAddressFromName(address)
      self.updateUIAddressQRCode()
    }
  }
}

extension KSendTokenViewController: KNContactTableViewDelegate {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent) {
    switch event {
    case .update(let height):
      self.updateContactTableView(height: height)
    case .select(let contact):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "selected_contact"])
      self.contactTableView(select: contact)
    case .edit(let contact):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "edit/add_contact"])
      self.delegate?.kSendTokenViewController(self, run: .addContact(address: contact.address, ens: nil))
    case .delete(let contact):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "delete_contact"])
      self.contactTableView(delete: contact)
    case .send(let address):
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_token", customAttributes: ["action": "send_contact"])
      if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
        self.contactTableView(select: contact)
      } else {
        self.viewModel.updateAddress(address)
        self.updateUIAddressQRCode()
      }
    case .copiedAddress:
      self.showMessageWithInterval(
        message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
      )
    }
  }

  fileprivate func updateContactTableView(height: CGFloat) {
    UIView.animate(
    withDuration: 0.25) {
      self.recentContactView.isHidden = (height == 0)
      self.recentContactHeightConstraint.constant = height == 0 ? 0 : height + 34.0
      self.recentContactTableViewHeightConstraint.constant = height
      self.updateUIAddressQRCode()
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func contactTableView(select contact: KNContact) {
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode()
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }

  fileprivate func contactTableView(delete contact: KNContact) {
    let alertController = UIAlertController(
      title: NSLocalizedString("do.you.want.to.delete.this.contact", value: "Do you want to delete this contact?", comment: ""),
      message: "",
      preferredStyle: .actionSheet
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      KNContactStorage.shared.delete(contacts: [contact])
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }
}

extension KSendTokenViewController: KNCustomToolbarDelegate {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardSendAllButtonPressed(toolbar)
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}

// MARK: Advanced Settings View
extension KSendTokenViewController: KAdvancedSettingsViewDelegate {
  func kAdvancedSettingsView(_ view: KAdvancedSettingsView, run event: KAdvancedSettingsViewEvent) {
    switch event {
    case .displayButtonPressed:
      UIView.animate(
        withDuration: 0.32,
        animations: {
          self.heightConstraintAdvancedSettingsView.constant = self.advancedSettingsView.height
          self.updateAdvancedSettingsView()
          self.view.layoutIfNeeded()
        }, completion: { _ in
          if self.advancedSettingsView.isExpanded {
            let bottomOffset = CGPoint(
              x: 0,
              y: self.scrollContainerView.contentSize.height - self.scrollContainerView.bounds.size.height
            )
            self.scrollContainerView.setContentOffset(bottomOffset, animated: true)
          }
        }
      )
    case .gasPriceChanged(let type, let value):
      self.viewModel.updateSelectedGasPriceType(type)
      self.viewModel.updateGasPrice(value)
    default: break
    }
  }
}
