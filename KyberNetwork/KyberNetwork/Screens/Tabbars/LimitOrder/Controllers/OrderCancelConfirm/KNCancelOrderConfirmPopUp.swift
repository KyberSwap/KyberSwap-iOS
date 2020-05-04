// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNCancelOrderConfirmPopUpDelegate: class {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject)
}

class KNCancelOrderConfirmPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var pairValueLabel: UILabel!
  @IBOutlet weak var dateValueLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var statusValueLabel: UIButton!

  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var sourceValueLabel: UILabel!

  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var destValueLabel: UILabel!

  @IBOutlet weak var priceTextLabel: UILabel!
  @IBOutlet weak var priceValueLabel: UILabel!

  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!

  weak var delegate: KNCancelOrderConfirmPopUpDelegate?

  let order: KNOrderObject

  init(order: KNOrderObject) {
    self.order = order
    super.init(nibName: KNCancelOrderConfirmPopUp.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // swift_lint:disable function_body_length
  override func viewDidLoad() {
    super.viewDidLoad()

    self.containerView.rounded(radius: 8.0)
    self.statusValueLabel.rounded(radius: self.statusValueLabel.frame.height / 2.0)

    self.titleTextLabel.text = "You are cancelling this order".toBeLocalised()
    self.feeTextLabel.text = NSLocalizedString("fee", value: "Fee", comment: "").uppercased()

    self.cancelButton.setTitle(
      NSLocalizedString("no", value: "No", comment: ""),
      for: .normal
    )
    self.cancelButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.confirmButton.setTitle(
      NSLocalizedString("yes", value: "Yes", comment: ""),
      for: .normal
    )
    self.confirmButton.rounded()
    self.confirmButton.applyGradient()

    let srcTokenSymbol = order.srcTokenSymbol
    let destTokenSymbol = order.destTokenSymbol
    let destAmount = self.order.sourceAmount * order.targetPrice

    let sideTrade = self.order.sideTrade ?? "sell"

    self.priceTextLabel.text = "Price".toBeLocalised().uppercased()
    self.priceTextLabel.isHidden = false
    self.priceValueLabel.isHidden = false
    self.fromTextLabel.text = "Total".toBeLocalised().uppercased()
    self.toTextLabel.text = "Amount".toBeLocalised().uppercased()
    if sideTrade == "sell" {
      self.pairValueLabel.text = String(format: "Sell %@".toBeLocalised(), srcTokenSymbol)
      self.priceValueLabel.text = {
        let price = BigInt(self.order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)
        return "\(price) \(destTokenSymbol)"
      }()
      // Sell sourceAmount to destAmount
      // Amount: sourceAmount
      // Total: destAmount
      // src is total, dest is amount
      self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: destAmount)) \(destTokenSymbol)"
      self.destValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.sourceAmount)) \(srcTokenSymbol)"
    } else {
      self.pairValueLabel.text = String(format: "Buy %@".toBeLocalised(), destTokenSymbol)
      self.priceValueLabel.text = {
        let price = BigInt(pow(10.0, 18.0)/self.order.targetPrice).displayRate(decimals: 18)
        return "\(price) \(srcTokenSymbol)"
      }()
      // Buy destAmount token from sourceAmount
      // Amount: destAmount
      // Total: sourceAmount
      // src is total, dest is amount
      self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.sourceAmount)) \(srcTokenSymbol)"
      self.destValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: destAmount)) \(destTokenSymbol)"
    }
    // only change pair label if version 1
    if self.order.sideTrade == nil {
      let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)
      self.pairValueLabel.text = "\(srcTokenSymbol)/\(destTokenSymbol) >= \(rate)"
    }

    self.dateValueLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    self.addressLabel.text = "\(self.order.sender.prefix(8))...\(self.order.sender.suffix(4))"
    switch order.state {
    case .open:
      self.statusValueLabel.setTitle("Open".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 234, green: 230, blue: 255)
      self.statusValueLabel.setTitleColor(UIColor(red: 64, green: 50, blue: 148), for: .normal)
    default:
      // Something went wrong, only can cancel open order
      self.statusValueLabel.isHidden = true
    }

    let feeDisplay: String = {
      let feeDouble = Double(self.order.fee) * self.order.sourceAmount
      return NumberFormatterUtil.shared.displayLimitOrderValue(from: feeDouble)
    }()
    self.feeValueLabel.text = "\(feeDisplay) \(srcTokenSymbol)"

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @objc func tapOutSideToDismiss(_ tapGesture: UITapGestureRecognizer) {
    let loc = tapGesture.location(in: self.view)
    if loc.x < self.containerView.frame.minX
      || loc.x > self.containerView.frame.maxX
      || loc.y < self.containerView.frame.minY
      || loc.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    guard let accessToken = IEOUserStorage.shared.user?.accessToken else { return }
    self.displayLoading(text: "Cancelling...".toBeLocalised(), animated: true)
    KNLimitOrderServerCoordinator.shared.cancelOrder(
      accessToken: accessToken,
      orderID: order.id) { [weak self] result in
        guard let `self` = self else { return }
        self.hideLoading()
        switch result {
        case .success(let message):
          self.dismiss(animated: true, completion: {
            self.delegate?.cancelOrderConfirmPopup(self, didConfirmCancel: self.order)
          })
          self.showSuccessTopBannerMessage(with: "", message: message, time: 1.5)
        case .failure(let error):
          self.displayError(error: error)
        }
    }
  }
}
