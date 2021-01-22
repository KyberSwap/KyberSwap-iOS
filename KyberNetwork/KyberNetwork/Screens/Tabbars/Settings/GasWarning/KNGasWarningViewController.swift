// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSelectedGasWarningType: Equatable {
  case option1
  case option2
  case option3
  case custom(value: Double)

  func getValue() -> Double {
    switch self {
    case .option1:
      return 500.0
    case .option2:
      return 200.0
    case .option3:
      return 100.0
    case .custom(let value):
      return value
    }
  }

  static public func ==(lhs: KNSelectedGasWarningType, rhs: KNSelectedGasWarningType) -> Bool {
    switch (lhs, rhs) {
    case (.option1, .option1), (.option2, .option2), (.option3, .option3), (.custom, .custom):
      return true
    default:
      return false
    }
  }
}

class KNGasWarningViewModel {
  var selectedType: KNSelectedGasWarningType

  init() {
    let saved = UserDefaults.standard.double(forKey: Constants.gasWarningValueKey)
    if saved == 0.0 || saved == 200 {
      self.selectedType = .option2
    } else if saved == 500 {
      self.selectedType = .option1
    } else if saved == 100 {
      self.selectedType = .option3
    } else {
      self.selectedType = .custom(value: saved)
    }
  }
}

protocol KNGasWarningViewControllerDelegate: class {
  func gasWarningViewControllerDidUpdateLimitValue(_ controller: KNGasWarningViewController)
}

class KNGasWarningViewController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!
  @IBOutlet weak var checkBox1Button: UIButton!
  @IBOutlet weak var checkBox2Button: UIButton!
  @IBOutlet weak var checkBox3Button: UIButton!
  @IBOutlet weak var checkBox4Button: UIButton!
  @IBOutlet weak var checkBox4TextFieldContainerView: UIView!
  @IBOutlet weak var checkBox4TextField: UITextField!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var confirmButton: UIButton!
  let viewModel = KNGasWarningViewModel()
  weak var delegate: KNGasWarningViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.updateCheckBoxUI()
    self.cancelButton.rounded(color: UIColor(red: 184, green: 186, blue: 190), width: 1, radius: 5)
    self.checkBox4TextFieldContainerView.rounded(color: UIColor(red: 232, green: 232, blue: 232), width: 1, radius: 3)
    self.confirmButton.rounded(radius: 5)
    self.confirmButton.applyGradient()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.confirmButton.removeSublayer(at: 0)
    self.confirmButton.applyGradient()
  }

  fileprivate func updateCheckBoxUI() {
    let selectedColor = UIColor.Kyber.enygold
    let normalColor = UIColor.Kyber.dashLine

    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0

    self.checkBox1Button.rounded(
      color: self.viewModel.selectedType == .option1 ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .option1 ? selectedWidth : normalWidth,
      radius: self.checkBox1Button.frame.height / 2.0
    )

    self.checkBox2Button.rounded(
      color: self.viewModel.selectedType == .option2 ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .option2 ? selectedWidth : normalWidth,
      radius: self.checkBox2Button.frame.height / 2.0
    )

    self.checkBox3Button.rounded(
      color: self.viewModel.selectedType == .option3 ? selectedColor : normalColor,
      width: self.viewModel.selectedType == .option3 ? selectedWidth : normalWidth,
      radius: self.checkBox3Button.frame.height / 2.0
    )

    var isCustomOption = false
    if case .custom(let value) = self.viewModel.selectedType {
      isCustomOption = true
      self.checkBox4TextField.text = String(value)
    } else {
      isCustomOption = false
      self.checkBox4TextField.text = ""
    }

    self.checkBox4Button.rounded(
      color: isCustomOption ? selectedColor : normalColor,
      width: isCustomOption ? selectedWidth : normalWidth,
      radius: self.checkBox4Button.frame.height / 2.0
    )

    self.checkBox4TextFieldContainerView.isUserInteractionEnabled = isCustomOption
  }

  fileprivate func updateValidState(isError: Bool) {
    let borderColor = isError ? UIColor.Kyber.strawberry : UIColor.Kyber.border
    self.checkBox4TextFieldContainerView.rounded(color: borderColor, width: 1, radius: 3)
    self.confirmButton.isEnabled = !isError
    self.confirmButton.alpha = isError ? 0.7 : 1
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func confirmButton(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      UserDefaults.standard.set(self.viewModel.selectedType.getValue(), forKey: Constants.gasWarningValueKey)
      self.delegate?.gasWarningViewControllerDidUpdateLimitValue(self)
    })
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    self.view.endEditing(true)
  }

  @IBAction func checkBoxButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      self.viewModel.selectedType = .option1
    case 2:
      self.viewModel.selectedType = .option2
    case 3:
      self.viewModel.selectedType = .option3
    case 4:
      self.viewModel.selectedType = .custom(value: 50)
    default:
      return
    }
    self.updateCheckBoxUI()
  }
}

extension KNGasWarningViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    if let customValue = Double(text) {
      self.viewModel.selectedType = .custom(value: customValue)
      textField.text = text
      self.updateValidState(isError: customValue <= 0)
    } else {
      textField.text = ""
    }

    return false
  }
}
