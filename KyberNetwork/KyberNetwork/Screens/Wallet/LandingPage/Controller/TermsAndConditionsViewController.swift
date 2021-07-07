//
//  TermsAndConditionsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/9/21.
//

import UIKit

class TermsAndConditionsViewController: KNBaseViewController {
  
  @IBOutlet weak var acceptTermTextView: UITextView!
  @IBOutlet weak var checkBoxButton: UIButton!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  var isAccepted: Bool = false
  var nextAction: (() -> ())?
  
  init() {
    super.init(nibName: TermsAndConditionsViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.checkBoxButton.rounded(radius: 2)
    self.nextButton.rounded(radius: 16)
    self.updateUI()
    let linkAttributes: [String: Any] = [
      NSAttributedStringKey.font.rawValue: UIFont.Kyber.regular(with: 14),
      NSAttributedStringKey.foregroundColor.rawValue: UIColor(named: "buttonBackgroundColor")!,
    ]
    let amountAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.regular(with: 15),
      NSAttributedStringKey.foregroundColor: UIColor(named: "textWhiteColor")!,
    ]
    let attributionString = NSMutableAttributedString(string: "I accept Terms of Use and Privacy Policy", attributes: amountAttributes)
    attributionString.addAttribute(.link, value: "https://files.krystal.app/terms.pdf", range: NSRange(location: 9, length: 12))
    attributionString.addAttribute(.link, value: "https://files.krystal.app/privacy.pdf", range: NSRange(location: 25, length: 15))
    self.acceptTermTextView.linkTextAttributes = linkAttributes
    
    self.acceptTermTextView.attributedText = attributionString
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func checkBoxButtonTapped(_ sender: Any) {
    self.isAccepted = !isAccepted
    self.updateUI()
  }
  
  @IBAction func nextButtonTapped(_ sender: Any) {
    self.dismiss(animated: true) {
      UserDefaults.standard.set(true, forKey: Constants.acceptedTermKey)
      if let action = self.nextAction {
        action()
      }
    }
    
    
  }
  
  fileprivate func updateUI() {
    if self.isAccepted {
      self.checkBoxButton.setImage(UIImage(named: "filter_check_icon"), for: .normal)
      self.nextButton.isEnabled = true
      self.nextButton.alpha = 1
    } else {
      self.checkBoxButton.setImage(nil, for: .normal)
      self.nextButton.isEnabled = false
      self.nextButton.alpha = 0.5
    }
  }

  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    UIApplication.shared.open(URL)
    return false
  }
}

extension TermsAndConditionsViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 200
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
