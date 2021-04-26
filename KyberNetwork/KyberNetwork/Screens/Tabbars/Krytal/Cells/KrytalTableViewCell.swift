//
//  KrytalTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/18/21.
//

import UIKit

struct KrytalCellViewModel {
  let codeObject: Code
  let referralCode: String
  
  var displayReferralCode: String {
    return self.referralCode
  }

  var displayRatio: String {
    let left = self.codeObject.ratio * 100 / 10000
    let right = 100 - left
    return "\(Int(left))-\(Int(right))"
  }
  
  var displayFriends: String {
    return "\(Int(self.codeObject.totalRefer))"
  }
  
  var displayPendingVol: String {
    return "\(self.codeObject.pendingVol)"
  }
  
  var displayConfirmedVol: String {
    return "\(self.codeObject.realizedVol)"
  }
}

protocol KrytalTableViewCellDelegate: class {
  func krytalTableViewCellDidSelectCopy(_ cell: KrytalTableViewCell, code: String)
  func krytalTableViewCellDidSelectShare(_ cell: KrytalTableViewCell, code: String, codeObject: Code)
  
}

class KrytalTableViewCell: UITableViewCell {
  static let cellHeight: CGFloat = 42
  static let cellID: String = "KrytalTableViewCell"
  
  @IBOutlet weak var referralCodeLabel: UILabel!
  @IBOutlet weak var ratioLabel: UILabel!
  @IBOutlet weak var friendsLabel: UILabel!
  @IBOutlet weak var pendingVolLabel: UILabel!
  @IBOutlet weak var confirmedVolLabel: UILabel!
  
  var viewModel: KrytalCellViewModel?
  weak var delegate: KrytalTableViewCellDelegate?
  
  func updateCell(viewModel: KrytalCellViewModel) {
    self.viewModel = viewModel
    self.referralCodeLabel.text = viewModel.displayReferralCode
    self.ratioLabel.text = viewModel.displayRatio
    self.friendsLabel.text = viewModel.displayFriends
    self.pendingVolLabel.text = viewModel.displayPendingVol
    self.confirmedVolLabel.text = viewModel.displayConfirmedVol
  }
  
  @IBAction func copyButtonTapped(_ sender: UIButton) {
    self.delegate?.krytalTableViewCellDidSelectCopy(self, code: self.viewModel?.referralCode ?? "")
  }
  
  @IBAction func shareButtonTapped(_ sender: UIButton) {
    guard let unwrapped = self.viewModel else {
      return
    }
    self.delegate?.krytalTableViewCellDidSelectShare(self, code: unwrapped.referralCode, codeObject: unwrapped.codeObject)
  }
}
