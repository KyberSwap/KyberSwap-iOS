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
    return "\(unwrapped.totalPoint) KP"
  }
  
  var displayTotalETHPoint: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.totalPoint) ETH"
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
      return KrytalCellViewModel(codeObject: unwrapped.codes[refCode] ?? Code(totalRefer: 0, totalPoint: 0, ratio: 0), referralCode: refCode)
    }
  }
  
  var displayWalletString: String {
    guard let unwrapped = self.wallet else { return "" }
    return unwrapped.address.description
  }
}

enum KrytalViewEvent {
  case openShareCode(refCode: String, codeObject: Code)
  case openHistory
  case openWalletList
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
    self.totalKrytalPointSectionLabel.text = self.viewModel.displayTotalKrytalPoint
    self.cashbackPointLabel.text = self.viewModel.displayTotalCashbackPoint
    self.walletListButton.setTitle(self.viewModel.displayWalletString, for: .normal)
    self.referralCodeTableView.reloadData()
  }

  func coordinatorDidUpdateOverviewReferral(_ overview: Overview) {
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
    self.navigationController?.showBottomBannerView(message: "Ask your friend to download Krystal app using your referral link. If they start using Krystal wallet, We will automatically map the referral to you. You will earn commission every time your friends transact via Krystal app.", icon: UIImage(named: "info_waring_blue_icon")!)
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
