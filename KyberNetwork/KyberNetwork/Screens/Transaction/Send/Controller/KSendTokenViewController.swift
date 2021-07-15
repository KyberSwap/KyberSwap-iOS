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
  case validate(transaction: UnconfirmedTransaction, ens: String?)
  case send(transaction: UnconfirmedTransaction, ens: String?)
  case addContact(address: String, ens: String?)
  case contactSelectMore
  case openGasPriceSelect(gasLimit: BigInt, selectType: KNSelectedGasPriceType)
  case openHistory
  case openWalletsList
}

protocol KSendTokenViewControllerDelegate: class {
  func kSendTokenViewController(_ controller: KSendTokenViewController, run event: KSendTokenViewEvent)
}

//swiftlint:disable file_length
class KSendTokenViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var amountTextField: UITextField!
  @IBOutlet weak var tokenBalanceLabel: UILabel!

  @IBOutlet weak var scrollContainerView: UIScrollView!

  @IBOutlet weak var moreContactButton: UIButton!
  @IBOutlet weak var recentContactView: UIView!
  @IBOutlet weak var recentContactLabel: UILabel!
  @IBOutlet weak var recentContactTableView: KNContactTableView!
  @IBOutlet weak var recentContactHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var recentContactTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var ensAddressLabel: UILabel!
  @IBOutlet weak var addressTextField: UITextField!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var bottomPaddingConstraintForScrollView: NSLayoutConstraint!

  @IBOutlet weak var selectedGasFeeLabel: UILabel!
  @IBOutlet weak var maxAmountButton: UIButton!
  @IBOutlet weak var sendMessageLabel: UILabel!

  fileprivate var isViewSetup: Bool = false
  fileprivate var isViewDisappeared: Bool = false
  @IBOutlet weak var currentTokenButton: UIButton!
  @IBOutlet weak var walletsSelectButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!

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
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
    self.isViewDisappeared = false
    self.updateUIAddressQRCode()
    self.updateUIPendingTxIndicatorView()
    KNCrashlyticsUtil.logCustomEvent(withName: "krystal_open_send_view", customAttributes: nil)
    self.updateUISwitchChain()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.isViewDisappeared = true
    self.view.endEditing(true)
  }

  fileprivate func setupUI() {
    self.setupNavigationView()
    self.setupTokenView()
    self.setupRecentContact()
    self.setupAddressTextField()
    self.setupSendButton()

    self.bottomPaddingConstraintForScrollView.constant = self.bottomPaddingSafeArea()
    self.updateGasFeeUI()
  }

  func removeObserveNotification() {
    if self.recentContactTableView != nil {
      self.recentContactTableView.removeNotificationObserve()
    }
  }

  fileprivate func setupNavigationView() {
    self.navTitleLabel.text = self.viewModel.navTitle
    self.walletsSelectButton.setTitle(self.viewModel.currentWalletAddress, for: .normal)
  }

  fileprivate func setupTokenView() {
    self.amountTextField.text = nil
    self.amountTextField.attributedPlaceholder = self.viewModel.placeHolderAmount
    self.amountTextField.adjustsFontSizeToFitWidth = true
    self.amountTextField.delegate = self
    self.currentTokenButton.setTitle(self.viewModel.tokenButtonText, for: .normal)
    self.tokenBalanceLabel.text = self.viewModel.totalBalanceText
    let tapBalanceGesture = UITapGestureRecognizer(target: self, action: #selector(self.tokenBalanceLabelTapped(_:)))
    self.tokenBalanceLabel.addGestureRecognizer(tapBalanceGesture)
  }

  fileprivate func setupRecentContact() {
    self.recentContactView.isHidden = true
    self.recentContactTableView.delegate = self
    self.recentContactTableView.updateScrolling(isEnabled: false)
    self.recentContactTableView.shouldUpdateContacts(nil)
    self.moreContactButton.setTitle(
      "more".toBeLocalised().uppercased(),
      for: .normal
    )
  }

  fileprivate func setupAddressTextField() {
    self.ensAddressLabel.isHidden = true
    self.recentContactLabel.text = NSLocalizedString("recent.contact", value: "Recent Contact", comment: "")
    self.addressTextField.attributedPlaceholder = self.viewModel.placeHolderEnterAddress
    self.addressTextField.delegate = self
    self.addressTextField.text = self.viewModel.displayAddress
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.ensAddressDidTapped(_:)))
    self.ensAddressLabel.addGestureRecognizer(tapGesture)
    self.ensAddressLabel.isUserInteractionEnabled = true
  }

  fileprivate func setupSendButton() {
    self.sendButton.setTitle(
      NSLocalizedString("Transfer Now", value: "Transfer Now", comment: ""),
      for: .normal
    )
  }

  @objc func tokenBalanceLabelTapped(_ sender: Any) {
    self.keyboardSendAllButtonPressed(sender)
    self.viewModel.isNeedUpdateEstFeeForTransferingAllBalance = true
  }

  @IBAction func maxButtonTapped(_ sender: UIButton) {
    self.tokenBalanceLabelTapped(sender)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .back)
  }

  @IBAction func tokenButtonPressed(_ sender: Any) {
    self.delegate?.kSendTokenViewController(self, run: .searchToken(selectedToken: self.viewModel.from))
  }

  @IBAction func gasFeeAreaTapped(_ sender: UIButton) {
    self.delegate?.kSendTokenViewController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, selectType: self.viewModel.selectedGasPriceType))
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    if self.showWarningInvalidAmountDataIfNeeded(isConfirming: true) { return }
    if self.showWarningInvalidAddressIfNeeded() { return }
    let event = KSendTokenViewEvent.validate(
      transaction: self.viewModel.unconfirmTransaction,
      ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil
    )
    self.delegate?.kSendTokenViewController(self, run: event)
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
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
    self.delegate?.kSendTokenViewController(self, run: .contactSelectMore)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.delegate?.kSendTokenViewController(self, run: .openHistory)
  }

  @IBAction func walletsSelectButtonTapped(_ sender: UIButton) {
    self.delegate?.kSendTokenViewController(self, run: .openWalletsList)
  }

  fileprivate func updateAmountFieldUIForTransferAllIfNeeded() {
    guard self.viewModel.isSendAllBalanace, self.viewModel.from.isETH else { return }
    self.amountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.amountTextField.text ?? "", forSendAllETH: true)
    self.amountTextField.resignFirstResponder()
    self.amountTextField.textColor = self.viewModel.amountTextColor
  }

  fileprivate func updateGasFeeUI() {
    self.selectedGasFeeLabel.text = self.viewModel.gasFeeString
  }

  @objc func keyboardSendAllButtonPressed(_ sender: Any) {
    self.viewModel.isSendAllBalanace = true
    self.amountTextField.text = self.viewModel.allTokenBalanceString.removeGroupSeparator()
    self.viewModel.updateAmount(self.amountTextField.text ?? "", forSendAllETH: self.viewModel.from.isETH)
    self.amountTextField.resignFirstResponder()
    self.amountTextField.textColor = self.viewModel.amountTextColor
    self.shouldUpdateEstimatedGasLimit(nil)
    if sender as? KSendTokenViewController != self {
      if self.viewModel.from.isETH {
        self.showSuccessTopBannerMessage(
          with: "",
          message: NSLocalizedString("a.small.amount.of.eth.is.used.for.transaction.fee", value: "A small amount of ETH will be used for transaction fee", comment: ""),
          time: 1.5
        )
      }
    }
    self.view.layoutIfNeeded()
  }

  @objc func keyboardDoneButtonPressed(_ sender: Any) {
    self.amountTextField.resignFirstResponder()
  }

  @objc func ensAddressDidTapped(_ sender: Any?) {
    if let addr = self.viewModel.address?.description,
       let url = URL(string: "\(KNGeneralProvider.shared.customRPC.etherScanEndpoint)address/\(addr)") {
      self.openSafari(with: url)
    }
  }

  fileprivate func shouldUpdateEstimatedGasLimit(_ sender: Any?) {
    // no need to update if address is invalid
    if self.viewModel.address == nil { return }
    // always failed if amount is bigger than balance
    if self.viewModel.isAmountTooBig { return }
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
        let quoteToken = KNGeneralProvider.shared.isEthereum ? "ETH" : "BNB"
        let fee = self.viewModel.ethFeeBigInt
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("Insufficient \(quoteToken) for transaction", value: "Insufficient \(quoteToken) for transaction", comment: ""),
          message: String(format: "Deposit more \(quoteToken) or click Advanced to lower GAS fee".toBeLocalised(), fee.shortString(units: .ether, maxFractionDigits: 6))
        )
        return true
      }
      guard EtherscanTransactionStorage.shared.isContainInsternalSendTransaction() == false else {
        self.showWarningTopBannerMessage(
          with: "",
          message: "Please wait for transaction is completed"
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
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = {
      let secondPopup = SwitchChainWalletsListViewController()
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }
}

// MARK: Update UIs
extension KSendTokenViewController {
  func updateUIFromTokenDidChange() {
    self.viewModel.updateAmount("")
    self.amountTextField.text = ""
    self.currentTokenButton.setTitle(self.viewModel.tokenButtonText, for: .normal)
    self.updateUIBalanceDidChange()
  }

  func updateUIBalanceDidChange() {
    self.tokenBalanceLabel.text = self.viewModel.totalBalanceText
    if !self.amountTextField.isEditing {
      self.amountTextField.textColor = self.viewModel.amountTextColor
    }
    self.view.layoutIfNeeded()
  }

  func updateUIAddressQRCode(isAddressChanged: Bool = true) {
    self.addressTextField.text = self.viewModel.displayAddress
    self.updateUIEnsMessage()
    if isAddressChanged { self.shouldUpdateEstimatedGasLimit(nil) }
    self.view.layoutIfNeeded()
  }

  func updateUIEnsMessage() {
    self.ensAddressLabel.isHidden = false
    self.ensAddressLabel.text = self.viewModel.displayEnsMessage
    self.ensAddressLabel.textColor = self.viewModel.displayEnsMessageColor
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    self.pendingTxIndicatorView.isHidden = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }
  
  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.isEthereum ? UIImage(named: "chain_eth_icon") : UIImage(named: "chain_bsc_icon")
    self.currentChainIcon.image = icon
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
    self.shouldUpdateEstimatedGasLimit(nil)
    self.view.layoutIfNeeded()
  }

  func coordinatorUpdateEstimatedGasLimit(_ gasLimit: BigInt, from: TokenObject, address: String) {
    if self.viewModel.updateEstimatedGasLimit(gasLimit, from: from, address: address) {
      self.updateAmountFieldUIForTransferAllIfNeeded()
      self.updateGasFeeUI()
      if self.viewModel.isNeedUpdateEstFeeForTransferingAllBalance {
        self.keyboardSendAllButtonPressed(self)
        self.viewModel.isNeedUpdateEstFeeForTransferingAllBalance = false
      }
    } else {
      // fail to update gas limit
      self.coordinatorFailedToUpdateEstimateGasLimit()
    }
  }

  func coordinatorFailedToUpdateEstimateGasLimit() {
    // update after 1 min
    DispatchQueue.main.asyncAfter(deadline: .now() + KNLoadingInterval.seconds60) {
      self.shouldUpdateEstimatedGasLimit(nil)
    }
  }

  func coordinatorUpdateGasPriceCached() {
    self.viewModel.updateSelectedGasPriceType(self.viewModel.selectedGasPriceType)
    self.updateGasFeeUI()
  }

  func coordinatorUpdateIsPromoWallet(_ isPromo: Bool) {
  }

  func coordinatorDidSelectContact(_ contact: KNContact) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != contact.address.lowercased()
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    KNContactStorage.shared.updateLastUsed(contact: contact)
  }

  func coordinatorSend(to address: String) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
    self.viewModel.updateAddress(address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    if let contact = KNContactStorage.shared.contacts.first(where: { return address.lowercased() == $0.address.lowercased() }) {
      KNContactStorage.shared.updateLastUsed(contact: contact)
    }
  }

  func coordinatorUpdateTrackerRate() {
  }

  func coordinatorDidValidateTransferTransaction() {
    let event = KSendTokenViewEvent.send(
      transaction: self.viewModel.unconfirmTransaction,
      ens: self.viewModel.isUsingEns ? self.viewModel.addressString : nil
    )
    self.delegate?.kSendTokenViewController(self, run: event)
  }

  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    self.updateAmountFieldUIForTransferAllIfNeeded()
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
  
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.currentWalletAddress = wallet.address.description
    self.setupNavigationView()
    self.updateUIBalanceDidChange()
    self.updateUIPendingTxIndicatorView()
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else { return }
    self.updateUISwitchChain()
    self.viewModel.resetFromToken()
    self.updateGasFeeUI()
    self.tokenBalanceLabel.text = self.viewModel.totalBalanceText
    self.currentTokenButton.setTitle(self.viewModel.tokenButtonText, for: .normal)
  }
}

// MARK: UITextFieldDelegate
extension KSendTokenViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    if self.amountTextField == textField {
      self.viewModel.updateAmount("")
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
    } else {
      textField.text = text
      self.viewModel.updateAddress(text)
      self.updateUIEnsMessage()
      self.getEnsAddressFromName(text)
    }
    self.view.layoutIfNeeded()
    return false
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.viewModel.isSendAllBalanace = false
    self.amountTextField.textColor = UIColor.white
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
      self.shouldUpdateEstimatedGasLimit(nil)
    }
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
      let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
      self.viewModel.updateAddress(address)
      self.getEnsAddressFromName(address)
      self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
    }
  }
}

extension KSendTokenViewController: KNContactTableViewDelegate {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent) {
    switch event {
    case .update(let height):
      self.updateContactTableView(height: height)
    case .select(let contact):
      self.contactTableView(select: contact)
    case .edit(let contact):
      self.delegate?.kSendTokenViewController(self, run: .addContact(address: contact.address, ens: nil))
    case .delete(let contact):
      self.contactTableView(delete: contact)
    case .send(let address):
      if let contact = KNContactStorage.shared.contacts.first(where: { $0.address.lowercased() == address.lowercased() }) {
        self.contactTableView(select: contact)
      } else {
        let isAddressChanged = self.viewModel.addressString.lowercased() != address.lowercased()
        self.viewModel.updateAddress(address)
        self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
      }
    case .copiedAddress:
      self.showMessageWithInterval(
        message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
      )
    case .addContact:
     break
    }
  }

  fileprivate func updateContactTableView(height: CGFloat) {
    UIView.animate(
    withDuration: 0.25) {
      self.recentContactView.isHidden = (height == 0)
      self.recentContactHeightConstraint.constant = height == 0 ? 0 : height + 34.0
      self.recentContactTableViewHeightConstraint.constant = height
      self.updateUIAddressQRCode(isAddressChanged: false)
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func contactTableView(select contact: KNContact) {
    let isAddressChanged = self.viewModel.addressString.lowercased() != contact.address.lowercased()
    self.viewModel.updateAddress(contact.address)
    self.updateUIAddressQRCode(isAddressChanged: isAddressChanged)
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
    self.viewModel.isNeedUpdateEstFeeForTransferingAllBalance = true
  }

  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar) {
    self.keyboardDoneButtonPressed(toolbar)
  }
}

