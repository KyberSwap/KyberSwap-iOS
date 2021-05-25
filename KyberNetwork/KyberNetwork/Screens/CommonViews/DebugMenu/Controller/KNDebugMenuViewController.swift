// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class KNDebugMenuViewController: KNBaseViewController {

  @IBOutlet weak var environmentSegmentedControl: UISegmentedControl!
  @IBOutlet weak var environmentEndpointLabel: UILabel!
  @IBOutlet weak var envNetworkAddressLabel: UILabel!
  @IBOutlet weak var envReserveAddressLabel: UILabel!

  fileprivate let environment = KNEnvironment.default

  fileprivate var newEnvironment: KNEnvironment = KNEnvironment.default

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupEnvironment()
  }

  fileprivate func setupEnvironment() {
    self.environmentSegmentedControl.rounded(color: .clear, width: 0, radius: 5.0)
    self.environmentSegmentedControl.selectedSegmentIndex = {
      if self.environment == .production { return 0 }
      if self.environment == .ropsten { return 1 }
      if self.environment == .kovan { return 2 }
      return 3 // staging
    }()
    self.updateEnvironmentData()
  }

  @IBAction func backPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func applyPressed(_ sender: Any) {
    if self.newEnvironment == self.environment {
      self.dismiss(animated: true, completion: nil)
      return
    }
    let alertController = UIAlertController(title: "", message: "Applying changes environment could restart the app", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { _ in
      KNAppTracker.updateExternalEnvironment(self.newEnvironment)
      self.handleEnviromentChangedIfNeeded()
      if self.newEnvironment != self.environment {
        exit(0)
      } else {
        self.dismiss(animated: true, completion: nil)
      }
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func environmentSegmentedControl(_ sender: UISegmentedControl) {
    self.newEnvironment = {
      if sender.selectedSegmentIndex == 0 { return .production }
      if sender.selectedSegmentIndex == 1 { return .ropsten }
      if sender.selectedSegmentIndex == 2 { return .kovan }
      return .staging
    }()
    self.updateEnvironmentData()
  }

  fileprivate func updateEnvironmentData() {
//    self.environmentEndpointLabel.text = self.newEnvironment.knCustomRPC?.customRPC.endpoint
//    self.envNetworkAddressLabel.text = "Network Address: \(self.newEnvironment.knCustomRPC?.networkAddress ?? "")"
  }

  private func handleEnviromentChangedIfNeeded() {
    if self.newEnvironment == self.environment { return }
    // update list wallets
    let newRealm: Realm = {
      let config = RealmConfiguration.globalConfiguration(for: KNGeneralProvider.shared.customRPC.chainID)
      return try! Realm(configuration: config)
    }()
    let newWallets = KNWalletStorage.shared.wallets.map({ return $0.copy(withNewName: $0.name) })
    newRealm.beginWrite()
    newRealm.delete(newRealm.objects(KNWalletObject.self))
    newRealm.add(newWallets, update: .modified)
    try! newRealm.commitWrite()
  }
}
