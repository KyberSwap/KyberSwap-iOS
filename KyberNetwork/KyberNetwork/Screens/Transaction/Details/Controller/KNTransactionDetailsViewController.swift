// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

enum KNTransactionDetailsViewEvent {
  case back
  case openEtherScan(hash: String)
  case openEnjinXScan
  case openEtherScanAddress(hash: String)
}

protocol KNTransactionDetailsViewControllerDelegate: class {
  func transactionDetailsViewController(_ controller: KNTransactionDetailsViewController, run event: KNTransactionDetailsViewEvent)
}

class KNTransactionDetailsViewController: KNBaseViewController {

  weak var delegate: KNTransactionDetailsViewControllerDelegate?
  fileprivate var viewModel: TransactionDetailsViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationTitleLabel: UILabel!

  @IBOutlet weak var txTypeLabel: UILabel!
  @IBOutlet weak var transactionDescriptionLabel: UILabel!
  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!
  @IBOutlet weak var toAddressLabel: UILabel!
  @IBOutlet weak var fromAddressLabel: UILabel!

  @IBOutlet weak var txHashLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var txStatusLabel: UILabel!
  @IBOutlet weak var historyTypeImage: UIImageView!
  @IBOutlet weak var fromIconImage: UIImageView!
  @IBOutlet weak var toIconImage: UIImageView!
  @IBOutlet weak var fromAddressContainerView: UIView!
  @IBOutlet weak var toAddressContainerView: UIView!
  @IBOutlet weak var fromFieldTitleLabel: UILabel!
  @IBOutlet weak var toFIeldTitleLabel: UILabel!

  init(viewModel: TransactionDetailsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTransactionDetailsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.updateUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  fileprivate func setupUI() {
    self.navigationTitleLabel.text = NSLocalizedString("transaction.details", value: "Transaction Details", comment: "")

    self.feeTextLabel.text = NSLocalizedString("transaction.fee", value: "Transaction Fee", comment: "")
    self.fromAddressContainerView.rounded(radius: 8)
    self.toAddressContainerView.rounded(radius: 8)
  }

  fileprivate func updateUI() {
    self.txTypeLabel.text = self.viewModel.displayTxTypeString
    self.feeValueLabel.text = self.viewModel.displayGasFee
    self.txStatusLabel.text = self.viewModel.displayTxStatus
    self.txStatusLabel.textColor = self.viewModel.displayTxStatusColor
    self.txStatusLabel.rounded(color: self.viewModel.displayTxStatusColor, width: 1, radius: 3)
    self.fromAddressLabel.text = self.viewModel.displayFromAddress
    self.toAddressLabel.text = self.viewModel.displayToAddress
    self.transactionDescriptionLabel.text = self.viewModel.displayAmountString
    self.fromFieldTitleLabel.text = self.viewModel.fromFieldTitle
    self.toFIeldTitleLabel.text = self.viewModel.toFieldTitle
    self.dateLabel.text = self.viewModel.displayDateString
    self.feeValueLabel.text = self.viewModel.displayGasFee
    self.txHashLabel.text = self.viewModel.displayHash

    if self.viewModel.toIconSymbol.isEmpty {
      self.toIconImage.image = UIImage()
    } else {
      self.toIconImage.setSymbolImage(symbol: self.viewModel.toIconSymbol)
    }
    if self.viewModel.fromIconSymbol.isEmpty {
      self.fromIconImage.image = UIImage()
    } else {
      self.fromIconImage.setSymbolImage(symbol: self.viewModel.fromIconSymbol)
    }
    self.historyTypeImage.image = self.viewModel.transactionTypeImage
  }

  fileprivate func hideSwapIcon(_ hidden: Bool) {
    self.fromIconImage.isHidden = hidden
    self.toIconImage.isHidden = hidden
    self.historyTypeImage.isHidden = !hidden
  }

  @IBAction func addressesAreaTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      self.delegate?.transactionDetailsViewController(self, run: .openEtherScanAddress(hash: self.viewModel.displayToAddress))
    } else {
      self.delegate?.transactionDetailsViewController(self, run: .openEtherScanAddress(hash: self.viewModel.displayFromAddress))
    }
  }

  @objc func txHashTapped(_ sender: Any) {
    self.copy(text: self.viewModel.displayHash)
  }

  fileprivate func copy(text: String) {
    UIPasteboard.general.string = text

    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

//  func coordinator(update transaction: Transaction, currentWallet: KNWalletObject) {
//    self.viewModel.update(transaction: transaction, currentWallet: currentWallet)
//    self.updateUI()
//  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.transactionDetailsViewController(self, run: .back)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.transactionDetailsViewController(self, run: .back)
    }
  }

  @IBAction func viewOnEtherscanButtonPressed(_ sender: Any) {
    self.delegate?.transactionDetailsViewController(self, run: .openEtherScan(hash: self.viewModel.displayHash))
  }
  
  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
}
