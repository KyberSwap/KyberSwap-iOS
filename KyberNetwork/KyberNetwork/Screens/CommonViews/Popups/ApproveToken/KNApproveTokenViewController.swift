// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNApproveTokenViewControllerDelegate: class {
  func approveTokenViewControllerDidCancel(_ controller: KNApproveTokenViewController)
  func approveTokenViewControllerDidConfirm(_ controller: KNApproveTokenViewController, isReset: Bool)
}

class KNApproveTokenViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var descTextLabel: UILabel!
  @IBOutlet weak var addressContainerView: UIView!
  @IBOutlet weak var addressTextLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!

  @IBOutlet weak var separatorView: UIView!
  @IBOutlet weak var approveButton: UIButton!

  weak var delegate: KNApproveTokenViewControllerDelegate?
  let token: TokenObject
  let userAddress: String
  let isReset: Bool
  let isSwap: Bool
  let fee: BigInt

  init(token: TokenObject, isReset: Bool, isSwap: Bool, userAddress: String, fee: BigInt) {
    self.token = token
    self.isReset = isReset
    self.isSwap = isSwap
    self.userAddress = userAddress
    self.fee = fee
    super.init(nibName: KNApproveTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 5.0)
    self.titleTextLabel.text = "Approve".toBeLocalised()

    let resetText: String = String(
      format: "You need reset allowance %@ of KyberSwap with this address".toBeLocalised(),
      self.token.symbol
    )
    let approveText: String = String(
      format: "You need approve KyberSwap to use token %@".toBeLocalised(),
      self.token.symbol
    )
    self.descTextLabel.text = self.isReset ? resetText : approveText

    self.addressContainerView.rounded(radius: 4.0)
    self.addressTextLabel.attributedText = {
      let attributedString = NSMutableAttributedString()
      let normalAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 158, green: 161, blue: 170),
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      ]
      let highlightAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      ]
      attributedString.append(NSAttributedString(string: "Addr ", attributes: normalAttributes))
      attributedString.append(NSAttributedString(string: self.userAddress, attributes: highlightAttributes))
      return attributedString
    }()

    self.feeLabel.text = NSLocalizedString("fee", value: "Fee", comment: "") + ": \(self.fee.displayRate(decimals: 18)) ETH"
    self.separatorView.backgroundColor = .clear
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
    self.approveButton.rounded()
    self.approveButton.applyGradient()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.approveTokenViewControllerDidCancel(self)
    }
  }

  @IBAction func approveButtonPressed(_ sender: Any) {
    self.delegate?.approveTokenViewControllerDidConfirm(self, isReset: self.isReset)
  }
}
