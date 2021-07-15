//
//  OverviewChangeCurrencyViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 7/13/21.
//

import UIKit

class OverviewChangeCurrencyViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  @IBOutlet weak var btcButton: UIButton!
  
  var selected: CurrencyMode = .usd
  var completeHandle: ((CurrencyMode) -> Void)?
  
  init(mode: CurrencyMode) {
    self.selected = mode
    super.init(nibName: OverviewChangeCurrencyViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.updateUI()
  }
  
  fileprivate func updateUI() {
    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0
    
    self.usdButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == .usd ? selectedWidth : normalWidth,
      radius: 8
    )
    
    self.ethButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == .eth ? selectedWidth : normalWidth,
      radius: 8
    )
    
    self.btcButton.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.selected == .btc ? selectedWidth : normalWidth,
      radius: 8
    )
  }

  @IBAction func currencyTypeButtonTapped(_ sender: UIButton) {
    guard let type = CurrencyMode(rawValue: sender.tag) else {
      return
    }
    self.selected = type
    self.updateUI()
    
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      if let handle = self.completeHandle {
        handle(self.selected)
      }
    })
  }
}

extension OverviewChangeCurrencyViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 300
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
