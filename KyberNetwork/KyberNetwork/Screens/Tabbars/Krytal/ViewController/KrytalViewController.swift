//
//  KrytalViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import UIKit
import MBProgressHUD

class KrytalViewModel {
  var overview: Overview?
  var wallet: Wallet?
  
  var displayTotalKrytalPoint: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.claimablePoint) KP"
  }
  
  var displayTotalETHPoint: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(Double(unwrapped.claimablePoint) / 1000.0) ETH"
  }
  
  var displayTotalCashbackPoint: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.cashbackPoint) KP"
  }
  
  var displayReferralCodes: [KrytalCellViewModel] {
    guard let unwrapped = self.overview else { return [] }
    let allHashs = unwrapped.codes.keys
    let sorted = allHashs.sorted { (left, right) -> Bool in
      return unwrapped.codes[left]?.ratio ?? 0 > unwrapped.codes[right]?.ratio ?? 0
    }
    return sorted.map { (refCode) -> KrytalCellViewModel in
      return KrytalCellViewModel(codeObject: unwrapped.codes[refCode] ?? Code(totalRefer: 0, totalEscrowed: 0, totalEarned: 0, ratio: 0), referralCode: refCode)
    }
  }
  
  var displayTotalEarned: String {
    guard let unwrapped = self.overview else { return "---" }
    var total = 0.0
    unwrapped.codes.values.forEach { (item) in
      total += item.totalEarned
    }
    return "\(total) KP"
  }
  
  var displayTotalEscrow: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.cashbackEscrowed) KP"
  }
  
  var displayWalletString: String {
    guard let unwrapped = self.wallet else { return "" }
    return unwrapped.address.description
  }
  
  var displayIntroAttributedString: NSAttributedString {
    let fullString = NSMutableAttributedString(string: "Copy below given Codes to share with your friends & start earning ".toBeLocalised())
    let image1Attachment = NSTextAttachment()
    image1Attachment.image = UIImage(named: "info_waring_blue_icon")
    let image1String = NSAttributedString(attachment: image1Attachment)
    fullString.append(image1String)
    return fullString
  }
}

enum KrytalViewEvent {
  case openShareCode(refCode: String, codeObject: Code)
  case openHistory
  case openWalletList
  case claim(amount: Double)
}

protocol KrytalViewControllerDelegate: class {
  func krytalViewController(_ controller: KrytalViewController, run event: KrytalViewEvent)
}

class KrytalViewController: KNBaseViewController {
  @IBOutlet weak var totalKrytalPointLabel: UILabel!
  @IBOutlet weak var totalETHLabel: UILabel!
  @IBOutlet weak var referralCodeTableView: UITableView!
  @IBOutlet weak var totalKrytalPointSectionLabel: UILabel!
  @IBOutlet weak var cashbackPointLabel: UILabel!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var introLabel: UILabel!
  @IBOutlet weak var cashBackEscrowLabel: UILabel!
  
  let viewModel = KrytalViewModel()
  weak var delegate: KrytalViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: KrytalTableViewCell.className, bundle: nil)
    self.referralCodeTableView.register(nib, forCellReuseIdentifier: KrytalTableViewCell.cellID)
    self.referralCodeTableView.rowHeight = KrytalTableViewCell.cellHeight
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.totalKrytalPointLabel.text = self.viewModel.displayTotalKrytalPoint
    self.totalETHLabel.text = self.viewModel.displayTotalETHPoint
    self.totalKrytalPointSectionLabel.text = self.viewModel.displayTotalEarned
    self.cashbackPointLabel.text = self.viewModel.displayTotalCashbackPoint
    self.walletListButton.setTitle(self.viewModel.displayWalletString, for: .normal)
    self.introLabel.attributedText = self.viewModel.displayIntroAttributedString
    self.cashBackEscrowLabel.text = self.viewModel.displayTotalEscrow
    self.referralCodeTableView.reloadData()
  }

  func coordinatorDidUpdateOverviewReferral(_ overview: Overview?) {
    self.viewModel.overview = overview
    guard self.isViewLoaded else { return }
    self.updateUI()
  }

  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalViewController(self, run: .openHistory)
  }
  
  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalViewController(self, run: .openWalletList)
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func helpIconTapped(_ sender: UITapGestureRecognizer) {
    self.navigationController?.showBottomBannerView(message: "Ask your friends to download Krystal App using your Referral Code. If they start using Krystal, we will automatically map the referral to your wallet. You will earn rewards if your friends actively use the Krystal Services.", icon: UIImage(named: "info_waring_blue_icon")!)
  }
  
  @IBAction func claimRewardButtonTapped(_ sender: UIButton) {
    guard let unwrapped = self.viewModel.overview else {
      return
    }
    self.delegate?.krytalViewController(self, run: .claim(amount: unwrapped.claimablePoint))
  }
}

extension KrytalViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.displayReferralCodes.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KrytalTableViewCell.cellID,
      for: indexPath
    ) as! KrytalTableViewCell

    cell.updateCell(viewModel: self.viewModel.displayReferralCodes[indexPath.row])
    cell.delegate = self
    return cell
  }
}

extension KrytalViewController: KrytalTableViewCellDelegate {
  func krytalTableViewCellDidSelectCopy(_ cell: KrytalTableViewCell, code: String) {
    UIPasteboard.general.string = code
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func krytalTableViewCellDidSelectShare(_ cell: KrytalTableViewCell, code: String, codeObject: Code) {
    self.delegate?.krytalViewController(self, run: .openShareCode(refCode: code, codeObject: codeObject))
  }
}
