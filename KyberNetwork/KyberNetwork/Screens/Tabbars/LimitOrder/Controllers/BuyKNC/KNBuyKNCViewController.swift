//
//  KNBuyKNCViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/25/20.
//

import UIKit

class KNBuyKNCViewController: KNBaseViewController {
  @IBOutlet weak var marketNameLabel: UIButton!
  @IBOutlet weak var priceField: UITextField!
  @IBOutlet weak var amountField: UITextField!
  @IBOutlet weak var tokenAvailableLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!
  @IBOutlet weak var beforeDiscountFeeLabel: UILabel!
  @IBOutlet weak var totalAmountLabel: UILabel!
  @IBOutlet weak var totalPriceLabel: UILabel!
  
  private let viewModel: KNBuyKNCViewModel
  fileprivate var isViewSetup: Bool = false
  
  init(viewModel: KNBuyKNCViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBuyKNCViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }
  
  fileprivate func setupUI() {
    // - Binding price from cached market
    self.viewModel.updateMarket()
    self.priceField.text = self.viewModel.targetPrice
    
  }
}
