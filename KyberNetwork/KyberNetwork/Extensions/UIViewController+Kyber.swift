// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SafariServices
import MBProgressHUD

extension UIViewController {

  func showInsufficientBalanceAlert() {
    let alertController: UIAlertController = {
      let alert = UIAlertController(
        title: NSLocalizedString("insufficient.balance", comment: ""),
        message: NSLocalizedString("you.do.not.have.enough.balance.to.make.the.transaction", comment: ""),
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      return alert
    }()
    self.present(alertController, animated: true, completion: nil)
  }

  func showInvalidDataToMakeTransactionAlert() {
    let alertController = UIAlertController(
      title: nil,
      message: NSLocalizedString("invalid.data.to.make.the.transaction", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }

  func showMessageWithInterval(message: String, time: TimeInterval = 1.5) {
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = message
    hud.hide(animated: true, afterDelay: time)
  }

  func openSafari(with url: URL) {
    guard UIApplication.shared.canOpenURL(url) else {
      return
    }
    let safariVC = SFSafariViewController(url: url)
    self.present(safariVC, animated: true, completion: nil)
  }

  func openSafari(with string: String) {
    guard let url = URL(string: string) else { return }
    self.openSafari(with: url)
  }

  func bottomPaddingSafeArea() -> CGFloat {
    if #available(iOS 11, *) { return 0.0 }
    return 50.0
  }
}
