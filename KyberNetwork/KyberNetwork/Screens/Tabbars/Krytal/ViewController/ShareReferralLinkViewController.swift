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
    self.okButton.rounded(radius: self.okButton.frame.size.height / 2)
    self.okButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.cancelButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.cancelButton.frame.size.height / 2)
    self.ratioLabel.text = self.viewModel.displayRatioString
    self.refCodeLabel.text = self.viewModel.refCode
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.okButton.removeSublayer(at: 0)
    self.okButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
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
