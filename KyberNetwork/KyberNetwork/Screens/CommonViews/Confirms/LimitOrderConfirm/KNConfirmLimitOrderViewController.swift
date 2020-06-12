// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmLimitOrderViewControllerDelegate: class {
  func confirmLimitOrderViewControllerDidBack()
  func confirmLimitOrderViewController(_ controller: KNConfirmLimitOrderViewController, order: KNLimitOrder)
}

class KNConfirmLimitOrderViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var broadcastConditonTextLabel: UILabel!

  @IBOutlet weak var srcDataLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var destDataLabel: UILabel!
  @IBOutlet weak var explainDestAmountLabel: UILabel!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueButton: UIButton!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  weak var delegate: KNConfirmLimitOrderViewControllerDelegate?

  let order: KNLimitOrder

  init(order: KNLimitOrder) {
    self.order = order
    super.init(nibName: KNConfirmLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let from = self.order.from
    let to = self.order.to
    let srcAmount = self.order.srcAmount
    // fee send to server is multiple with 10^6
    let fee = BigInt(self.order.fee + self.order.transferFee) * srcAmount / BigInt(1000000)
    let targetRate = self.order.targetRate

    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.navTitleLabel.text = "Confirm Order".toBeLocalised()

    let srcAmountString = srcAmount.string(
      decimals: from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(from.decimals, 6)
    ).prefix(12)

    let text = "Your transaction will be broadcasted when rate of %@".toBeLocalised()
    let condition = "\(from.symbol)/\(to.symbol) (for \(srcAmountString) \(from.symbol)) >= \(targetRate.displayRate(decimals: to.decimals))"
    self.broadcastConditonTextLabel.text = String(format: text, condition)

    self.srcDataLabel.text = "\(srcAmountString) \(from.symbol)"
    self.toTextLabel.text = NSLocalizedString("to", value: "To", comment: "")

    let feeAmountString = fee.string(
      decimals: from.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(from.decimals, 6)
    ).prefix(12)
    let rateString = targetRate.displayRate(decimals: to.decimals)
    let receivedAmount: BigInt = {
      let srcAfterFee = max(BigInt(0), srcAmount - fee)
      return srcAfterFee * targetRate / BigInt(10).power(from.decimals)
    }()
    let receiveAmountStr = receivedAmount.string(
      decimals: to.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(to.decimals, 6)
    ).prefix(12)
    self.destDataLabel.text = "\(receiveAmountStr) \(to.symbol)"
    self.explainDestAmountLabel.text = "(\(srcAmountString) - \(feeAmountString)) \(from.symbol) * \(rateString) = \(receiveAmountStr) \(to.symbol)"

    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    self.feeTextLabel.text = NSLocalizedString("fee", value: "Fee", comment: "")
    self.feeValueButton.semanticContentAttribute = .forceRightToLeft
    self.feeValueButton.setTitle("\(feeAmountString) \(from.symbol)", for: .normal)

    self.confirmButton.setTitle(NSLocalizedString("confirm", value: "Confirm", comment: ""), for: .normal)
    self.confirmButton.rounded()
    self.confirmButton.applyGradient()

    self.cancelButton.setTitle(NSLocalizedString("cancel", value: "Cancel", comment: ""), for: .normal)

  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
    self.separatorView.removeSublayer(at: 0)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_confirm_back_tapped", customAttributes: nil)
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.confirmLimitOrderViewControllerDidBack()
    })
  }

  @IBAction func feeValueButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_confirm_fee_tapped", customAttributes: nil)
    self.showTopBannerView(
      with: "",
      message: "Don’t worry. You will not be charged now. \nYou pay fees only when transaction is executed (broadcasted & mined).".toBeLocalised(),
      icon: UIImage(named: "info_blue_icon"),
      time: 2.0
    )
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_confirm_confirm_tapped", customAttributes: ["pair": "\(self.order.from.symbol)_\(self.order.to.symbol)", "src_amount": self.order.srcAmount.displayRate(decimals: self.order.from.decimals)])
    self.delegate?.confirmLimitOrderViewController(self, order: self.order)
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "lo_confirm_cancel_tapped", customAttributes: nil)
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.confirmLimitOrderViewControllerDidBack()
    })
  }
}
