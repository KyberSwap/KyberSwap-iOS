//
//  PreviewLimitOrderV2ViewController.swift
//  KyberNetwork
//
//  Created by Le Xuan Manh on 4/9/20.
//

import UIKit
import BigInt

protocol PreviewLimitOrderV2ViewControllerDelegate: class {
  func previewLimitOrderV2ViewControllerDidBack()
  func previewLimitOrderV2ViewController(_ controller: PreviewLimitOrderV2ViewController, order: KNLimitOrder)
}

class PreviewLimitOrderV2ViewController: KNBaseViewController {

  fileprivate let order: KNLimitOrder
  fileprivate let confirmData: KNLimitOrderConfirmData
  weak var delegate: PreviewLimitOrderV2ViewControllerDelegate?

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var quantityTextLabel: UILabel!
  @IBOutlet weak var quantityValueLabel: UILabel!

  @IBOutlet weak var yourPriceTextLabel: UILabel!
  @IBOutlet weak var yourPriceValueLabel: UILabel!

  @IBOutlet weak var livePriceTextLabel: UILabel!
  @IBOutlet weak var livePriceValueLabel: UILabel!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var totalTextLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!

  @IBOutlet weak var separatorView: UIView!
  @IBOutlet weak var rateMessageLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  init(order: KNLimitOrder, confirmData: KNLimitOrderConfirmData) {
    self.order = order
    self.confirmData = confirmData
    super.init(nibName: PreviewLimitOrderV2ViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.navTitleLabel.text = "Preview Order".toBeLocalised()
    self.titleTextLabel.text = {
      if self.order.isBuy == true {
        return "Buy \(self.order.to.symbolLODisplay) with \(self.order.from.symbolLODisplay)".uppercased()
      }
      return "Sell \(self.order.from.symbolLODisplay) to \(self.order.to.symbolLODisplay)".uppercased()
    }()

    self.quantityTextLabel.text = "Quantity".toBeLocalised()
    self.quantityValueLabel.text = {
      if self.order.isBuy == true {
        return "\(self.confirmData.amount.prefix(12)) \(self.order.to.symbolLODisplay)"
      }
      return "\(self.confirmData.amount.prefix(12)) \(self.order.from.symbolLODisplay)"
    }()

    self.yourPriceTextLabel.text = "Your price".toBeLocalised()
    self.yourPriceValueLabel.text = self.confirmData.price.removeGroupSeparator().fullBigInt(decimals: 18)?.displayRate(decimals: 18)

    self.livePriceTextLabel.text = "Live price".toBeLocalised()
    self.livePriceValueLabel.text = self.confirmData.livePrice.removeGroupSeparator().fullBigInt(decimals: 18)?.displayRate(decimals: 18)

    self.feeTextLabel.text = "Fee".toBeLocalised()
    self.feeValueLabel.text = {
      let fee = BigInt(self.order.fee + self.order.transferFee) * self.order.srcAmount / BigInt(1000000)
      let feeAmountString = fee.string(
        decimals: self.order.from.decimals,
        minFractionDigits: 0,
        maxFractionDigits: min(self.order.from.decimals, 6)
      ).prefix(12)
      return "\(feeAmountString) \(self.order.from.symbolLODisplay)"
    }()

    self.totalTextLabel.text = "Total".toBeLocalised()
    let totalAmountString: String = {
      if self.order.isBuy == true {
        return "\(self.confirmData.totalAmount.prefix(12)) \(self.order.from.symbolLODisplay)"
      }
      return "\(self.confirmData.totalAmount.prefix(12)) \(self.order.to.symbolLODisplay)"
    }()
    self.totalValueLabel.text = totalAmountString

    let sourceAmount: String = {
      if self.order.isBuy == true {
        return "\(self.confirmData.totalAmount.prefix(12)) \(self.order.from.symbolLODisplay)"
      }
      return "\(self.confirmData.amount.prefix(12)) \(self.order.from.symbolLODisplay)"
    }()
    let pairString: String = {
      if self.order.isBuy == true { return "\(self.order.to.symbolLODisplay)/\(self.order.from.symbolLODisplay)" }
      return "\(self.order.from.symbolLODisplay)/\(self.order.to.symbolLODisplay)"
    }()

    self.rateMessageLabel.text = "Limit order are non custodial, which means \(sourceAmount) will remain in your wallet till \(pairString) price reaches \(self.confirmData.price)"

    self.confirmButton.applyGradient()
    self.confirmButton.rounded(radius: 5.0)
    self.confirmButton.setTitle("Confirm".toBeLocalised(), for: .normal)
    self.cancelButton.setTitle("Cancel".toBeLocalised(), for: .normal)

    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.confirmButton.removeSublayer(at: 0)
    self.separatorView.removeSublayer(at: 0)

    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.confirmButton.applyGradient()
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_preview_order", customAttributes: ["action": "back"])
    self.delegate?.previewLimitOrderV2ViewControllerDidBack()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_preview_order", customAttributes: ["action": "confirm"])
    self.delegate?.previewLimitOrderV2ViewController(self, order: self.order)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_preview_order", customAttributes: ["action": "cancel"])
    self.delegate?.previewLimitOrderV2ViewControllerDidBack()
  }
}
