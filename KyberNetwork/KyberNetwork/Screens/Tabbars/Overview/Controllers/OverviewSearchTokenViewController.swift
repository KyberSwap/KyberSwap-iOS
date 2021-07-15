//
//  OverviewSearchTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/25/21.
//

import UIKit
import TagListView

protocol OverviewSearchTokenViewControllerDelegate: class {
  func overviewSearchTokenViewController(_ controller: OverviewSearchTokenViewController, open token: Token)
}

class OverviewSearchTokenViewModel {
  var searchText = ""
  var dataSource: [OverviewMainCellViewModel] = []
  var currencyMode: CurrencyMode = .usd
  
  func reloadAllData() {
    guard !self.searchText.isEmpty else {
      self.dataSource.removeAll()
      return
    }
    
    var tokens = KNSupportedTokenStorage.shared.allTokens
    tokens = tokens.filter({ (item) -> Bool in
      return item.symbol.lowercased().contains(self.searchText.lowercased())
    })
    tokens.sort { (left, right) -> Bool in
      return left.symbol < right.symbol
    }
    let viewModels = tokens.map { (token) -> OverviewMainCellViewModel in
      return OverviewMainCellViewModel(mode: .search(token: token), currency: self.currencyMode)
    }
    self.dataSource = viewModels
  }
  
  func getRecentSearchTag() -> [String] {
    if let tags = UserDefaults.standard.object(forKey: KNEnvironment.default.envPrefix + "Recent-search") as? [String] {
      return tags
    } else {
      return []
    }
  }
  
  func saveNewSearchTag(_ tag: String) {
    if var tags = UserDefaults.standard.object(forKey: KNEnvironment.default.envPrefix + "Recent-search") as? [String] {
      if !tags.contains(tag) {
        tags.append(tag)
        if tags.count > 8 {
          tags.remove(at: 0)
        }
        UserDefaults.standard.setValue(tags, forKey: KNEnvironment.default.envPrefix + "Recent-search")
      }
    } else {
      UserDefaults.standard.setValue([tag], forKey: KNEnvironment.default.envPrefix + "Recent-search")
    }
  }
  
  var recommendTags: [String] {
    if KNGeneralProvider.shared.isEthereum {
      return ["ETH", "USDC", "USDT", "WBTC", "DAI", "UNI", "LINK", "AAVE"]
    } else {
      return ["BNB", "BUSD", "CAKE", "USDT", "BTCB", "ETH", "USDC", "SAFEMOON"]
    }
  }
}

class OverviewSearchTokenViewController: KNBaseViewController {
  
  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var recentSearchTitle: UILabel!
  @IBOutlet weak var recentSearchTagList: TagListView!
  @IBOutlet weak var suggestSearchTItle: UILabel!
  @IBOutlet weak var suggestSearchTagList: TagListView!
  @IBOutlet weak var suggestSearchTitleTopContraint: NSLayoutConstraint!
  
  let viewModel = OverviewSearchTokenViewModel()
  weak var delegate: OverviewSearchTokenViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewMainViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMainViewCell.kCellID
    )
    self.recentSearchTagList.textFont = UIFont.Kyber.regular(with: 14)
    self.suggestSearchTagList.textFont = UIFont.Kyber.regular(with: 14)
    self.suggestSearchTagList.addTags(self.viewModel.recommendTags)
    self.updateUIEmptyView()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  func updateUIEmptyView() {
    if self.viewModel.dataSource.isEmpty {
      self.emptyView.isHidden = false
      let recentTags = self.viewModel.getRecentSearchTag()
      self.recentSearchTagList.removeAllTags()
      self.recentSearchTagList.addTags(recentTags)
      if recentTags.isEmpty {
        self.recentSearchTitle.isHidden = true
        self.recentSearchTagList.isHidden = true
        self.suggestSearchTitleTopContraint.constant = 10.0
      } else {
        self.recentSearchTitle.isHidden = false
        self.recentSearchTagList.isHidden = false
        self.suggestSearchTitleTopContraint.constant = 180.0
      }
    } else {
      self.emptyView.isHidden = true
    }
  }
  
  func coordinatorUpdateCurrency(_ mode: CurrencyMode) {
    self.viewModel.currencyMode = mode
  }
}

extension OverviewSearchTokenViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewMainViewCell.kCellID,
      for: indexPath
    ) as! OverviewMainViewCell
    
    let cellModel = self.viewModel.dataSource[indexPath.row]
    cell.updateCell(cellModel)
    return cell
  }
}

extension OverviewSearchTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellModel = self.viewModel.dataSource[indexPath.row]
    switch cellModel.mode {
    case .search(token: let token):
      self.delegate?.overviewSearchTokenViewController(self, open: token)
      self.viewModel.saveNewSearchTag(token.symbol)
    default:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return OverviewMainViewCell.kCellHeight
  }
}

extension OverviewSearchTokenViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    self.viewModel.searchText = text
    self.viewModel.reloadAllData()
    self.tableView.reloadData()
    self.updateUIEmptyView()
    return true
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return false
  }
}

extension OverviewSearchTokenViewController: TagListViewDelegate {
  func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
    let tokens = KNSupportedTokenStorage.shared.allTokens
    if let found = tokens.first(where: { (token) -> Bool in
      return token.symbol.lowercased() == title.lowercased()
    }) {
      self.delegate?.overviewSearchTokenViewController(self, open: found)
    }
  }
}
