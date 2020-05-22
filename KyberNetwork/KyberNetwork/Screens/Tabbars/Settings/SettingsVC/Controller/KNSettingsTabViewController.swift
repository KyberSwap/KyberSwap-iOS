// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSettingsTabViewEvent {
  case manageWallet
  case manageAlerts
  case alertMethods
  case contact
  case support
  case changePIN
  case about
  case community
  case shareWithFriends
  case telegram
  case telegramDev
  case github
  case twitter
  case facebook
  case medium
  case reddit
  case linkedIn
  case reportBugs
  case rateOurApp
  case liveChat
}

protocol KNSettingsTabViewControllerDelegate: class {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent)
}

class KNSettingsTabViewController: KNBaseViewController {

  weak var delegate: KNSettingsTabViewControllerDelegate?

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var manageAlerts: UIButton!
  @IBOutlet weak var alertMethodsButton: UIButton!
  @IBOutlet weak var contactButton: UIButton!
  @IBOutlet weak var supportButton: UIButton!
  @IBOutlet weak var changePINButton: UIButton!
  @IBOutlet weak var aboutButton: UIButton!
  @IBOutlet weak var community: UIButton!
  @IBOutlet weak var shareWithFriendsButton: UIButton!
  @IBOutlet weak var reportBugsButton: UIButton!
  @IBOutlet weak var rateOurAppButton: UIButton!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var liveChatButton: UIButton!
  @IBOutlet weak var unreadBadgeLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = NSLocalizedString("settings", value: "Settings", comment: "")
    self.manageWalletButton.setTitle(
      NSLocalizedString("manage.wallet", value: "Manage Wallet", comment: ""),
      for: .normal
    )
    self.manageWalletButton.addTextSpacing()
    self.manageAlerts.setTitle(NSLocalizedString("Manage Alert", comment: ""), for: .normal)
    self.manageAlerts.addTextSpacing()
    self.manageAlerts.isHidden = !KNAppTracker.isPriceAlertEnabled
    self.alertMethodsButton.setTitle(NSLocalizedString("Alert Method", comment: ""), for: .normal)
    self.alertMethodsButton.addTextSpacing()
    self.alertMethodsButton.isHidden = !KNAppTracker.isPriceAlertEnabled
    self.contactButton.setTitle(
      NSLocalizedString("contact", value: "Contact", comment: ""),
      for: .normal
    )
    self.contactButton.addTextSpacing()
    self.supportButton.setTitle(
      NSLocalizedString("support", value: "Support", comment: ""),
      for: .normal
    )
    self.supportButton.addTextSpacing()
    self.changePINButton.setTitle(
      NSLocalizedString("change.pin", value: "Change PIN", comment: ""),
      for: .normal
    )
    self.changePINButton.addTextSpacing()
    self.aboutButton.setTitle(
      NSLocalizedString("Get Started", value: "Get Started", comment: ""),
      for: .normal
    )
    self.aboutButton.addTextSpacing()
    self.community.setTitle(
      NSLocalizedString("community", value: "Community", comment: ""),
      for: .normal
    )
    self.community.addTextSpacing()
    self.shareWithFriendsButton.setTitle(
      NSLocalizedString("share.with.friends", value: "Share with friends", comment: ""),
      for: .normal
    )
    self.reportBugsButton.setTitle(
      NSLocalizedString("report.bugs", value: "Report Bugs", comment: ""),
      for: .normal
    )
    self.rateOurAppButton.setTitle(
      NSLocalizedString("rate.our.app", value: "Rate our App", comment: ""),
      for: .normal
    )
    self.shareWithFriendsButton.addTextSpacing()
    var version = Bundle.main.versionNumber ?? ""
    version += " - \(Bundle.main.buildNumber ?? "")"
    version += " - \(KNEnvironment.default.displayName)"
    self.versionLabel.text = "\(NSLocalizedString("version", value: "Version", comment: "")) \(version)"

    self.unreadBadgeLabel.rounded(color: .white, width: 1, radius: self.unreadBadgeLabel.frame.height / 2)

    NotificationCenter.default.addObserver(self, selector: #selector(self.methodOfReceivedNotification(notification:)), name: Notification.Name(FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED), object: nil)
  }

  deinit {
    let name = Notification.Name(FRESHCHAT_UNREAD_MESSAGE_COUNT_CHANGED)
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.checkUnreadMessage()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func manageWalletButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .manageWallet)
  }

  @IBAction func manageAlertsButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .manageAlerts)
  }

  @IBAction func notificationsButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .alertMethods)
  }

  @IBAction func contactButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .contact)
  }

  @IBAction func supportButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .support)
  }

  @IBAction func changePasscodeButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .changePIN)
  }

  @IBAction func aboutButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .about)
  }

  @IBAction func communityButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .community)
  }

  @IBAction func shareWithFriendButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .shareWithFriends)
  }

  @IBAction func telegramButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegram)
  }

  @IBAction func telegramDevButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .telegramDev)
  }

  @IBAction func githubButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .github)
  }

  @IBAction func twitterButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .twitter)
  }

  @IBAction func facebookButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .facebook)
  }

  @IBAction func mediumButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .medium)
  }

  @IBAction func linkedInButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .linkedIn)
  }

  @IBAction func reportBugsButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .reportBugs)
  }

  @IBAction func rateOurAppButtonPressed(_ sender: Any) {
    self.delegate?.settingsTabViewController(self, run: .rateOurApp)
  }

  @IBAction func liveChatButtonPressed(_ sender: UIButton) {
    self.delegate?.settingsTabViewController(self, run: .liveChat)
  }

  fileprivate func checkUnreadMessage() {
    Freshchat.sharedInstance().unreadCount { (num: Int) -> Void in
      if num > 0 {
        self.unreadBadgeLabel.isHidden = false
        self.unreadBadgeLabel.text = num.description
        self.navigationController?.tabBarItem.badgeValue = num.description
      } else {
        self.unreadBadgeLabel.isHidden = true
        self.navigationController?.tabBarItem.badgeValue = nil
      }
    }
  }

  @objc func methodOfReceivedNotification(notification: Notification) {
    self.checkUnreadMessage()
  }
}
