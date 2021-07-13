// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BetterSegmentedControl
import SwipeCellKit

enum KNListWalletsViewEvent {
  case close
  case select(wallet: KNWalletObject)
  case remove(wallet: KNWalletObject)
  case edit(wallet: KNWalletObject)
  case addWallet(type: AddNewWalletType)
}

protocol KNListWalletsViewControllerDelegate: class {
  func listWalletsViewController(_ controller: KNListWalletsViewController, run event: KNListWalletsViewEvent)
}

class KNListWalletsViewModel {
  var listWallets: [KNWalletObject] = []
  var curWallet: KNWalletObject
  var isDisplayWatchWallets: Bool = false

  init(listWallets: [KNWalletObject], curWallet: KNWalletObject) {
    self.listWallets = listWallets
    self.curWallet = curWallet
  }

  var displayWallets: [KNWalletObject] {
    return self.listWallets.filter { (object) -> Bool in
      return object.isWatchWallet == self.isDisplayWatchWallets
    }
  }

  var numberRows: Int { return self.displayWallets.count }
  func wallet(at row: Int) -> KNWalletObject { return self.displayWallets[row] }
  func isCurrentWallet(row: Int) -> Bool { return self.displayWallets[row].address == self.curWallet.address }

  func update(wallets: [KNWalletObject], curWallet: KNWalletObject) {
    self.listWallets = wallets
    self.curWallet = curWallet
  }
}

class KNListWalletsViewController: KNBaseViewController {

  fileprivate let kCellID: String = "walletsTableViewCellID"

  weak var delegate: KNListWalletsViewControllerDelegate?
  fileprivate var viewModel: KNListWalletsViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var walletTableView: UITableView!
  @IBOutlet weak var bottomPaddingConstraintForTableView: NSLayoutConstraint!
  fileprivate var longPressTimer: Timer?
  @IBOutlet weak var emptyView: UIView!
  @IBOutlet weak var emptyMessageLabel: UILabel!
  @IBOutlet weak var emptyViewAddButton: UIButton!
  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var segmentedControl: SegmentedControl!
  
  init(viewModel: KNListWalletsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNListWalletsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    segmentedControl.highlightSelectedSegment()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
    self.setupWalletTableView()
    self.setupSegmentedControl()
    self.emptyViewAddButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.emptyViewAddButton.frame.size.height / 2)
    self.updateEmptyView()
    self.addWalletButton.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: 16)
  }

  @IBAction func segmentedControlDidChange(_ sender: UISegmentedControl) {
    segmentedControl.underlinePosition()
    self.viewModel.isDisplayWatchWallets = self.segmentedControl.selectedSegmentIndex == 1
    self.updateEmptyView()
    self.walletTableView.reloadData()
  }
  
  fileprivate func setupSegmentedControl() {
    segmentedControl.frame = CGRect(x: self.segmentedControl.frame.minX, y: self.segmentedControl.frame.minY, width: segmentedControl.frame.width, height: 30)
  }

  fileprivate func setupNavigationBar() {
  }

  fileprivate func setupWalletTableView() {
    let nib = UINib(nibName: KNListWalletsTableViewCell.className, bundle: nil)
    self.walletTableView.register(nib, forCellReuseIdentifier: kCellID)
    self.walletTableView.rowHeight = 60.0
    self.walletTableView.delegate = self
    self.walletTableView.dataSource = self
    self.bottomPaddingConstraintForTableView.constant = self.bottomPaddingSafeArea()

    self.walletTableView.isUserInteractionEnabled = true

    self.view.layoutIfNeeded()
  }

  func updateView(with wallets: [KNWalletObject], currentWallet: KNWalletObject) {
    self.viewModel.update(wallets: wallets, curWallet: currentWallet)
    self.updateEmptyView()
    self.walletTableView.reloadData()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateEmptyView() {
    self.emptyView.isHidden = !self.viewModel.displayWallets.isEmpty
    let walletString = self.segmentedControl.selectedSegmentIndex == 0 ? "wallet" : "watched wallet"
    self.emptyMessageLabel.text = "Your list of \(walletString)s is empty.".toBeLocalised()
    self.addWalletButton.setTitle("Add " + walletString, for: .normal)
  }

  func coordinatorDidUpdateWalletsList() {
    //TODO: perform wait wallet save to disk
    self.viewModel.listWallets = KNWalletStorage.shared.wallets
    self.walletTableView.reloadData()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .close)
  }

  @IBAction func addButtonPressed(_ sender: Any) {
    self.delegate?.listWalletsViewController(self, run: .addWallet(type: .full))
  }

  @IBAction func emptyViewAddButtonTapped(_ sender: UIButton) {
    self.delegate?.listWalletsViewController(self, run: self.viewModel.isDisplayWatchWallets ? .addWallet(type: .watch) : .addWallet(type: .onlyReal))
  }
}

extension KNListWalletsViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let wallet = self.viewModel.wallet(at: indexPath.row)
    let alertController = UIAlertController(
      title: "",
      message: NSLocalizedString("Choose your action", value: "Choose your action", comment: ""),
      preferredStyle: .actionSheet
    )
    if wallet.address.lowercased() != self.viewModel.curWallet.address.lowercased() {
      alertController.addAction(UIAlertAction(title: NSLocalizedString("Switch Wallet", comment: ""), style: .default, handler: { _ in
        self.delegate?.listWalletsViewController(self, run: .select(wallet: wallet))
      }))
    }
    alertController.addAction(UIAlertAction(title: NSLocalizedString("edit", value: "Edit", comment: ""), style: .default, handler: { _ in
      self.delegate?.listWalletsViewController(self, run: .edit(wallet: wallet))
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("delete", value: "Delete", comment: ""), style: .destructive, handler: { _ in
      self.delegate?.listWalletsViewController(self, run: .remove(wallet: wallet))
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }
}

extension KNListWalletsViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kCellID, for: indexPath) as! KNListWalletsTableViewCell
    let wallet = self.viewModel.wallet(at: indexPath.row)
    cell.updateCell(with: wallet, id: indexPath.row)
    cell.delegate = self
    if self.viewModel.isCurrentWallet(row: indexPath.row) {
      cell.accessoryType = .checkmark
      cell.tintColor = UIColor.Kyber.SWGreen
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
}

extension KNListWalletsViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }
    let wallet = self.viewModel.wallet(at: indexPath.row)

    let copy = SwipeAction(style: .default, title: nil) { (_, _) in
      UIPasteboard.general.string = wallet.address
      self.showMessageWithInterval(
        message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
      )
    }
    copy.hidesWhenSelected = true
    copy.title = "copy".toBeLocalised().uppercased()
    copy.textColor = UIColor(named: "normalTextColor")
    copy.font = UIFont.Kyber.medium(with: 12)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 60))!
    copy.backgroundColor = UIColor(patternImage: resized)

    let edit = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.listWalletsViewController(self, run: .edit(wallet: wallet))
    }
    edit.title = "edit".toBeLocalised().uppercased()
    edit.textColor = UIColor(named: "normalTextColor")
    edit.font = UIFont.Kyber.medium(with: 12)
    edit.backgroundColor = UIColor(patternImage: resized)

    let delete = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.listWalletsViewController(self, run: .remove(wallet: wallet))
    }
    delete.title = "delete".toBeLocalised().uppercased()
    delete.textColor = UIColor(named: "normalTextColor")
    delete.font = UIFont.Kyber.medium(with: 12)
    delete.backgroundColor = UIColor(patternImage: resized)

    return [delete, edit, copy]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
