// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FSPagerView
import Kingfisher

enum KNExploreViewEvent {
  case getListMobileBanner
  case openNotification
  case openAlert
  case openHistory
  case openLogin
}

class KNExploreViewModel {
  var bannerItems: [[String: String]] = []
}

protocol KNExploreViewControllerDelegate: class {
  func kExploreViewController(_ controller: KNExploreViewController, run event: KNExploreViewEvent)
}

class KNExploreViewController: KNBaseViewController {
  @IBOutlet weak var bannerPagerView: FSPagerView! {
    didSet {
      self.bannerPagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
    }
  }
  @IBOutlet weak var bannerPagerControl: FSPageControl!
  @IBOutlet weak var notificationButton: UIButton!
  @IBOutlet weak var alertButton: UIButton!
  @IBOutlet weak var historyButton: UIButton!
  @IBOutlet weak var loginButton: UIButton!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var headerTitleLabel: UILabel!

  var viewModel: KNExploreViewModel
  weak var delegate: KNExploreViewControllerDelegate?

  init(viewModel: KNExploreViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNExploreViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.bannerPagerControl.setFillColor(UIColor.Kyber.orange, for: .selected)
    self.bannerPagerControl.setFillColor(UIColor.Kyber.lightPeriwinkle, for: .normal)
    self.bannerPagerControl.numberOfPages = 0
    self.notificationButton.centerVertically(padding: 10)
    self.alertButton.centerVertically(padding: 10)
    self.historyButton.centerVertically(padding: 10)
    self.loginButton.centerVertically(padding: 10)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.headerTitleLabel.text = "Explore".toBeLocalised()
    self.notificationButton.setTitle("Notifications".toBeLocalised(), for: .normal)
    self.alertButton.setTitle("Alert".toBeLocalised(), for: .normal)
    self.historyButton.setTitle("History".toBeLocalised(), for: .normal)
    self.loginButton.setTitle("profile".toBeLocalised(), for: .normal)
    self.delegate?.kExploreViewController(self, run: .getListMobileBanner)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.bannerPagerView.itemSize = self.bannerPagerView.frame.size
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }
  func coordinatorUpdateBannerImages(items: [[String: String]]) {
    self.viewModel.bannerItems = items
    self.bannerPagerControl.numberOfPages = self.viewModel.bannerItems.count
    self.bannerPagerControl.currentPage = 0
    self.bannerPagerView.reloadData()
  }

  @IBAction func menuButtonTapped(_ sender: UIButton) {
    switch sender.tag {
    case 1:
      self.delegate?.kExploreViewController(self, run: .openNotification)
    case 2:
      self.delegate?.kExploreViewController(self, run: .openAlert)
    case 3:
      self.delegate?.kExploreViewController(self, run: .openHistory)
    case 4:
      self.delegate?.kExploreViewController(self, run: .openLogin)
    default:
      break
    }
  }
}

extension KNExploreViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    return self.viewModel.bannerItems.count
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
    let url = URL(string: self.viewModel.bannerItems[index]["image_url"] ?? "")
    cell.imageView?.kf.setImage(with: url)
    cell.imageView?.contentMode = .scaleAspectFill
    cell.imageView?.clipsToBounds = true
    return cell
  }
}

extension KNExploreViewController: FSPagerViewDelegate {
  func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
    pagerView.deselectItem(at: index, animated: true)
    pagerView.scrollToItem(at: index, animated: true)
  }

  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    self.bannerPagerControl.currentPage = targetIndex
  }

  func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
    self.bannerPagerControl.currentPage = pagerView.currentIndex
  }
}
