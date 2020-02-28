// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNListAlertHeaderView: UITableViewHeaderFooterView {

  @IBOutlet weak var triggeredTextLabel: UILabel!
  @IBOutlet weak var deleteAllButton: UIButton!
  var tapClosure: (() -> Void)?

  func updateText(_ text: String) {
    self.triggeredTextLabel.text = text
  }

  func updateDeleteButtonText(_ closure: @escaping () -> Void) {
    self.deleteAllButton.setTitle("delete all".toBeLocalised().uppercased(), for: .normal)
    self.tapClosure = closure
  }

  @IBAction func deleteAllButtonTapped(_ sender: UIButton) {
    guard let closure = tapClosure else {
      return
    }
    closure()
  }
}
