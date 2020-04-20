// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNSetSlippageRateViewControllerDelegate: class {
  // nil: user's back, value: user's done
  func setSlippageRateViewControllerDidReturn(slippageRate: Double?)
}

struct KNSetSlippageRateViewModel {

  let maxValue: Double = 50.0

  var slippageRate: Double

  init(slippageRate: Double) {
    self.slippageRate = slippageRate
  }

  var navTitle: String {
    return "Slippage Rate".toBeLocalised()
  }

  var displayMaxText: String {
    return "5%"
  }

  var displayCurrentValueText: String {
    return "\(self.slippageRate)%"
  }

  var currentValue: Float {
    return Float(slippageRate * 10.0)
  }

  mutating func updateSlippageRate(_ newVal: Int) {
    self.slippageRate = Double(newVal) / 10.0
  }
}

class KNSetSlippageRateViewController: KNBaseViewController {

  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var currentValueLabel: UILabel!
  @IBOutlet weak var maxValueLabel: UILabel!
  @IBOutlet weak var slider: UISlider!

  @IBOutlet weak var leadingConstraintForCurrentValueLabel: NSLayoutConstraint!

  @IBOutlet weak var doneButton: UIButton!

  weak var delegate: KNSetSlippageRateViewControllerDelegate?
  fileprivate var viewModel: KNSetSlippageRateViewModel

  init(viewModel: KNSetSlippageRateViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSetSlippageRateViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
    self.updateUI()
  }

  fileprivate func setupUI() {
    self.navTitleLabel.text = self.viewModel.navTitle
    self.maxValueLabel.text = self.viewModel.displayMaxText
    self.doneButton.rounded()
    self.slider.setThumbImage(UIImage(named: "slider_thumb_icon"), for: .normal)
    self.slider.setThumbImage(UIImage(named: "slider_thumb_icon"), for: .highlighted)
    self.slider.setValue(Float(self.viewModel.currentValue), animated: false)
  }

  func updateViewModel(_ viewModel: KNSetSlippageRateViewModel) {
    self.viewModel = viewModel
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.currentValueLabel.text = self.viewModel.displayCurrentValueText
    let leading: CGFloat = CGFloat(self.viewModel.currentValue) / CGFloat(self.viewModel.maxValue) * (self.slider.frame.width - self.currentValueLabel.frame.width)
    self.leadingConstraintForCurrentValueLabel.constant = leading
    self.view.layoutIfNeeded()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.setSlippageRateViewControllerDidReturn(slippageRate: nil)
  }

  @IBAction func doneButtonPressed(_ sender: Any) {
    self.delegate?.setSlippageRateViewControllerDidReturn(slippageRate: self.viewModel.slippageRate)
  }

  @IBAction func sliderValueDidChange(_ sender: UISlider) {
    self.viewModel.updateSlippageRate(Int(floor(sender.value)))
    self.updateUI()
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.setSlippageRateViewControllerDidReturn(slippageRate: nil)
    }
  }
}

class CustomSlider: UISlider {
  override func trackRect(forBounds bounds: CGRect) -> CGRect {
    let customBounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: 8.0))
    super.trackRect(forBounds: customBounds)
    return customBounds
  }
}
