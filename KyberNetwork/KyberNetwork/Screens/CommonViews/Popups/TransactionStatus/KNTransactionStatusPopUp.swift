// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNTransactionStatusPopUpEvent {
  case dismiss
  case swap
  case transfer
  case tryAgain
}

protocol KNTransactionStatusPopUpDelegate: class {
  func transactionStatusPopUp(_ controller: KNTransactionStatusPopUp, action: KNTransactionStatusPopUpEvent)
}

class KNTransactionStatusPopUp: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var titleIconImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!

  @IBOutlet weak var detailsButton: UIButton!

  @IBOutlet weak var rateValueLabel: UILabel!

  // Broadcast
  @IBOutlet weak var loadingImageView: UIImageView!
  // 32 if broadcasting, 104 if done/failed
  @IBOutlet weak var bottomPaddingBroadcastConstraint: NSLayoutConstraint!

  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var transferCenterXConstraint: NSLayoutConstraint!
  @IBOutlet weak var swapButton: UIButton!
  @IBOutlet var actionButtonHeightConstraints: [NSLayoutConstraint]!

  weak var delegate: KNTransactionStatusPopUpDelegate?

  var detailsAttributes: [NSAttributedStringKey: Any] {
    return [
      NSAttributedStringKey.foregroundColor: UIColor(red: 20, green: 25, blue: 39),
      NSAttributedStringKey.font: self.transaction.state == .pending ? UIFont.Kyber.medium(with: 12) : UIFont.Kyber.medium(with: 14),
    ]
  }

  fileprivate(set) var transaction: KNTransaction

  init(transaction: KNTransaction) {
    self.transaction = transaction
    super.init(nibName: KNTransactionStatusPopUp.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    let name = Notification.Name(rawValue: "viewDidBecomeActive")
    NotificationCenter.default.removeObserver(self, name: name, object: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.commontSetup()
    let name = Notification.Name(rawValue: "viewDidBecomeActive")
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.viewDidBecomeActive(_:)),
      name: name,
      object: nil
    )
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateView(with: self.transaction)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if !self.loadingImageView.isHidden {
      self.loadingImageView.stopAnimating()
    }
  }

  fileprivate func commontSetup() {
    self.containerView.rounded(radius: 5.0)
    self.transferButton.setTitle(NSLocalizedString("transfer", comment: ""), for: .normal)
    self.transferButton.rounded(radius: self.transferButton.frame.height / 2.0)
    self.transferButton.applyGradient()

    self.swapButton.setTitle(NSLocalizedString("swap", comment: ""), for: .normal)
    self.swapButton.rounded(radius: self.transferButton.frame.height / 2.0)
    self.swapButton.applyGradient()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.userDidTapOutsideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  fileprivate func updateViewTransactionDidChange() {
    let (details, rate) = self.transaction.getNewTxDetails()
    self.detailsButton.setAttributedTitle(
      NSAttributedString(string: details, attributes: self.detailsAttributes),
      for: .normal
    )
    self.rateValueLabel.text = rate
    if self.transaction.state == .pending {
      self.titleIconImageView.image = UIImage(named: "tx_broadcasted_icon")
      self.titleLabel.text = "Broadcasted!".toBeLocalised()
      self.subTitleLabel.text = "Your transaction has been broadcasted!".toBeLocalised()
      self.detailsButton.semanticContentAttribute = .forceRightToLeft

      self.loadingImageView.isHidden = false
      self.loadingImageView.startRotating()

      self.transferButton.isHidden = true
      self.swapButton.isHidden = true
      self.rateValueLabel.isHidden = true

      self.actionButtonHeightConstraints.forEach({ $0.constant = 0.0 })
      self.bottomPaddingBroadcastConstraint.constant = 32.0
      self.view.layoutSubviews()
    } else if self.transaction.state == .completed {
      self.titleIconImageView.image = UIImage(named: "tx_success_icon")
      self.titleLabel.text = "Done!".toBeLocalised()
      self.subTitleLabel.text = {
        if transaction.type == .cancel {
          return "Your transaction has been cancelled successfully".toBeLocalised()
        } else if transaction.type == .speedup {
          return "Your transaction has been speeded up successfully".toBeLocalised()
        } else if self.transaction.isTransfer {
          return "Transferred successfully".toBeLocalised()
        }
        return "Swapped successfully".toBeLocalised()
      }()
      self.detailsButton.semanticContentAttribute = .forceRightToLeft

      self.loadingImageView.stopRotating()
      self.loadingImageView.isHidden = true

      self.transferButton.isHidden = false
      self.transferButton.setTitle(NSLocalizedString("transfer", comment: ""), for: .normal)
      self.swapButton.isHidden = false
      self.transferCenterXConstraint.constant = -66

      self.rateValueLabel.isHidden = rate == nil ? true : false

      self.actionButtonHeightConstraints.forEach({ $0.constant = 45.0 })
      self.bottomPaddingBroadcastConstraint.constant = 120
      self.view.layoutSubviews()
    } else if self.transaction.state == .error || self.transaction.state == .failed {
      self.titleIconImageView.image = UIImage(named: "tx_failed_icon")
      self.titleLabel.text = "Failed!".toBeLocalised()
      if self.transaction.state == .error {
        var errorTitle = ""
        switch transaction.type {
        case .cancel:
          errorTitle = "Your cancel transaction might be lost".toBeLocalised()
        case .speedup:
          errorTitle = "Your speedup transaction might be lost".toBeLocalised()
        default:
          errorTitle = "Your transaction might be lost, dropped or replaced. Please check Etherscan for more information".toBeLocalised()
        }
        self.subTitleLabel.text = errorTitle
      } else {
        self.subTitleLabel.text = "Transaction error".toBeLocalised()
      }
      self.detailsButton.semanticContentAttribute = .forceRightToLeft

      self.loadingImageView.stopRotating()
      self.loadingImageView.isHidden = true

      self.swapButton.isHidden = true
      if transaction.type == .normal {
        self.transferButton.isHidden = false
        self.transferButton.setTitle(NSLocalizedString("try.again", comment: ""), for: .normal)
        self.transferCenterXConstraint.constant = 0
        self.actionButtonHeightConstraints.forEach({ $0.constant = 45.0 })
        self.bottomPaddingBroadcastConstraint.constant = 120
      } else {
        self.transferButton.isHidden = true
        self.bottomPaddingBroadcastConstraint.constant = 20
      }
      self.rateValueLabel.isHidden = true
      self.view.layoutSubviews()
    }
  }

  func updateView(with transaction: KNTransaction?) {
    if let trans = transaction {
      self.transaction = trans
    } else {
      self.transaction.internalState = TransactionState.error.rawValue
    }
    self.updateViewTransactionDidChange()
  }

  @objc func userDidTapOutsideToDismiss(_ sender: UITapGestureRecognizer) {
    let loc = sender.location(in: self.view)
    if loc.x < self.containerView.frame.minX || loc.x > self.containerView.frame.maxX
      || loc.y < self.containerView.frame.minY || loc.y > self.containerView.frame.maxY {
      self.dismiss(animated: true) {
        self.delegate?.transactionStatusPopUp(self, action: .dismiss)
      }
    }
  }

  @objc func viewDidBecomeActive(_ sender: Any?) {
    if !self.loadingImageView.isHidden {
      self.loadingImageView.startRotating()
    }
  }

  @IBAction func openTransactionDetailsPressed(_ sender: Any) {
    let urlString = KNEnvironment.default.etherScanIOURLString + "tx/\(transaction.id)"
    self.openSafari(with: urlString)
  }

  @IBAction func transferButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      if self.transaction.state == .completed {
        self.delegate?.transactionStatusPopUp(self, action: .transfer)
      } else {
        self.delegate?.transactionStatusPopUp(self, action: .tryAgain)
      }
    }
  }

  @IBAction func swapButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.transactionStatusPopUp(self, action: .swap)
    }
  }
}
