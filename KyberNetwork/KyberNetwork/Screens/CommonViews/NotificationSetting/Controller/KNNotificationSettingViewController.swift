// Copyright SIX DAY LLC. All rights reserved.

import UIKit
protocol KNNotificationSettingViewControllerDelegate: class {
  func notificationSettingViewControllerDidApply(_ controller: KNNotificationSettingViewController)
}

class KNNotificationSettingViewController: KNBaseViewController {
  fileprivate var viewModel: KNNotificationSettingViewModel
  fileprivate let kFilterTokensTableViewCellID: String = "kFilterTokensTableViewCellID"
  @IBOutlet var separatorViews: [UIView]!
  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var applyButton: UIButton!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var tokensViewActionButton: UIButton!
  @IBOutlet weak var tokensTableView: UITableView!
  @IBOutlet weak var tokensTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var tokenTextLabel: UILabel!
  @IBOutlet weak var enableSubcribeTokenTextLabel: UILabel!
  @IBOutlet weak var subcribeTokenSwitch: UISwitch!
  @IBOutlet var formViews: [UIView]!
  @IBOutlet weak var tokensViewActionButtonHeight: NSLayoutConstraint!
  weak var delegate: KNNotificationSettingViewControllerDelegate?

  init(viewModel: KNNotificationSettingViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNNotificationSettingViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tokenTextLabel.text = "Token".toBeLocalised()
    self.enableSubcribeTokenTextLabel.text = "Price Trending Notification".toBeLocalised()
    self.subcribeTokenSwitch.tintColor = UIColor.Kyber.orange
    self.subcribeTokenSwitch.onTintColor = UIColor.Kyber.orange
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = "Notification Setting".toBeLocalised()
    self.separatorViews.forEach({ $0.backgroundColor = .clear })
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
    self.resetButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 5
    )
    self.resetButton.setTitle("Reset".toBeLocalised(), for: .normal)
    self.applyButton.applyGradient()
    self.applyButton.setTitle(NSLocalizedString("apply", value: "Apply", comment: ""), for: .normal)
    self.applyButton.rounded(radius: 5)

    let nib = UINib(nibName: KNTransactionFilterTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: kFilterTokensTableViewCellID)
    self.tokensTableView.rowHeight = 44.0
    self.tokensTableView.delegate = self
    self.tokensTableView.dataSource = self
    self.tokensTableView.reloadData()
    self.tokensTableView.allowsSelection = false
    self.subcribeTokenSwitch.isOn = self.viewModel.notiStatus
    self.hideFormViews(!self.viewModel.notiStatus)
    self.updateUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
    self.applyButton.removeSublayer(at: 0)
    self.applyButton.applyGradient()
  }

  fileprivate func updateUI() {
    let btnTitle: String = self.viewModel.isSeeMore ? NSLocalizedString("see.less", value: "See less", comment: "") : NSLocalizedString("see.more", value: "See more", comment: "")
    self.tokensViewActionButton.setTitle(
      btnTitle,
      for: .normal
    )
    let shouldShowSeeMoreButton = self.viewModel.supportedTokens.count <= 12
    self.tokensViewActionButton.isHidden = shouldShowSeeMoreButton
    self.tokensViewActionButtonHeight.constant = shouldShowSeeMoreButton ? 0 : 36
    self.tokensTableViewHeightConstraint.constant = {
      if shouldShowSeeMoreButton {
        return CGFloat((self.viewModel.supportedTokens.count + 3) / 4) * self.tokensTableView.rowHeight
      }
      let numberRows = self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 3
      return CGFloat(numberRows) * self.tokensTableView.rowHeight
    }()
    self.tokensTableView.reloadData()
  }

  fileprivate func hideFormViews(_ hidden: Bool) {
    for view in self.formViews {
      view.isHidden = hidden
    }
    self.tokensViewActionButton.isHidden = self.viewModel.supportedTokens.count <= 12
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func tokensActionButtonPressed(_ sender: Any) {
    self.viewModel.isSeeMore = !self.viewModel.isSeeMore
    self.updateUI()
  }

  @IBAction func toggleSubcribeTokenSwitch(_ sender: UISwitch) {
    let state = sender.isOn
    self.displayLoading()
    KNNotificationCoordinator.shared.toggleSubscriptionTokens(state: state) { [weak self] (message) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let errorMessage = message {
        sender.isOn = !state
        self.showErrorTopBannerMessage(message: errorMessage)
      } else {
        self.hideFormViews(!state)
        KNCrashlyticsUtil.logCustomEvent(withName: state ? "pricetrending_noti_enable" : "pricetrending_noti_disable", customAttributes: nil)
      }
    }
  }

  @IBAction func resetButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "pricetrending_reset_tapped", customAttributes: nil)
    self.viewModel.resetTokens()
    self.updateUI()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "pricetrending_apply_tapped", customAttributes: nil)
    self.displayLoading()
    KNNotificationCoordinator.shared.updateListSubscriptionTokens(symbols: self.viewModel.tokens) { [weak self] (message) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let errorMessage = message {
        self.showErrorTopBannerMessage(message: errorMessage)
      } else {
        self.delegate?.notificationSettingViewControllerDidApply(self)
      }
    }
  }
}

extension KNNotificationSettingViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 3
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let view = UIView()
    view.isUserInteractionEnabled = false
    return view
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kFilterTokensTableViewCellID, for: indexPath) as! KNTransactionFilterTableViewCell
    let data = Array(self.viewModel.supportedTokens[indexPath.row * 4..<min(indexPath.row * 4 + 4, self.viewModel.supportedTokens.count)])
    cell.delegate = self
    cell.updateCell(with: data, selectedTokens: self.viewModel.tokens)
    return cell
  }
}

extension KNNotificationSettingViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
  }
}

extension KNNotificationSettingViewController: KNTransactionFilterTableViewCellDelegate {
  func transactionFilterTableViewCell(_ cell: KNTransactionFilterTableViewCell, select token: String) {
    self.viewModel.selectTokenSymbol(token)
    self.tokensTableView.reloadData()
  }
}
