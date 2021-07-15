// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var qrcodeImageView: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!

  @IBOutlet weak var copyWalletButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var infoLabel: UILabel!

  fileprivate var viewModel: KNWalletQRCodeViewModel

  fileprivate let style = KNAppStyleType.current

  init(viewModel: KNWalletQRCodeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNWalletQRCodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupWalletData()
    self.setupButtons()
  }


  fileprivate func setupWalletData() {
    self.titleLabel.text = self.viewModel.wallet.name
    self.addressLabel.text = self.viewModel.displayedAddress
    let text = self.viewModel.address
    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: text)
      DispatchQueue.main.async {
        self.qrcodeImageView.image = image
      }
    }
  }

  fileprivate func setupButtons() {
    self.shareButton.rounded(
      radius: 16
    )
    self.copyWalletButton.rounded(
      color: UIColor.Kyber.SWButtonBlueColor,
      width: 1.0,
      radius: 16
    )
    self.copyWalletButton.setTitle(
      NSLocalizedString("copy", value: "Copy", comment: ""),
      for: .normal
    )
    self.shareButton.setTitle(
      NSLocalizedString("share", value: "Share", comment: ""),
      for: .normal
    )
    let token = KNGeneralProvider.shared.isEthereum ? "ERC20" : "BEP20"
    let quoteToken = KNGeneralProvider.shared.isEthereum ? "ETH" : "BNB"
    let attributedString = NSMutableAttributedString(string: "Only send \(quoteToken) or any \(token) token to this address\n\n*Sending any other tokens may result in loss of your funds", attributes: [
      .font: UIFont.Kyber.regular(with: 14),
      .foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      .kern: 0.0,
    ])
    if let range = attributedString.string.range(of: "Only send \(quoteToken) or any \(token)".toBeLocalised()) {
      let r = NSRange(range, in: attributedString.string)
      attributedString.addAttribute(.font, value: UIFont.Kyber.regular(with: 14), range: r)
    }
    self.infoLabel.attributedText = attributedString
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyWalletButtonPressed(_ sender: Any) {
    UIPasteboard.general.string = self.viewModel.address

    self.showMessageWithInterval(
      message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
    )
  }

  @IBAction func shareButtonPressed(_ sender: UIButton) {
    let activityItems: [Any] = {
      var items: [Any] = []
      items.append(self.viewModel.shareText)
      if let image = self.qrcodeImageView.image { items.append(image) }
      return items
    }()
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    activityViewController.popoverPresentationController?.sourceView = sender
    self.present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.navigationController?.popViewController(animated: true)
    }
  }
}
