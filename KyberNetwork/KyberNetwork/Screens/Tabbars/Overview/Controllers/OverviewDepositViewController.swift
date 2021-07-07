//
//  OverviewDepositViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt

class OverviewDepositViewModel {
  var dataSource: [String: [OverviewDepositCellViewModel]] = [:]
  var sectionKeys: [String] = []
  var currencyType: CurrencyType = .usd
  var hideBalanceStatus: Bool = false
  
  init() {
    self.reloadAllData()
  }
  
  func reloadAllData() {
    self.dataSource.removeAll()
    self.sectionKeys.removeAll()
    let allBalances: [LendingPlatformBalance] = BalanceStorage.shared.getAllLendingBalances()
    allBalances.forEach { (item) in
      var balances: [OverviewDepositLendingBalanceCellViewModel] = []
      item.balances.forEach { (balanceItem) in
        let viewModel = OverviewDepositLendingBalanceCellViewModel(balance: balanceItem)
        viewModel.hideBalanceStatus = self.hideBalanceStatus
        balances.append(viewModel)
      }
      if !balances.isEmpty {
        self.dataSource[item.name] = balances
        self.sectionKeys.append(item.name)
      }
    }
    if let otherData = BalanceStorage.shared.getDistributionBalance() {
      let viewModel = OverviewDepositDistributionBalanceCellViewModel(balance: otherData)
      viewModel.hideBalanceStatus = self.hideBalanceStatus
      self.dataSource["OTHER"] = [viewModel]
      self.sectionKeys.append("OTHER")
    }
  }
  
  func reloadDataSource() {
    self.sectionKeys.forEach { (key) in
      self.dataSource[key]?.forEach({ viewModel in
        viewModel.updateCurrencyType(self.currencyType)
      })
    }
  }
  
  func getDataSourceForSection(_ section: Int) -> [OverviewDepositCellViewModel] {
    let key = self.sectionKeys[section]
    return self.dataSource[key] ?? []
  }
  
  func getTotalValueForSection(_ section: Int) -> BigInt {
    let viewModels = self.getDataSourceForSection(section)
    var total = BigInt(0)
    viewModels.forEach { (item) in
      total += item.valueBigInt
    }
    return total
  }
  
  func displayTotalValueForSection(_ section: Int) -> String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let valueBigInt = self.getTotalValueForSection(section)
    let totalString = valueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
    return self.currencyType == .usd ? "$" + totalString : totalString
  }
  
  var totalValueBigInt: BigInt {
    var total = BigInt(0)
    for index in self.sectionKeys.indices {
      total += self.getTotalValueForSection(index)
    }
    return total
  }

  var totalValueString: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let totalString = self.totalValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
    switch self.currencyType {
    case .usd:
      return "$" + totalString
    case .eth:
      return totalString + " ETH"
    case .btc:
      return totalString + " BTC"
    }
  }
}

enum OverviewDepositViewEvent {
  case withdrawBalance(platform: String, balance: LendingBalance)
  case claim(balance: LendingDistributionBalance)
  case depositMore
}

protocol OverviewDepositViewControllerDelegate: class {
  func overviewDepositViewController(_ controller: OverviewDepositViewController, run event: OverviewDepositViewEvent)
}

class OverviewDepositViewController: KNBaseViewController, OverviewViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var totalStringLabel: UILabel!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var supplyButton: UIButton!
  @IBOutlet weak var borrowButton: UIButton!
  
  weak var container: OverviewViewController?
  weak var delegate: OverviewDepositViewControllerDelegate?
  let viewModel = OverviewDepositViewModel()
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewDepositTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewDepositTableViewCell.kCellID
    )
    self.tableView.rowHeight = OverviewDepositTableViewCell.kCellHeight
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
    self.updateUITotalValue()
    self.supplyButton.rounded(color: UIColor.Kyber.SWYellow, width: 1, radius: self.supplyButton.frame.size.height / 2)
    self.borrowButton.rounded(color: UIColor.Kyber.SWButtonBlueColor.withAlphaComponent(0.5), width: 1, radius: self.borrowButton.frame.size.height / 2)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.reloadAllData()
    self.reloadUI()
  }
  
  fileprivate func updateUITotalValue() {
    self.totalStringLabel.text = self.viewModel.totalValueString
  }
  
  fileprivate func reloadUI() {
    guard self.isViewLoaded else {
      return
    }
    self.emptyView.isHidden = self.viewModel.totalValueBigInt != BigInt(0)
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
    self.updateUITotalValue()
  }

  @IBAction func supplyButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewDepositViewController(self, run: .depositMore)
  }
  
  func viewControllerDidChangeCurrencyType(_ controller: OverviewViewController, type: CurrencyType) {
    guard type != self.viewModel.currencyType else {
      return
    }
    self.viewModel.currencyType = type
    self.reloadUI()
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.reloadUI()
    self.updateUITotalValue()
  }
  
  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.reloadAllData()
    guard self.isViewLoaded else { return }
    self.reloadUI()
  }
  
  func containerDidUpdateHideBalanceStatus(_ status: Bool) {
    self.viewModel.hideBalanceStatus = status
    guard self.isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.updateUITotalValue()
    self.tableView.reloadData()
  }
}

extension OverviewDepositViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.getDataSourceForSection(section).count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewDepositTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewDepositTableViewCell
    let viewModel = self.viewModel.getDataSourceForSection(indexPath.section)[indexPath.row]
    cell.updateCell(viewModel: viewModel)
    return cell
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.sectionKeys.count
  }
}

extension OverviewDepositViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 35, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = self.viewModel.sectionKeys[section]
    titleLabel.font = UIFont.Kyber.latoBold(with: 18)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    let valueLabel = UILabel(frame: CGRect(x: tableView.frame.size.width - 100 - 35, y: 0, width: 100, height: 40))
    valueLabel.text = self.viewModel.displayTotalValueForSection(section)
    valueLabel.font = UIFont.Kyber.latoBold(with: 14)
    valueLabel.textAlignment = .right
    valueLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(valueLabel)

    return view
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 40
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let viewModel = self.viewModel.getDataSourceForSection(indexPath.section)[indexPath.row] as? OverviewDepositLendingBalanceCellViewModel {
      self.delegate?.overviewDepositViewController(self, run: .withdrawBalance(platform: self.viewModel.sectionKeys[indexPath.section], balance: viewModel.balance))
    } else if let viewModel = self.viewModel.getDataSourceForSection(indexPath.section)[indexPath.row] as? OverviewDepositDistributionBalanceCellViewModel {
      self.delegate?.overviewDepositViewController(self, run: .claim(balance: viewModel.balance))
    }
  }
}
