//
//  EarnMenuViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/26/21.
//

import UIKit

protocol EarnMenuViewControllerDelegate: class {
  func earnMenuViewControllerDidSelectToken(controller: EarnMenuViewController, token: TokenData)
}

class EarnMenuViewModel {
  var dataSource: [EarnMenuTableViewCellViewModel] = []
  var wallet: Wallet?
}

class EarnMenuViewController: KNBaseViewController {
  @IBOutlet weak var menuTableView: UITableView!
  @IBOutlet weak var walletsSelectButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  
  let viewModel: EarnMenuViewModel
  weak var delegate: EarnMenuViewControllerDelegate?
  fileprivate var isViewSetup: Bool = false
  weak var navigationDelegate: NavigationBarDelegate?

  init(viewModel: EarnMenuViewModel) {
    self.viewModel = viewModel
    super.init(nibName: EarnMenuViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: EarnMenuTableViewCell.className, bundle: nil)
    self.menuTableView.register(
      nib,
      forCellReuseIdentifier: EarnMenuTableViewCell.kCellID
    )
    self.menuTableView.rowHeight = EarnMenuTableViewCell.kCellHeight
    if let notNil = self.viewModel.wallet {
      self.updateUIWalletSelectButton(notNil)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.isViewSetup = true
    self.updateUIPendingTxIndicatorView()
  }
  
  fileprivate func updateUIWalletSelectButton(_ wallet: Wallet) {
    self.walletsSelectButton.setTitle(wallet.address.description, for: .normal)
  }

  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }

  @IBAction func walletsButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    self.pendingTxIndicatorView.isHidden = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }
  
  func coordinatorDidUpdateLendingToken(_ tokens: [TokenData]) {
    self.viewModel.dataSource = tokens.map { EarnMenuTableViewCellViewModel(token: $0) }
    if self.isViewSetup {
      self.menuTableView.reloadData()
    }
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.viewModel.wallet = wallet
    if self.isViewSetup {
      self.updateUIWalletSelectButton(wallet)
    }
  }
  
  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
}

extension EarnMenuViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: EarnMenuTableViewCell.kCellID,
      for: indexPath
    ) as! EarnMenuTableViewCell
    let cellViewModel = viewModel.dataSource[indexPath.row]
    cell.updateCellWithViewModel(cellViewModel)
    return cell
  }
}

extension EarnMenuViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.earnMenuViewControllerDidSelectToken(controller: self, token: self.viewModel.dataSource[indexPath.row].token)
  }
}
