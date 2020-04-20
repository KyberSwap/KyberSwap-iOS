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
    return self.isFirstTime ? NSLocalizedString("try.again", value: "Try Again", comment: "") : NSLocalizedString("retry", value: "Retry", comment: "")
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

  var secondButtonColor: UIColor {
    return KNAppStyleType.current.walletFlowHeaderColor
  }
}

class KNTestBackUpStatusViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!

  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!

  @IBOutlet weak var secondButtonWidthConstraint: NSLayoutConstraint!
  @IBOutlet weak var paddingConstraintForButtons: NSLayoutConstraint!

  fileprivate var viewModel: KNTestBackUpStatusViewModel
  weak var delegate: KNTestBackUpStatusViewControllerDelegate?

  init(viewModel: KNTestBackUpStatusViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTestBackUpStatusViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    let style = KNAppStyleType.current

    self.containerView.rounded(radius: 10.0)
    self.containerView.isHidden = self.viewModel.isContainerViewHidden

    self.titleLabel.text = self.viewModel.title
    self.titleLabel.addLetterSpacing()
    self.messageLabel.text = self.viewModel.message
    self.messageLabel.addLetterSpacing()

    self.firstButton.rounded(
      color: self.viewModel.firstButtonBorderColor,
      width: 1,
      radius: style.buttonRadius()
    )
    self.firstButton.setTitle(self.viewModel.firstButtonTitle, for: .normal)

    self.secondButton.rounded(radius: style.buttonRadius())
    self.secondButton.setTitle(self.viewModel.secondButtonTitle, for: .normal)
    self.secondButton.backgroundColor = self.viewModel.secondButtonColor

    if self.viewModel.numberButtons == 1 {
      self.secondButtonWidthConstraint.constant = 0
      self.paddingConstraintForButtons.constant = 0
      self.firstButton.applyGradient()
      self.firstButton.setTitleColor(.white, for: .normal)
    } else {
      self.paddingConstraintForButtons.constant = 16
      self.secondButtonWidthConstraint.constant = (self.containerView.frame.width - 48) / 2.0
      self.secondButton.applyGradient()
      self.firstButton.setTitleColor(UIColor.Kyber.mirage, for: .normal)
      self.secondButton.setTitleColor(.white, for: .normal)
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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if self.viewModel.numberButtons == 1 {
      self.firstButton.removeSublayer(at: 0)
      self.firstButton.applyGradient()
    } else {
      self.secondButton.removeSublayer(at: 0)
      self.secondButton.applyGradient()
    }
  }

  @IBAction func firstButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func secondButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.testBackUpStatusViewDidPressSecondButton(sender: self)
    }
  }
}
