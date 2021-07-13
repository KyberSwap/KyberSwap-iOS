//
//  EarnOverviewViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/5/21.
//

import UIKit
import BigInt

protocol EarnOverviewViewControllerDelegate: class {
  func earnOverviewViewControllerDidSelectExplore(_ controller: EarnOverviewViewController)
}

class EarnOverviewViewController: KNBaseViewController {
  @IBOutlet weak var exploreButton: UIButton!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletListButton: UIButton!
  @IBOutlet weak var pendingTxIndicatorView: UIView!
  @IBOutlet weak var currentChainIcon: UIImageView!
  @IBOutlet weak var bscNotSupportView: UIView!
  
  weak var delegate: EarnOverviewViewControllerDelegate?
  weak var navigationDelegate: NavigationBarDelegate?
  
  let depositViewController: OverviewDepositViewController
  var wallet: Wallet?
  var firstTimeLoaded: Bool = false
  
  init(_ controller: OverviewDepositViewController) {
    self.depositViewController = controller
    super.init(nibName: EarnOverviewViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.exploreButton.rounded(radius: 16)
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
    if UserDefaults.standard.bool(forKey: "earn-tutorial" ) == false {
      let tutorial = EarnTutorialViewController()
      tutorial.modalPresentationStyle = .overFullScreen
      self.navigationController?.present(tutorial, animated: true, completion: nil)
      UserDefaults.standard.set(true, forKey: "earn-tutorial")
    }
    if self.depositViewController.viewModel.totalValueBigInt == BigInt(0) {
      if KNGeneralProvider.shared.isEthereum {
        if self.firstTimeLoaded == false {
          self.delegate?.earnOverviewViewControllerDidSelectExplore(self)
        }
      }
    }
    self.firstTimeLoaded = true
    self.updateUISwitchChain()
  }
  
  fileprivate func updateUIPendingTxIndicatorView() {
    guard self.isViewLoaded else {
      return
    }
    self.pendingTxIndicatorView.isHidden = EtherscanTransactionStorage.shared.getInternalHistoryTransaction().isEmpty
  }
  
  fileprivate func updateUISwitchChain() {
    guard self.isViewLoaded else {
      return
    }
    let icon = KNGeneralProvider.shared.isEthereum ? UIImage(named: "chain_eth_icon") : UIImage(named: "chain_bsc_icon")
    self.currentChainIcon.image = icon
    self.bscNotSupportView.isHidden = KNGeneralProvider.shared.isEthereum
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
  
  @IBAction func switchChainButtonTapped(_ sender: UIButton) {
    let popup = SwitchChainViewController()
    popup.completionHandler = {
      let secondPopup = SwitchChainWalletsListViewController()
      self.present(secondPopup, animated: true, completion: nil)
    }
    self.present(popup, animated: true, completion: nil)
  }
  
  fileprivate func updateUIWalletSelectButton(_ wallet: Wallet) {
    self.walletListButton.setTitle(wallet.address.description, for: .normal)
  }

  func coordinatorUpdateNewSession(wallet: Wallet) {
    self.wallet = wallet
    if self.isViewLoaded {
      self.updateUIWalletSelectButton(wallet)
      self.depositViewController.coordinatorUpdateNewSession(wallet: wallet)
      self.updateUIPendingTxIndicatorView()
      self.updateUIPendingTxIndicatorView()
    }
  }

  func coordinatorDidUpdatePendingTx() {
    self.updateUIPendingTxIndicatorView()
  }
  
  func coordinatorDidUpdateChain() {
    self.updateUISwitchChain()
  }
  
  func coordinatorDidUpdateHideBalanceStatus(_ status: Bool) {
    self.depositViewController.containerDidUpdateHideBalanceStatus(status)
  }

  func coordinatorDidUpdateDidUpdateTokenList() {
    self.depositViewController.coordinatorDidUpdateDidUpdateTokenList()
  }
}
