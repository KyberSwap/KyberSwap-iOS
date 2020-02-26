// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import TrustCore

enum KNProfileHomeViewEvent {
  case logOut
  case addPriceAlert
  case managePriceAlerts
  case editAlert(alert: KNAlertObject)
  case leaderBoard
}

enum KNSignInViewEvent {
  case signInWithEmail(email: String, password: String)
  case signInWithFacebook
  case signInWithGoogle
  case signInWithTwitter
  case forgotPassword
  case dontHaveAccountSignUp
}

class KNSignInViewModel {
  var isSecureText: Bool = true

  var dontHaveAccountAttributedText: NSAttributedString = {
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 90, green: 94, blue: 103),
    ]
    let orangeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.foregroundColor: UIColor(red: 254, green: 163, blue: 76),
    ]
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: "Don't have an account? ".toBeLocalised(), attributes: normalAttributes))
    attributedText.append(NSAttributedString(string: "Sign Up Now".toBeLocalised(), attributes: orangeAttributes)
    )
    return attributedText
  }()
}

protocol KNProfileHomeViewControllerDelegate: class {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent)
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNSignInViewEvent)
}

class KNProfileHomeViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var notSignInView: UIView!

  // Not Sign in view
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var notSignInNavTitle: UILabel!
  @IBOutlet weak var orTextLabel: UILabel!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet weak var passwordTextField: UITextField!
  @IBOutlet weak var forgotPassButton: UIButton!
  @IBOutlet weak var secureTextButton: UIButton!
  @IBOutlet weak var dontHaveAnAccountButton: UIButton!
  @IBOutlet weak var signInButton: UIButton!

  @IBOutlet weak var socialContainerView: UIView!
  @IBOutlet weak var userImageView: UIImageView!
  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var userEmailLabel: UILabel!
  @IBOutlet weak var signInHeaderView: UIView!
  @IBOutlet weak var signedInView: UIView!
  @IBOutlet weak var logOutButton: UIButton!
  @IBOutlet weak var priceAlertContainerView: UIView!
  @IBOutlet weak var priceAlertsTextLabel: UILabel!
  @IBOutlet weak var noPriceAlertContainerView: UIView!
  @IBOutlet weak var noPriceAlertMessageLabel: UILabel!
  @IBOutlet weak var listPriceAlertsContainerView: UIView!
  @IBOutlet weak var priceAlertTableView: KNAlertTableView!
  @IBOutlet weak var moreAlertsButton: UIButton!
  @IBOutlet weak var priceAlertContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var listPriceAlertsContainerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var priceAlertTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var bottomPaddingConstraintForSignedInView: NSLayoutConstraint!

  weak var delegate: KNProfileHomeViewControllerDelegate?
  fileprivate var viewModel: KNProfileHomeViewModel
  fileprivate let signInViewModel: KNSignInViewModel

  fileprivate let appStyle = KNAppStyleType.current

  fileprivate var isViewSetup: Bool = false

  init(viewModel: KNProfileHomeViewModel) {
    self.viewModel = viewModel
    self.signInViewModel = KNSignInViewModel()
    super.init(nibName: KNProfileHomeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.signInHeaderView.applyGradient(with: UIColor.Kyber.headerColors)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
    self.updateUIUserDidSignedIn()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.signInHeaderView.removeSublayer(at: 0)
    self.signInHeaderView.applyGradient(with: UIColor.Kyber.headerColors)

    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.signInButton.removeSublayer(at: 0)
    self.signInButton.applyGradient()
  }

  fileprivate func setupUI() {
    self.navTitleLabel.text = NSLocalizedString("profile", value: "Profile", comment: "")
    self.navTitleLabel.addLetterSpacing()
    self.setupNotSignInView()
    self.setupUserSignedInView()
  }

  fileprivate func setupNotSignInView() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.socialContainerView.rounded(radius: self.socialContainerView.frame.height / 2.0)
    self.signInButton.applyGradient()
    self.notSignInNavTitle.text = NSLocalizedString("sign.in", value: "Sign In", comment: "")
    self.orTextLabel.text = "Or sign in with".toBeLocalised()
    self.signInButton.setTitle(NSLocalizedString("sign.in", value: "Sign In", comment: ""), for: .normal)
    self.signInButton.rounded(radius: KNAppStyleType.current.buttonRadius(for: self.signInButton.frame.height))
    self.emailTextField.placeholder = "Email Address".toBeLocalised()
    self.passwordTextField.placeholder = "Password".toBeLocalised()
    self.forgotPassButton.setTitle("Forgot Password?".toBeLocalised(), for: .normal)
    self.dontHaveAnAccountButton.setAttributedTitle(self.signInViewModel.dontHaveAccountAttributedText, for: .normal)
    self.passwordTextField.isSecureTextEntry = self.signInViewModel.isSecureText
    let image = !self.signInViewModel.isSecureText ? UIImage(named: "hide_secure_text") : UIImage(named: "show_secure_text")
    self.secureTextButton.setImage(image, for: .normal)
    self.signInButton.rounded(
      radius: self.appStyle.buttonRadius(for: self.signInButton.frame.height)
    )
    self.signInButton.setTitle(
      NSLocalizedString("sign.in", value: "Sign In", comment: ""),
      for: .normal
    )
    self.signInButton.addTextSpacing()
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.view.layoutSubviews()
  }

  fileprivate func setupUserSignedInView() {
    self.signInHeaderView.applyGradient(with: UIColor.Kyber.headerColors)
    self.bottomPaddingConstraintForSignedInView.constant = self.bottomPaddingSafeArea()
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
    self.logOutButton.setTitle(NSLocalizedString("log.out", value: "Log Out", comment: ""), for: .normal)
    self.logOutButton.addTextSpacing()
    self.userImageView.rounded(
      color: UIColor.Kyber.border,
      width: 0.5,
      radius: self.userImageView.frame.height / 2.0
    )
    self.setupPriceAlertsView()
    self.updateUIUserDidSignedIn()
    self.view.layoutSubviews()
  }

  fileprivate func setupPriceAlertsView() {
    self.priceAlertsTextLabel.text = NSLocalizedString("Price Alerts", value: "Price Alerts", comment: "").uppercased()
    self.noPriceAlertMessageLabel.text = NSLocalizedString("We will send you notifications when prices go above or below your targets", value: "We will send you notifications when prices go above or below your targets", comment: "")
    self.moreAlertsButton.setTitle(
      NSLocalizedString("More Alerts", value: "More Alerts", comment: ""),
      for: .normal
    )
    self.priceAlertTableView.delegate = self
    self.priceAlertTableView.updateView(with: KNAlertStorage.shared.alerts, isFull: false)
    self.priceAlertTableView.updateScrolling(isEnabled: false)
  }

  fileprivate func updatePriceAlertsView(tableViewHeight: CGFloat) {
    if tableViewHeight == 0.0 {
      // no alerts
      self.listPriceAlertsContainerView.isHidden = true
      self.noPriceAlertContainerView.isHidden = false
      self.priceAlertContainerViewHeightConstraint.constant = 160.0
    } else {
      self.listPriceAlertsContainerView.isHidden = false
      self.noPriceAlertContainerView.isHidden = true
      // section height + table height + moreAlerts button height
      self.priceAlertContainerViewHeightConstraint.constant = 60.0 + tableViewHeight + 56.0
      self.priceAlertTableViewHeightConstraint.constant = tableViewHeight
      self.listPriceAlertsContainerViewHeightConstraint.constant = tableViewHeight + 56.0
    }
    self.moreAlertsButton.backgroundColor = KNAlertStorage.shared.alerts.count == 1 ? UIColor(red: 246, green: 247, blue: 250) : UIColor(red: 242, green: 243, blue: 246)
    self.updateViewConstraints()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateUIUserDidSignedIn() {
    guard let user = self.viewModel.currentUser else { return }
    let url: String = {
      if user.avatarURL.starts(with: "http") { return user.avatarURL }
      return "\(KNAppTracker.getKyberProfileBaseString())\(user.avatarURL)"
    }()
    self.emailTextField.text = ""
    self.passwordTextField.text = ""
    self.signInHeaderView.removeSublayer(at: 0)
    self.signInHeaderView.applyGradient(with: UIColor.Kyber.headerColors)
    self.priceAlertTableView.updateView(
      with: KNAlertStorage.shared.alerts,
      isFull: false
    )
    self.userImageView.setImage(
      with: url,
      placeholder: UIImage(named: "account"),
      size: nil
    )
    self.userNameLabel.text = user.name
    self.userNameLabel.addLetterSpacing()
    self.userEmailLabel.text = user.contactID
    self.userEmailLabel.addLetterSpacing()
  }

  @IBAction func forgotButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.delegate?.profileHomeViewController(self, run: .forgotPassword)
  }

  @IBAction func facebookButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNAppTracker.saveLastTimeAuthenticate()
    self.delegate?.profileHomeViewController(self, run: .signInWithFacebook)
  }

  @IBAction func googleButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNAppTracker.saveLastTimeAuthenticate()
    self.delegate?.profileHomeViewController(self, run: .signInWithGoogle)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    KNAppTracker.saveLastTimeAuthenticate()
    self.delegate?.profileHomeViewController(self, run: .signInWithTwitter)
  }

  @IBAction func secureTextButtonPressed(_ sender: Any) {
    self.signInViewModel.isSecureText = !self.signInViewModel.isSecureText
    self.passwordTextField.isSecureTextEntry = self.signInViewModel.isSecureText
    let image = !self.signInViewModel.isSecureText ? UIImage(named: "hide_secure_text") : UIImage(named: "show_secure_text")
    self.secureTextButton.setImage(image, for: .normal)
  }

  @IBAction func signInButtonPressed(_ sender: Any) {
    let email = self.emailTextField.text ?? ""
    let pass = self.passwordTextField.text ?? ""
    guard email.isValidEmail() else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Please enter a valid email address to continue".toBeLocalised(),
        time: 2.0
      )
      return
    }
    guard !pass.isEmpty else {
      self.showErrorTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: "Please enter a password to continue".toBeLocalised(),
        time: 2.0
      )
      return
    }
    self.view.endEditing(true)
    self.delegate?.profileHomeViewController(self, run: .signInWithEmail(email: email, password: pass))
  }

  @IBAction func dontHaveAccountButtonPressed(_ sender: Any) {
    self.view.endEditing(true)
    self.delegate?.profileHomeViewController(self, run: .dontHaveAccountSignUp)
  }

  @IBAction func logOutButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "sign_out_button_pressed"])
    self.delegate?.profileHomeViewController(self, run: .logOut)
  }

  @IBAction func addPriceAlertButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "add_alert"])
    self.delegate?.profileHomeViewController(self, run: .addPriceAlert)
  }

  @IBAction func moreAlertsButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "more_alerts"])
    self.delegate?.profileHomeViewController(self, run: .managePriceAlerts)
  }

  @IBAction func leaderBoardButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "leader_board"])
    self.delegate?.profileHomeViewController(self, run: .leaderBoard)
  }
}

extension KNProfileHomeViewController {
  func coordinatorUserDidSignInSuccessfully(isFirstTime: Bool = false) {
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
    self.updateUIUserDidSignedIn()
  }

  func coordinatorDidSignOut() {
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
  }
}

extension KNProfileHomeViewController: KNAlertTableViewDelegate {
  func alertTableView(_ tableView: UITableView, run event: KNAlertTableViewEvent) {
    switch event {
    case .update(let height):
      self.updatePriceAlertsView(tableViewHeight: height)
    case .delete(let alert):
      let warningMessage = NSLocalizedString(
        "This alert is eligible for a reward from the current competition. Do you still want to delete?",
        value: "This alert is eligible for a reward from the current competition. Do you still want to delete?",
        comment: ""
      )
      let normalMessage = NSLocalizedString("Do you want to delete this alert?", value: "Do you want to delete this alert?", comment: "")
      let message = alert.hasReward ? warningMessage : normalMessage
      let alertController = UIAlertController(title: NSLocalizedString("delete", value: "Delete", comment: ""), message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
      alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
        self.deleteAnAlert(alert)
      }))
      self.present(alertController, animated: true, completion: nil)
    case .edit(let alert):
      self.delegate?.profileHomeViewController(self, run: .editAlert(alert: alert))
    case .select(let alert):
      self.delegate?.profileHomeViewController(self, run: .editAlert(alert: alert))
    case .deleteAll:
      break
    }
  }

  fileprivate func deleteAnAlert(_ alert: KNAlertObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "delete_alert"])
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.displayLoading()
    KNPriceAlertCoordinator.shared.removeAnAlert(accessToken: accessToken, alertID: alert.id) { [weak self] (_, error) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let error = error {
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_profile_kyc", customAttributes: ["action": "delete_alert_failed", "error": error])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error,
          time: 1.5
        )
      } else {
        self.showSuccessTopBannerMessage(
          with: "",
          message: NSLocalizedString("Alert deleted!", value: "Alert deleted!", comment: ""),
          time: 1.0
        )
      }
    }
  }
}
