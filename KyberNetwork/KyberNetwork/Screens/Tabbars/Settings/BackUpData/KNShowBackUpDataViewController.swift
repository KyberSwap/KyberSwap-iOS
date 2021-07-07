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
    self.saveButton.rounded(radius: 16)
    self.saveButton.setTitle(NSLocalizedString("save", value: "Save", comment: ""), for: .normal)
    let fullString = NSMutableAttributedString()
    let image1Attachment = NSTextAttachment()
    image1Attachment.image = UIImage(named: "warning_yellow_icon")
    let image1String = NSAttributedString(attachment: image1Attachment)
    fullString.append(image1String)
    fullString.append(NSAttributedString(string: " " + "export.at.your.own.risk".toBeLocalised()))
    self.warningMessageLabel.attributedText = fullString
    self.dataLabel.text = self.backupData
    self.qrcodeImageView.image = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.qrcodeImageView.image = UIImage.generateQRCode(from: self.backupData)
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
    let fileName = "krystal_backup_\(self.wallet.description)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
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
