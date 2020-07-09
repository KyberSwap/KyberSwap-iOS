// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

enum KNSearchTokenViewEvent {
  case cancel
  case select(token: TokenObject)
}

protocol KNSearchTokenViewControllerDelegate: class {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent)
}

class KNSearchTokenViewModel {

  let headerColor: UIColor
  var supportedTokens: [TokenObject] = []
  var balances: [String: Balance] = [:]
  var searchedText: String = "" {
    didSet {
      self.updateDisplayedTokens()
    }
  }
  var displayedTokens: [TokenObject] = []

  init(headerColor: UIColor, supportedTokens: [TokenObject]) {
    self.headerColor = headerColor
    self.supportedTokens = supportedTokens.sorted(by: { return $0.symbol < $1.symbol })
    self.searchedText = ""
    self.displayedTokens = self.supportedTokens
  }

  var isNoMatchingTokenHidden: Bool { return !self.displayedTokens.isEmpty }

  func updateDisplayedTokens() {
    self.displayedTokens = {
      if self.searchedText == "" {
        return self.supportedTokens
      }
      return self.supportedTokens.filter({ return ($0.symbol + " " + $0.name).lowercased().contains(self.searchedText.lowercased()) }).filter({
        if $0.isListed == false { return false }
        return true
      })
    }()
    self.displayedTokens.sort { (token0, token1) -> Bool in
      let isFav0 = KNAppTracker.isTokenFavourite(token0.contract.lowercased())
      let isFav1 = KNAppTracker.isTokenFavourite(token1.contract.lowercased())
      if isFav0 && !isFav1 { return true }
      if !isFav0 && isFav1 { return false }
      if token0.isSupported && !token1.isSupported { return true }
      if token1.isSupported && !token0.isSupported { return false }
      let isContain0 = token0.symbol.lowercased().contains(self.searchedText.lowercased())
      let isContain1 = token1.symbol.lowercased().contains(self.searchedText.lowercased())
      if isContain0 && !isContain1 { return true }
      if !isContain0 && isContain1 { return false }
      guard let balance0 = self.balances[token0.contract] else { return false }
      guard let balance1 = self.balances[token1.contract] else { return true }
      return balance0.value * BigInt(10).power(18 - token0.decimals) > balance1.value * BigInt(10).power(18 - token1.decimals)
    }
  }

  func updateListSupportedTokens(_ tokens: [TokenObject]) {
    self.supportedTokens = tokens.sorted(by: { return $0.symbol < $1.symbol })
    self.updateDisplayedTokens()
  }

  func updateBalances(_ balances: [String: Balance]) {
    balances.forEach { (key, value) in
      self.balances[key] = value
    }
  }
}

class KNSearchTokenViewController: KNBaseViewController {

  fileprivate let kSearchTokenTableViewCellID: String = "CellID"

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tokensTableView: UITableView!
  @IBOutlet weak var noMatchingTokensLabel: UILabel!
  @IBOutlet weak var tableViewBottomPaddingConstraint: NSLayoutConstraint!

  fileprivate var viewModel: KNSearchTokenViewModel
  weak var delegate: KNSearchTokenViewControllerDelegate?

  init(viewModel: KNSearchTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSearchTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name.UIKeyboardDidShow,
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name.UIKeyboardDidHide,
      object: nil
    )
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.searchTextField.text = ""
    self.searchTextDidChange("")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.searchTextField.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.view.endEditing(true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.navTitleLabel.text = NSLocalizedString("search", value: "Search", comment: "")
    self.navTitleLabel.addLetterSpacing()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.searchTextField.delegate = self
    self.searchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: self.searchTextField.frame.height))
    self.searchTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: self.searchTextField.frame.height))
    self.searchTextField.rounded(
      color: UIColor(red: 231, green: 231, blue: 231),
      width: 1,
      radius: 5.0
    )

    let nib = UINib(nibName: KNSearchTokenTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: kSearchTokenTableViewCellID)
    self.tokensTableView.rowHeight = 46
    self.tokensTableView.delegate = self
    self.tokensTableView.dataSource = self
    self.tableViewBottomPaddingConstraint.constant = self.bottomPaddingSafeArea()

    self.noMatchingTokensLabel.text = NSLocalizedString("no.matching.tokens", value: "No matching tokens", comment: "")
    self.noMatchingTokensLabel.addLetterSpacing()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.keyboardDidShow(_:)),
      name: NSNotification.Name.UIKeyboardDidShow,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.keyboardDidHide(_:)),
      name: NSNotification.Name.UIKeyboardDidHide,
      object: nil
    )
  }

  fileprivate func searchTextDidChange(_ newText: String) {
    self.viewModel.searchedText = newText
    self.updateUIDisplayedDataDidChange()
  }

  fileprivate func updateUIDisplayedDataDidChange() {
    self.noMatchingTokensLabel.isHidden = self.viewModel.isNoMatchingTokenHidden
    self.tokensTableView.isHidden = !self.viewModel.isNoMatchingTokenHidden
    self.tokensTableView.reloadData()
  }

  func updateListSupportedTokens(_ tokens: [TokenObject]) {
    self.viewModel.updateListSupportedTokens(tokens)
    self.updateUIDisplayedDataDidChange()
  }

  func updateBalances(_ balances: [String: Balance]) {
    self.viewModel.updateBalances(balances)
    self.updateUIDisplayedDataDidChange()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.searchTokenViewController(self, run: .cancel)
  }

  @objc func keyboardDidShow(_ sender: Notification) {
    if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      UIView.animate(
      withDuration: 0.25) {
        self.tableViewBottomPaddingConstraint.constant = keyboardSize.height
        self.view.updateConstraints()
      }
    }
  }

  @objc func keyboardDidHide(_ sender: Notification) {
    UIView.animate(
    withDuration: 0.25) {
      self.tableViewBottomPaddingConstraint.constant = self.bottomPaddingSafeArea()
      self.view.updateConstraints()
    }
  }
}

extension KNSearchTokenViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.searchTextDidChange(text)
    return false
  }
}

extension KNSearchTokenViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.row < self.viewModel.displayedTokens.count {
      let token = self.viewModel.displayedTokens[indexPath.row]
      self.delegate?.searchTokenViewController(self, run: .select(token: token))
    }
  }
}

extension KNSearchTokenViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.displayedTokens.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kSearchTokenTableViewCellID, for: indexPath) as! KNSearchTokenTableViewCell
    let token = self.viewModel.displayedTokens[indexPath.row]
    let balance = self.viewModel.balances[token.contract]
    cell.updateCell(with: token, balance: balance)
    return cell
  }
}
