//
//  CustomTokenListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/21/21.
//

import UIKit
import SwipeCellKit

class CustomTokenListViewModel {
  var dataSource: [CustomTokenCellViewModel] = []
  
  func reloadData() {
    self.dataSource = KNSupportedTokenStorage.shared.getCustomToken().map({ (token) -> CustomTokenCellViewModel in
      let balance = BalanceStorage.shared.balanceForAddress(token.address)
      let viewModel = CustomTokenCellViewModel(token: token, balance: balance?.balance ?? "---")
      return viewModel
    })
  }
}

enum CustomTokenListViewEvent {
  case edit(token: Token)
  case delete(token: Token)
  case add
}

protocol CustomTokenListViewControllerDelegate: class {
  func customTokenListViewController(_ controller: CustomTokenListViewController, run event: CustomTokenListViewEvent)
}

class CustomTokenListViewController: KNBaseViewController {
  
  @IBOutlet weak var tokenTableView: UITableView!
  let viewModel = CustomTokenListViewModel()
  weak var delegate: CustomTokenListViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: CustomTokenTableViewCell.className, bundle: nil)
    self.tokenTableView.register(
      nib,
      forCellReuseIdentifier: CustomTokenTableViewCell.kCellID
    )
    self.tokenTableView.rowHeight = CustomTokenTableViewCell.kCellHeight
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.viewModel.reloadData()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func addTokenButtonTapped(_ sender: UIButton) {
    self.delegate?.customTokenListViewController(self, run: .add)
  }
  
  func coordinatorDidUpdateTokenList() {
    self.viewModel.reloadData()
    self.tokenTableView.reloadData()
  }
}

extension CustomTokenListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: CustomTokenTableViewCell.kCellID,
      for: indexPath
    ) as! CustomTokenTableViewCell

    cell.updateCell(self.viewModel.dataSource[indexPath.row])
    cell.delegate = self
    return cell
  }
}

extension CustomTokenListViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else {
      return nil
    }
    let token = self.viewModel.dataSource[indexPath.row].token
    let edit = SwipeAction(style: .default, title: nil) { (_, _) in
      self.delegate?.customTokenListViewController(self, run: .edit(token: token))
    }
    edit.hidesWhenSelected = true
    edit.title = "Edit".toBeLocalised().uppercased()
    edit.textColor = UIColor.Kyber.SWYellow
    edit.font = UIFont.Kyber.latoBold(with: 10)
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: CustomTokenTableViewCell.kCellHeight))!
    edit.backgroundColor = UIColor(patternImage: resized)

    let delete = SwipeAction(style: .default, title: nil) { _, _ in
      self.delegate?.customTokenListViewController(self, run: .delete(token: token))
    }
    delete.title = "Delete".toBeLocalised().uppercased()
    delete.textColor = UIColor.Kyber.SWYellow
    delete.font = UIFont.Kyber.latoBold(with: 10)
    delete.backgroundColor = UIColor(patternImage: resized)

    return [edit, delete]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
