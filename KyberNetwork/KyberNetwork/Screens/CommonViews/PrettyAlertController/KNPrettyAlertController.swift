// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPrettyAlertController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var containerView: UIView!

  let mainTitle: String?
  let message: String
  let yesTitle: String?
  let noTitle: String
  let secondButtonAction:  (() -> Void)?
  let firstButtonAction: (() -> Void)?
  init(title: String?,
       message: String,
       secondButtonTitle: String?,
       firstButtonTitle: String = "cancel".toBeLocalised(),
       secondButtonAction: (() -> Void)?,
       firstButtonAction: (() -> Void)?) {
    self.mainTitle = title
    self.message = message
    self.yesTitle = secondButtonTitle
    self.noTitle = firstButtonTitle
    self.secondButtonAction = secondButtonAction
    self.firstButtonAction = firstButtonAction
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
    self.secondButton.rounded()
    self.firstButton.rounded(color: UIColor.Kyber.border, width: 1)
    if let titleTxt = self.mainTitle {
      self.titleLabel.text = titleTxt
    } else {
      self.titleLabel.removeFromSuperview()
      let messageTopContraint = NSLayoutConstraint(item: self.contentLabel, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 33)
      self.containerView.addConstraint(messageTopContraint)
    }
    self.contentLabel.text = message
    self.firstButton.setTitle(noTitle, for: .normal)
    if let yesTxt = self.yesTitle {
      self.secondButton.setTitle(yesTxt, for: .normal)
    } else {
      self.secondButton.removeFromSuperview()
      let noButtonTrailingContraint = NSLayoutConstraint(item: self.firstButton, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: -36)
      self.containerView.addConstraint(noButtonTrailingContraint)
      self.firstButton.rounded()
      self.firstButton.backgroundColor = UIColor.Kyber.orange
      self.firstButton.setTitleColor(.white, for: .normal)
    }
    self.containerView.layoutIfNeeded()
  }

  @IBAction func yesButtonTapped(_ sender: UIButton) {
    if let action = self.secondButtonAction {
      action()
    }
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func noButtonTapped(_ sender: UIButton) {
    if let action = self.firstButtonAction {
      action()
    }
    self.dismiss(animated: true, completion: nil)
  }
}
