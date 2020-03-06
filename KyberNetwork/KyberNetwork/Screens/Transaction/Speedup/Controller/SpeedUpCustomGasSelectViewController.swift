// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum SpeedUpCustomGasSelectViewEvent {
  case back
  case done(transaction: Transaction, newGasPrice: BigInt)
  case invaild
}

protocol SpeedUpCustomGasSelectDelegate: class {
  func speedUpCustomGasSelectViewController(_ controller: SpeedUpCustomGasSelectViewController, run event: SpeedUpCustomGasSelectViewEvent)
}

class SpeedUpCustomGasSelectViewController: KNBaseViewController {
  @IBOutlet weak var navigationTitleLabel: UILabel!
  @IBOutlet weak var headerView: UIView!
  @IBOutlet weak var superFastGasPriceButton: UIButton!
  @IBOutlet weak var superFastGasPriceLabel: UILabel!
  @IBOutlet weak var fastGasPriceButton: UIButton!
  @IBOutlet weak var fastGasPriceLabel: UILabel!
  @IBOutlet weak var regularGasPriceButton: UIButton!
  @IBOutlet weak var regularGasPriceLabel: UILabel!
  @IBOutlet weak var slowGasPriceButton: UIButton!
  @IBOutlet weak var slowGasPriceLabel: UILabel!
  @IBOutlet weak var currentFeeLabel: UILabel!
  @IBOutlet weak var newFeeLabel: UILabel!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var gasFeeSelectBoxContainer: UIView!
  @IBOutlet weak var mainTextTitle: UILabel!
  @IBOutlet weak var currentFeeTitleLabel: UILabel!
  @IBOutlet weak var newFeeTitleLabel: UILabel!
  @IBOutlet weak var gasPriceWarningMessageLabel: UILabel!
  fileprivate let viewModel: SpeedUpCustomGasSelectViewModel
  weak var delegate: SpeedUpCustomGasSelectDelegate?

  init(viewModel: SpeedUpCustomGasSelectViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SpeedUpCustomGasSelectViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateUI()
    self.updateGasPriceUIs()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerView.removeSublayer(at: 0)
    self.headerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.doneButton.removeSublayer(at: 0)
    self.doneButton.applyGradient()
  }

  fileprivate func updateUI() {
    self.navigationTitleLabel.text = "Customize Gas".toBeLocalised()
    self.mainTextTitle.text = "Select.higher.tx.fee.to.accelerate".toBeLocalised()
    self.gasPriceWarningMessageLabel.text = "your.gas.must.be.10.percent.higher".toBeLocalised()
    self.currentFeeLabel.text = "Current fee".toBeLocalised()
    self.newFeeLabel.text = "New fee".toBeLocalised()
    self.doneButton.setTitle("done".toBeLocalised(), for: .normal)

    self.headerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.gasFeeSelectBoxContainer.rounded(radius: 5.0)
    self.superFastGasPriceButton.backgroundColor = .white
    self.fastGasPriceButton.backgroundColor = .white
    self.regularGasPriceButton.backgroundColor = .white
    self.slowGasPriceButton.backgroundColor = .white

    let tapSuperFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    self.superFastGasPriceLabel.addGestureRecognizer(tapSuperFast)
    let tapFast = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    self.fastGasPriceLabel.addGestureRecognizer(tapFast)
    let tapRegular = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    self.regularGasPriceLabel.addGestureRecognizer(tapRegular)
    let tapSlow = UITapGestureRecognizer(target: self, action: #selector(self.userTappedSelectBoxLabel(_:)))
    self.slowGasPriceLabel.addGestureRecognizer(tapSlow)
    self.currentFeeLabel.text = self.viewModel.currentTransactionFeeETHString
    let style = KNAppStyleType.current
    let radius = style.buttonRadius(for: self.doneButton.frame.height)
    self.doneButton.rounded(radius: radius)
    self.doneButton.applyGradient()
  }

  func updateGasPriceUIs() {
    self.superFastGasPriceLabel.attributedText = self.viewModel.superFastGasString
    self.fastGasPriceLabel.attributedText = self.viewModel.fastGasString
    self.regularGasPriceLabel.attributedText = self.viewModel.mediumGasString
    self.slowGasPriceLabel.attributedText = self.viewModel.slowGasString

    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.superFastGasPriceButton.rounded(
      color: self.viewModel.selectedType == .superFast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .superFast ? selectedWidth : normalWidth,
      radius: self.superFastGasPriceButton.frame.height / 2.0
    )

    self.fastGasPriceButton.rounded(
      color: self.viewModel.selectedType == .fast ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .fast ? selectedWidth : normalWidth,
      radius: self.fastGasPriceButton.frame.height / 2.0
    )

    self.regularGasPriceButton.rounded(
      color: self.viewModel.selectedType == .medium ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .medium ? selectedWidth : normalWidth,
      radius: self.regularGasPriceButton.frame.height / 2.0
    )

    self.slowGasPriceButton.rounded(
      color: self.viewModel.selectedType == .slow ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .slow ? selectedWidth : normalWidth,
      radius: self.slowGasPriceButton.frame.height / 2.0
    )
    self.newFeeLabel.text = self.viewModel.getNewTransactionFeeETHString()
  }

  @IBAction func doneButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_done_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": self.viewModel.transaction.id])
    if viewModel.isNewGasPriceValid() {
      self.delegate?.speedUpCustomGasSelectViewController(self, run: .done(transaction: self.viewModel.transaction, newGasPrice: self.viewModel.getNewTransactionGasPriceETH()))
    } else {
      self.delegate?.speedUpCustomGasSelectViewController(self, run: .invaild)
    }
  }
  @IBAction func backButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_back_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": self.viewModel.transaction.id])
    self.delegate?.speedUpCustomGasSelectViewController(self, run: .back)
  }
  @objc func userTappedSelectBoxLabel(_ sender: UITapGestureRecognizer) {
    guard let type = KNSelectedGasPriceType(rawValue: sender.view!.tag) else { return }
    self.handleGasFeeChange(type)
  }
  @IBAction func selectBoxButtonTapped(_ sender: UIButton) {
    guard let type = KNSelectedGasPriceType(rawValue: sender.tag) else { return }
    KNCrashlyticsUtil.logCustomEvent(withName: "tap_option_button_in_custom_gas_price_select_screen", customAttributes: ["transactionHash": self.viewModel.transaction.id, "option": type])
    self.handleGasFeeChange(type)
  }
  func handleGasFeeChange(_ type: KNSelectedGasPriceType) {
    self.viewModel.updateSelectedType(type)
    self.updateGasPriceUIs()
  }
}
