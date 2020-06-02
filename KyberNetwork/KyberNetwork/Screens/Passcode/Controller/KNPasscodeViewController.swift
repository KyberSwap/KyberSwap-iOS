// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import LocalAuthentication

enum KNPasscodeViewEvent {
  case cancel
  case enterPasscode(passcode: String)
  case createNewPasscode(passcode: String)
  case evaluatedPolicyWithBio
}

protocol KNPasscodeViewControllerDelegate: class {
  func passcodeViewController(_ controller: KNPasscodeViewController, run event: KNPasscodeViewEvent)
}

enum KNPasscodeViewType {
  // view to set new passcode
  case setPasscode(cancellable: Bool)
  // view to authenticate
  case authenticate(isUpdating: Bool)
  case verifyPasscode
}

class KNPasscodeViewController: KNBaseViewController {
  fileprivate let viewType: KNPasscodeViewType
  fileprivate weak var delegate: KNPasscodeViewControllerDelegate?

  fileprivate var currentPasscode = ""
  fileprivate var firstPasscode: String?

  fileprivate var timer: Timer?

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var errorLabel: UILabel!

  @IBOutlet weak var passcodeContainerView: UIView!
  @IBOutlet var passcodeViews: [UIView]!

  @IBOutlet var digitButtons: [UIButton]!
  @IBOutlet weak var actionButton: UIButton!

  init(viewType: KNPasscodeViewType, delegate: KNPasscodeViewControllerDelegate?) {
    self.viewType = viewType
    self.delegate = delegate
    super.init(nibName: KNPasscodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUI()
    if case .authenticate = self.viewType {
      self.runTimerIfNeeded()
    }
    if case .verifyPasscode = self.viewType {
      self.runTimerIfNeeded()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  fileprivate func setupUI() {
    self.passcodeViews.forEach({ $0.rounded(radius: $0.frame.width / 2.0) })
    self.digitButtons.forEach({ $0.rounded(radius: $0.frame.width / 2.0) })
    self.actionButton.setTitle(self.actionButtonTitle, for: .normal)
    self.digitButtons.forEach({
      $0.setBackgroundColor(.white, forState: .normal)
      $0.setBackgroundColor(UIColor.Kyber.enygold, forState: .highlighted)
      $0.setTitleColor(UIColor.Kyber.enygold, for: .normal)
      $0.setTitleColor(.white, for: .highlighted)
    })
    self.updateUI()
  }

  fileprivate func updateUI() {
    self.titleLabel.text = self.titleText
    self.titleLabel.addLetterSpacing()
    self.errorLabel.text = self.errorText
    self.errorLabel.addLetterSpacing()
    self.passcodeViews.forEach({ $0.backgroundColor = $0.tag < self.currentPasscode.count ? UIColor.Kyber.enygold : UIColor.Kyber.passcodeInactive })
    self.actionButton.setTitle(self.actionButtonTitle, for: .normal)
    self.view.layoutIfNeeded()
  }

  func showBioAuthenticationIfNeeded() {
    if case .verifyPasscode = self.viewType { return }
    guard case .authenticate(let isUpdating) = self.viewType, !isUpdating else { return }
    if KNPasscodeUtil.shared.timeToAllowNewAttempt() > 0 {
      self.runTimerIfNeeded()
      return
    }
    var error: NSError?
    let context = LAContext()
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      return
    }
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("use.touchid/faceid.to.secure.your.account", value: "Use touchID/faceID to secure your account", comment: "")) { [weak self] (success, error) in
      guard let `self` = self else { return }
      DispatchQueue.main.async {
        if success {
          self.delegate?.passcodeViewController(self, run: .evaluatedPolicyWithBio)
        } else {
          guard let error = error else { return }
          guard let message = self.errorMessageForLAErrorCode(error.code) else {
            // User cancelled using bio
            return
          }
          let alert = UIAlertController(title: NSLocalizedString("try.again", value: "Try again", comment: ""), message: message, preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: NSLocalizedString("try.again", value: "Try again", comment: ""), style: .default, handler: { _ in
            self.showBioAuthenticationIfNeeded()
          }))
          alert.addAction(UIAlertAction(title: NSLocalizedString("enter.pin", value: "Enter PIN", comment: ""), style: .default, handler: nil))
          self.present(alert, animated: true, completion: nil)
        }
      }
    }
  }

  func runTimerIfNeeded() {
    self.timer?.invalidate()
    if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
      self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
        if KNPasscodeUtil.shared.timeToAllowNewAttempt() == 0 {
          KNPasscodeUtil.shared.deleteNumberAttempts()
          KNPasscodeUtil.shared.deleteCurrentMaxAttemptTime()
          self.timer?.invalidate()
        }
        self.updateUI()
      })
    }
  }

  func resetUI() {
    self.currentPasscode = ""
    self.firstPasscode = nil
    self.updateUI()
  }

  func userDidTypeWrongPasscode() {
    // shake passcode view
    self.currentPasscode = ""
    self.updateUI()

    let keypath = "position"
    let animation = CABasicAnimation(keyPath: keypath)
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: self.passcodeContainerView.center.x - 10, y: self.passcodeContainerView.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: self.passcodeContainerView.center.x + 10, y: self.passcodeContainerView.center.y))
    self.passcodeContainerView.layer.add(animation, forKey: keypath)

    self.runTimerIfNeeded()
  }

  @IBAction func digitButtonPressed(_ sender: UIButton) {
    if KNPasscodeUtil.shared.numberAttemptsLeft() == 0 {
      if case .authenticate = self.viewType { return }
      if case .verifyPasscode = self.viewType { return }
    }
    self.currentPasscode = "\(self.currentPasscode)\(sender.tag)"
    if self.currentPasscode.count == 6 {
      self.userDidEnterPasscode()
    }
    self.updateUI()
  }

  @IBAction func actionButtonPressed(_ sender: UIButton) {
    if !self.currentPasscode.isEmpty {
      self.currentPasscode = String(self.currentPasscode.prefix(self.currentPasscode.count - 1))
      self.updateUI()
    } else {
      if case .setPasscode(let cancellable) = self.viewType {
        if self.firstPasscode != nil {
          self.resetUI()
          return
        }
        if cancellable {
          self.delegate?.passcodeViewController(self, run: .cancel)
        }
      } else if case .authenticate(let isUpdating) = self.viewType, isUpdating {
        self.delegate?.passcodeViewController(self, run: .cancel)
      } else if case .verifyPasscode = self.viewType {
        self.delegate?.passcodeViewController(self, run: .cancel)
      }
    }
  }

  fileprivate func userDidEnterPasscode() {
    if case .authenticate = self.viewType {
      self.delegate?.passcodeViewController(self, run: .enterPasscode(passcode: self.currentPasscode))
    } else if case .verifyPasscode = self.viewType {
      self.delegate?.passcodeViewController(self, run: .enterPasscode(passcode: self.currentPasscode))
    } else {
      guard let firstPass = self.firstPasscode else {
        self.firstPasscode = self.currentPasscode
        self.currentPasscode = ""
        return
      }
      if firstPass == self.currentPasscode {
        self.delegate?.passcodeViewController(self, run: .createNewPasscode(passcode: self.currentPasscode))
      } else {
        self.firstPasscode = nil
        self.currentPasscode = ""
        self.showWarningTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("your.PIN.and.confirm.PIN.do.not.match", value: "Your PIN and confirm PIN do not match", comment: ""),
          time: 1.5
        )
      }
    }
  }
}

extension KNPasscodeViewController {
  fileprivate var titleText: String {
    switch self.viewType {
    case .authenticate(let isUpdating):
      return isUpdating ? NSLocalizedString("enter.your.old.pin", value: "Enter your current PIN", comment: "") : NSLocalizedString("verify.your.access", value: "Verify your access", comment: "")
    case .setPasscode:
      if self.firstPasscode != nil {
        return NSLocalizedString("repeat.pin", value: "Repeat PIN", comment: "")
      }
      return NSLocalizedString("set.a.new.pin", value: "Set a new PIN", comment: "")
    case .verifyPasscode:
      return "verify.your.access".toBeLocalised()
    }

  }

  fileprivate var errorText: String {
    if case .setPasscode = self.viewType {
      if self.firstPasscode == nil {
        return NSLocalizedString(
          "your.pin.is.used.to.access.your.wallets",
          value: "Your PIN is used to access your wallets",
          comment: ""
        )
      }
      return NSLocalizedString(
        "remember.this.code.to.access.your.wallets",
        value: "Remember this code to access your wallets",
        comment: "")
    }
    if KNPasscodeUtil.shared.currentNumberAttempts() == 0 { return "" }
    if KNPasscodeUtil.shared.isExceedNumberAttempt() {
      let text = NSLocalizedString(
        "too.many.attempts.please.try.in.second",
        value: "Too many attempts. Please try in %d second(s)",
        comment: ""
      )
      return String.localizedStringWithFormat(text, KNPasscodeUtil.shared.timeToAllowNewAttempt())
    }
    let numberAttemptsLeft = KNPasscodeUtil.shared.numberAttemptsLeft()
    let text = NSLocalizedString("you.have.attempt", value: "You have %d attempt(s) left", comment: "")
    return String.localizedStringWithFormat(text, numberAttemptsLeft)
  }

  fileprivate var actionButtonTitle: String {
    if !self.currentPasscode.isEmpty { return NSLocalizedString("delete", value: "Delete", comment: "") }
    if case .setPasscode(let cancellable) = self.viewType {
      if cancellable || self.firstPasscode != nil { return NSLocalizedString("cancel", value: "Cancel", comment: "") }
    }
    if case .authenticate(let isUpdating) = self.viewType, isUpdating { return NSLocalizedString("cancel", value: "Cancel", comment: "") }
    if case .verifyPasscode = self.viewType { return NSLocalizedString("cancel", value: "Cancel", comment: "") }
    return ""
  }

  func errorMessageForLAErrorCode(_ errorCode: Int ) -> String? {
    if #available(iOS 11.0, *) {
      switch errorCode {
      case LAError.biometryLockout.rawValue:
        return NSLocalizedString(
          "too.many.failed.attempts",
          value: "Too many failed attempts. Please try to use PIN",
          comment: ""
        )
      case LAError.biometryNotAvailable.rawValue:
        return NSLocalizedString(
          "touchid.faceid.is.not.available",
          value: "TouchID/FaceID is not available on the device",
          comment: ""
        )
      default:
        break
      }
    }
    switch errorCode {
    case LAError.authenticationFailed.rawValue:
      return NSLocalizedString(
        "invalid.authentication",
        value: "Invalid authentication.",
        comment: ""
      )
    case LAError.passcodeNotSet.rawValue:
      return NSLocalizedString(
        "pin.is.not.set.on.the.device",
        value: "PIN is not set on the device",
        comment: ""
      )
    case LAError.biometryLockout.rawValue:
      return NSLocalizedString(
        "too.many.failed.attempts",
        value: "Too many failed attempts. Please try to use PIN",
        comment: ""
      )
    case LAError.biometryNotAvailable.rawValue:
      return NSLocalizedString(
        "touchid.faceid.is.not.available",
        value: "TouchID/FaceID is not available on the device",
        comment: ""
      )
    case LAError.appCancel.rawValue, LAError.userCancel.rawValue, LAError.userFallback.rawValue:
      return nil
    default:
      return NSLocalizedString(
        "something.went.wrong.try.to.use.pin",
        value: "Something went wrong. Try to use PIN",
        comment: ""
      )
    }
  }
}
