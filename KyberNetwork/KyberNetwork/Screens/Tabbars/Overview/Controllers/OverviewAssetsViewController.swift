//
//  OverviewAssetsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt
import SwipeCellKit

enum AssetsOverviewSortingType {
  case balance(dec: Bool)
  case price(dec: Bool)
  case value(dec: Bool)
}

class OverviewAssetsViewModel {
  var data: [OverviewAssetsCellViewModel] = []
  var dataSource: [OverviewAssetsCellViewModel] = []
  var currencyType: CurrencyType = .usd
  var soringType: AssetsOverviewSortingType = .value(dec: false)
  var searchText: String = ""
  var hideBalanceStatus: Bool = true
  
  init() {
    self.reloadAllData()
  }
  
  func reloadAllData() {
    self.data.removeAll()
    let tokens = KNSupportedTokenStorage.shared.allTokens
    let lendingBalances = BalanceStorage.shared.getAllLendingBalances()
    var lendingSymbols: [String] = []
    lendingBalances.forEach { (lendingPlatform) in
      lendingPlatform.balances.forEach { (balance) in
        lendingSymbols.append(balance.interestBearingTokenSymbol.lowercased())
      }
    }
    tokens.forEach { (token) in
      guard token.getBalanceBigInt() > BigInt(0), !lendingSymbols.contains(token.symbol.lowercased()) else {
        return
      }
      let viewModel = OverviewAssetsCellViewModel(token: token)
      viewModel.hideBalanceStatus = self.hideBalanceStatus
      self.data.append(viewModel)
    }
    self.reloadDataSource()
  }

  func reloadDataSource() {
    var cache = self.data
    cache.forEach { (viewModel) in
      viewModel.currencyType = self.currencyType
    }
    
    cache.sort { (left, right) -> Bool in
      switch self.soringType {
      case .balance(let dec):
        return dec ? left.comparableBalanceBigInt < right.comparableBalanceBigInt : left.comparableBalanceBigInt > right.comparableBalanceBigInt
      case .price(let dec):
        return dec ? left.priceDouble < right.priceDouble : left.priceDouble > right.priceDouble
      case .value(let dec):
        return dec ? left.valueBigInt < right.valueBigInt : left.valueBigInt > right.valueBigInt
      }
    }
    
    if !self.searchText.isEmpty {
      cache = cache.filter({ (item) -> Bool in
        return item.token.symbol.lowercased().contains(self.searchText.lowercased())
      })
    }
    
    self.dataSource = cache
  }
  
  var totalValueBigInt: BigInt {
    var total = BigInt(0)
    self.dataSource.forEach { (viewModel) in
      total += viewModel.valueBigInt
    }
    return total
  }
  
  var totalValueString: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    let totalString = self.totalValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
    return self.currencyType == .usd ? "$" + totalString : totalString
  }
}

class OverviewAssetsViewController: KNBaseViewController, OverviewViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var currencySelectButtons: [UIButton]!
  @IBOutlet var sortingImageIndicator: [UIImageView]!
  @IBOutlet weak var totalStringLabel: UILabel!
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  @IBOutlet weak var btcButton: UIButton!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var buyETHButton: UIButton!
  
  weak var container: OverviewViewController?
  weak var delegate: OverviewTokenListViewDelegate?

  let viewModel = OverviewAssetsViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: OverviewAssetsTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewAssetsTableViewCell.kCellID
    )
    self.tableView.rowHeight = OverviewAssetsTableViewCell.kCellHeight
    self.buyETHButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.buyETHButton.frame.size.height / 2)
    self.updateUITotalValue()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.reloadAllData()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadUI()
  }
  
  fileprivate func updateUITotalValue() {
    self.totalStringLabel.text = self.viewModel.totalValueString
  }
  
  fileprivate func reloadUI() {
    guard self.isViewLoaded else {
      return
    }
    switch self.viewModel.currencyType {
    case .usd:
      self.usdButton.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
      self.ethButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      self.btcButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
    case .eth:
      self.usdButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      self.ethButton.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
      self.btcButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
    case .btc:
      self.usdButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      self.ethButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      self.btcButton.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
    }
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
    self.updateUITotalValue()
    self.emptyView.isHidden = !self.viewModel.dataSource.isEmpty
    self.buyETHButton.isHidden = !KNGeneralProvider.shared.isEthereum
  }
  
  @IBAction func currencyTypeButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      self.viewModel.currencyType = .usd
    } else if sender.tag == 2 {
      self.viewModel.currencyType = .eth
    } else {
      self.viewModel.currencyType = .btc
    }
    self.reloadUI()
    self.container?.viewControllerDidChangeCurrencyType(self, type: self.viewModel.currencyType)
  }

  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    self.sortingImageIndicator.forEach { (imageView) in
      if imageView.tag == sender.tag {
        if sender.tag == 1 {
          if case let .balance(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .balance(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .balance(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        } else if sender.tag == 2 {
          if case let .price(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .price(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .price(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        } else if sender.tag == 3 {
          if case let .value(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .value(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .value(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        }
      } else {
        imageView.image = UIImage(named: "no_arrow_overview_icon")
      }
    }
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
  }
  
  fileprivate func updateUIForIndicatorView(imageView: UIImageView, dec: Bool) {
    if dec {
      imageView.image = UIImage(named: "down_arrow_overview_icon")
    } else {
      imageView.image = UIImage(named: "up_arrow_overview_icon")
    }
  }

  @IBAction func buyETHButtonTapped(_ sender: UIButton) {
    UIApplication.shared.open(URL(string: "https://krystal.app/buy-crypto")!)
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
    self.coordinatorDidUpdateDidUpdateTokenList()
  }

  func coordinatorDidUpdateSearchText(_ text: String) {
    self.viewModel.searchText = text
    guard self.isViewLoaded else { return }
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
  }
  
  func containerDidUpdateHideBalanceStatus(_ status: Bool) {
    self.viewModel.hideBalanceStatus = status
    guard self.isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.tableView.reloadData()
    self.updateUITotalValue()
  }
}

extension OverviewAssetsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewAssetsTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewAssetsTableViewCell

    cell.updateCell(viewModel: self.viewModel.dataSource[indexPath.row])
    cell.delegate = self
    return cell
  }
}

extension OverviewAssetsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let token = self.viewModel.dataSource[indexPath.row].token
    self.delegate?.overviewTokenListView(self, run: .select(token: token))
  }
}

extension OverviewAssetsViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }
    let token = self.viewModel.dataSource[indexPath.row].token
    let buy = SwipeAction(style: .default, title: nil) { (_, _) in
      self.delegate?.overviewTokenListView(self, run: .buy(token: token))
    }
    buy.hidesWhenSelected = true
    buy.title = "buy".toBeLocalised().uppercased()
    buy.textColor = UIColor.Kyber.SWYellow
    buy.font = UIFont.Kyber.latoBold(with: 10)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 60))!
    buy.backgroundColor = UIColor(patternImage: resized)

    let sell = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.overviewTokenListView(self, run: .sell(token: token))
    }
    sell.title = "sell".toBeLocalised().uppercased()
    sell.textColor = UIColor.Kyber.SWYellow
    sell.font = UIFont.Kyber.latoBold(with: 10)
    sell.backgroundColor = UIColor(patternImage: resized)

    let transfer = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.overviewTokenListView(self, run: .transfer(token: token))
    }
    transfer.title = "transfer".toBeLocalised().uppercased()
    transfer.textColor = UIColor.Kyber.SWYellow
    transfer.font = UIFont.Kyber.latoBold(with: 10)
    transfer.backgroundColor = UIColor(patternImage: resized)

    return [buy, sell, transfer]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
