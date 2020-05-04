// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNFilterLimitOrderViewControllerDelegate: class {
  func filterLimitOrderViewController(_ controller: KNFilterLimitOrderViewController, isDateDesc: Bool, pairs: [String]?, status: [Int], addresses: [String]?)
}

class KNFilterLimitOrderViewModel {
  var isDateDesc: Bool = true
  var pairs: [String]?
  var addresses: [String]?
  var status: [Int] = [0, 1, 2, 3, 4]
  let isSortAsc: Bool = true

  var allPairs: [String] = []
  var allAddresses: [String] = []

  init(isDateDesc: Bool, pairs: [String]?, status: [Int], addresses: [String]?, allPairs: [String], allAddresses: [String]) {
    self.isDateDesc = isDateDesc
    self.pairs = pairs
    self.status = status
    self.allPairs = allPairs.sorted(by: {
      return $0 < $1 && self.isSortAsc
    })
    self.addresses = addresses
    self.allAddresses = allAddresses
  }

  func updateAllPairs(_ pairs: [String]) {
    self.allPairs = pairs.sorted(by: {
      if self.isSortAsc { return $0 < $1 }
      return $0 > $1
    })
  }

  func updateAllAddresses(_ addresses: [String]) {
    self.allAddresses = addresses
  }
}

class KNFilterLimitOrderViewController: KNBaseViewController {

  let kFilterLimitOrderSelectPairTableViewCellID = "kFilterLimitOrderSelectPairTableViewCell"
  let kFilterLimitOrderAddressTableViewCellID = "kFilterLimitOrderAddressTableViewCellID"
  let kFilterLimitOrderSelectPairTableViewCellHeight: CGFloat = 36.0

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var dateContainerView: UIView!
  @IBOutlet weak var dateTextLabel: UILabel!
  @IBOutlet weak var latestSelectButton: UIButton!
  @IBOutlet weak var latestTextButton: UIButton!
  @IBOutlet weak var oldestTextButton: UIButton!
  @IBOutlet weak var oldestSelectButton: UIButton!

  @IBOutlet weak var pairContainerView: UIView!
  @IBOutlet weak var statusContainerView: UIView!
  @IBOutlet weak var addressContainerView: UIView!

  @IBOutlet weak var filterTextLabel: UILabel!
  @IBOutlet weak var pairTextLabel: UILabel!
  @IBOutlet weak var statusTextLabel: UILabel!

  @IBOutlet weak var listPairsTableView: UITableView!
  @IBOutlet weak var listPairsTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var dontHaveAnyOrdersLabel: UILabel!

  @IBOutlet weak var statusOpenButton: UIButton!
  @IBOutlet weak var statusFilledButton: UIButton!
  @IBOutlet weak var statusCanceledButton: UIButton!
  @IBOutlet weak var statusInProgressButton: UIButton!
  @IBOutlet weak var statusInvalidatedButton: UIButton!

  @IBOutlet weak var addressTableView: UITableView!
  @IBOutlet weak var addressTableViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var applyButton: UIButton!

  let viewModel: KNFilterLimitOrderViewModel
  weak var delegate: KNFilterLimitOrderViewControllerDelegate?

  init(viewModel: KNFilterLimitOrderViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNFilterLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.dateTextLabel.text = NSLocalizedString("Date", value: "Date", comment: "")
    self.filterTextLabel.text = NSLocalizedString("Filter", value: "Filter", comment: "")
    self.pairTextLabel.text = NSLocalizedString("Filter", value: "Filter", comment: "")
    self.statusTextLabel.text = NSLocalizedString("Status", value: "Status", comment: "")

    self.latestTextButton.setTitle("Latest".toBeLocalised(), for: .normal)
    self.oldestTextButton.setTitle("Oldest".toBeLocalised(), for: .normal)
    self.latestSelectButton.backgroundColor = .white
    self.oldestTextButton.backgroundColor = .white

    self.resetButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.resetButton.setTitle("Reset".toBeLocalised(), for: .normal)

    self.applyButton.rounded()
    self.applyButton.applyGradient()
    self.applyButton.setTitle(NSLocalizedString("apply", value: "Apply", comment: ""), for: .normal)

    let nib = UINib(nibName: KNFilterLimitOrderSelectPairTableViewCell.className, bundle: nil)
    self.listPairsTableView.register(
      nib,
      forCellReuseIdentifier: kFilterLimitOrderSelectPairTableViewCellID
    )
    self.listPairsTableView.backgroundColor = .clear
    self.listPairsTableView.rowHeight = kFilterLimitOrderSelectPairTableViewCellHeight
    self.listPairsTableView.dataSource = self

    self.addressTableView.register(
      nib,
      forCellReuseIdentifier: kFilterLimitOrderAddressTableViewCellID
    )
    self.addressTableView.backgroundColor = .clear
    self.addressTableView.rowHeight = kFilterLimitOrderSelectPairTableViewCellHeight
    self.addressTableView.dataSource = self

    self.dontHaveAnyOrdersLabel.text = "No order found".toBeLocalised()
    self.dontHaveAnyOrdersLabel.isHidden = true

    self.dateContainerView.rounded(radius: 4.0)
    self.pairContainerView.rounded(radius: 4.0)
    self.statusContainerView.rounded(radius: 4.0)
    self.addressContainerView.rounded(radius: 4.0)

    self.updateDateView()
    self.updateSortPairView()
    self.updateStatusView()
    self.updateAddressView()
    self.updateUIOrdersChanged()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func updateDateView() {
    self.latestSelectButton.rounded(
      color: self.viewModel.isDateDesc ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: self.viewModel.isDateDesc ? 6.0 : 1.0
    )
    self.oldestSelectButton.rounded(
      color: !self.viewModel.isDateDesc ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: !self.viewModel.isDateDesc ? 6.0 : 1.0
    )
  }

  fileprivate func updateUIOrdersChanged() {
    self.dontHaveAnyOrdersLabel.isHidden = !self.viewModel.allPairs.isEmpty
    self.pairContainerView.isHidden = self.viewModel.allPairs.isEmpty
    self.statusContainerView.isHidden = self.viewModel.allPairs.isEmpty
    self.addressContainerView.isHidden = self.viewModel.allPairs.isEmpty
  }

  fileprivate func updateSortPairView() {
    self.listPairsTableView.reloadData()

    self.listPairsTableViewHeightConstraint.constant = {
      if self.viewModel.allPairs.isEmpty { return 60.0 }
      return min(108.0, CGFloat((self.viewModel.allPairs.count + 1) / 2) * 36.0) + 10.0
    }()
    self.view.layoutIfNeeded()
  }

  fileprivate func updateAddressView() {
    self.addressTableView.reloadData()
    self.addressTableViewHeightConstraint.constant = {
      if self.viewModel.allAddresses.isEmpty { return 60.0 }
      return min(108.0, CGFloat((self.viewModel.allAddresses.count + 1) / 2) * 36.0)
    }()
  }

  fileprivate func updateStatusView() {
    self.statusOpenButton.rounded(
      color: self.viewModel.status.contains(0) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusOpenButton.setImage(
      self.viewModel.status.contains(0) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusInProgressButton.rounded(
      color: self.viewModel.status.contains(1) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusInProgressButton.setImage(
      self.viewModel.status.contains(1) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusFilledButton.rounded(
      color: self.viewModel.status.contains(2) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusFilledButton.setImage(
      self.viewModel.status.contains(2) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusCanceledButton.rounded(
      color: self.viewModel.status.contains(3) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusCanceledButton.setImage(
      self.viewModel.status.contains(3) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusInvalidatedButton.rounded(
      color: self.viewModel.status.contains(4) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusInvalidatedButton.setImage(
      self.viewModel.status.contains(4) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
  }

  func updateListPairs(_ pairs: [String], selectedPairs: [String]?, status: [Int]) {
    self.viewModel.updateAllPairs(pairs)
    self.viewModel.pairs = selectedPairs
    self.viewModel.status = status
    self.updateUIOrdersChanged()
    self.updateSortPairView()
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func latestButtonPressed(_ sender: Any) {
    self.viewModel.isDateDesc = true
    self.updateDateView()
  }

  @IBAction func oldestButtonPressed(_ sender: Any) {
    self.viewModel.isDateDesc = false
    self.updateDateView()
  }

  @IBAction func statusOpenButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 0) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(0)
    }
    self.updateStatusView()
  }

  @IBAction func statusInProgressButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 1) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(1)
    }
    self.updateStatusView()
  }

  @IBAction func statusFilledButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 2) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(2)
    }
    self.updateStatusView()
  }

  @IBAction func statusCancelledButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 3) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(3)
    }
    self.updateStatusView()
  }

  @IBAction func statusInvalidateButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 4) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(4)
    }
    self.updateStatusView()
  }

  @IBAction func resetButtonPressed(_ sender: Any) {
    self.viewModel.pairs = nil
    self.viewModel.status = [0, 1, 2, 3, 4]
    self.viewModel.addresses = nil

    self.updateSortPairView()
    self.updateStatusView()
    self.updateAddressView()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true, completion: {
      self.delegate?.filterLimitOrderViewController(
        self,
        isDateDesc: self.viewModel.isDateDesc,
        pairs: self.viewModel.pairs,
        status: self.viewModel.status,
        addresses: self.viewModel.addresses
      )
    })
  }
}

extension KNFilterLimitOrderViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if tableView == self.addressTableView { return (self.viewModel.allAddresses.count + 1) / 2 }
    return (self.viewModel.allPairs.count + 1) / 2
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell: KNFilterLimitOrderSelectPairTableViewCell = {
      if tableView == self.addressTableView {
        return tableView.dequeueReusableCell(
          withIdentifier: kFilterLimitOrderAddressTableViewCellID,
          for: indexPath
        ) as! KNFilterLimitOrderSelectPairTableViewCell
      }
      return tableView.dequeueReusableCell(
        withIdentifier: kFilterLimitOrderSelectPairTableViewCellID,
        for: indexPath
      ) as! KNFilterLimitOrderSelectPairTableViewCell
    }()
    let row = indexPath.row

    let isAddr = tableView == self.addressTableView

    let firstPair = isAddr ? self.viewModel.allAddresses[2 * row] : self.viewModel.allPairs[2 * row]
    let isFirstPairSelected: Bool = {
      if isAddr {
        guard let addresses = self.viewModel.addresses else { return true }
        return addresses.contains(firstPair)
      }
      if let pairs = self.viewModel.pairs {
        return pairs.contains(firstPair)
      }
      return true
    }()
    let secondPair: String = {
      if isAddr {
        let hasData  = 2 * row + 1 < self.viewModel.allAddresses.count
        return hasData ? self.viewModel.allAddresses[2 * row + 1] : ""
      }
      let hasData = 2 * row + 1 < self.viewModel.allPairs.count
      return hasData ? self.viewModel.allPairs[2 * row + 1] : ""
    }()
    let isSecondPairSelected: Bool = {
      if secondPair.isEmpty { return false }
      if isAddr {
        guard let addresses = self.viewModel.addresses else { return true }
        return addresses.contains(secondPair)
      }
      if let pairs = self.viewModel.pairs {
        return pairs.contains(secondPair)
      }
      return true
    }()
    cell.updateCell(
      firstPair: firstPair,
      isFirstPairSelected: isFirstPairSelected,
      secondPair: secondPair,
      isSecondPairSelected: isSecondPairSelected,
      isPair: !isAddr
    )
    cell.delegate = self
    return cell
  }
}

extension KNFilterLimitOrderViewController: KNFilterLimitOrderSelectPairTableViewCellDelegate {
  func filterLimitOrderSelectPairTableViewCell(_ cell: KNFilterLimitOrderSelectPairTableViewCell, didSelect string: String, isPair: Bool) {
    if isPair {
      // select pair token
      var pairs: [String] = {
        if let pairs = self.viewModel.pairs { return pairs }
        return self.viewModel.allPairs
      }()
      if let index = pairs.firstIndex(of: string) {
        pairs.remove(at: index)
      } else {
        pairs.append(string)
      }
      if pairs.count == self.viewModel.allPairs.count {
        self.viewModel.pairs = nil // select all
      } else {
        self.viewModel.pairs = pairs
      }
      self.listPairsTableView.reloadData()
      return
    }
    // select address
    var addresses: [String] = {
      if let addresses = self.viewModel.addresses { return addresses }
      return self.viewModel.allAddresses
    }()
    if let index = addresses.firstIndex(of: string) {
      addresses.remove(at: index)
    } else {
      addresses.append(string)
    }
    if addresses.count == self.viewModel.allAddresses.count {
      self.viewModel.addresses = nil // select all
    } else {
      self.viewModel.addresses = addresses
    }
    self.addressTableView.reloadData()
    return
  }
}
