// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTestBackUpStatusViewControllerDelegate: class {
  func testBackUpStatusViewDidPressSecondButton(sender: KNTestBackUpStatusViewController)
  func testBackUpStatusViewDidComplete(sender: KNTestBackUpStatusViewController)
}

struct KNTestBackUpStatusViewModel {
  let isSuccess: Bool
  let isFirstTime: Bool

  init(isFirstTime: Bool, isSuccess: Bool) {
    self.isFirstTime = isFirstTime
    self.isSuccess = isSuccess
  }

  var isContainerViewHidden: Bool {
    return self.isSuccess
  }

  var isSuccessViewHidden: Bool {
    return !self.isSuccess
  }

  var title: String {
    return self.isFirstTime ? NSLocalizedString("wrong.backup", comment: "") : NSLocalizedString("wrong.again", comment: "")
  }

  var message: String {
    return self.isFirstTime ? NSLocalizedString("your.backup.words.are.incorrect", comment: "") : NSLocalizedString("you.entered.the.wrong.backup.words.another.time", comment: "")
  }

  var numberButtons: Int {
    return self.isFirstTime ? 1 : 2
  }

  var firstButtonTitle: String {
    return NSLocalizedString("try.again", value: "Try Again", comment: "")
  }

  var firstButtonColor: UIColor {
    return self.isFirstTime ? KNAppStyleType.current.walletFlowHeaderColor : UIColor.clear
  }

  var firstButtonTitleColor: UIColor {
    return self.isFirstTime ? UIColor.white : UIColor(red: 20, green: 25, blue: 39)
  }

  var firstButtonBorderColor: UIColor {
    return self.isFirstTime ? UIColor.clear : UIColor.Kyber.border
  }

  var secondButtonTitle: String {
    return NSLocalizedString("backup.again", value: "Backup Again", comment: "")
  }
}

class KNTestBackUpStatusViewController: KNBaseViewController, BottomPopUpAbstract {

  @IBOutlet weak var containerView: UIView!

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!

  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!

  @IBOutlet weak var secondButtonWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var paddingConstraintForButtons: NSLayoutConstraint!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  let transitor = TransitionDelegate()

  fileprivate var viewModel: KNTestBackUpStatusViewModel
  weak var delegate: KNTestBackUpStatusViewControllerDelegate?

  init(viewModel: KNTestBackUpStatusViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTestBackUpStatusViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

    self.containerView.rounded(radius: 10.0)
    self.containerView.isHidden = self.viewModel.isContainerViewHidden

    self.titleLabel.text = self.viewModel.title
    self.titleLabel.addLetterSpacing()
    self.messageLabel.text = self.viewModel.message
    self.messageLabel.addLetterSpacing()

    if self.viewModel.numberButtons == 1 {
      self.secondButtonWidthConstraint.constant = 0
      self.paddingConstraintForButtons.constant = 0
      self.firstButton.rounded(radius: 16)
      self.firstButton.setTitle(self.viewModel.firstButtonTitle, for: .normal)
      self.firstButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
      self.firstButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
    } else {
      self.firstButton.rounded(color: UIColor.Kyber.SWButtonYellow, width: 1, radius: self.firstButton.frame.size.height / 2)
      self.firstButton.setTitle(self.viewModel.firstButtonTitle, for: .normal)
      self.secondButton.rounded(radius: 16)
      self.secondButton.setTitle(self.viewModel.secondButtonTitle, for: .normal)

      self.paddingConstraintForButtons.constant = 16
      self.secondButtonWidthConstraint.constant = (self.containerView.frame.width - 48) / 2.0
      
      self.secondButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
      self.secondButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
      
      self.firstButton.backgroundColor = UIColor(named: "navButtonBgColor")
      self.firstButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
      
      
    }
    self.view.updateConstraints()
    if self.viewModel.isSuccess {
      self.showSuccessTopBannerMessage(
        with: "",
        message: NSLocalizedString("you.have.successfully.backed.up.your.wallet", value: "You have successfully backed up your wallet", comment: ""),
        time: 1.5
      )
      Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] _ in
        guard let `self` = self else { return }
        self.dismiss(animated: true) {
          self.delegate?.testBackUpStatusViewDidComplete(sender: self)
        }
      })
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
  }

  @IBAction func firstButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func secondButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.testBackUpStatusViewDidPressSecondButton(sender: self)
    }
  }

  @IBAction func tapOutSidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }

  // MARK: BottomPopUpAbstract
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 294
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}
