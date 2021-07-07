// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import TrustCore
import SwipeCellKit

struct KNContactTableViewCellModel {
  let contact: KNContact
  let index: Int

  init(
    contact: KNContact,
    index: Int
    ) {
    self.contact = contact
    self.index = index
  }

  var addressImage: UIImage? {
    guard let data = Address(string: self.contact.address)?.data else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }

  var displayedName: String { return self.contact.name }

  var nameAndAddressAttributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()

    return attributedString
  }

  var displayedAddress: String {
    let address = self.contact.address.lowercased()
    return "\(address.prefix(20))...\(address.suffix(6))"
  }

  var backgroundColor: UIColor {
    return self.index % 2 == 0 ? UIColor.clear : UIColor.white
  }
}

struct KNWalletTableCellViewModel {
  let wallet: KNWalletObject
  
  var addressImage: UIImage? {
    guard let data = Address(string: self.wallet.address.description)?.data else { return nil }
    return UIImage.generateImage(with: 32, hash: data)
  }

  var displayedName: String { return self.wallet.name }
  var displayedAddress: String {
    let address = self.wallet.address.description.lowercased()
    return "\(address.prefix(20))...\(address.suffix(6))"
  }
}

class KNContactTableViewCell: SwipeTableViewCell {

  static let height: CGFloat = 60

  @IBOutlet weak var addressImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var contactAddressLabel: UILabel!
  
  @IBOutlet weak var checkIcon: UIImageView!
  @IBOutlet weak var addressImageLeftPaddingContraint: NSLayoutConstraint!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    self.contactNameLabel.text = ""
    self.contactAddressLabel.text = ""
    self.addressImageView.rounded(radius: self.addressImageView.frame.height / 2.0)
  }

  func update(with viewModel: KNContactTableViewCellModel) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactNameLabel.addLetterSpacing()
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.contactAddressLabel.addLetterSpacing()
    self.addressImageLeftPaddingContraint.constant = 24
    self.checkIcon.isHidden = true
    self.layoutIfNeeded()
  }
  
  func update(with viewModel: KNWalletTableCellViewModel, selected: String) {
    self.addressImageView.image = viewModel.addressImage
    self.contactNameLabel.text = viewModel.displayedName
    self.contactNameLabel.addLetterSpacing()
    self.contactAddressLabel.text = viewModel.displayedAddress
    self.contactAddressLabel.addLetterSpacing()
    let isSelected = viewModel.wallet.address.description.lowercased() == selected.lowercased()
    self.addressImageLeftPaddingContraint.constant = (isSelected ? 66.0 : 24.0)
    self.checkIcon.isHidden = !isSelected
    self.layoutIfNeeded()
  }
}
