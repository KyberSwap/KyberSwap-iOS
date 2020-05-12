// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPrettyAlertController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var containerView: UIView!

  let mainTitle: String?
  let message: String
  let yesTitle: String?
  let noTitle: String
  let yesAction:  (() -> Void)?
  let noAction: (() -> Void)?
  init(title: String?,
       message: String,
       yesTitle: String?,
       noTitle: String = "cancel".toBeLocalised(),
       yesAction: (() -> Void)?,
       noAction: (() -> Void)?) {
    self.mainTitle = title
    self.message = message
    self.yesTitle = yesTitle
    self.noTitle = noTitle
    self.yesAction = yesAction
    self.noAction = noAction
    super.init(nibName: KNPrettyAlertController.className, bundle: nil)
    self.modalTransitionStyle = .crossDissolve
    self.modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded()
    self.yesButton.rounded()
    self.noButton.rounded(color: UIColor.Kyber.border, width: 1)
    if let titleTxt = self.mainTitle {
      self.titleLabel.text = titleTxt
    } else {
      self.titleLabel.removeFromSuperview()
      let messageTopContraint = NSLayoutConstraint(item: self.contentLabel, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 33)
      self.containerView.addConstraint(messageTopContraint)
    }
    self.contentLabel.text = message
    self.noButton.setTitle(noTitle, for: .normal)
    if let yesTxt = self.yesTitle {
      self.yesButton.setTitle(yesTxt, for: .normal)
    } else {
      self.yesButton.removeFromSuperview()
      let noButtonTrailingContraint = NSLayoutConstraint(item: self.noButton, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: -36)
      self.containerView.addConstraint(noButtonTrailingContraint)
      self.noButton.rounded()
      self.noButton.backgroundColor = UIColor.Kyber.orange
      self.noButton.setTitleColor(.white, for: .normal)
    }
    self.containerView.layoutIfNeeded()
  }

  @IBAction func yesButtonTapped(_ sender: UIButton) {
    if let action = self.yesAction {
      action()
    }
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func noButtonTapped(_ sender: UIButton) {
    if let action = self.noAction {
      action()
    }
    self.dismiss(animated: true, completion: nil)
  }
}
