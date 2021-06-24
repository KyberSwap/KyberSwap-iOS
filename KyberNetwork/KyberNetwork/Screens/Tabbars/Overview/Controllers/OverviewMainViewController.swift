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
  case select(token: Token)
  case selectListWallet
}

enum ViewMode {
  case market
  case asset
  case supply
  case favourite
}

enum MarketSortType {
  case name(des: Bool)
  case ch24(des: Bool)
}

protocol OverviewMainViewControllerDelegate: class {
  func overviewMainViewController(_ controller: OverviewMainViewController, run event: OverviewMainViewEvent)
}

class OverviewMainViewModel {
  fileprivate var session: KNSession!
  var currentMode: ViewMode = .asset
  var dataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayDataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayHeader: [String] = []
  var displayTotalValues: [String: String] = [:]
  var hideBalanceStatus: Bool = true
  var marketSortType: MarketSortType = .ch24(des: true)
  
  init(session: KNSession) {
    self.session = session
  }

  func reloadAllData() {
    switch self.currentMode {
    case .market:
      let marketToken = KNSupportedTokenStorage.shared.allTokens.sorted { (left, right) -> Bool in
        switch self.marketSortType {
        case .name(des: let des):
          return des ? left.symbol > right.symbol : left.symbol < right.symbol
        case .ch24(des: let des):
          return des ? left.getTokenPrice().usd24hChange > right.getTokenPrice().usd24hChange : left.getTokenPrice().usd24hChange < right.getTokenPrice().usd24hChange
        }
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
    case .favourite:
      let marketToken = KNSupportedTokenStorage.shared.allTokens.sorted { (left, right) -> Bool in
        switch self.marketSortType {
        case .name(des: let des):
          return des ? left.symbol > right.symbol : left.symbol < right.symbol
        case .ch24(des: let des):
          return des ? left.getTokenPrice().usd24hChange > right.getTokenPrice().usd24hChange : left.getTokenPrice().usd24hChange < right.getTokenPrice().usd24hChange
        }
      }.filter { (token) -> Bool in
        return KNSupportedTokenStorage.shared.getFavedStatusWithAddress(token.address)
      }
      self.displayHeader = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item))
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
      self.displayTotalValues = [:]
    }
  }
  
  var numberOfSections: Int {
    return self.displayHeader.isEmpty ? 1 : self.displayHeader.count
  }

  func getViewModelsForSection(_ section: Int) -> [OverviewMainCellViewModel] {
    guard !self.displayHeader.isEmpty else {
      return self.displayDataSource[""] ?? []
    }
    
    let key = self.displayHeader[section]
    return self.displayDataSource[key] ?? []
  }
  
  var displayPageTotalValue: String {
    guard self.currentMode != .market, self.currentMode != .favourite else {
      return ""
    }
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
    case .favourite:
      return "Favourite"
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
  @IBOutlet weak var currentChainLabel: UILabel!
  @IBOutlet weak var sortingContainerView: UIView!
  @IBOutlet weak var sortMarketByNameButton: UIButton!
  @IBOutlet weak var sortMarketByCh24Button: UIButton!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var walletNameLabel: UILabel!
  
  weak var delegate: OverviewMainViewControllerDelegate?
  
  let viewModel: OverviewMainViewModel
  
  init(viewModel: OverviewMainViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewMainViewController.className, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
  
  fileprivate func updateUIWalletList() {
    self.walletNameLabel.text = self.viewModel.session.wallet.address.description
  }

  fileprivate func reloadUI() {
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.viewModel.reloadAllData()
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.currentPageNameLabel.text = self.viewModel.displayCurrentPageName
    self.updateUIHideBalanceButton()
    self.sortingContainerView.isHidden = self.viewModel.currentMode != .market
    self.updateUIWalletList()
    self.tableView.reloadData()
  }

  fileprivate func updateUISwitchChain() {
    let icon = KNGeneralProvider.shared.isEthereum ? UIImage(named: "chain_eth_icon") : UIImage(named: "chain_bsc_icon")
    self.currentChainIcon.image = icon
    self.currentChainLabel.text = KNGeneralProvider.shared.isEthereum ? "ETH" : "BSC"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadUI()
  }

  @IBAction func sendButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .send)
  }
  
  @IBAction func receiveButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .receive)
  }
  
  @IBAction func walletsListButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .selectListWallet)
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
  
  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      if case let .name(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .name(des: !dec)
        self.updateUIForIndicatorView(button: sender, dec: !dec)
      } else {
        self.viewModel.marketSortType = .name(des: true)
        self.updateUIForIndicatorView(button: sender, dec: true)
      }
      self.sortMarketByCh24Button.setImage(UIImage(named: "sort_none_icon"), for: .normal)
    } else if sender.tag == 2 {
      if case let .ch24(dec) = self.viewModel.marketSortType {
        self.viewModel.marketSortType = .ch24(des: !dec)
        self.updateUIForIndicatorView(button: sender, dec: !dec)
      } else {
        self.viewModel.marketSortType = .ch24(des: true)
        self.updateUIForIndicatorView(button: sender, dec: true)
      }
      self.sortMarketByNameButton.setImage(UIImage(named: "sort_none_icon"), for: .normal)
    }
    self.viewModel.reloadAllData()
    self.reloadUI()
  }
  
  @IBAction func notificationsButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .notifications)
  }

  @IBAction func searchButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewMainViewController(self, run: .search)
  }

  fileprivate func updateUIForIndicatorView(button: UIButton, dec: Bool) {
    if dec {
      let img = UIImage(named: "sort_down_icon")
      button.setImage(img, for: .normal)
    } else {
      let img = UIImage(named: "sort_up_icon")
      button.setImage(img, for: .normal)
    }
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
  
  func coordinatorDidUpdateNewSession(_ session: KNSession) {
    self.viewModel.session = session
    guard self.isViewLoaded else { return }
    self.updateUIWalletList()
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.viewModel.reloadAllData()
    self.tableView.reloadData()
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    self.totalPageValueLabel.text = self.viewModel.displayPageTotalValue
    self.totalValueLabel.text = self.viewModel.displayTotalValue
    self.viewModel.reloadAllData()
    self.tableView.reloadData()
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
    case .asset, .market, .favourite:
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
    guard self.viewModel.currentMode == .supply else {
      return 0
    }
    return 40
  }
}

extension OverviewMainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
    switch cellModel.mode {
    case .asset(token: let token):
      self.delegate?.overviewMainViewController(self, run: .select(token: token))
    case .market(token: let token):
      self.delegate?.overviewMainViewController(self, run: .select(token: token))
    case .supply(balance: let balance):
      break
    }
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
