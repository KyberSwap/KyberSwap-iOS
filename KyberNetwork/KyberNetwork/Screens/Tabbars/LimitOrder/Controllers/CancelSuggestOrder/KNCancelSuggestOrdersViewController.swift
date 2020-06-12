// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNCancelSuggestOrdersViewControllerDelegate: class {
  func cancelSuggestOrdersViewControllerDidCheckUnderstand(_ controller: KNCancelSuggestOrdersViewController)
}

class KNCancelSuggestOrdersViewController: KNBaseViewController {
  let kCancelOrdersCollectionViewCellID: String = "kCancelOrdersCollectionViewCellID"

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var headerTitleLabel: UILabel!
  @IBOutlet weak var explainLabel: UILabel!
  @IBOutlet weak var whyButton: UIButton!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var checkButton: UIButton!
  @IBOutlet weak var understandButton: UIButton!

  let cancelSuggestHeaders: [String]
  let cancelSuggestSections: [String: [KNOrderObject]]
  let cancelOrder: KNOrderObject?
  let sourceVC: UIViewController
  weak var delegate: KNCancelSuggestOrdersViewControllerDelegate?

  init(header: [String], sections: [String: [KNOrderObject]], cancelOrder: KNOrderObject?, parent: UIViewController) {
    self.cancelSuggestHeaders = header
    self.cancelSuggestSections = sections
    self.cancelOrder = cancelOrder
    self.sourceVC = parent
    super.init(nibName: KNCancelSuggestOrdersViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func checkButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "cancelsuggestorder_checkbox_clicked", customAttributes: nil)
    self.checkButton.rounded(
      color: UIColor.clear,
      width: 0.0,
      radius: 2.5
    )
    self.checkButton.setImage(
      UIImage(named: "check_box_icon"),
      for: .normal
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.delegate?.cancelSuggestOrdersViewControllerDidCheckUnderstand(self)
    }
  }

  @IBAction func whyButtonTapped(_ sender: UIButton) {
    KNCrashlyticsUtil.logCustomEvent(withName: "cancelsuggestorder_why_button_clicked", customAttributes: nil)
    let url = "\(KNEnvironment.default.profileURL)/faq#can-I-submit-multiple-limit-orders-for-same-token-pair"
    self.navigationController?.openSafari(with: url)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.headerTitleLabel.text = "Cancel Order".toBeLocalised()
    self.explainLabel.text = "By submitting this order, you also CANCEL the following orders:".toBeLocalised()
    self.whyButton.setTitle("Why?".toBeLocalised(), for: .normal)
    self.understandButton.setTitle("I understand".toBeLocalised(), for: .normal)
    let nib = UINib(nibName: KNLimitOrderCollectionViewCell.className, bundle: nil)
    let headerNib = UINib(nibName: KNTransactionCollectionReusableView.className, bundle: nil)
    self.collectionView.register(nib, forCellWithReuseIdentifier: kCancelOrdersCollectionViewCellID)
    self.collectionView.register(
      headerNib,
      forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
      withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID
    )
    self.checkButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
  }
}

extension KNCancelSuggestOrdersViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets.zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNLimitOrderCollectionViewCell.kLimitOrderCellHeight
    )
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: 44
    )
  }
}

extension KNCancelSuggestOrdersViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.cancelSuggestHeaders.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let date = self.cancelSuggestHeaders[section]
    return self.cancelSuggestSections[date]?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
    withReuseIdentifier: kCancelOrdersCollectionViewCellID,
    for: indexPath
    ) as! KNLimitOrderCollectionViewCell
    let order: KNOrderObject = {
      let date = self.cancelSuggestHeaders[indexPath.section]
      let orders: [KNOrderObject] = self.cancelSuggestSections[date] ?? []
      return orders[indexPath.row]
    }()
    let isReset: Bool = {
      if let cancelBtnOrder = self.cancelOrder {
        return cancelBtnOrder.id != order.id
      }
      return true
    }()
    let color: UIColor = {
      return indexPath.row % 2 == 0 ? UIColor.white : UIColor(red: 246, green: 247, blue: 250)
    }()
    cell.updateCell(
      with: order,
      isReset: isReset,
      hasAction: false,
      bgColor: color
    )
    cell.closeButton.isHidden = true
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionElementKindSectionHeader:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KNTransactionCollectionReusableView.kOrderViewID, for: indexPath) as! KNTransactionCollectionReusableView
      let headerText = self.cancelSuggestHeaders[indexPath.section]
      headerView.updateView(with: headerText)
      return headerView
    default:
      assertionFailure("Unhandling")
      return UICollectionReusableView()
    }
  }
}
