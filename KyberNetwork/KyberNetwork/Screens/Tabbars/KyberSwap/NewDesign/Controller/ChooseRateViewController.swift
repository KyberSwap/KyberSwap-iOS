//
//  ChooseRateViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/22/20.
//

import UIKit
import BigInt

class ChooseRateViewModel {
  var data: [JSONDictionary]
  fileprivate(set) var from: TokenData
  fileprivate(set) var to: TokenData
  fileprivate(set) var gasPrice: BigInt
  fileprivate(set) var isDeposit: Bool
  
  init(from: TokenObject, to: TokenObject, data: [JSONDictionary], gasPrice: BigInt, isDeposit: Bool = false) {
    self.data = data
    self.from = from.toTokenData()
    self.to = to.toTokenData()
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
  }
  
  init(from: TokenData, to: TokenData, data: [JSONDictionary], gasPrice: BigInt, isDeposit: Bool = false) {
    self.data = data
    self.from = from
    self.to = to
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
  }

  var uniRateText: String {
    let key = KNGeneralProvider.shared.isEthereum ? "uniswap" : "PancakeSwap v2"
    return rateStringFor(platform: key)
  }

  var kyberRateText: String {
    let key = KNGeneralProvider.shared.isEthereum ? "kyber" : "PancakeSwap v1"
    return rateStringFor(platform: key)
  }
  
  var uniFeeText: String {
    let key = KNGeneralProvider.shared.isEthereum ? "uniswap" : "PancakeSwap v2"
    return feeStringFor(platform: key)
  }
  
  var kyberFeeText: String {
    let key = KNGeneralProvider.shared.isEthereum ? "kyber" : "PancakeSwap v1"
    return feeStringFor(platform: key)
  }

  fileprivate func rateStringFor(platform: String) -> String {
    let dict = self.data.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let rateString = dict?["rate"] as? String, let rate = BigInt(rateString) {
      return rate.isZero ? "---" : "1 \(self.from.symbol) = \(rate.displayRate(decimals: 18)) \(self.to.symbol)"
    } else {
      return "---"
    }
  }

  fileprivate func feeStringFor(platform: String) -> String {
    let dict = self.data.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let estGasString = dict?["estimatedGas"] as? NSNumber, let estGas = BigInt(estGasString.stringValue) {
      let rate = KNTrackerRateStorage.shared.getETHPrice()
      let rateUSDDouble = rate?.usd ?? 0
      let fee = estGas * gasPrice
      let rateBigInt = BigInt(rateUSDDouble * pow(10.0, 18.0))
      let feeUSD = fee * rateBigInt / BigInt(10).power(18)
      return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken) ~ $\(feeUSD.displayRate(decimals: 18))"
    } else {
      return "---"
    }
  }
}

protocol ChooseRateViewControllerDelegate: class {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String)
}

class ChooseRateViewController: KNBaseViewController {
  @IBOutlet weak var kyberRateLabel: UILabel!
  @IBOutlet weak var uniRateLabel: UILabel!
  @IBOutlet weak var feeKyberLabel: UILabel!
  @IBOutlet weak var feeUniLabel: UILabel!
  @IBOutlet weak var feeKyberTitleLabel: UILabel!
  @IBOutlet weak var feeUniTitleLabel: UILabel!
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var firstplatformNameLabel: UILabel!
  @IBOutlet weak var secondPlatformLabel: UILabel!
  @IBOutlet weak var firstPlatformIconImage: UIImageView!
  @IBOutlet weak var secondPlatformIconImage: UIImageView!
  
  weak var delegate: ChooseRateViewControllerDelegate?
  let viewModel: ChooseRateViewModel
  let transitor = TransitionDelegate()

  init(viewModel: ChooseRateViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ChooseRateViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.kyberRateLabel.text = self.viewModel.kyberRateText
    self.uniRateLabel.text = self.viewModel.uniRateText
    if !self.viewModel.isDeposit {
      self.feeUniLabel.text = self.viewModel.uniFeeText
      self.feeKyberLabel.text = self.viewModel.kyberFeeText
    } else {
      self.feeUniLabel.isHidden = true
      self.feeKyberLabel.isHidden = true
      self.feeUniTitleLabel.isHidden = true
      self.feeKyberTitleLabel.isHidden = true
    }
    if !KNGeneralProvider.shared.isEthereum {
      self.firstPlatformIconImage.image = UIImage(named: "pancake_icon")
      self.secondPlatformIconImage.image = UIImage(named: "pancake_icon")
      self.firstplatformNameLabel.text = "PancakeSwap v1"
      self.secondPlatformLabel.text = "PancakeSwap v2"
    }
  }

  @IBAction func chooseRateButtonTapped(_ sender: UIButton) {
    if sender.tag == 0 {
      let key = KNGeneralProvider.shared.isEthereum ? "kyber" : "PancakeSwap v1"
      self.delegate?.chooseRateViewController(self, didSelect: key)
    } else {
      let key = KNGeneralProvider.shared.isEthereum ? "uniswap" : "PancakeSwap v2"
      self.delegate?.chooseRateViewController(self, didSelect: key)
    }
    self.dismiss(animated: true, completion: nil)
  }
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ChooseRateViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 331
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
