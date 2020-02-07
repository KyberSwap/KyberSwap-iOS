// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNNewAlertViewModel {
  lazy var numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 6
    formatter.minimumFractionDigits = 2
    return formatter
  }()

  lazy var priceNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 1
    formatter.maximumFractionDigits = 9
    return formatter
  }()

  fileprivate(set) var alertID: Int?
  fileprivate(set) var alertCreatedDate: Double?
  fileprivate(set) var currencyType: KWalletCurrencyType = .usd
  fileprivate(set) var token: String = "ETH"
  fileprivate(set) var currentPrice: Double = 0.0
  fileprivate(set) var targetPrice: Double = 0.0

  var displayTokenTitle: String { return "\(token)/\(currencyType.rawValue)" }
  var displayCurrencyTitle: String { return currencyType.rawValue }

  var currentPriceDisplay: String {
    let price = BigInt(currentPrice * pow(10.0, 18.0))
    let display = price.displayRate(decimals: 18)
    let string = NSLocalizedString("Current Price: %@", comment: "")
    return String(format: string, display)
  }

  var isPercentageHidden: Bool { return self.percentageChange < 0.01 || currentPrice == 0.0 }
  var isAbove: Bool { return targetPrice >= currentPrice }
  var percentageImage: UIImage? { return self.isAbove ? UIImage(named: "change_up") : UIImage(named: "change_down") }
  var percentageChange: Double { return fabs(targetPrice - currentPrice) * 100.0 / currentPrice }
  var percentageChangeDisplay: String {
    return (self.numberFormatter.string(from: NSNumber(value: percentageChange)) ?? "") + "%"
  }
  var percentageChangeColor: UIColor {
    return self.isAbove ? UIColor(red: 49, green: 203, blue: 158) : UIColor(red: 250, green: 101, blue: 102)
  }

  func update(token: String, currencyType: KWalletCurrencyType) {
    self.token = token
    self.currencyType = currencyType
    self.updateCurrentPrice()
  }

  func updateEditAlert(_ alert: KNAlertObject) {
    self.alertID = alert.id
    self.alertCreatedDate = alert.createdDate
    self.currencyType = KWalletCurrencyType(rawValue: alert.currency) ?? .usd
    self.token = alert.token
    self.targetPrice = alert.price
    self.updateCurrentPrice()
  }

  func updateTargetPrice(_ price: Double) {
    self.targetPrice = price
  }

  func updateCurrentPrice() {
    self.currentPrice = {
      if let rate = KNTrackerRateStorage.shared.rates.first(where: { $0.tokenSymbol == self.token }) {
        return self.currencyType == .eth ? rate.rateETHNow : rate.rateUSDNow
      }
      return 0.0
    }()
  }

  func updateCurrencyType(_ type: KWalletCurrencyType) {
    self.currencyType = type
    self.updateCurrentPrice()
  }

  func switchCurrencyType() {
    self.currencyType = self.currencyType == .usd ? .eth : .usd
    self.updateCurrentPrice()
  }
}

class KNNewAlertViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var tokenTextLabel: UILabel!
  @IBOutlet weak var tokenButton: UIButton!

  @IBOutlet weak var currencyLabel: UILabel!
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var usdLabel: UILabel!
  @IBOutlet weak var ethButton: UIButton!
  @IBOutlet weak var ethLabel: UILabel!

  @IBOutlet weak var alertPriceTextLabel: UILabel!
  @IBOutlet weak var alertPriceTextField: UITextField!
  @IBOutlet weak var currentPriceTextLabel: UILabel!
  @IBOutlet weak var percentageChange: UIButton!

  let viewModel: KNNewAlertViewModel = {
    let viewModel = KNNewAlertViewModel()
    if let alert = KNAlertStorage.shared.alerts.sorted(by: { return $0.updatedDate > $1.updatedDate }).first {
      viewModel.update(
        token: alert.token,
        currencyType: KWalletCurrencyType.usd
      )
    }
    return viewModel
  }()

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kExchangeTokenRateNotificationKey), object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.currencyLabel.text = NSLocalizedString("Currency", comment: "")

    let tabUSDGesture = UITapGestureRecognizer(target: self, action: #selector(self.usdButtonPressed(_:)))
    self.usdLabel.addGestureRecognizer(tabUSDGesture)

    let tabETHGesture = UITapGestureRecognizer(target: self, action: #selector(self.ethButtonPressed(_:)))
    self.ethLabel.addGestureRecognizer(tabETHGesture)

    self.updateUIs()

    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["info": "currency_\(self.viewModel.currencyType.rawValue)"])
    self.alertPriceTextLabel.text = "Alert Price".toBeLocalised()
    self.alertPriceTextField.delegate = self
    self.viewModel.updateCurrentPrice()
    self.updateUIs()
    NotificationCenter.default.addObserver(self, selector: #selector(self.trackerRateDidUpdate(_:)), name: NSNotification.Name(rawValue: kExchangeTokenRateNotificationKey), object: nil)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if IEOUserStorage.shared.user == nil {
      self.navigationController?.popViewController(animated: true)
    }
    // force reload current exchange rate
    KNRateCoordinator.shared.fetchCacheRate(nil)
    self.alertPriceTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @objc func trackerRateDidUpdate(_ sender: Any) {
    self.viewModel.updateCurrentPrice()
    self.updateUIs()
  }

  func updatePair(token: TokenObject, currencyType: KWalletCurrencyType) {
    self.viewModel.update(token: token.symbol, currencyType: currencyType)
    self.updateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["info": "currency_\(self.viewModel.currencyType.rawValue)"])
    // for refetch token rates
    KNRateCoordinator.shared.fetchCacheRate(nil)
  }

  func updateEditAlert(_ alert: KNAlertObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["info": "editting_alert"])
    self.viewModel.updateEditAlert(alert)
    self.alertPriceTextField.text = self.viewModel.priceNumberFormatter.string(from: NSNumber(value: alert.price))
    self.updateUIs()
  }

  fileprivate func updateUIs() {
    if self.viewModel.token == "ETH" || self.viewModel.token == "WETH" {
      // always force to use usd
      self.viewModel.updateCurrencyType(.usd)
    }
    UIView.animate(withDuration: 0.16) {
      self.tokenButton.setTokenImage(for: self.viewModel.token, size: CGSize(width: 36.0, height: 36.0))
      self.percentageChange.isHidden = self.viewModel.isPercentageHidden || (self.alertPriceTextField.text ?? "").isEmpty
      self.percentageChange.setImage(self.viewModel.percentageImage, for: .normal)
      self.percentageChange.setTitle(self.viewModel.percentageChangeDisplay, for: .normal)
      self.percentageChange.setTitleColor(self.viewModel.percentageChangeColor, for: .normal)
      self.tokenButton.setTitle(self.viewModel.displayTokenTitle, for: .normal)

      self.usdButton.rounded(
        color: self.viewModel.currencyType == .usd ? UIColor.Kyber.enygold : UIColor.Kyber.border,
        width: self.viewModel.currencyType == .usd ? 6.0 : 1.0,
        radius: 12.0
      )
      self.ethButton.rounded(
        color: self.viewModel.currencyType == .eth ? UIColor.Kyber.enygold : UIColor.Kyber.border,
        width: self.viewModel.currencyType == .eth ? 6.0 : 1.0,
        radius: 12.0
      )

      self.currentPriceTextLabel.text = self.viewModel.currentPriceDisplay
      self.view.layoutIfNeeded()
    }
  }
  @IBAction func usdButtonPressed(_ sender: Any) {
    if self.viewModel.currencyType == .eth {
      self.viewModel.updateTargetPrice(0)
      self.alertPriceTextField.text = ""
    }
    self.viewModel.updateCurrencyType(.usd)
    self.updateUIs()
  }

  @IBAction func ethButtonPressed(_ sender: Any) {
    if self.viewModel.currencyType == .usd {
      self.viewModel.updateTargetPrice(0)
      self.alertPriceTextField.text = ""
    }
    self.viewModel.updateCurrencyType(.eth)
    self.updateUIs()
  }

  @IBAction func selectTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["action": "select_token_btn_clicked"])
    let viewModel = KNSearchTokenViewModel(
      headerColor: UIColor.Kyber.shamrock,
      supportedTokens: KNSupportedTokenStorage.shared.supportedTokens
    )
    let searchTokenVC = KNSearchTokenViewController(viewModel: viewModel)
    searchTokenVC.loadViewIfNeeded()
    searchTokenVC.delegate = self
    self.navigationController?.pushViewController(searchTokenVC, animated: true)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["action": "back_btn_clicked"])
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer
    ) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["action": "screen_edge_pan"])
      self.navigationController?.popViewController(animated: true)
    }
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["action": "save_button_\(self.viewModel.alertID == nil ? "new_alert" : "update_alert")"])
    if self.viewModel.currentPrice == 0.0 {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("We can not update current price of this token pair", comment: ""),
        time: 1.5
      )
      return
    }
    let change = self.getPercentageChange(
      targetPrice: self.viewModel.targetPrice,
      currentPrice: self.viewModel.currentPrice
    )
    if change < KNAppTracker.minimumPriceAlertPercent || change > KNAppTracker.maximumPriceAlertPercent {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("Your target price should be from 1% to 10000% of current price", comment: ""),
        time: 1.5
      )
      return
    }
    if fabs(change) < KNAppTracker.minimumPriceAlertChangePercent {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("Your target price should be different at least 0.1% from current price", value: "Your target price should be different at least 0.1% from current price", comment: ""),
        time: 1.5
      )
      return
    }
    if (self.viewModel.token == "ETH" || self.viewModel.token == "WETH") && self.viewModel.currencyType == .eth {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("Can not select pair ETH/ETH, WETH/ETH", value: "Can not select pair ETH/ETH, WETH/ETH", comment: ""),
        time: 1.5
      )
      return
    }
    let targetPrice = self.alertPriceTextField.text ?? ""
    guard let price = targetPrice.amountBigInt(decimals: 18), !targetPrice.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("error", value: "Error", comment: ""),
        message: NSLocalizedString("Please enter your target price to be alerted", value: "Please enter your target price to be alerted", comment: ""),
        time: 1.5
      )
      return
    }
    self.viewModel.updateTargetPrice(Double(price) / pow(10.0, 18.0))
    if let _ = self.viewModel.alertID {
      self.updateAlertWithWarningIfNeeded()
    } else {
      self.createNewAlertSavePressed()
    }
  }

  fileprivate func createNewAlertSavePressed() {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    let alert = KNAlertObject(
      token: self.viewModel.token,
      currency: self.viewModel.currencyType.rawValue,
      price: self.viewModel.targetPrice,
      currentPrice: self.viewModel.currentPrice,
      isAbove: self.viewModel.targetPrice > self.viewModel.currentPrice
    )
    self.displayLoading()
    KNPriceAlertCoordinator.shared.addNewAlert(accessToken: accessToken, jsonData: alert.json) { [weak self] (_, error) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let error = error {
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["info": "create_new_alert_failed_\(error)"])
        KNAppTracker.logFirstTimePriceAlertIfNeeded()
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error,
          time: 1.5
        )
      } else {
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: NSLocalizedString("New alert has been added successfully!", comment: ""),
          time: 1.0
        )
        self.navigationController?.popViewController(animated: true)
        if #available(iOS 10.3, *) {
          KNAppstoreRatingManager.requestReviewIfAppropriate()
        }
      }
    }
  }

  fileprivate func updateAlertWithWarningIfNeeded() {
    guard let alertID = self.viewModel.alertID else { return }
    if let alert = KNAlertStorage.shared.getObject(primaryKey: alertID), alert.hasReward {
      let message = NSLocalizedString("This alert is eligible for a reward from the current competition. Do you still want to update?", comment: "")
      let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
      alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
      alertController.addAction(UIAlertAction(title: NSLocalizedString("continue", value: "Continue", comment: ""), style: .destructive, handler: { _ in
        self.updateAlertSavePressed()
      }))
      self.present(alertController, animated: true, completion: nil)
    } else {
      self.updateAlertSavePressed()
    }
  }

  fileprivate func updateAlertSavePressed() {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken, let alertID = self.viewModel.alertID else { return }
    let createdDate: Date = {
      if let date = self.viewModel.alertCreatedDate {
        return Date(timeIntervalSince1970: date)
      }
      return Date()
    }()
    let json: JSONDictionary = [
      "id": alertID,
      "symbol": self.viewModel.token,
      "base": self.viewModel.currencyType.rawValue.lowercased(),
      "alert_type": 0,
      "alert_price": self.viewModel.targetPrice,
      "created_at_price": self.viewModel.currentPrice,
      "is_above": self.viewModel.targetPrice > self.viewModel.currentPrice,
      "status": 0, // active
      "created_at": DateFormatterUtil.shared.priceAlertAPIFormatter.string(from: createdDate),
      "updated_at": DateFormatterUtil.shared.priceAlertAPIFormatter.string(from: Date()),
    ]
    let newAlert = KNAlertObject(json: json)
    self.displayLoading()
    KNPriceAlertCoordinator.shared.updateAlert(accessToken: accessToken, jsonData: newAlert.json) { [weak self] (_, error) in
      guard let `self` = self else { return }
      self.hideLoading()
      if let error = error {
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_new_alert", customAttributes: ["info": "update_alert_failed_\(error)"])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error,
          time: 1.5
        )
      } else {
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: NSLocalizedString("Updated alert successfully!", comment: ""),
          time: 1.0
        )
        self.navigationController?.popViewController(animated: true)
      }
    }
  }
}

extension KNNewAlertViewController: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.navigationController?.popViewController(animated: true, completion: {
      if case .select(let token) = event {
        self.viewModel.update(token: token.symbol, currencyType: self.viewModel.currencyType)

        self.alertPriceTextField.text = ""
        self.viewModel.updateTargetPrice(0)

        // for refetch token rates
        KNRateCoordinator.shared.fetchCacheRate(nil)
        self.updateUIs()
      }
    })
  }
}

extension KNNewAlertViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    self.alertPriceTextField.text = ""
    self.viewModel.updateTargetPrice(0)
    self.updateUIs()
    return false
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    guard let priceBigInt = text.amountBigInt(decimals: 18) else {
      return false
    }
    let targetPrice = Double(priceBigInt) / pow(10.0, 18.0)
    let change = self.getPercentageChange(targetPrice: targetPrice, currentPrice: self.viewModel.currentPrice)
    if change > KNAppTracker.maximumPriceAlertPercent { return false }
    self.viewModel.updateTargetPrice(targetPrice)
    self.alertPriceTextField.text = text
    self.updateUIs()
    return false
  }

  fileprivate func getPercentageChange(targetPrice: Double, currentPrice: Double) -> Double {
    if currentPrice == 0 { return KNAppTracker.maximumPriceAlertPercent + 1.0 }
    return (targetPrice - currentPrice) * 100.0 / currentPrice
  }
}
