//
//  OverviewMainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/9/21.
//

import UIKit

enum ViewMode {
  case market
  case asset
  case supply
}

class OverviewMainViewModel {
  var currentMode: ViewMode = .asset
  var dataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayDataSource: [String: [OverviewMainCellViewModel]] = [:]
  var displayHeader: [String] = []
  
  
  func reloadAllData() {
    switch self.currentMode {
    case .market:
      let marketToken = KNSupportedTokenStorage.shared.allTokens
      self.displayHeader = []
      let models = marketToken.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item))
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
    case .asset:
      let assetTokens = KNSupportedTokenStorage.shared.getAssetTokens()
      self.displayHeader = []
      let models = assetTokens.map { (item) -> OverviewMainCellViewModel in
        return OverviewMainCellViewModel(mode: .market(token: item))
      }
      self.dataSource = ["": models]
      self.displayDataSource = ["": models]
    case .supply:
      let supplyBalance = BalanceStorage.shared.getSupplyBalances()
      self.displayHeader = supplyBalance.0
      
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
}

class OverviewMainViewController: KNBaseViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalBalanceContainerView: UIView!
  @IBOutlet weak var currentWalletLabel: UILabel!
  @IBOutlet weak var totalBalanceLabel: UILabel!
  @IBOutlet weak var hideBalanceButton: UIButton!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var searchButton: UIButton!
  
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
    self.tableView.rowHeight = OverviewMainViewCell.kCellHeight
    
    self.tableView.contentInset = UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0)
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.reloadAllData()
  }
  
  @IBAction func sendButtonTapped(_ sender: UIButton) {
    print("Send")
  }
  
  @IBAction func receiveButtonTapped(_ sender: UIButton) {
    print("Tapped")
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
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewMainViewCell.kCellID,
      for: indexPath
    ) as! OverviewMainViewCell
    
    let cellModel = self.viewModel.getViewModelsForSection(indexPath.section)[indexPath.row]
    cell.updateCell(cellModel)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 18, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
//    titleLabel.text = self.viewModel.sectionKeys[section]
    titleLabel.font = UIFont.Kyber.latoBold(with: 12)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - 100 - 18, y: 0, width: 100, height: 40))
//    valueLabel.text = self.viewModel.displayTotalValueForSection(section)
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
}

extension OverviewMainViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    let alpha = scrollView.contentOffset.y <= 0 ? abs(scrollView.contentOffset.y) / 200.0 : 0.0
    self.totalBalanceContainerView.alpha = alpha
  }
}
