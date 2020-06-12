// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNSelectMarketEvent {
  case getListFavouriteMarket
  case updateMarketFavouriteStatus(base: String, quote: String, status: Bool)
}

protocol KNSelectMarketViewControllerDelegate: class {
  func selectMarketViewControllerDidSelectMarket(_ controller: KNSelectMarketViewController, market: KNMarket)
  func selectMarketViewControllerDidSelectLOV1(_ controller: KNSelectMarketViewController)
  func selectMakertViewController(_ controller: KNSelectMarketViewController, run event: KNSelectMarketEvent)
}

class KNSelectMarketViewController: KNBaseViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var pairButton: UIButton!
  @IBOutlet weak var priceButton: UIButton!
  @IBOutlet weak var volumeButton: UIButton!
  @IBOutlet weak var change24hButton: UIButton!
  @IBOutlet weak var favouriteButton: UIButton!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var headerTitle: UILabel!
  @IBOutlet weak var noDataView: UIView!
  @IBOutlet weak var noMarketFoundTextLabel: UILabel!
  var marketTypeButtons: [UIButton] = []
  @IBOutlet weak var searchField: UITextField!
  @IBOutlet weak var marketButtonsStackView: UIStackView!
  var pickerButton: UIButton?

  lazy var pickerView: UIPickerView = {
    let pickerView = UIPickerView(frame: CGRect.zero)
    pickerView.showsSelectionIndicator = true
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()
  lazy var toolBar: UIToolbar = {
    let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
    let toolBar = UIToolbar(frame: frame)
    toolBar.barStyle = .default
    let doneBtn = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(self.dataPickerDonePressed(_:))
    )
    let flexibleSpaceBtn = UIBarButtonItem(
      barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
      target: nil,
      action: nil
    )
    doneBtn.tintColor = UIColor.Kyber.dark
    let cancelBtn = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(self.dataPickerCancelPressed(_:))
    )
    cancelBtn.tintColor = UIColor.Kyber.dark
    toolBar.setItems([cancelBtn, flexibleSpaceBtn, doneBtn], animated: false)
    return toolBar
  }()
  fileprivate var fakeTextField: UITextField = UITextField(frame: CGRect.zero)

  fileprivate let viewModel: KNSelectMarketViewModel
  weak var delegate: KNSelectMarketViewControllerDelegate?

  init(viewModel: KNSelectMarketViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNSelectMarketViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupMarketTableView()
    self.updateSortButtonTitle()
    self.view.addSubview(self.fakeTextField)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.headerTitle.text = "Market".toBeLocalised()
    self.noMarketFoundTextLabel.text = "No markets found".toBeLocalised()
    self.marketTypeButtons.append(self.favouriteButton)
    if self.viewModel.pickerViewData.count >= 1, let first = self.viewModel.pickerViewData.first {
      let button = self.buildMarketButton(first)
      button.tag = 0
      if self.viewModel.pickerViewData.count > 1 {
        button.setImage(UIImage(named: "arrow_down_grey"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -5)
        self.pickerButton = button
      }
      self.marketButtonsStackView.addArrangedSubview(button)
      self.marketTypeButtons.append(button)
    }
    for (index, element) in self.viewModel.marketButtonsData.enumerated() {
      let button = self.buildMarketButton(element)
      button.tag = index + 1
      self.marketButtonsStackView.addArrangedSubview(button)
      self.marketTypeButtons.append(button)
    }
    self.marketTypeButtons.forEach { (button) in
      button.rounded(radius: 5)
      button.layer.borderColor = UIColor.Kyber.orange.cgColor
    }
    if let button = self.marketTypeButtons.first(where: { $0.tag == 1 }), let buttonTitle = button.currentTitle {
      self.viewModel.marketType = "/" + buttonTitle
      self.setSelectButton(button)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.displayLoading()
    self.delegate?.selectMakertViewController(self, run: .getListFavouriteMarket)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func buildMarketButton(_ title: String) -> UIButton {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor(red: 246, green: 247, blue: 250)
    button.rounded()
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = UIFont.Kyber.medium(with: 14)
    button.setTitleColor(UIColor(red: 90, green: 94, blue: 103), for: .normal)
    button.heightAnchor.constraint(equalToConstant: 33.0).isActive = true
    button.widthAnchor.constraint(equalToConstant: 68.0).isActive = true
    button.addTarget(self, action: #selector(marketTypeButtonTapped(_:)), for: .touchUpInside)
    return button
  }

  fileprivate func setupMarketTableView() {
    let nib = UINib(nibName: KNMarketTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: KNMarketTableViewCell.kCellID
    )
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.rowHeight = KNBalanceTokenTableViewCell.kCellHeight
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
  }

  fileprivate func setSelectButton(_ sender: UIButton?) {
    self.marketTypeButtons.forEach { (button) in
      button.layer.borderWidth = 0
    }
    sender?.layer.borderWidth = 2.0
    self.fakeTextField.resignFirstResponder()
  }

  func coordinatorMarketCachedDidUpdate() {
    self.viewModel.updateMarketFromCoordinator()
    self.tableView.reloadData()
  }

  fileprivate func presentPickerView() {
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_open_quote_token_picker", customAttributes: nil)
    if let index = self.viewModel.pickerViewData.firstIndex(where: { $0 == self.pickerButton?.currentTitle }) {
      let type = self.viewModel.pickerViewData[index]
      self.viewModel.pickerViewSelectedValue = "/" + type
      self.pickerView.selectRow(index, inComponent: 0, animated: false)
    } else {
      if let firstValue = self.viewModel.pickerViewData.first {
        self.viewModel.pickerViewSelectedValue = "/" + firstValue
      }
      self.pickerView.selectRow(0, inComponent: 0, animated: false)
    }
    self.fakeTextField.inputView = self.pickerView
    self.fakeTextField.inputAccessoryView = self.toolBar
    self.pickerView.reloadAllComponents()
    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func limitOrderV1ButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_open_limit_order_v1", customAttributes: nil)
    self.delegate?.selectMarketViewControllerDidSelectLOV1(self)
  }

  @IBAction func marketTypeButtonTapped(_ sender: UIButton) {
    self.viewModel.isFav = false
    self.favouriteButton.setImage(UIImage(named: "unselected_fav_icon"), for: .normal)
    self.setSelectButton(sender)
    if sender.tag == 0 && self.viewModel.pickerViewData.count > 1 {
      self.presentPickerView()
      return
    }
    if let buttonTitle = sender.currentTitle {
      KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_change_market_button_tapped", customAttributes: ["market": buttonTitle])
      self.viewModel.marketType = "/" + buttonTitle
      self.noDataView.isHidden = !self.viewModel.showNoDataView
      self.tableView.reloadData()
    }
  }

  @IBAction func sortButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_sort_by_pair_name_tapped", customAttributes: nil)
      if case .pair(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .pair(asc: !asc)
      } else {
        self.viewModel.sortType = .pair(asc: false)
      }
    case 2:
      KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_sort_by_price_tapped", customAttributes: nil)
      if case .price(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .price(asc: !asc)
      } else {
        self.viewModel.sortType = .price(asc: false)
      }
    case 3:
      KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_sort_by_volume_tapped", customAttributes: nil)
      if case .volume(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .volume(asc: !asc)
      } else {
        self.viewModel.sortType = .volume(asc: false)
      }
    case 4:
      KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_sort_by_24hchange_tapped", customAttributes: nil)
      if case .change(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .change(asc: !asc)
      } else {
        self.viewModel.sortType = .change(asc: false)
      }
    default:
      break
    }
    self.updateSortButtonTitle()
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
  }

  fileprivate func updateSortButtonTitle() {
    let arrowUpAttributedString: NSAttributedString = {
      let attributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.regular(with: 15),
        NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
      ]
      return NSAttributedString(string: " ↑", attributes: attributes)
    }()

    let arrowDownAttributedString: NSAttributedString = {
      let attributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.regular(with: 15),
        NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
      ]
      return NSAttributedString(string: " ↓", attributes: attributes)
    }()
    let displayTypeNormalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.bold(with: 11.5),
      NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
    ]
    switch self.viewModel.sortType {
    case .pair(let asc):
      let sortingCharacter = asc ? arrowUpAttributedString : arrowDownAttributedString
      let attributeTitle = NSMutableAttributedString(string: "Pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes)
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(attributeTitle, for: .normal)
      self.priceButton.setAttributedTitle(NSAttributedString(string: "Price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes), for: .normal)
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "Volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h%".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .price(let asc):
      let sortingCharacter = asc ? arrowUpAttributedString : arrowDownAttributedString
      let attributeTitle = NSMutableAttributedString(string: "Price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "Pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(attributeTitle, for: .normal)
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "Volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h%".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .volume(let asc):
      let sortingCharacter = asc ? arrowUpAttributedString : arrowDownAttributedString
      let attributeTitle = NSMutableAttributedString(string: "Volume".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "Pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "Price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(attributeTitle, for: .normal)
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h%".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .change(let asc):
      let sortingCharacter = asc ? arrowUpAttributedString : arrowDownAttributedString
      let attributeTitle = NSMutableAttributedString(string: "24h%".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "Pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "Price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "Volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(attributeTitle, for: .normal)
    }
  }

  @objc func dataPickerDonePressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
    guard let selected = self.viewModel.pickerViewSelectedValue else { return }
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_select_token_from_picker", customAttributes: ["token": selected])
    self.viewModel.marketType = selected
    self.pickerButton?.setTitle(String(selected.dropFirst()), for: .normal)
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
    self.viewModel.pickerViewSelectedValue = nil
  }

  @objc func dataPickerCancelPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_cancel_token_picker", customAttributes: nil)
    self.fakeTextField.resignFirstResponder()
    self.viewModel.pickerViewSelectedValue = nil
  }

  @IBAction func favouriteButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_favorite_button_tapped", customAttributes: nil)
    guard (IEOUserStorage.shared.user?.accessToken) != nil else {
      self.tabBarController?.selectedIndex = 3
      self.showWarningTopBannerMessage(
        with: "Sign in required".toBeLocalised(),
        message: "You must sign in to use Limit Order feature".toBeLocalised(),
        time: 1.5
      )
      return
    }
    guard self.viewModel.isFav == false else { return }
    self.setSelectButton(sender)
    self.viewModel.isFav = true
    let icon = UIImage(named: "selected_fav_icon")
    self.favouriteButton.setImage(icon, for: .normal)
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
  }

  @IBAction func searchButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "selectmarket_search_token_tapped", customAttributes: nil)
    self.searchField.becomeFirstResponder()
  }

  func coordinatorUpdatedFavouriteList(_ success: Bool) {
    self.hideLoading()
    guard success else {
      return
    }
    self.viewModel.updateMarketFromCoordinator()
    self.tableView.reloadData()
  }
}

extension KNSelectMarketViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let viewModel = self.viewModel.displayCellViewModels[indexPath.row]
    self.delegate?.selectMarketViewControllerDidSelectMarket(self, market: viewModel.source)
  }
}

extension KNSelectMarketViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.displayCellViewModels.count
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 36.0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KNMarketTableViewCell.kCellID,
      for: indexPath
    ) as! KNMarketTableViewCell
    cell.delegate = self
    let viewModel = self.viewModel.displayCellViewModels[indexPath.row]
    cell.updateViewModel(viewModel)
    return cell
  }
}

extension KNSelectMarketViewController: KNMarketTableViewCellDelegate {
  func marketTableViewCellDidSelectFavorite(_ cell: KNMarketTableViewCell, isFav: Bool) {
    self.displayLoading()
    let tokens = cell.viewModel.source.pair.components(separatedBy: "_")
    let quote = tokens.first ?? ""
    let base = tokens.last ?? ""
    self.delegate?.selectMakertViewController(self, run: .updateMarketFavouriteStatus(base: base, quote: quote, status: isFav))
  }
}

extension KNSelectMarketViewController: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    let sym = self.viewModel.pickerViewData[row]
    self.viewModel.pickerViewSelectedValue = "/\(sym)"
  }
}

extension KNSelectMarketViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.viewModel.pickerViewData.count
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 32
  }

  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.dark,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]

    let localisedString = self.viewModel.pickerViewData[row]
    return NSAttributedString(
      string: localisedString,
      attributes: attributes
    )
  }
}

extension KNSelectMarketViewController: UITextFieldDelegate {
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    textField.text = ""
    self.viewModel.searchText = ""
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: " ", with: "")
    textField.text = text
    self.viewModel.searchText = text
    self.noDataView.isHidden = !self.viewModel.showNoDataView
    self.tableView.reloadData()
    return false
  }
}
