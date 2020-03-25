// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNCancelOrderConfirmPopUpDelegate: class {
  func cancelOrderConfirmPopup(_ controller: KNCancelOrderConfirmPopUp, didConfirmCancel order: KNOrderObject)
}

class KNCancelOrderConfirmPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleTextLabel: UILabel!

  @IBOutlet weak var headerContainerView: UIView!
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

  override func viewDidLoad() {
    super.viewDidLoad()

    self.containerView.rounded(radius: 8.0)
    self.headerContainerView.rounded(radius: 2.5)
    self.statusValueLabel.rounded(radius: self.statusValueLabel.frame.height / 2.0)

    self.titleTextLabel.text = "You are cancelling this order".toBeLocalised()
    self.feeTextLabel.text = "Fee".toBeLocalised().uppercased()
    self.fromTextLabel.text = NSLocalizedString("From", value: "From", comment: "").uppercased()
    self.toTextLabel.text = NSLocalizedString("To", value: "To", comment: "").uppercased()
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
    let rate = BigInt(order.targetPrice * pow(10.0, 18.0)).displayRate(decimals: 18)

    self.pairValueLabel.text = "\(srcTokenSymbol)  ➞  \(destTokenSymbol) >= \(rate)"
    self.dateValueLabel.text = DateFormatterUtil.shared.limitOrderFormatter.string(from: order.dateToDisplay)
    self.addressLabel.text = "\(self.order.sender.prefix(8))...\(self.order.sender.suffix(4))"
    switch order.state {
    case .open:
      self.statusValueLabel.setTitle("Open".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 234, green: 230, blue: 255)
      self.statusValueLabel.setTitleColor(UIColor(red: 64, green: 50, blue: 148), for: .normal)
    case .inProgress:
      self.statusValueLabel.setTitle("In progress".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 222, green: 235, blue: 255)
      self.statusValueLabel.setTitleColor(UIColor(red: 0, green: 73, blue: 176), for: .normal)
    case .filled:
      self.statusValueLabel.setTitle("Filled".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 215, green: 242, blue: 226)
      self.statusValueLabel.setTitleColor(UIColor(red: 0, green: 102, blue: 68), for: .normal)
    case .cancelled:
      self.statusValueLabel.setTitle("Cancelled".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 255, green: 235, blue: 229)
      self.statusValueLabel.setTitleColor(UIColor(red: 191, green: 38, blue: 0), for: .normal)
    case .invalidated:
      self.statusValueLabel.setTitle("Invalidated".toBeLocalised(), for: .normal)
      self.statusValueLabel.backgroundColor = UIColor(red: 247, green: 232, blue: 173)
      self.statusValueLabel.setTitleColor(UIColor(red: 23, green: 43, blue: 77), for: .normal)
    default:
      self.statusValueLabel.isHidden = true
    }

    let feeDisplay: String = {
      let feeDouble = Double(order.fee) * order.sourceAmount
      return NumberFormatterUtil.shared.displayLimitOrderValue(from: feeDouble)
    }()
    self.feeValueLabel.text = "\(feeDisplay) \(srcTokenSymbol)"

    let actualSrcAmount = order.sourceAmount * (1.0 - order.fee)
    self.sourceValueLabel.text = "\(NumberFormatterUtil.shared.displayLimitOrderValue(from: order.sourceAmount)) \(srcTokenSymbol)"
    self.destValueLabel.text = ">= \(NumberFormatterUtil.shared.displayLimitOrderValue(from: actualSrcAmount * order.targetPrice)) \(destTokenSymbol)"

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
