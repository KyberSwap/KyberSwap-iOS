// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNManageAlertsViewEvent {
  case back
  case addNewAlert
  case alertMethod
  case leaderBoard
}

protocol KNManageAlertsViewControllerDelegate: class {
  func manageAlertsViewController(_ viewController: KNManageAlertsViewController, run event: KNManageAlertsViewEvent)
  func manageAlertsViewController(_ viewController: KNManageAlertsViewController, run event: KNAlertTableViewEvent)
}

class KNManageAlertsViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var alertTableView: KNAlertTableView!
  @IBOutlet weak var bottomPaddingConstraintForAlertTableView: NSLayoutConstraint!

  @IBOutlet weak var emptyStateContainerView: UIView!
  @IBOutlet weak var emptyAlertDescLabel: UILabel!
  @IBOutlet weak var addAlertButton: UIButton!

  lazy var refreshControl: UIRefreshControl = {
    let refresh = UIRefreshControl()
    refresh.tintColor = UIColor.Kyber.enygold
    return refresh
  }()

  weak var delegate: KNManageAlertsViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.addAlertButton.applyGradient()

    let alerts = KNAlertStorage.shared.alerts
    self.alertTableView.delegate = self
    self.alertTableView.updateView(
      with: alerts,
      isFull: true
    )
    self.alertTableView.updateScrolling(isEnabled: true)
    self.navTitleLabel.text = NSLocalizedString("Manage Alert", comment: "")
    self.emptyAlertDescLabel.text = NSLocalizedString("We will send you notifications when prices go above or below your targets", comment: "")

    self.alertTableView.isHidden = alerts.isEmpty
    self.emptyStateContainerView.isHidden = !alerts.isEmpty
    self.addAlertButton.rounded(radius: KNAppStyleType.current.buttonRadius())
    self.addAlertButton.applyGradient()
    self.addAlertButton.setTitle(
      NSLocalizedString("Add Alert", comment: ""),
      for: .normal
    )

    self.alertTableView.alertTableView.refreshControl = self.refreshControl
    self.refreshControl.addTarget(self, action: #selector(self.userDidRefreshBalanceView(_:)), for: .valueChanged)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if IEOUserStorage.shared.user == nil {
      self.delegate?.manageAlertsViewController(self, run: .back)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.bottomPaddingConstraintForAlertTableView.constant = self.bottomPaddingSafeArea()
    let alerts = KNAlertStorage.shared.alerts
    self.alertTableView.updateView(with: alerts, isFull: true)
    self.emptyStateContainerView.isHidden = !alerts.isEmpty
    self.alertTableView.isHidden = alerts.isEmpty
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.addAlertButton.removeSublayer(at: 0)
    self.addAlertButton.applyGradient()
  }

  @objc func userDidRefreshBalanceView(_ sender: Any?) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    KNPriceAlertCoordinator.shared.loadListPriceAlerts(accessToken) { [weak self] (_, error) in
      self?.refreshControl.endRefreshing()
      if let err = error {
        self?.showWarningTopBannerMessage(with: NSLocalizedString("error", comment: ""), message: err)
      }
    }
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "manage_alert_edge_pan_back", customAttributes: nil)
      self.delegate?.manageAlertsViewController(self, run: .back)
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_alert_back_button_tapped", customAttributes: nil)
    self.delegate?.manageAlertsViewController(self, run: .back)
  }

  @IBAction func addAlertButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "manage_alert_add_alert_button_tapped", customAttributes: nil)
    self.delegate?.manageAlertsViewController(self, run: .addNewAlert)
  }

  @IBAction func alertMethodButtonPressed(_ sender: Any) {
    self.delegate?.manageAlertsViewController(self, run: .alertMethod)
  }

  @IBAction func alertLeaderBoardButtonPressed(_ sender: Any) {
    self.delegate?.manageAlertsViewController(self, run: .leaderBoard)
  }
}

extension KNManageAlertsViewController: KNAlertTableViewDelegate {
  func alertTableView(_ tableView: UITableView, run event: KNAlertTableViewEvent) {
    switch event {
    case .update:
      let alerts = KNAlertStorage.shared.alerts
      self.emptyStateContainerView.isHidden = !alerts.isEmpty
      self.alertTableView.isHidden = alerts.isEmpty
    default:
      self.delegate?.manageAlertsViewController(self, run: event)
    }
  }
}
