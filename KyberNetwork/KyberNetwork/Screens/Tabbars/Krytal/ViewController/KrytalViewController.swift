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
    return "\(Double(unwrapped.claimablePoint) / 10000.0) \(KNGeneralProvider.shared.quoteToken)"
  }

  var displayReferralCodes: [KrytalCellViewModel] {
    guard let unwrapped = self.overview else { return [] }
    let allHashs = unwrapped.codes.keys
    let sorted = allHashs.sorted { (left, right) -> Bool in
      return unwrapped.codes[left]?.ratio ?? 0 > unwrapped.codes[right]?.ratio ?? 0
    }
    return sorted.map { (refCode) -> KrytalCellViewModel in
      return KrytalCellViewModel(codeObject: unwrapped.codes[refCode] ?? Code(totalRefer: 0, pendingVol: 0, realizedVol: 0, ratio: 0), referralCode: refCode)
    }
  }
  
  var displayWalletString: String {
    guard let unwrapped = self.wallet else { return "" }
    return unwrapped.address.description
  }
  
  var displayIntroAttributedString: NSAttributedString {
    let fullString = NSMutableAttributedString(string: "Copy below given Referral Codes to share with your friends. Afterward, both of you can start earning Referral Rewards.".toBeLocalised())
    let image1Attachment = NSTextAttachment()
    image1Attachment.image = UIImage(named: "info_waring_blue_icon")
    let image1String = NSAttributedString(attachment: image1Attachment)
    fullString.append(image1String)
    return fullString
  }
  
  var displayCashbackPendingVol: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.cashbackPendingVol)"
  }
  
  var displayCashbackConfirmedVol: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.cashbackRealizedVol)"
  }
  
  var displayTotalPendingVol: String {
    guard let unwrapped = self.overview else { return "---" }
    var total = unwrapped.cashbackPendingVol
    unwrapped.codes.values.forEach { (item) in
      total += item.pendingVol
    }
    return "\(total)"
  }
  
  var displayTotalConfirmedVol: String {
    guard let unwrapped = self.overview else { return "---" }
    var total = unwrapped.cashbackRealizedVol
    unwrapped.codes.values.forEach { (item) in
      total += item.realizedVol
    }
    return "\(total)"
  }

  var displayTier: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.minTier) \(KNGeneralProvider.shared.quoteToken) - \(unwrapped.maxTier) \(KNGeneralProvider.shared.quoteToken)"
  }

  var displayRealizedPoint: String {
    guard let unwrapped = self.overview else { return "---" }
    return "\(unwrapped.realizedReward) KP"
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
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var introLabel: UILabel!
  @IBOutlet weak var cashbackPendingVolLabel: UILabel!
  @IBOutlet weak var cashbackConfirmedVolLabel: UILabel!
  @IBOutlet weak var totalPendingVolLabel: UILabel!
  @IBOutlet weak var totalConfirmedVolLabel: UILabel!
  @IBOutlet weak var tierLabel: UILabel!
  @IBOutlet weak var realizedPointLabel: UILabel!
  @IBOutlet weak var pendingVolTitleLabel: UILabel!
  @IBOutlet weak var confirmVolTitleLabel: UILabel!
  
  
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
    self.walletListButton.setTitle(self.viewModel.displayWalletString, for: .normal)
    self.introLabel.attributedText = self.viewModel.displayIntroAttributedString
    self.cashbackPendingVolLabel.text = self.viewModel.displayCashbackPendingVol
    self.cashbackConfirmedVolLabel.text = self.viewModel.displayCashbackConfirmedVol
    self.totalPendingVolLabel.text = self.viewModel.displayTotalPendingVol
    self.totalConfirmedVolLabel.text = self.viewModel.displayTotalConfirmedVol
    self.tierLabel.text = self.viewModel.displayTier
    self.realizedPointLabel.text = self.viewModel.displayRealizedPoint
    self.pendingVolTitleLabel.text = "Pending\nVol. (\(KNGeneralProvider.shared.quoteToken))"
    self.confirmVolTitleLabel.text = "Confirmed\nVol. (\(KNGeneralProvider.shared.quoteToken))"
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
    self.navigationController?.showBottomBannerView(message: "Ask your friend to download Krystal app using your Referral Code. If they start using Krystal, We will automatically map the referral to you. You will earn rewards every time your friends transact via Krystal app.", icon: UIImage(named: "info_waring_blue_icon")!, time: 10, tapHandler: {
      self.openSafari(with: "https://support.krystal.app/support/solutions/articles/47001181546-referral-program")
    })
  }
  
  @IBAction func claimRewardButtonTapped(_ sender: UIButton) {
    guard let unwrapped = self.viewModel.overview else {
      return
    }
//    self.delegate?.krytalViewController(self, run: .claim(amount: unwrapped.claimablePoint))
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

extension KrytalViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let viewModel = self.viewModel.displayReferralCodes[indexPath.row]
    self.delegate?.krytalViewController(self, run: .openShareCode(refCode: viewModel.referralCode, codeObject: viewModel.codeObject))
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

    let text = "Here's my referral code \(code) to earn bonus rewards on the Krystal app! Use the code when connecting your wallet in the app. Details: https://krystal.app"
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.view
    self.navigationController?.present(activitiy, animated: true, completion: nil)
  }
}
