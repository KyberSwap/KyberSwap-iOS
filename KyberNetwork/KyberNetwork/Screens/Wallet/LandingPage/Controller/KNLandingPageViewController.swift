// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNLandingPageViewEvent {
  case openPromoCode
  case openCreateWallet
  case openImportWallet
  case openTermAndCondition
  case openMigrationAlert
}

protocol KNLandingPageViewControllerDelegate: class {
  func landinagePageViewController(_ controller: KNLandingPageViewController, run event: KNLandingPageViewEvent)
}

class KNLandingPageViewController: KNBaseViewController {

  weak var delegate: KNLandingPageViewControllerDelegate?

  @IBOutlet weak var welcomeScreenCollectionView: KNWelcomeScreenCollectionView!
  @IBOutlet weak var debugButton: UIButton!
  @IBOutlet weak var promoCodeButton: UIButton!
  @IBOutlet weak var createWalletButton: UIButton!
  @IBOutlet weak var importWalletButton: UIButton!
  @IBOutlet weak var termAndConditionButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    let style = KNAppStyleType.current
    self.view.applyGradient(with: UIColor.Kyber.backgroundColors)

    self.promoCodeButton.backgroundColor = .white
    self.promoCodeButton.setTitleColor(
      UIColor(red: 250, green: 107, blue: 100),
      for: .normal
    )
    self.promoCodeButton.setTitle(
      NSLocalizedString("kybercode", value: "KyberCode", comment: ""),
      for: .normal
    )

    self.createWalletButton.backgroundColor = .clear
    self.createWalletButton.setTitleColor(
      .white,
      for: .normal
    )
    self.createWalletButton.setTitle(
      NSLocalizedString("create.wallet", value: "Create Wallet", comment: ""),
      for: .normal
    )
    self.importWalletButton.backgroundColor = .clear
    self.importWalletButton.setTitleColor(
      .white,
      for: .normal
    )
    self.importWalletButton.setTitle(
      NSLocalizedString("import.wallet", value: "Import Wallet", comment: ""),
      for: .normal
    )
    self.importWalletButton.addTextSpacing()

    let radius = style.buttonRadius()
    self.promoCodeButton.rounded(radius: radius)
    self.createWalletButton.rounded(color: .white, width: 1.0, radius: radius)
    self.importWalletButton.rounded(color: .white, width: 1.0, radius: radius)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = NSTextAlignment.center
    let attributeString = NSMutableAttributedString(
      string: "By using KyberSwap, you agree to\n the Terms and Conditions".toBeLocalised(),
      attributes: [
        .font: UIFont.Kyber.medium(with: 14),
        .foregroundColor: UIColor.white,
        .kern: 0.0,
        .paragraphStyle: paragraphStyle,
      ]
    )

    if let range = attributeString.string.range(of: "terms.and.conditions".toBeLocalised()) {
      let r = NSRange(range, in: attributeString.string)
      attributeString.addAttribute(.font, value: UIFont.Kyber.bold(with: 15), range: r)
    }
    self.termAndConditionButton.setAttributedTitle(attributeString, for: .normal)

    self.debugButton.isHidden = false
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if UserDefaults.standard.object(forKey: Constants.isShowMigrationTutorial) == nil {
      self.delegate?.landinagePageViewController(self, run: .openMigrationAlert)
      UserDefaults.standard.set(true, forKey: Constants.isShowMigrationTutorial)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.view.removeSublayer(at: 0)
    self.view.applyGradient(with: UIColor.Kyber.backgroundColors)
  }

  @IBAction func promoCodeButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openPromoCode)
  }

  @IBAction func createWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openCreateWallet)
  }

  @IBAction func importWalletButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openImportWallet)
  }

  @IBAction func termAndConditionButtonPressed(_ sender: Any) {
    self.delegate?.landinagePageViewController(self, run: .openTermAndCondition)
  }

  @IBAction func debugPressed(_ sender: Any) {
    let debugVC = KNDebugMenuViewController()
    self.present(debugVC, animated: true, completion: nil)
  }
}
