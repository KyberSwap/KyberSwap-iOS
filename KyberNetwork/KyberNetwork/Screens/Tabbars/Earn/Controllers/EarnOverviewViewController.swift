//
//  EarnOverviewViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/5/21.
//

import UIKit

protocol EarnOverviewViewControllerDelegate: class {
  func earnOverviewViewControllerDidSelectExplore(_ controller: EarnOverviewViewController)
}

class EarnOverviewViewController: KNBaseViewController {
  @IBOutlet weak var exploreButton: UIButton!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  
  weak var delegate: EarnOverviewViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?
  
  let depositViewController: OverviewDepositViewController
  var wallet: Wallet?
  
  init(_ controller: OverviewDepositViewController) {
    self.depositViewController = controller
    super.init(nibName: EarnOverviewViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.exploreButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
    self.exploreButton.rounded(radius: self.exploreButton.frame.size.height / 2)
    self.addChildViewController(self.depositViewController)
    self.contentView.addSubview(self.depositViewController.view)
    self.depositViewController.didMove(toParentViewController: self)
    self.depositViewController.view.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
    self.depositViewController.view.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
    self.depositViewController.view.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
    self.depositViewController.view.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
    self.depositViewController.view.translatesAutoresizingMaskIntoConstraints = false
    if let notNil = self.wallet {
      self.updateUIWalletSelectButton(notNil)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIPendingTxIndicatorView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.exploreButton.removeSublayer(at: 0)
    self.exploreButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    self.pendingTxIndicatorView.isHidden = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }

  @IBAction func exploreButtonTapped(_ sender: UIButton) {
    self.delegate?.earnOverviewViewControllerDidSelectExplore(self)
  }
  
  @IBAction func historyButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectHistory(self)
  }
  
  @IBAction func walletListButtonTapped(_ sender: UIButton) {
    self.navigationDelegate?.viewControllerDidSelectWallets(self)
  }
  
  fileprivate func updateUIWalletSelectButton(_ wallet: Wallet) {
    self.walletListButton.setTitle(wallet.address.description, for: .normal)
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.wallet = wallet
    if self.isViewLoaded {
      self.updateUIWalletSelectButton(wallet)
      self.depositViewController.coordinatorUpdateNewSession(wallet: wallet)
    }
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
}
