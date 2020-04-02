//
//  LimitOrderContainerViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/25/20.
//

import UIKit
import BigInt

enum LimitOrderContainerViewEvent {
  case estimateRate(from: TokenObject, to: TokenObject, amount: BigInt, showWarning: Bool)
}

protocol LimitOrderContainerViewControllerDelegate: class {
  func kLimitOrderContainerViewController(_ controller: LimitOrderContainerViewController, run event: LimitOrderContainerViewEvent)
}

class LimitOrderContainerViewController: KNBaseViewController {
  @IBOutlet weak var pagerIndicator: UIView!
  @IBOutlet weak var contentContainerView: UIView!
  @IBOutlet weak var buyKncButton: UIButton!
  @IBOutlet weak var sellKncButton: UIButton!
  @IBOutlet weak var pagerIndicatorCenterXContraint: NSLayoutConstraint!
  
  weak var delegate: KNCreateLimitOrderViewControllerDelegate? //Note: delete later

  private var pageController: UIPageViewController!
  private var pages: [KNBuyKNCViewController]
  
  init(wallet: Wallet) {
    let buyViewModel = KNBuyKNCViewModel(wallet: wallet)
    let sellViewModel = KNBuyKNCViewModel(wallet: wallet)
    self.pages = [KNBuyKNCViewController(viewModel: buyViewModel), KNBuyKNCViewController(viewModel: sellViewModel)]
    
    super.init(nibName: LimitOrderContainerViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    for vc in self.pages {
      vc.delegate = self.delegate
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.setupPageController()
  }

  @IBAction func pagerButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      self.pageController.setViewControllers([pages.first!], direction: .forward, animated: true, completion: nil)
      self.animatePagerIndicator(index: 1, delay: 0.3)
    } else {
      self.pageController.setViewControllers([pages.last!], direction: .reverse, animated: true, completion: nil)
      self.animatePagerIndicator(index: 2, delay: 0.3)
    }
  }

  private func setupPageController() {
    self.pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    self.pageController.dataSource = self
    self.pageController.delegate = self
    self.pageController.view.backgroundColor = .clear
    self.pageController.view.frame = CGRect(x: 0,
                                            y: 0,
                                            width: self.contentContainerView.frame.width,
                                            height: self.contentContainerView.frame.height
    )
    self.addChildViewController(self.pageController)
    self.contentContainerView.addSubview(self.pageController.view)
    let initialVC = self.pages.first!
    self.pageController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
    self.pageController.didMove(toParentViewController: self)
  }

  fileprivate func animatePagerIndicator(index: NSInteger, delay: Double = 0) {
    let value = self.view.frame.size.width / 4
    self.pagerIndicatorCenterXContraint.constant = index == 1 ? -value : value
    UIView.animate(withDuration: 0.3, delay: delay, animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  func coordinatorUpdateTokenBalance(_ balances: [String: Balance]) {
    for vc in self.pages {
      vc.coordinatorUpdateTokenBalance(balances)
    }
  }
  
  func coordinatorUpdateEstimateFee(_ fee: Double, discount: Double, feeBeforeDiscount: Double, transferFee: Double) {
    for vc in self.pages {
      vc.coordinatorUpdateEstimateFee(fee, discount: discount, feeBeforeDiscount: feeBeforeDiscount, transferFee: transferFee)
    }
  }
}

extension LimitOrderContainerViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard viewController.isKind(of: KNSellKNCViewController.self) else {
      return nil
    }
    return self.pages.first!
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard viewController.isKind(of: KNBuyKNCViewController.self) else {
      return nil
    }
    return self.pages.last!
  }
}

extension LimitOrderContainerViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {

  }

  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard let viewController = previousViewControllers.first, completed == true else { return }
    if viewController.isKind(of: KNSellKNCViewController.self) {
      self.animatePagerIndicator(index: 1)
    } else if viewController.isKind(of: KNBuyKNCViewController.self) {
      self.animatePagerIndicator(index: 2)
    }
  }
}
