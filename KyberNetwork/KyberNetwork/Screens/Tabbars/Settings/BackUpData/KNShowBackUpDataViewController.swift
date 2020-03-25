// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNShowBackUpDataViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var warningMessageLabel: UILabel!
  @IBOutlet weak var qrcodeImageView: UIImageView!
  @IBOutlet weak var dataLabel: UILabel!
  @IBOutlet weak var saveButton: UIButton!

  fileprivate let backupData: String
  fileprivate let wallet: String

  init(wallet: String, backupData: String) {
    self.backupData = backupData
    self.wallet = wallet
    super.init(nibName: "KNShowBackUpDataViewController", bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = NSLocalizedString("backup.your.wallet", value: "Backup Your Wallet", comment: "")
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.saveButton.rounded()
    self.saveButton.applyGradient(with: UIColor.Kyber.buttonColors)
    self.saveButton.setTitle(NSLocalizedString("save", value: "Save", comment: ""), for: .normal)
    self.warningMessageLabel.text = NSLocalizedString("export.at.your.own.risk", value: "Export at your own risk!", comment: "")
    self.dataLabel.text = self.backupData
    self.qrcodeImageView.image = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.qrcodeImageView.image = UIImage.generateQRCode(from: self.backupData)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.saveButton.removeSublayer(at: 0)
    self.saveButton.applyGradient(with: UIColor.Kyber.buttonColors)
  }

  @IBAction func edgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.navigationController?.popViewController(animated: true)
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    let fileName = "kyberswap_backup_\(self.wallet.description)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
    do {
      try self.backupData.data(using: .utf8)!.write(to: url)
    } catch { return }
    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, result, _, error in
      do { try FileManager.default.removeItem(at: url)
      } catch { }
    }
    activityViewController.popoverPresentationController?.sourceView = self.view
    activityViewController.popoverPresentationController?.sourceRect = self.view.centerRect
    self.present(activityViewController, animated: true, completion: nil)
  }
}
