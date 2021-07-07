//
//  SwitchChainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 5/21/21.
//

import UIKit


class SwitchChainViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var ethCheckMarkIcon: UIImageView!
  @IBOutlet weak var bscCheckMarkIcon: UIImageView!
  var isEthChainSelected: Bool
  var completionHandler: () -> Void = { }
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  
  
  init() {
    self.isEthChainSelected = KNGeneralProvider.shared.isEthereum
    super.init(nibName: SwitchChainViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
    
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateSelectedChainUI()
    self.cancelButton.rounded(radius: 16)
    self.nextButton.rounded(radius: 16)
  }
  
  fileprivate func updateSelectedChainUI() {
    self.ethCheckMarkIcon.isHidden = !self.isEthChainSelected
    self.bscCheckMarkIcon.isHidden = self.isEthChainSelected
    let enableNextButton = self.isEthChainSelected != KNGeneralProvider.shared.isEthereum
    self.nextButton.isEnabled = enableNextButton
    self.nextButton.alpha = enableNextButton ? 1.0 : 0.5
    
  }
  
  @IBAction func ethButtonTapped(_ sender: UIButton) {
    self.isEthChainSelected = true
    self.updateSelectedChainUI()
  }
  
  @IBAction func bscButtonTapped(_ sender: UIButton) {
    self.isEthChainSelected = false
    self.updateSelectedChainUI()
  }
  
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    
    self.dismiss(animated: true, completion: {
      self.completionHandler()
    })
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SwitchChainViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
