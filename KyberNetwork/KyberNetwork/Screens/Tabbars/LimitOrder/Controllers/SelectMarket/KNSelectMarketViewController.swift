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
    self.updateMarketTypeButtonUI()
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

  @IBAction func marketTypeButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      self.viewModel.marketType = .dai
    case 2:
      self.viewModel.marketType = .eth
    case 3:
      self.viewModel.marketType = .wbtc
    default:
      break
    }
    self.updateMarketTypeButtonUI()
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

  fileprivate func updateMarketTypeButtonUI() {
    let arrowImg = UIImage(named: "arrow_down_grey")
    switch self.viewModel.marketType {
    case .dai:
      self.daiMarketButton.setImage(arrowImg, for: .normal)
      self.ethMarketButton.setImage(nil, for: .normal)
      self.wbtcMarketButton.setImage(nil, for: .normal)
    case .eth:
      self.daiMarketButton.setImage(nil, for: .normal)
      self.ethMarketButton.setImage(arrowImg, for: .normal)
      self.wbtcMarketButton.setImage(nil, for: .normal)
    case .wbtc:
      self.daiMarketButton.setImage(nil, for: .normal)
      self.ethMarketButton.setImage(nil, for: .normal)
      self.wbtcMarketButton.setImage(arrowImg, for: .normal)
    }
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
      let attributeTitle = NSMutableAttributedString(string: "pair".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(attributeTitle, for: .normal)
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
    case .price(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "price".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.priceButton.setAttributedTitle(attributeTitle, for: .normal)
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
    case .volume(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "volume".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(attributeTitle, for: .normal)
      self.change24hButton.setAttributedTitle(NSAttributedString(string: "24h".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
    case .change(let asc):
      let sortingCharacter = asc ? arrowDownAttributedString : arrowUpAttributedString
      let attributeTitle = NSMutableAttributedString(string: "24h".toBeLocalised().uppercased(),
                                                     attributes: displayTypeNormalAttributes
      )
      attributeTitle.append(sortingCharacter)
      self.pairButton.setAttributedTitle(NSAttributedString(string: "pair".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.priceButton.setAttributedTitle(NSAttributedString(string: "price".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.volumeButton.setAttributedTitle(NSAttributedString(string: "volume".toBeLocalised().uppercased(),
                                                             attributes: displayTypeNormalAttributes),
                                          for: .normal
      )
      self.change24hButton.setAttributedTitle(attributeTitle, for: .normal)
    }
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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: KNMarketTableViewCell.kCellID,
      for: indexPath
    ) as! KNMarketTableViewCell
    let viewModel = self.viewModel.displayCellViewModels[indexPath.row]
    cell.updateViewModel(viewModel)
    return cell
  }
}
