//
//  EarnTutorialViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 4/6/21.
//

import UIKit
import FSPagerView


struct TutorialItem {
  let image: String
  let content: String
}

struct EarnTutorialViewModel {
  let dataSource: [TutorialItem] = [
    TutorialItem(image: "earn_intro_1", content: "Supply tokens to earn interest (APY). Withdraw anytime."),
    TutorialItem(image: "earn_intro_2", content: "Earn bonus rewards with auto-farming of governance tokens on top of interest from supplying."),
    TutorialItem(image: "earn_intro_3", content: "Don’t worry if you don’t have the required token. Easily swap from any token to the required token before supplying."),
    TutorialItem(image: "earn_intro_4", content: "Swap and supply in a single transaction to save on gas fees.")
  ]
}

class EarnTutorialViewController: UIViewController {
  @IBOutlet weak var bannerPagerView: FSPagerView! {
    didSet {
      let nib = UINib(nibName: EarnTutorialCell.className, bundle: nil)
      self.bannerPagerView.register(nib, forCellWithReuseIdentifier: "EarnTutorialCell")
    }
  }
  @IBOutlet weak var bannerPagerControl: FSPageControl!
  
  let viewModel = EarnTutorialViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bannerPagerControl.setFillColor(UIColor(named: "buttonBackgroundColor")!, for: .selected)
    self.bannerPagerControl.setFillColor(UIColor(named: "normalTextColor")!, for: .normal)
    self.bannerPagerControl.numberOfPages = 0
    self.bannerPagerControl.numberOfPages = self.viewModel.dataSource.count
  }
  
  @IBAction func exploreButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
}

extension EarnTutorialViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    return self.viewModel.dataSource.count
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "EarnTutorialCell", at: index) as? EarnTutorialCell else {
      return FSPagerViewCell()
    }
    
    cell.iconImageView.image = UIImage(named: self.viewModel.dataSource[index].image)
    cell.contentLabel.text = self.viewModel.dataSource[index].content
    return cell
  }
}

extension EarnTutorialViewController: FSPagerViewDelegate {
  func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
    pagerView.deselectItem(at: index, animated: true)
    pagerView.scrollToItem(at: index, animated: true)
//    self.delegate?.investViewController(self, run: .openLink(url: self.viewModel.bannerDataSource[index].url))
  }

  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    self.bannerPagerControl.currentPage = targetIndex
  }

  func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
    self.bannerPagerControl.currentPage = pagerView.currentIndex
  }
}
