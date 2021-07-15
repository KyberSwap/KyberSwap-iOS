// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNPrettyAlertController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!

  let mainTitle: String?
  let isWarning: Bool
  let message: String
  let secondButtonTitle: String?
  let firstButtonTitle: String
  let secondButtonAction:  (() -> Void)?
  let firstButtonAction: (() -> Void)?
  var gradientButton: UIButton!
  let transitor = TransitionDelegate()
  
  init(title: String?,
       isWarning: Bool = false,
       message: String,
       secondButtonTitle: String?,
       firstButtonTitle: String = "cancel".toBeLocalised(),
       secondButtonAction: (() -> Void)?,
       firstButtonAction: (() -> Void)?) {
    self.mainTitle = title
    self.isWarning = isWarning
    self.message = message
    self.secondButtonTitle = secondButtonTitle
    self.firstButtonTitle = firstButtonTitle
    self.secondButtonAction = secondButtonAction
    self.firstButtonAction = firstButtonAction
    super.init(nibName: KNPrettyAlertController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded()
    self.secondButton.rounded(radius: 16)
    self.firstButton.rounded(radius: 16)
    if let titleTxt = self.mainTitle {
      if self.isWarning {
        let fullString = NSMutableAttributedString()
        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: "warning_yellow_icon")
        let image1String = NSAttributedString(attachment: image1Attachment)
        fullString.append(image1String)
        fullString.append(NSAttributedString(string: " " + titleTxt))
        self.titleLabel.attributedText = fullString
      } else {
        self.titleLabel.text = titleTxt
      }
      
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
    self.gradientButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
    self.gradientButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
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

extension KNPrettyAlertController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 300
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
