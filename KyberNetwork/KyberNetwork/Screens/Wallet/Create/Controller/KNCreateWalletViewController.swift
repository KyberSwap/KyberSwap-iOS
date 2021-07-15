// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNCreateWalletViewEvent {
  case back
  case next(name: String)
  case openQR
  case sendRefCode(code: String)
}

protocol KNCreateWalletViewControllerDelegate: class {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent)
}

class KNCreateWalletViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var confirmLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var refCodeField: UITextField!
  @IBOutlet weak var containerRefCodeView: UIView!
  @IBOutlet weak var refCodeTitleLabel: UILabel!
  
  let transitor = TransitionDelegate()

  weak var delegate: KNCreateWalletViewControllerDelegate?

  init() {
    super.init(nibName: KNCreateWalletViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.containerView.rounded(radius: 5.0)
    self.confirmLabel.text = NSLocalizedString("confirm", value: "Confirm", comment: "").uppercased()
    self.descLabel.text = "This will create a new wallet for you to send and receive tokens. Same wallet can be used on both chains ETH and BSC."
    self.confirmButton.rounded(radius: 16)
    self.confirmButton.setTitle(
      NSLocalizedString("confirm", value: "Confirm", comment: ""),
      for: .normal
    )
    self.refCodeField.attributedPlaceholder = NSAttributedString(string: "Paste your Referral Code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.view.isUserInteractionEnabled = true
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
      self.delegate?.createWalletViewController(self, run: .back)
    })
    
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    if let text = self.refCodeField.text, !text.isEmpty {
      self.delegate?.createWalletViewController(self, run: .sendRefCode(code: text.uppercased()))
    }
    self.delegate?.createWalletViewController(self, run: .next(name: "New Wallet"))
  }

  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.refCodeField.text = string
    }
  }
  
  @IBAction func qrCodeButtonTapped(_ sender: UIButton) {
    self.delegate?.createWalletViewController(self, run: .openQR)
  }
  
  func containerViewDidUpdateRefCode(_ refCode: String) {
    self.refCodeField.text = refCode
  }
}

extension KNCreateWalletViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 400
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
