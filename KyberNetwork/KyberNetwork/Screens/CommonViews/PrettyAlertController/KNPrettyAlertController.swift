//
//  KNPrettyAlertController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 5/11/20.
//

import UIKit

class KNPrettyAlertController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!

  let mainTitle: String?
  let message: String
  let yesTitle: String?
  let noTitle: String
  let yesAction:  (() -> Void)?
  let noAction: () -> Void
  init(title: String?,
       message: String,
       yesTitle: String?,
       noTitle: String, yesAction: (() -> Void)?, noAction: @escaping () -> Void) {
    self.mainTitle = title
    self.message = message
    self.yesTitle = yesTitle
    self.noTitle = noTitle
    self.yesAction = yesAction
    self.noAction = noAction
    super.init(nibName: KNPrettyAlertController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }

}
