// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNLimitOrderDetailsPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var pairContainerView: UIView!
  @IBOutlet weak var pairTextLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var senderAddressLabel: UILabel!
  @IBOutlet weak var statusButton: UIButton!
  @IBOutlet weak var fromTextLabel: UILabel!
  @IBOutlet weak var fromValueLabel: UILabel!
  @IBOutlet weak var toTextLabel: UILabel!
  @IBOutlet weak var toValueLabel: UILabel!
  @IBOutlet weak var feeTextLabel: UILabel!
  @IBOutlet weak var feeValueLabel: UILabel!

  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var detailsButton: UIButton!
  @IBOutlet weak var priceTextLabel: UILabel!
  @IBOutlet weak var priceValueLabel: UILabel!

  let order: KNOrderObject

  init(order: KNOrderObject) {
    self.order = order
    super.init(nibName: KNLimitOrderDetailsPopUp.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let sideTrade = self.order.sideTrade ?? "sell"
    let destAmountWithoutFee = order.sourceAmount * order.targetPrice
    self.containerView.rounded(radius: 8.0)
    self.pairContainerView.rounded(radius: 2.5)
    self.statusButton.rounded(radius: self.statusButton.frame.height / 2.0)

    self.titleTextLabel.text = "Your order is filled".toBeLocalised()
    self.feeTextLabel.text = "Fee".toBeLocalised().uppercased()
    self.fromTextLabel.text = "Total".toBeLocalised().uppercased()
    self.toTextLabel.text = "Amount".toBeLocalised().uppercased()
    self.closeButton.setTitle(
      NSLocalizedString("close", value: "Close", comment: ""),
      for: .normal
    )
    self.closeButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.detailsButton.setTitle(
      NSLocalizedString("details", value: "Details", comment: ""),
      for: .normal
    )
    self.detailsButton.rounded()
    self.detailsButton.applyGradient()

    let srcTokenSymbol = order.srcTokenSymbol
    let destTokenSymbol = order.destTokenSymbol
    if sideTrade == "sell" {
      self.pairTextLabel.text = "Sell \(srcTokenSymbol)".toBeLocalised()
      self.priceValueLabel.text = {
        let price = BigInt(self.order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)
        return "\(price) \(destTokenSymbol)"
      }()
      self.fromValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: destAmountWithoutFee)) \(destTokenSymbol)"
      self.toValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.sourceAmount)) \(srcTokenSymbol)"
    } else {
      self.pairTextLabel.text = "Buy \(destTokenSymbol)".toBeLocalised()
      self.priceValueLabel.text = {
        let price = BigInt(pow(10.0, 18.0)/self.order.targetPrice).displayRate(decimals: 18)
        return "\(price) \(srcTokenSymbol)"
      }()
      self.fromValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: self.order.sourceAmount)) \(srcTokenSymbol)"
      self.toValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: destAmountWithoutFee)) \(destTokenSymbol)"
    }
    if self.order.sideTrade == nil {
      let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)
      self.pairTextLabel.text = "\(srcTokenSymbol)/\(destTokenSymbol) >= \(rate)"
    }

    self.dateLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    self.senderAddressLabel.text = "\(self.order.sender.prefix(8))...\(self.order.sender.suffix(4))"
    switch order.state {
    case .filled:
      self.statusButton.setTitle("Filled".toBeLocalised(), for: .normal)
      self.statusButton.backgroundColor = UIColor(red: 215, green: 242, blue: 226)
      self.statusButton.setTitleColor(UIColor(red: 0, green: 102, blue: 68), for: .normal)
    default:
      self.statusButton.isHidden = true
    }

    let feeDisplay: String = {
      let feeDouble = Double(order.fee) * order.sourceAmount
      return NumberFormatterUtil.shared.displayLimitOrderValue(from: feeDouble)
    }()
    self.feeValueLabel.text = "\(feeDisplay) \(srcTokenSymbol)"

    let extraAmount: String = "+ \(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.extraAmount)) \(destTokenSymbol)"
    let actualSrcAmount = self.order.sourceAmount * (1.0 - self.order.fee)
    let destAmountStr: String = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: actualSrcAmount * order.targetPrice)) \(destTokenSymbol)"
    if order.state == .filled && order.extraAmount > 0 {
      let normalAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 11),
      ]
      let extraAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 49, green: 203, blue: 158),
        NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 10),
      ]
      if sideTrade == "buy" {
        self.toValueLabel.text = nil
        self.toValueLabel.attributedText = {
          let attributedString = NSMutableAttributedString()
          attributedString.append(NSAttributedString(string: destAmountStr, attributes: normalAttributes))
          attributedString.append(NSAttributedString(string: "\n\(extraAmount)", attributes: extraAttributes))
          return attributedString
        }()
      } else {
        self.fromValueLabel.text = nil
        self.fromValueLabel.attributedText = {
          let attributedString = NSMutableAttributedString()
          attributedString.append(NSAttributedString(string: destAmountStr, attributes: normalAttributes))
          attributedString.append(NSAttributedString(string: "\n\(extraAmount)", attributes: extraAttributes))
          return attributedString
        }()
      }
    }

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.detailsButton.removeSublayer(at: 0)
    self.detailsButton.applyGradient()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
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

  @IBAction func detailsButtonPressed(_ sender: Any) {
    if let hash = self.order.txHash,
      let etherScanEndpoint = KNEnvironment.default.knCustomRPC?.etherScanEndpoint,
      let url = URL(string: "\(etherScanEndpoint)tx/\(hash)") {
      self.openSafari(with: url)
    } else {
      self.dismiss(animated: true, completion: nil)
    }
  }
}
