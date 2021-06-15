//
//  OverviewMainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/9/21.
//

import UIKit
import BigInt

enum OverviewMainViewEvent {
  case send
  case receive
  case search
  case notifications
  case changeMode(current: ViewMode)
  case walletConfig
}

enum ViewMode {
  case market
  case asset
  case supply
}

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
}

class OverviewMainViewModel {
  var currentMode: ViewMode = .asset
  var dataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayDataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayHeader: [String] = []
  var displayTotalValues: [String: String] = [:]
  var hideBalanceStatus: Bool = true
  
  func reloadAllData() {
    switch self.currentMode {
    case .market:
      let marketToken = KNSupportedTokenStorage.shared.allTokens.sorted { (left, right) -> Bool in
        return left.getTokenPrice().usd24hChange > right.getTokenPrice().usd24hChange
      }
      self.displayHeader = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item))
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      self.displayTotalValues = [:]
    case .asset:
      let assetTokens = KNSupportedTokenStorage.shared.getAssetTokens().sorted { (left, right) -> Bool in
        return left.getValueUSDBigInt() > right.getValueUSDBigInt()
      }
      self.displayHeader = []
      self.displayTotalValues = [:]
      var total = BigInt(0)
      let models = assetTokens.map { (item) -> OverviewMainCellViewModel in
        total += item.getValueUSDBigInt()
        return OverviewMainCellViewModel(mode: .asset(token: item))
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      let displayTotalString = "$" + total.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
      self.displayTotalValues["all"] = displayTotalString
    case .supply:
      let supplyBalance = BalanceStorage.shared.getSupplyBalances()
      self.displayHeader = supplyBalance.0
      let data = supplyBalance.1
      var models: [String: [OverviewMainCellViewModel]] = [:]
      var total = BigInt(0)
      self.displayHeader.forEach { (key) in
        var sectionModels: [OverviewMainCellViewModel] = []
        var totalSection = BigInt(0)
        data[key]?.forEach({ (item) in
          if let lendingBalance = item as? LendingBalance {
            totalSection += lendingBalance.getValueBigInt()
          } else if let distributionBalance = item as? LendingDistributionBalance {
            totalSection += distributionBalance.getValueBigInt()
          }
          sectionModels.append(OverviewMainCellViewModel(mode: .supply(balance: item)))
        })
        models[key] = sectionModels
        let displayTotalSection = "$" + totalSection.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
        self.displayTotalValues[key] = displayTotalSection
        total += totalSection
      }
      self.dataSource = models
      self.displayDataSource = models
      self.displayTotalValues["all"] = "$" + total.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
    }
  }
  
  var numberOfSections: Int {
    return self.displayHeader.isEmpty ? 1 : self.displayHeader.count
  }
  
  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel]  {
    guard !self.displayHeader.isEmpty else {
      return self.displayDataSource[""] ?? []
    }
    
    let key = self.displayHeader[section]
    return self.displayDataSource[key] ?? []
  }
  
  var displayPageTotalValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    return self.displayTotalValues["all"] ?? ""
  }
  
  func getTotalValueForSection(_ section: Int) -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let key = self.displayHeader[section]
    return self.displayTotalValues[key] ?? ""
  }
  
  var displayTotalValue: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let total = BalanceStorage.shared.getTotalBalance()
    return "$" + total.string(decimals: 18, minFractionDigits: 6, maxFractionDigits: 6)
  }
  
  var displayHideBalanceImage: UIImage {
    return self.hideBalanceStatus ? UIImage(named: "hide_eye_icon")! : UIImage(named: "show_eye_icon")!
  }
  
  var displayCurrentPageName: String {
    switch self.currentMode {
    case .asset:
      return "Assets"
    case .market:
      return "Market"
    case .supply:
      return "Supply"
    }
  }
}

class OverviewMainViewController: KNBaseViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalBalanceContainerView: UIView!
  @IBOutlet weak var currentWalletLabel: UILabel!
  @IBOutlet weak var totalBalanceLabel: UILabel!
  @IBOutlet weak var hideBalanceButton: UIButton!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var searchButton: UIButton!
  @IBOutlet weak var totalPageValueLabel: UILabel!
  @IBOutlet weak var currentPageNameLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var currentChainIcon: UIImageView!
  
  weak var delegate: OverviewMainViewControllerDelegate?
  
  let viewModel = OverviewMainViewModel()
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init() {
    super.init(nibName: OverviewMainViewController.className, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewMainViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMainViewCell.kCellID
    )
    
    let nibSupply = UINib(nibName: OverviewDepositTableViewCell.className, bundle: nil)
    self.tableView.register(
      nibSupply,
      forCellReuseIdentifier: OverviewDepositTableViewCell.kCellID
    )
    
    self.tableView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUISwitchChain()
  }

  fileprivate func updateUIHideBalanceButton() {
    self.hideBalanceButton.setImage(self.viewModel.displayHideBalanceImage, for: .normal)
  }

  fileprivate func reloadUI() {
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.viewModel.reloadAllData()
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
    self.updateUIHideBalanceButton()
    self.tableView.reloadData()
  }

  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.isEthereum ? UIImage(named: "chain_eth_icon") : UIImage(named: "chain_bsc_icon")
    self.currentChainIcon.image = icon
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadUI()
  }

  @IBAction func sendButtonTapped(_ sender: UIButton) {
    print("Send")
  }
  
  @IBAction func receiveButtonTapped(_ sender: UIButton) {
    print("Tapped")
  }
  
  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = {
      let secondPopup = SwitchChainWalletsListViewController()
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }
  
  @IBAction func hideBalanceButtonTapped(_ sender: UIButton) {
    self.viewModel.hideBalanceStatus = !self.viewModel.hideBalanceStatus
    self.reloadUI()
  }

  @IBAction func toolbarOptionButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .changeMode(current: self.viewModel.currentMode))
  }

  @IBAction func walletOptionButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .walletConfig)
  }
  
  
  
  func coordinatorDidSelectMode(_ mode: ViewMode) {
    self.viewModel.currentMode = mode
    self.reloadUI()
  }
  
  func coordinatorDidUpdateChain() {
    guard self.isViewLoaded else {
      return
    }
    self.updateUISwitchChain()
  }
}

extension OverviewMainViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberOfSections
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.getViewModelsForSection(section).count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch self.viewModel.currentMode {
    case .asset, .market:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewMainViewCell.kCellID,
        for: indexPath
      ) as! OverviewMainViewCell
      
      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
      
      return cell
    default:
      let cell = tableView.dequeueReusableCell(
        withIdentifier: OverviewDepositTableViewCell.kCellID,
        for: indexPath
      ) as! OverviewDepositTableViewCell
      let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
      cellModel.hideBalanceStatus = self.viewModel.hideBalanceStatus
      cell.updateCell(cellModel)
      return cell
    }
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard self.viewModel.currentMode == .supply else {
      return nil
    }
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = self.viewModel.displayHeader[section]
    titleLabel.font = UIFont.Kyber.latoBold(with: 18)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - 100 - 35, y: 0, width: 100, height: 40))
    valueLabel.text = self.viewModel.getTotalValueForSection(section)
    valueLabel.font = UIFont.Kyber.latoBold(with: 14)
    valueLabel.textAlignment = .right
    valueLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(valueLabel)
    
    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 40
  }
}

extension OverviewMainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch self.viewModel.currentMode {
    case .asset, .market:
      return OverviewMainViewCell.kCellHeight
    default:
      return OverviewDepositTableViewCell.kCellHeight
    }
  }
}

extension OverviewMainViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let alpha = scrollView.contentOffset.y <= 0 ? abs(scrollView.contentOffset.y) / 200.0 : 0.0
    self.totalBalanceContainerView.alpha = alpha
  }
}
