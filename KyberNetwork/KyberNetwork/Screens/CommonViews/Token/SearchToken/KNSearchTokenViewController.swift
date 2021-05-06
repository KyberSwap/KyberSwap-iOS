// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import TrustCore

enum KNSearchTokenViewEvent {
  case cancel
  case select(token: TokenObject)
  case add(token: TokenObject)
}

protocol KNSearchTokenViewControllerDelegate: class {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent)
}

class KNSearchTokenViewModel {

  var supportedTokens: [TokenObject] = []
  var balances: [String: Balance] = [:]
  var searchedText: String = "" {
    didSet {
      guard Address(string: self.searchedText) == nil else {
        let tokens = self.checkExistAddress()
        self.displayedTokens = tokens
        return
      }
      self.updateDisplayedTokens()
    }
  }
  var displayedTokens: [TokenObject] = []

  init(supportedTokens: [TokenObject]) {
    self.supportedTokens = supportedTokens.sorted(by: { return $0.symbol < $1.symbol })
    self.searchedText = ""
    self.displayedTokens = self.supportedTokens
  }

  var isNoMatchingTokenHidden: Bool { return !self.displayedTokens.isEmpty }
  
  @discardableResult
  func checkExistAddress() -> [TokenObject] {
    let tokens = self.supportedTokens.filter { (item) -> Bool in
      return item.address.lowercased() == self.searchedText.lowercased()
    }
    return tokens
  }
  
  func checkSearchTextIsAddress() -> Bool {
    return Address(string: self.searchedText) != nil
  }

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
      let balance0 = token0.getBalanceBigInt()
      let balance1 = token1.getBalanceBigInt()
      return balance0 * BigInt(10).power(18 - token0.decimals) > balance1 * BigInt(10).power(18 - token1.decimals)
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

  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var tokensTableView: UITableView!
  @IBOutlet weak var noMatchingTokensLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()

  fileprivate var viewModel: KNSearchTokenViewModel
  weak var delegate: KNSearchTokenViewControllerDelegate?

  init(viewModel: KNSearchTokenViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSearchTokenViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
  }

  fileprivate func setupUI() {
    self.searchTextField.delegate = self

    let nib = UINib(nibName: KNSearchTokenTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: kSearchTokenTableViewCellID)
    self.tokensTableView.rowHeight = 40
    self.tokensTableView.dataSource = self

    self.noMatchingTokensLabel.text = NSLocalizedString("no.matching.tokens", value: "No matching tokens", comment: "")
    self.noMatchingTokensLabel.addLetterSpacing()
  }

  fileprivate func searchTextDidChange(_ newText: String) {
    self.viewModel.searchedText = newText
    self.updateUIDisplayedDataDidChange()
    self.requestTokenInfoIfNeeded()
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

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapInsidePopup(_ sender: UITapGestureRecognizer) {
    print("tap")
  }
  
  fileprivate func requestTokenInfoIfNeeded() {
    guard Address(string: self.viewModel.searchedText) != nil else {
      return
    }
    guard self.viewModel.checkExistAddress().isEmpty == true else {
      return
    }
    var tokenSymbol = ""
    var tokenDecimal = ""
    let group = DispatchGroup()
    group.enter()
    KNGeneralProvider.shared.getTokenSymbol(address: self.viewModel.searchedText) { (result) in
      switch result {
      case .success(let symbol):
        tokenSymbol = symbol
      case .failure(let error):
        print("[Custom token][Errror] \(error.description)")
      }
      group.leave()
    }
    group.enter()
    KNGeneralProvider.shared.getTokenDecimals(address: self.viewModel.searchedText) { (result) in
      switch result {
      case .success(let decimals):
        tokenDecimal = decimals
      case .failure(let error):
        print("[Custom token][Errror] \(error.description)")
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      let tokenObj = TokenObject(name: "", symbol: tokenSymbol, address: self.viewModel.searchedText, decimals: Int(tokenDecimal) ?? 18, logo: "")
      self.viewModel.displayedTokens = [tokenObj]
      self.updateUIDisplayedDataDidChange()
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
    let existedToken = (self.viewModel.displayedTokens.count == 1) && self.viewModel.checkSearchTextIsAddress() && self.viewModel.checkExistAddress().isEmpty
    cell.updateCell(with: token, isExistToken: !existedToken)
    cell.delegate = self
    return cell
  }
}

extension KNSearchTokenViewController: KNSearchTokenTableViewCellDelegate {
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didSelect token: TokenObject) {
    self.delegate?.searchTokenViewController(self, run: .select(token: token))
  }
  
  func searchTokenTableCell(_ cell: KNSearchTokenTableViewCell, didAdd token: TokenObject) {
    self.delegate?.searchTokenViewController(self, run: .add(token: token))
  }
}

extension KNSearchTokenViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
