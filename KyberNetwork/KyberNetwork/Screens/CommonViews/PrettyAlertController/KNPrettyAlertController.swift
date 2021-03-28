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
  let secondButtonTitle: String?
  let firstButtonTitle: String
  let secondButtonAction:  (() -> Void)?
  let firstButtonAction: (() -> Void)?
  var gradientButton: UIButton!
  init(title: String?,
       message: String,
       secondButtonTitle: String?,
       firstButtonTitle: String = "cancel".toBeLocalised(),
       secondButtonAction: (() -> Void)?,
       firstButtonAction: (() -> Void)?) {
    self.mainTitle = title
    self.message = message
    self.secondButtonTitle = secondButtonTitle
    self.firstButtonTitle = firstButtonTitle
    self.secondButtonAction = secondButtonAction
    self.firstButtonAction = firstButtonAction
    super.init(nibName: KNPrettyAlertController.className, bundle: nil)
    DispatchQueue.main.async {
      self.modalTransitionStyle = .crossDissolve
      self.modalPresentationStyle = .overFullScreen
    }
    
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded()
    self.secondButton.rounded(radius: self.secondButton.frame.size.height / 2)
    self.firstButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.firstButton.frame.size.height / 2)
    if let titleTxt = self.mainTitle {
      self.titleLabel.text = titleTxt
    } else {
      self.titleLabel.removeFromSuperview()
      let messageTopContraint = NSLayoutConstraint(item: self.contentLabel, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 33)
      self.containerView.addConstraint(messageTopContraint)
    }
    self.contentLabel.text = message
    self.firstButton.setTitle(firstButtonTitle, for: .normal)
    if let yesTxt = self.secondButtonTitle {
      self.secondButton.setTitle(yesTxt, for: .normal)
      self.gradientButton = self.secondButton
    } else {
      self.secondButton.removeFromSuperview()
      let noButtonTrailingContraint = NSLayoutConstraint(item: self.firstButton, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: -36)
      self.containerView.addConstraint(noButtonTrailingContraint)
      self.firstButton.rounded()
      self.firstButton.backgroundColor = UIColor.Kyber.orange
      self.firstButton.setTitleColor(.white, for: .normal)
      self.gradientButton = firstButton
    }
    self.gradientButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.gradientButton.removeSublayer(at: 0)
    self.gradientButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
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
