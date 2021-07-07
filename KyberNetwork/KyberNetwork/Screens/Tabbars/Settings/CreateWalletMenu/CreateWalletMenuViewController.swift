//
//  CreateWalletMenuViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/15/21.
//

import UIKit

enum CreateWalletMenuViewControllerEvent {
  case createRealWallet
  case importWallet
  case createWatchWallet
  case close
}

protocol CreateWalletMenuViewControllerDelegate: class {
  func createWalletMenuViewController(_ controller: CreateWalletMenuViewController, run event: CreateWalletMenuViewControllerEvent)
}

class CreateWalletMenuViewController: UIViewController {
  @IBOutlet weak var createRealWalletButton: UIButton!
  @IBOutlet weak var importWalletButton: UIButton!
  @IBOutlet weak var addWatchWalletButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let isFull: Bool
  weak var delegate: CreateWalletMenuViewControllerDelegate?

  init(isFull: Bool) {
    self.isFull = isFull
    super.init(nibName: CreateWalletMenuViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.setupUI()
  }

  fileprivate func setupUI() {
    self.createRealWalletButton.rounded(radius: 16)
    self.importWalletButton.rounded(radius: 16)
    self.addWatchWalletButton.rounded(radius: 16)
    self.addWatchWalletButton.isHidden = !isFull
  }

  @IBAction func createRealWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.createWalletMenuViewController(self, run: .createRealWallet)
    }
  }

  @IBAction func importWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.createWalletMenuViewController(self, run: .importWallet)
    }
  }
  
  @IBAction func createWatchWalletButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      self.delegate?.createWalletMenuViewController(self, run: .createWatchWallet)
    }
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true) {
      self.delegate?.createWalletMenuViewController(self, run: .close)
    }
  }
}

extension CreateWalletMenuViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    let space = self.isFull ? 0 : 56
    return CGFloat(296 - space)
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
