// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNConfirmSignUpViewEvent {
  case back
  case confirmSignUp(accountType: KNSocialAccountsType, isSubscribe: Bool)
  case alreadyMemberSignIn
}

protocol KNConfirmSignUpViewControllerDelegate: class {
  func confirmSignUpViewController(_ controller: KNConfirmSignUpViewController, run event: KNConfirmSignUpViewEvent)
}

class KNConfirmSignUpViewModel {
  let accountType: KNSocialAccountsType
  var isSubscribe: Bool

  init(accountType: KNSocialAccountsType, isSubscribe: Bool = false) {
    self.isSubscribe = isSubscribe
    self.accountType = accountType
  }

  var socialImage: UIImage? {
    switch self.accountType {
    case .facebook: return UIImage(named: "social_facebook")
    case .twitter: return UIImage(named: "social_twitter")
    case .google: return UIImage(named: "social_google")
    case .apple: return UIImage(named: "siwa_icon")
    default: return nil
    }
  }

  var userIconURL: String {
    switch self.accountType {
    case .facebook(_, _, let icon, _): return icon
    case .twitter(_, _, let icon, _, _): return icon
    case .google(_, _, let icon, _): return icon
    default: return ""
    }
  }

  var userEmail: String {
    switch self.accountType {
    case .facebook(_, let email, _, _): return email
    case .twitter(_, let email, _, _, _): return email
    case .google(_, let email, _, _): return email
    case .normal(let email, _, _): return email
    case .apple(_, let email, _, _, _): return email ?? ""
    }
  }

  var userName: String {
    switch self.accountType {
    case .facebook(let name, _, _, _): return name
    case .twitter(let name, _, _, _, _): return name
    case .google(let name, _, _, _): return name
    case .normal(let name, _, _): return name
    case .apple(let name, _, _, _, _): return name
    }
  }

  var alreadyMemberAttributedText: NSAttributedString = {
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    ]
    let orangeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 254, green: 163, blue: 76),
    ]
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: "Already a member? ".toBeLocalised(), attributes: normalAttributes))
    attributedText.append(NSAttributedString(string: "Sign In", attributes: orangeAttributes)
    )
    return attributedText
  }()
}

class KNConfirmSignUpViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var topPaddingConfirmSignUpTextLabel: NSLayoutConstraint!
  @IBOutlet weak var confirmSignUpTextLabel: UILabel!
  @IBOutlet weak var socialIconImageView: UIImageView!
  @IBOutlet weak var userIconImageView: UIImageView!
  @IBOutlet weak var userEmailLabel: UILabel!
  @IBOutlet weak var userNameLabel: UILabel!

  @IBOutlet weak var separatorViews: UIView!

  @IBOutlet weak var subscribeNewsLettersButton: UIButton!
  @IBOutlet weak var subscribeButton: UIButton!

  @IBOutlet weak var signUpButton: UIButton!

  @IBOutlet weak var alreadyMemberSignInButton: UIButton!

  fileprivate let viewModel: KNConfirmSignUpViewModel
  weak var delegate: KNConfirmSignUpViewControllerDelegate?

  init(viewModel: KNConfirmSignUpViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNConfirmSignUpViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.topPaddingConfirmSignUpTextLabel.constant = (UIDevice.isIphone5 || UIDevice.isIphone6) ? 32.0 : 60.0
    self.separatorViews.backgroundColor = .clear
    self.separatorViews.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.socialIconImageView.image = self.viewModel.socialImage
    self.userIconImageView.setImage(with: self.viewModel.userIconURL, placeholder: UIImage(named: "account"))
    self.userIconImageView.rounded(radius: self.userIconImageView.frame.height / 2.0)
    self.userEmailLabel.text = self.viewModel.userEmail
    self.userNameLabel.text = self.viewModel.userName

    self.subscribeButton.setImage(self.viewModel.isSubscribe ? UIImage(named: "check_box_icon") : nil, for: .normal)
    self.subscribeButton.rounded(color: self.viewModel.isSubscribe ? UIColor.clear : UIColor.Kyber.border, width: 1.0, radius: 2.5)

    self.signUpButton.setTitle(NSLocalizedString("sign.up", value: "Sign Up", comment: ""), for: .normal)
    self.signUpButton.rounded(radius: KNAppStyleType.current.buttonRadius())
    self.signUpButton.applyGradient()

    self.alreadyMemberSignInButton.setAttributedTitle(
      self.viewModel.alreadyMemberAttributedText,
      for: .normal
    )
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.signUpButton.removeSublayer(at: 0)
    self.signUpButton.applyGradient()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.confirmSignUpViewController(self, run: .back)
  }

  @IBAction func subscribeButtonPressed(_ sender: Any) {
    self.viewModel.isSubscribe = !self.viewModel.isSubscribe
    self.subscribeButton.setImage(self.viewModel.isSubscribe ? UIImage(named: "check_box_icon") : nil, for: .normal)
    self.subscribeButton.rounded(color: self.viewModel.isSubscribe ? UIColor.clear : UIColor.Kyber.border, width: 1.0, radius: 2.5)
    self.view.layoutIfNeeded()
  }

  @IBAction func signUpButtonPressed(_ sender: Any) {
    let event = KNConfirmSignUpViewEvent.confirmSignUp(
      accountType: self.viewModel.accountType,
      isSubscribe: self.viewModel.isSubscribe
    )
    self.delegate?.confirmSignUpViewController(self, run: event)
  }

  @IBAction func alreadyMemberSignInButtonPressed(_ sender: Any) {
    self.delegate?.confirmSignUpViewController(self, run: .alreadyMemberSignIn)
  }
}
