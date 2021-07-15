//
//  ShareReferralLinkViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/19/21.
//

import UIKit
import MBProgressHUD

struct ShareReferralLinkViewModel {
  let refCode: String
  let codeObject: Code
  
  var displayRatioString: String {
    let left = self.codeObject.ratio * 100 / 10000
    let right = 100 - left
    return "You receive \(left)%/ Friend receive \(right)%"
  }
}

class ShareReferralLinkViewController: UIViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var okButton: UIButton!
  @IBOutlet weak var ratioLabel: UILabel!
  @IBOutlet weak var refCodeLabel: UILabel!
  
  let viewModel: ShareReferralLinkViewModel
  
  init(viewModel: ShareReferralLinkViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ShareReferralLinkViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  let transitor = TransitionDelegate()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.okButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)
    self.ratioLabel.text = self.viewModel.displayRatioString
    self.refCodeLabel.text = self.viewModel.refCode
  }


  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func refCodeAreaTapped(_ sender: UIButton) {
    UIPasteboard.general.string = self.viewModel.refCode
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func okButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func shareTwitterButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func shareDircordButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func shareButtonTapped(_ sender: UIButton) {
    let text = "Here's my referral code \(self.viewModel.refCode) to earn bonus rewards on the Krystal app! Use the code when connecting your wallet in the app. Details: https://krystal.app"
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.view
    self.present(activitiy, animated: true, completion: nil)
  }
}

extension ShareReferralLinkViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 300
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
