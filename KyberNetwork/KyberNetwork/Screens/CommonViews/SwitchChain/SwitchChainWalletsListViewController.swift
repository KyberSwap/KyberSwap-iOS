//
//  SwitchChainWalletsListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/2/21.
//

import UIKit

class SwitchChainWalletsListViewModel {
  let dataSource: [KNWalletTableCellViewModel]
  var selectedAddress: String = ""
  init() {
    self.dataSource = KNWalletStorage.shared.wallets.map({ (obj) -> KNWalletTableCellViewModel in
      return KNWalletTableCellViewModel(wallet: obj)
    })
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      self.selectedAddress = appDelegate.coordinator.session.wallet.address.description
    }
  }
  
  var title: String {
    return "Choose Wallet"
  }
}

class SwitchChainWalletsListViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var walletsTableView: UITableView!
  let kContactTableViewCellID: String = "kContactTableViewCellID"
  
  let transitor = TransitionDelegate()
  let viewModel = SwitchChainWalletsListViewModel()
  
  init() {
    super.init(nibName: SwitchChainWalletsListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
    
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: KNContactTableViewCell.className, bundle: nil)
    self.walletsTableView.register(nib, forCellReuseIdentifier: kContactTableViewCellID)
    self.walletsTableView.rowHeight = KNContactTableViewCell.height
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self
    self.titleLabel.text = self.viewModel.title
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      KNGeneralProvider.shared.isEthereum = !KNGeneralProvider.shared.isEthereum
      KNNotificationUtil.postNotification(for: kChangeChainNotificationKey, object: self.viewModel.selectedAddress)
    }
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
}

extension SwitchChainWalletsListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}


extension SwitchChainWalletsListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cellModel = self.viewModel.dataSource[indexPath.row]
    self.viewModel.selectedAddress = cellModel.wallet.address.description
    tableView.reloadData()
  }
}

extension SwitchChainWalletsListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath) as! KNContactTableViewCell
    let cellModel = self.viewModel.dataSource[indexPath.row]
    cell.update(with: cellModel, selected: self.viewModel.selectedAddress)
    return cell
  }
}
