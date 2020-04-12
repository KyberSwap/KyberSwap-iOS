//
//  KNSelectMarketViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/7/20.
//

import UIKit

protocol KNSelectMarketViewControllerDelegate: class {
  func selectMarketViewControllerDidSelectMarket(_ controller: KNSelectMarketViewController, market: KNMarket)
}

class KNSelectMarketViewController: KNBaseViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var daiMarketButton: UIButton!
  @IBOutlet weak var ethMarketButton: UIButton!
  @IBOutlet weak var wbtcMarketButton: UIButton!
  @IBOutlet weak var pairButton: UIButton!
  @IBOutlet weak var priceButton: UIButton!
  @IBOutlet weak var volumeButton: UIButton!
  @IBOutlet weak var change24hButton: UIButton!
  @IBOutlet weak var favouriteButton: UIButton!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var headerTitle: UILabel!

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
  let pickerViewData = ["SAI", "DAI", "TUSD", "USDC", "USDT"]

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
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
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
    self.tableView.reloadData()
  }

  func coordinatorMarketCachedDidUpdate() {
    self.viewModel.updateMarketFromCoordinator()
  }

  fileprivate func presentPickerView() {
    if let index = self.pickerViewData.firstIndex(where: { $0 == self.daiMarketButton.currentTitle }) {
      let type = MarketType(rawValue: self.pickerViewData[index])
      self.viewModel.pickerViewSelectedValue = type
      self.pickerView.selectRow(index, inComponent: 0, animated: false)
    } else {
      self.viewModel.pickerViewSelectedValue = .dai
      self.pickerView.selectRow(1, inComponent: 0, animated: false)
    }
    self.fakeTextField.inputView = self.pickerView
    self.fakeTextField.inputAccessoryView = self.toolBar
    self.pickerView.reloadAllComponents()
    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func marketTypeButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      self.presentPickerView()
    case 2:
      self.viewModel.marketType = .eth
    case 3:
      self.viewModel.marketType = .wbtc
    default:
      break
    }
    self.tableView.reloadData()
  }

  @IBAction func sortButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      if case .pair(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .pair(asc: !asc)
      } else {
        self.viewModel.sortType = .pair(asc: true)
      }
    case 2:
      if case .price(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .price(asc: !asc)
      } else {
        self.viewModel.sortType = .price(asc: true)
      }
    case 3:
      if case .volume(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .volume(asc: !asc)
      } else {
        self.viewModel.sortType = .volume(asc: true)
      }
    case 4:
      if case .change(let asc) = self.viewModel.sortType {
        self.viewModel.sortType = .change(asc: !asc)
      } else {
        self.viewModel.sortType = .change(asc: true)
      }
    default:
      break
    }
    self.updateSortButtonTitle()
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
      NSAttributedStringKey.font: UIFont.Kyber.semiBold(with: 12),
      NSAttributedStringKey.foregroundColor: UIColor(red: 78, green: 80, blue: 99),
    ]
    switch self.viewModel.sortType {
    case .pair(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes)
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(attributeTitle, for: .normal)
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes), for: .normal)
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .price(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(attributeTitle, for: .normal)
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .volume(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "volume".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(attributeTitle, for: .normal)
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                              for: .normal
      )
    case .change(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "24h".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                         for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(), attributes: displayTypeNormalAttributes),
                                           for: .normal
      )
      self.change24hButton.setAttributedTitle(attributeTitle, for: .normal)
    }
  }

  @objc func dataPickerDonePressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
    guard let selected = self.viewModel.pickerViewSelectedValue else { return }
    self.viewModel.marketType = selected
    self.daiMarketButton.setTitle(selected.rawValue, for: .normal)
    self.tableView.reloadData()
    self.viewModel.pickerViewSelectedValue = nil
  }

  @objc func dataPickerCancelPressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
    self.viewModel.pickerViewSelectedValue = nil
  }

  @IBAction func favouriteButtonTapped(_ sender: UIButton) {
    self.viewModel.isFav = !self.viewModel.isFav
    let icon = self.viewModel.isFav ? UIImage(named: "selected_fav_icon") : UIImage(named: "unselected_fav_icon")
    self.favouriteButton.setImage(icon, for: .normal)
    if self.viewModel.isFav {
      self.viewModel.generateFavouriteData()
    } else {
      self.viewModel.updateMarketFromCoordinator()
    }
    self.tableView.reloadData()
  }
}

extension KNSelectMarketViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let viewModel = self.viewModel.displayCellViewModels[indexPath.row]
    guard let market = self.viewModel.getMarketObject(viewModel: viewModel) else {
      return
    }
    self.delegate?.selectMarketViewControllerDidSelectMarket(self, market: market)
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
    let message = isFav ? NSLocalizedString("Successfully added to your favorites", comment: "") : NSLocalizedString("Removed from your favorites", comment: "")
    self.showTopBannerView(with: "", message: message, time: 1.0)
    self.viewModel.updateMarketFromCoordinator()
    self.tableView.reloadData()
  }
}

extension KNSelectMarketViewController: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    switch row {
    case 0:
      self.viewModel.pickerViewSelectedValue = .sai
    case 1:
      self.viewModel.pickerViewSelectedValue = .dai
    case 2:
      self.viewModel.pickerViewSelectedValue = .tusd
    case 3:
      self.viewModel.pickerViewSelectedValue = .usdc
    case 4:
      self.viewModel.pickerViewSelectedValue = .usdt
    default:
      break
    }
  }
}

extension KNSelectMarketViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return self.pickerViewData.count
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 32
  }

  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.dark,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]

    let localisedString = self.pickerViewData[row]
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
    self.tableView.reloadData()
    return true
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string).replacingOccurrences(of: " ", with: "")
    textField.text = text
    self.viewModel.searchText = text
    self.tableView.reloadData()
    return false
  }
}
