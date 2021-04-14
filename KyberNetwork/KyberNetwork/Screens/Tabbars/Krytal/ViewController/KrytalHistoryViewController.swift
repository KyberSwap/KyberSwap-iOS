//
//  KrytalHistoryViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/3/21.
//

import UIKit

class KrytalHistoryViewModel {
  var wallet: Wallet?
  var claimedItems: [Claim] = [] {
    didSet {
      let dates = self.claimedItems.map { (item) -> String in
        let time = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
        return self.dateFormatter.string(from: time)
      }
      var uniqueDates = [String]()
      dates.forEach({
        if !uniqueDates.contains($0) { uniqueDates.append($0) }
      })
      self.headers = uniqueDates
      var data: [String: [ClaimHistoryCellViewModel]] = [:]
      self.claimedItems.forEach { (item) in
        let viewModel = ClaimHistoryCellViewModel(historyItem: item)
        let time = Date(timeIntervalSince1970: TimeInterval(item.timestamp))
        let timeString = self.dateFormatter.string(from: time)
        var trans = data[timeString] ?? []
        trans.append(viewModel)
        data[timeString] = trans
      }
      self.dataSources = data
    }
  }
  var dateFormatter: DateFormatter = {
    return DateFormatterUtil.shared.limitOrderFormatter
  }()
  
  var dataSources: [String: [ClaimHistoryCellViewModel]] = [:]
  var headers: [String] = []
}

enum KrytalHistoryViewEvent {
  case openWalletList
  case select(hash: String)
}

protocol KrytalHistoryViewControllerDelegate: class {
  func krytalHistoryViewController(_ controller: KrytalHistoryViewController, run event: KrytalHistoryViewEvent)
}

class KrytalHistoryViewController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var historyTableView: UITableView!
  let viewModel = KrytalHistoryViewModel()
  weak var delegate: KrytalHistoryViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: ClaimHistoryTableViewCell.className, bundle: nil)
    self.historyTableView.register(nib, forCellReuseIdentifier: ClaimHistoryTableViewCell.cellID)
    self.historyTableView.rowHeight = ClaimHistoryTableViewCell.cellHeight
    self.walletListButton.rounded(radius: self.walletListButton.frame.size.height / 2)
    self.updateUI()
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func walletListButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalHistoryViewController(self, run: .openWalletList)
  }
  
  fileprivate func updateUI() {
    self.historyTableView.reloadData()
    self.walletListButton.setTitle(self.viewModel.wallet?.address.description, for: .normal)
  }

  func coordinatorDidUpdateClaimedTransaction(_ items: [Claim]) {
    self.viewModel.claimedItems = items
    guard self.isViewLoaded else {
      return
    }
    self.historyTableView.reloadData()
  }
  
  func coordinatorDidUpdateWallet(_ wallet: Wallet) {
    self.viewModel.wallet = wallet
    guard self.isViewLoaded else { return }
    self.updateUI()
  }
}

extension KrytalHistoryViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.headers.count
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let header = self.viewModel.headers[section]
    return self.viewModel.dataSources[header]?.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ClaimHistoryTableViewCell.cellID,
      for: indexPath
    ) as! ClaimHistoryTableViewCell
    let header = self.viewModel.headers[indexPath.section]
    if let viewModel = self.viewModel.dataSources[header]?[indexPath.row] {
      cell.updateCell(viewModel: viewModel)
    }
    
    return cell
  }
  
}

extension KrytalHistoryViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 18, y: 0, width: 100, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = self.viewModel.headers[section]
    titleLabel.font = UIFont.Kyber.latoBold(with: 12)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let header = self.viewModel.headers[indexPath.section]
    if let viewModel = self.viewModel.dataSources[header]?[indexPath.row] {
      self.delegate?.krytalHistoryViewController(self, run: .select(hash: viewModel.historyItem.txHash))
    }
  }
}
