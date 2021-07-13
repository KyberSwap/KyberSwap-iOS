//
//  WalletsListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/20/20.
//

import UIKit
import MBProgressHUD

enum WalletsListViewEvent {
  case select(wallet: KNWalletObject)
  case copy(wallet: KNWalletObject)
  case manageWallet
  case connectWallet
  case addWallet
}

protocol WalletsListViewControllerDelegate: class {
  func walletsListViewController(_ controller: WalletsListViewController, run event: WalletsListViewEvent)
}

class WalletsListViewModel {
  var wallets: [KNWalletObject]
  var currentWallet: KNWalletObject

  init(
    walletObjects: [KNWalletObject],
    currentWallet: KNWalletObject
    ) {
    self.wallets = walletObjects
    self.currentWallet = currentWallet
  }

  func update(wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.wallets = wallets
    self.currentWallet = currentWallet
  }

  var watchWallets: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return object.isWatchWallet
    }
  }

  var realWallets: [KNWalletObject] {
    return self.wallets.filter { (object) -> Bool in
      return !object.isWatchWallet
    }
  }

  var dataSource: [Any] {
    var data: [Any] = []
    let realSectionViewModels = self.realWallets.map { (object) -> WalletListTableViewCellViewModel in
      return WalletListTableViewCellViewModel(walletName: object.name, walletAddress: object.address, isCurrentWallet: object.address.lowercased() == self.currentWallet.address.lowercased())
    }
    if !realSectionViewModels.isEmpty {
      let sectionViewModel = WalletListSectionTableViewCellViewModel(sectionTile: "Change Wallets", isFirstSection: true)
      data.append(sectionViewModel)
      data.append(contentsOf: realSectionViewModels)
    }

    let watchSectionViewModels = self.watchWallets.map { (object) -> WalletListTableViewCellViewModel in
      return WalletListTableViewCellViewModel(walletName: object.name, walletAddress: object.address, isCurrentWallet: object.address.lowercased() == self.currentWallet.address.lowercased())
    }
    if !watchSectionViewModels.isEmpty {
      let sectionModel = WalletListSectionTableViewCellViewModel(sectionTile: "Watch wallets", isFirstSection: data.isEmpty)
      data.append(sectionModel)
      data.append(contentsOf: watchSectionViewModels)
    }

    return data
  }

  var walletCellRowHeight: CGFloat {
    return 60.0
  }

  var walletCellSectionRowHeight: CGFloat {
    return 80.0
  }

  func getWalletObject(address: String) -> KNWalletObject? {
    return self.wallets.first { (object) -> Bool in
      return object.address.lowercased() == address.lowercased()
    }
  }

  var walletTableViewHeight: CGFloat {
    var realWalletCellsHeight = CGFloat(self.realWallets.count) * self.walletCellRowHeight
    if realWalletCellsHeight > 0 {
      realWalletCellsHeight += self.walletCellSectionRowHeight
    }
    var watchWalletCellsHeight = CGFloat(self.watchWallets.count) * self.walletCellRowHeight
    if watchWalletCellsHeight > 0 {
      watchWalletCellsHeight += self.walletCellSectionRowHeight
    }
    return min(372.0, realWalletCellsHeight + watchWalletCellsHeight)
  }

  func isCurrentWallet(row: Int) -> Bool { return self.wallets[row].address == self.currentWallet.address }
}

class WalletsListViewController: KNBaseViewController {
  @IBOutlet weak var walletTableView: UITableView!
  @IBOutlet weak var manageWalletButton: UIButton!
  @IBOutlet weak var connectWalletButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableViewHeightContraint: NSLayoutConstraint!

  fileprivate var viewModel: WalletsListViewModel

  fileprivate let kWalletTableViewCellID: String = "WalletListTableViewCell"
  fileprivate let kWalletSectionTableViewCellID: String = "WalletListSectionTableViewCell"
  let transitor = TransitionDelegate()
  var delegate: WalletsListViewControllerDelegate?

  init(viewModel: WalletsListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: WalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: WalletListTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kWalletTableViewCellID)

    let sectionNib = UINib(nibName: WalletListSectionTableViewCell.className, bundle: nil)
    self.walletTableView.register(sectionNib, forCellReuseIdentifier: kWalletSectionTableViewCellID)

    self.walletsTableViewHeightContraint.constant = self.viewModel.walletTableViewHeight
    self.walletTableView.allowsSelection = true
  }

  func updateView(with wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: wallets, currentWallet: currentWallet)
    self.walletTableView.reloadData()
    self.walletsTableViewHeightContraint.constant = self.viewModel.walletTableViewHeight
    self.view.layoutIfNeeded()
  }

  @IBAction func manageWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .manageWallet)
    }
  }

  @IBAction func connectWalletButtonTapped(_ sender: UIButton) {
    guard KNGeneralProvider.shared.isEthereum else {
      self.showTopBannerView(message: "WalletConnect for BSC will be supported soon")
      return
    }
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .connectWallet)
    }
  }

  @IBAction func tapView(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension WalletsListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let viewModel = self.viewModel.dataSource[indexPath.row]
    if let sectionViewModel = viewModel as? WalletListSectionTableViewCellViewModel {
      let cell = tableView.dequeueReusableCell(withIdentifier: kWalletSectionTableViewCellID, for: indexPath) as! WalletListSectionTableViewCell
      cell.updateCellWith(viewModel: sectionViewModel)
      cell.delegate = self
      return cell
    }

    if let cellViewModel = viewModel as? WalletListTableViewCellViewModel {
      let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath) as! WalletListTableViewCell
      cell.updateCell(with: cellViewModel)
      cell.delegate = self
      return cell
    }
    return UITableViewCell()
  }
}

extension WalletsListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let viewModel = self.viewModel.dataSource[indexPath.row]
    if let sectionModel = viewModel as? WalletListSectionTableViewCellViewModel {
      return sectionModel.isFirstSection ? 80.0 : 60.0
    } else {
      return 60.0
    }
  }
}

extension WalletsListViewController: WalletListTableViewCellDelegate {
  func walletListTableViewCell(_ controller: WalletListTableViewCell, run event: WalletListTableViewCellEvent) {
    switch event {
    case .copy(let address):
      if let wallet = self.viewModel.getWalletObject(address: address) {
        self.delegate?.walletsListViewController(self, run: .copy(wallet: wallet))
      }
    case .select(let address):
      self.dismiss(animated: true) {
        if let wallet = self.viewModel.getWalletObject(address: address) {
          self.delegate?.walletsListViewController(self, run: .select(wallet: wallet))
        }
      }
    }
  }
}

extension WalletsListViewController: WalletListSectionTableViewCellDelegate {
  func walletListSectionTableViewCellDidSelectAction(_ cell: WalletListSectionTableViewCell) {
    self.dismiss(animated: true) {
      self.delegate?.walletsListViewController(self, run: .addWallet)
    }
  }
}

extension WalletsListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.walletTableViewHeight + 179
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
