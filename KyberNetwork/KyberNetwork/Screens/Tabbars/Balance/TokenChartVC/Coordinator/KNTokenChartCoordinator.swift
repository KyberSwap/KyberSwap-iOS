// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

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
    self.rootViewController.coordinatorUpdateBalance(balance: self.balances)
  }

  func stop() {
    self.delegate?.tokenChartCoordinatorShouldBack()
  }

  func coordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.rootViewController.coordinatorUpdateBalance(balance: self.balances)
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: self.balances)
  }

  func coordinatorUpdatePendingBalances(address: String, balances: JSONDictionary) {
    // different address
    if address.lowercased() != self.session.wallet.address.description.lowercased() { return }
    let bal: Double = {
      if self.token.isETH || self.token.isWETH {
        return (balances["ETH"] as? Double ?? 0.0) + (balances["WETH"] as? Double ?? 0.0)
      }
      return balances[self.token.symbol] as? Double ?? 0.0
    }()
    let balance = BigInt(bal * pow(10.0, Double(self.token.decimals)))
    self.rootViewController.coordinatorUpdatePendingBalance(balance: balance)
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
  
  func coordinatorDidUpdateGasWarningLimit() {
    self.sendTokenCoordinator?.coordinatorDidUpdateGasWarningLimit()
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
      if let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint {
        let address = self.session.wallet.address.description.lowercased()
        let urlString: String = {
          if token.isETH {
            // if eth, open address as there is no address for eth
            return "\(etherScanEndpoint)address/\(address)"
          }
          // open token with current address
          return "\(etherScanEndpoint)token/\(token.contract)?a=\(address)"
        }()
        if let url = URL(string: urlString) {
          self.navigationController.openSafari(with: url)
        }
      }
    case .addNewAlert(let token):
      if KNAlertStorage.shared.isMaximumAlertsReached {
        let alertController = KNPrettyAlertController(
          title: "Alert limit exceeded".toBeLocalised(),
          message: "You already have 10 (maximum) alerts in your inbox. Please delete an existing alert to add a new one".toBeLocalised(),
          secondButtonTitle: nil,
          firstButtonTitle: "OK".toBeLocalised(),
          secondButtonAction: nil,
          firstButtonAction: nil
        )
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
