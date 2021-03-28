// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNWelcomeScreenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWelcomeScreenCollectionViewCellID"
  static let height: CGFloat = 246

  @IBOutlet weak var imageView: UIImageView!
  

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
  }

  func updateCell(with data: KNWelcomeScreenViewModel.KNWelcomeData) {
    self.imageView.image = UIImage(named: data.icon)
  }
}
