//
//  KNSelectMarketViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/7/20.
//

import UIKit

class KNSelectMarketViewController: KNBaseViewController {
  @IBOutlet weak var tableView: UITableView!
  
  
  fileprivate let viewModel: KNSelectMarketViewModel
  
  init(viewModel: KNSelectMarketViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSelectMarketViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupMarketTableView()
  }

  fileprivate func setupMarketTableView() {
    let nib = UINib(nibName: KNMarketTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: KNMarketTableViewCell.kCellID
    )
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.rowHeight = KNBalanceTokenTableViewCell.kCellHeight
    self.tableView.reloadData()
  }

  func coordinatorMarketCachedDidUpdate() {
    self.viewModel.updateMarketFromCoordinator()
  }
}

extension KNSelectMarketViewController: UITableViewDelegate {
}

extension KNSelectMarketViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.cellViewModels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KNMarketTableViewCell.kCellID,
      for: indexPath
    ) as! KNMarketTableViewCell
    let viewModel = self.viewModel.cellViewModels[indexPath.row]
    cell.updateViewModel(viewModel)
    return cell
  }
}
