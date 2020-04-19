// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTokenChartCoordinatorDelegate: class {
  func tokenChartCoordinator(sell token: TokenObject)
  func tokenChartCoordinator(buy token: TokenObject)
  func tokenChartCoordinatorShouldBack()
}

class KNTokenChartCoordinator: Coordinator {

  let navigationController: UINavigationController
  let session: KNSession
  let token: TokenObject
  var chartLOData: KNLimitOrderChartData? //if open from LO
  var coordinators: [Coordinator] = []
  var balances: [String: Balance] = [:]

  weak var delegate: KNTokenChartCoordinatorDelegate?

  lazy var rootViewController: KNTokenChartViewController = {
    let viewModel = KNTokenChartViewModel(token: self.token, chartDataLO: self.chartLOData)
    let controller = KNTokenChartViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?

  fileprivate var newAlertController: KNNewAlertViewController?

  init(
    navigationController: UINavigationController,
    session: KNSession,
    balances: [String: Balance],
    token: TokenObject,
    chartLOData: KNLimitOrderChartData? = nil
    ) {
    self.navigationController = navigationController
    self.session = session
    self.balances = balances
    self.token = token
    self.chartLOData = chartLOData
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
    if let bal = balances[self.token.contract] {
      self.rootViewController.coordinatorUpdateBalance(balance: [self.token.contract: bal])
    }
  }

  func stop() {
    self.delegate?.tokenChartCoordinatorShouldBack()
  }

  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    if let bal = balances[self.token.contract] {
      self.rootViewController.coordinatorUpdateBalance(balance: [self.token.contract: bal])
    }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func coordinatorExchangeRateDidUpdate() {
    self.rootViewController.coordinatorUpdateRate()
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }

  func coordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func coordinatorGasPriceCachedDidUpdate() {
    self.sendTokenCoordinator?.coordinatorGasPriceCachedDidUpdate()
  }

  func coordinatorDidUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    return self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) ?? false
  }

  func coordinatorDidUpdateMarketData() {
    // no market data
    guard let curMarket = self.chartLOData?.market else { return }
    guard let newMarket = KNRateCoordinator.shared.cachedMarket.first(where: { return $0.pair == curMarket.pair }) else { return }
    self.rootViewController.coordinatorUpdateMarketPair(market: newMarket)
  }
}

extension KNTokenChartCoordinator: KNTokenChartViewControllerDelegate {
  func tokenChartViewController(_ controller: KNTokenChartViewController, run event: KNTokenChartViewEvent) {
    switch event {
    case .back:
      self.stop()
    case .buy(let token):
      self.delegate?.tokenChartCoordinator(buy: token)
    case .sell(let token):
      self.delegate?.tokenChartCoordinator(sell: token)
    case .send(let token):
      if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
        self.sendTokenCoordinator = KNSendTokenViewCoordinator(
          navigationController: self.navigationController,
          session: self.session,
          balances: self.balances,
          from: token
        )
        self.sendTokenCoordinator?.start()
      } else {
        let message = NSLocalizedString(
          "Please wait for other transactions to be mined before making a transfer",
          value: "Please wait for other transactions to be mined before making a transfer",
          comment: ""
        )
        self.navigationController.showWarningTopBannerMessage(
          with: "",
          message: message,
          time: 2.0
        )
      }
    case .openEtherscan(let token):
      if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint, let url = URL(string: "\(etherScanEndpoint)address/\(token.contract)") {
        self.navigationController.openSafari(with: url)
      }
    case .addNewAlert(let token):
      if KNAlertStorage.shared.isMaximumAlertsReached {
        let alertController = UIAlertController(
          title: NSLocalizedString("Alert limit exceeded", value: "Alert limit exceeded", comment: ""),
          message: NSLocalizedString("You already have 10 (maximum) alerts in your inbox. Please delete an existing alert to add a new one", comment: ""),
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", value: "OK", comment: ""), style: .cancel, handler: nil))
        self.navigationController.present(alertController, animated: true, completion: nil)
        return
      }
      if IEOUserStorage.shared.user == nil {
        self.navigationController.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
          time: 1.5
        )
        return
      }
      self.newAlertController = KNNewAlertViewController()
      self.newAlertController?.loadViewIfNeeded()
      self.navigationController.pushViewController(self.newAlertController!, animated: true) {
        self.newAlertController?.updatePair(token: token, currencyType: KNAppTracker.getCurrencyType())
      }
    }
  }
}
