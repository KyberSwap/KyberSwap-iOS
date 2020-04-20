// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNTransactionFilter {
  let from: Date?
  let to: Date?
  let isSend: Bool
  let isReceive: Bool
  let isSwap: Bool
  let tokens: [String]
}

class KNTransactionFilterViewModel {
  private(set) var from: Date?
  private(set) var to: Date?
  private(set) var isSend: Bool = false
  private(set) var isReceive: Bool = false
  private(set) var isSwap: Bool = false
  private(set) var tokens: [String] = []
  private(set) var supportedTokens: [String] = []
  private(set) var isSelectAll: Bool = true
  var isSeeMore: Bool = false

  init(tokens: [String], filter: KNTransactionFilter) {
    self.from = filter.from
    self.to = filter.to
    self.isSend = filter.isSend
    self.isReceive = filter.isReceive
    self.isSwap = filter.isSwap
    self.tokens = filter.tokens
    self.supportedTokens = tokens
    if filter.tokens.count < self.supportedTokens.count / 2 { self.isSelectAll = false }
    self.supportedTokens.sort { (t0, t1) -> Bool in
      let isContain0 = self.tokens.contains(t0)
      let isContain1 = self.tokens.contains(t1)
      if isContain0 && !isContain1 { return true }
      if !isContain0 && isContain1 { return false }
      return t0 < t1
    }
  }

  func updateFrom(date: Date?) {
    self.from = date
  }

  func updateTo(date: Date?) {
    self.to = date
  }

  func updateIsSend(_ flag: Bool) {
    self.isSend = flag
  }

  func updateIsReceive(_ flag: Bool) {
    self.isReceive = flag
  }

  func updateIsSwap(_ flag: Bool) {
    self.isSwap = flag
  }

  func updateTokens(_ tokens: [String]) {
    self.tokens = tokens
  }

  func selectTokenSymbol(_ symbol: String) {
    if self.tokens.contains(symbol) {
      self.removeToken(symbol)
    } else {
      self.addToken(symbol)
    }
  }

  func addToken(_ token: String) {
    if self.tokens.first(where: { return $0 == token }) == nil {
      self.tokens.append(token)
    }
  }

  func removeToken(_ token: String) {
    if let id = self.tokens.index(of: token) {
      self.tokens.remove(at: id)
    }
  }

  func resetFilters() {
    self.from = nil
    self.to = nil
    self.isSend = true
    self.isReceive = true
    self.isSwap = true
    self.tokens = self.supportedTokens
    self.isSelectAll = true
    self.isSeeMore = false
  }

  func updateSelectAll(_ isSelectAll: Bool) {
    self.isSelectAll = isSelectAll
    self.tokens = self.isSelectAll ? self.supportedTokens : []
  }
}

protocol KNTransactionFilterViewControllerDelegate: class {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply filter: KNTransactionFilter)
}

class KNTransactionFilterViewController: KNBaseViewController {

  fileprivate let kFilterTokensTableViewCellID: String = "kFilterTokensTableViewCellID"
  fileprivate var viewModel: KNTransactionFilterViewModel

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var timeTextLabel: UILabel!
  @IBOutlet weak var fromTextField: UITextField!
  @IBOutlet weak var toTextField: UITextField!

  @IBOutlet weak var transactionTypeTextLabel: UILabel!

  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var receiveButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!

  @IBOutlet weak var selectButton: UIButton!
  @IBOutlet weak var tokenTextLabel: UILabel!
  @IBOutlet weak var tokensTableView: UITableView!
  @IBOutlet weak var tokensTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var tokensViewActionButton: UIButton!

  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var applyButton: UIButton!
  @IBOutlet weak var bottomPaddingForButtonConstraint: NSLayoutConstraint!

  @IBOutlet var separatorViews: [UIView]!

  weak var delegate: KNTransactionFilterViewControllerDelegate?

  lazy var fromDatePicker: UIDatePicker = {
    let frame = CGRect(
      x: 0,
      y: self.view.frame.height - 200.0,
      width: self.view.frame.width,
      height: 200.0
    )
    let picker = UIDatePicker(frame: frame)
    picker.datePickerMode = .date
    picker.minimumDate = Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    picker.maximumDate = Date()
    picker.addTarget(self, action: #selector(self.fromDatePickerDidChange(_:)), for: .valueChanged)
    picker.date = Date()
    return picker
  }()

  lazy var toDatePicker: UIDatePicker = {
    let frame = CGRect(
      x: 0,
      y: self.view.frame.height - 200.0,
      width: self.view.frame.width,
      height: 200.0
    )
    let picker = UIDatePicker(frame: frame)
    picker.datePickerMode = .date
    picker.minimumDate = Date().addingTimeInterval(-200.0 * 360.0 * 24.0 * 60.0 * 60.0)
    picker.maximumDate = Date()
    picker.addTarget(self, action: #selector(self.toDatePickerDidChange(_:)), for: .valueChanged)
    picker.date = Date()
    return picker
  }()

  init(viewModel: KNTransactionFilterViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTransactionFilterViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = "Filter".toBeLocalised()
    self.timeTextLabel.text = "Time".toBeLocalised()
    self.separatorViews.forEach({ $0.backgroundColor = .clear })
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
    self.transactionTypeTextLabel.text = "Transaction Type".toBeLocalised()
    self.sendButton.setTitle(NSLocalizedString("transfer", value: "Transfer", comment: ""), for: .normal)
    self.receiveButton.setTitle(NSLocalizedString("receive", value: "Receive", comment: ""), for: .normal)
    self.swapButton.setTitle(NSLocalizedString("swap", value: "Swap", comment: ""), for: .normal)
    self.tokenTextLabel.text = "Token".toBeLocalised()
    self.resetButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.resetButton.setTitle("Reset".toBeLocalised(), for: .normal)
    self.applyButton.applyGradient()
    self.applyButton.setTitle(NSLocalizedString("apply", value: "Apply", comment: ""), for: .normal)
    self.applyButton.rounded()

    let nib = UINib(nibName: KNTransactionFilterTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: kFilterTokensTableViewCellID)
    self.tokensTableView.rowHeight = 44.0
    self.tokensTableView.delegate = self
    self.tokensTableView.dataSource = self
    self.tokensTableView.reloadData()
    self.tokensTableView.allowsSelection = false

    self.fromTextField.inputView = self.fromDatePicker
    self.fromTextField.delegate = self
    self.toTextField.inputView = self.toDatePicker
    self.toTextField.delegate = self

    self.bottomPaddingForButtonConstraint.constant = 24.0 + self.bottomPaddingSafeArea()

    self.updateUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
    self.applyButton.removeSublayer(at: 0)
    self.applyButton.applyGradient()
  }

  fileprivate func updateUI(isUpdatingTokens: Bool = true) {
    UIView.animate(withDuration: 0.16) {
      self.selectButton.setTitle(
        self.viewModel.isSelectAll ? "Deselect All".toBeLocalised() : "Select All".toBeLocalised(),
        for: .normal
      )
      if isUpdatingTokens {
        let btnTitle: String = self.viewModel.isSeeMore ? NSLocalizedString("see.less", value: "See less", comment: "") : NSLocalizedString("see.more", value: "See more", comment: "")
        self.tokensViewActionButton.setTitle(
          btnTitle,
          for: .normal
        )
      }
      if self.viewModel.isSend {
        self.sendButton.rounded(color: UIColor.Kyber.enygold, width: 1.0)
        self.sendButton.setImage(UIImage(named: "filter_check_icon"), for: .normal)
        self.sendButton.backgroundColor = .white
      } else {
        self.sendButton.rounded(color: .clear, width: 0.0)
        self.sendButton.setImage(nil, for: .normal)
        self.sendButton.backgroundColor = .clear
      }
      if self.viewModel.isReceive {
        self.receiveButton.rounded(color: UIColor.Kyber.enygold, width: 1.0)
        self.receiveButton.setImage(UIImage(named: "filter_check_icon"), for: .normal)
        self.receiveButton.backgroundColor = .white
      } else {
        self.receiveButton.rounded(color: .clear, width: 0.0)
        self.receiveButton.setImage(nil, for: .normal)
        self.receiveButton.backgroundColor = .clear
      }
      if self.viewModel.isSwap {
        self.swapButton.rounded(color: UIColor.Kyber.enygold, width: 1.0)
        self.swapButton.setImage(UIImage(named: "filter_check_icon"), for: .normal)
        self.swapButton.backgroundColor = .white
      } else {
        self.swapButton.rounded(color: .clear, width: 0.0)
        self.swapButton.setImage(nil, for: .normal)
        self.swapButton.backgroundColor = .clear
      }
      if let date = self.viewModel.from {
        self.fromDatePicker.setDate(date, animated: false)
        self.fromDatePickerDidChange(self.fromDatePicker)
      } else {
        self.fromTextField.text = ""
      }
      if let date = self.viewModel.to {
        self.toDatePicker.setDate(date, animated: false)
        self.toDatePickerDidChange(self.toDatePicker)
      } else {
        self.toTextField.text = ""
      }
      if isUpdatingTokens {
        self.tokensTableViewHeightConstraint.constant = {
          let numberRows = self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 3
          return CGFloat(numberRows) * self.tokensTableView.rowHeight
        }()
        self.tokensTableView.reloadData()
      }
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func sendButtonPressed(_ sender: Any) {
    self.viewModel.updateIsSend(!self.viewModel.isSend)
    self.updateUI(isUpdatingTokens: false)
  }

  @IBAction func receiveButtonPressed(_ sender: Any) {
    self.viewModel.updateIsReceive(!self.viewModel.isReceive)
    self.updateUI(isUpdatingTokens: false)
  }

  @IBAction func swapButtonPressed(_ sender: Any) {
    self.viewModel.updateIsSwap(!self.viewModel.isSwap)
    self.updateUI(isUpdatingTokens: false)
  }

  @IBAction func selectButtonPressed(_ sender: Any) {
    self.viewModel.updateSelectAll(!self.viewModel.isSelectAll)
    self.updateUI()
  }

  // See more/less
  @IBAction func tokensActionButtonPressed(_ sender: Any) {
    self.viewModel.isSeeMore = !self.viewModel.isSeeMore
    self.updateUI()
  }

  @objc func fromDatePickerDidChange(_ sender: UIDatePicker) {
    let dob = DateFormatterUtil.shared.kycDateFormatter.string(from: self.fromDatePicker.date)
    self.fromTextField.text = dob
    self.viewModel.updateFrom(date: self.fromDatePicker.date)
    if self.toDatePicker.date < self.fromDatePicker.date {
      self.toDatePicker.setDate(self.fromDatePicker.date, animated: false)
      self.toDatePickerDidChange(self.toDatePicker)
      self.viewModel.updateTo(date: self.toDatePicker.date)
    }
  }

  @objc func toDatePickerDidChange(_ sender: UIDatePicker) {
    let dob = DateFormatterUtil.shared.kycDateFormatter.string(from: self.toDatePicker.date)
    self.toTextField.text = dob
    self.viewModel.updateTo(date: self.toDatePicker.date)
    if self.toDatePicker.date < self.fromDatePicker.date {
      self.fromDatePicker.setDate(self.toDatePicker.date, animated: false)
      self.fromDatePickerDidChange(self.toDatePicker)
      self.viewModel.updateFrom(date: self.fromDatePicker.date)
    }
  }

  @IBAction func resetButtonPressed(_ sender: Any) {
    self.viewModel.resetFilters()
    self.updateUI()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    let filter = KNTransactionFilter(
      from: self.viewModel.from,
      to: self.viewModel.to,
      isSend: self.viewModel.isSend,
      isReceive: self.viewModel.isReceive,
      isSwap: self.viewModel.isSwap,
      tokens: self.viewModel.tokens
    )
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.transactionFilterViewController(self, apply: filter)
    })
  }
}

extension KNTransactionFilterViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
  }
}

extension KNTransactionFilterViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 3
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kFilterTokensTableViewCellID, for: indexPath) as! KNTransactionFilterTableViewCell
    let data = Array(self.viewModel.supportedTokens[indexPath.row * 4..<min(indexPath.row * 4 + 4, self.viewModel.supportedTokens.count)])
    cell.delegate = self
    cell.updateCell(with: data, selectedTokens: self.viewModel.tokens)
    return cell
  }
}

extension KNTransactionFilterViewController: KNTransactionFilterTableViewCellDelegate {
  func transactionFilterTableViewCell(_ cell: KNTransactionFilterTableViewCell, select token: String) {
    self.viewModel.selectTokenSymbol(token)
    self.tokensTableView.reloadData()
  }
}

extension KNTransactionFilterViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.fromTextField && (self.fromTextField.text ?? "").isEmpty {
      self.fromDatePickerDidChange(self.fromDatePicker)
    }
    if textField == self.toTextField && (self.toTextField.text ?? "").isEmpty {
      self.toDatePickerDidChange(self.toDatePicker)
    }
  }
}
