//
//  WalletListTableViewCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/20/20.
//

import UIKit

struct WalletListTableViewCellViewModel {
  let walletName: String
  let walletAddress: String
  let isCurrentWallet: Bool
}

enum WalletListTableViewCellEvent {
  case copy(address: String)
  case select(address: String)
}

protocol WalletListTableViewCellDelegate: class {
  func walletListTableViewCell(_ controller: WalletListTableViewCell, run event: WalletListTableViewCellEvent)
}

class WalletListTableViewCell: UITableViewCell {
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!
  @IBOutlet weak var checkIconImage: UIImageView!
  @IBOutlet weak var leftPaddingContraint: NSLayoutConstraint!
  
  weak var delegate: WalletListTableViewCellDelegate?
  var viewModel: WalletListTableViewCellViewModel?

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }

  func updateCell(with viewModel: WalletListTableViewCellViewModel) {
    self.viewModel = viewModel
    self.walletNameLabel.text = viewModel.walletName
    self.walletAddressLabel.text = viewModel.walletAddress.lowercased()
    self.checkIconImage.isHidden = !viewModel.isCurrentWallet
    self.leftPaddingContraint.constant = viewModel.isCurrentWallet ? 66.0 : 40.0
  }

  @IBAction func copyButtonTapped(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .copy(address: self.viewModel?.walletAddress ?? ""))
  }

  @IBAction func tapCell(_ sender: UIButton) {
    self.delegate?.walletListTableViewCell(self, run: .select(address: self.viewModel?.walletAddress ?? ""))
  }
}
