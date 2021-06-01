//
//  ClaimRewardViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/5/21.
//

import UIKit

struct ClaimRewardViewModel {
  let claimablePoint: Int

  var displayClaimablePoint: String {
    return "\(self.claimablePoint) KP"
  }
  
  var displayValue: String {
    guard let rate = KNTrackerRateStorage.shared.getETHPrice() else { return "---" }
    let ethAmount: Double = Double(self.claimablePoint) / 10000.0
    return "$\(ethAmount * rate.usd)"
  }
}

protocol ClaimRewardViewControllerDelegate: class {
  func claimRewardViewControllerDidClaim(_ controller: ClaimRewardViewController)
}

class ClaimRewardViewController: UIViewController {
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var usdAmountLabel: UILabel!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let viewModel: ClaimRewardViewModel
  weak var delegate: ClaimRewardViewControllerDelegate?
  
  init(viewModel: ClaimRewardViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ClaimRewardViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.secondButton.rounded(radius: self.secondButton.frame.size.height / 2)
    self.secondButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.firstButton.setTitle("Cancel".toBeLocalised(), for: .normal)
    self.secondButton.setTitle("Claim Reward".toBeLocalised(), for: .normal)
    self.secondButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
  }
  
  @IBAction func firstButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func secondButtonTapped(_ sender: UIButton) {
    self.delegate?.claimRewardViewControllerDidClaim(self)
  }
  
}
