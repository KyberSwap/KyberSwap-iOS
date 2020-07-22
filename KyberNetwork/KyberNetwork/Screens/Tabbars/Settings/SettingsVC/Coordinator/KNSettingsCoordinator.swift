// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI

protocol KNSettingsCoordinatorDelegate: class {
  func settingsCoordinatorUserDidSelectNewWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidSelectExit()
  func settingsCoordinatorUserDidRemoveWallet(_ wallet: Wallet)
  func settingsCoordinatorUserDidUpdateWalletObjects()
  func settingsCoordinatorUserDidSelectAddWallet()
}

class KNSettingsCoordinator: NSObject, Coordinator {

  var coordinators: [Coordinator] = []
  let navigationController: UINavigationController
  private(set) var session: KNSession
  fileprivate(set) var balances: [String: Balance] = [:]
  var selectedWallet: KNWalletObject?

  weak var delegate: KNSettingsCoordinatorDelegate?

  lazy var rootViewController: KNSettingsTabViewController = {
    let controller = KNSettingsTabViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var listWalletsCoordinator: KNListWalletsCoordinator = {
    return KNListWalletsCoordinator(
      navigationController: self.navigationController,
      session: self.session,
      delegate: self
    )
  }()

  lazy var contactVC: KNListContactViewController = {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()

  lazy var passcodeCoordinator: KNPasscodeCoordinator = {
    let coordinator = KNPasscodeCoordinator(
      navigationController: self.navigationController,
      type: .setPasscode(cancellable: true)
    )
    coordinator.delegate = self
    return coordinator
  }()

  fileprivate var sendTokenCoordinator: KNSendTokenViewCoordinator?
  fileprivate var manageAlertCoordinator: KNManageAlertCoordinator?

  init(
    navigationController: UINavigationController = UINavigationController(),
    session: KNSession
    ) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
    self.session = session
  }

  func start() {
    self.navigationController.viewControllers = [self.rootViewController]
  }

  func stop() {
    self.navigationController.popToRootViewController(animated: false)
  }

  func appCoordinatorDidUpdateNewSession(_ session: KNSession, resetRoot: Bool = false) {
    self.session = session
    if resetRoot {
      self.navigationController.popToRootViewController(animated: true)
    }
    self.listWalletsCoordinator.updateNewSession(self.session)
  }

  func appCoordinatorTokenBalancesDidUpdate(balances: [String: Balance]) {
    balances.forEach { self.balances[$0.key] = $0.value }
    self.sendTokenCoordinator?.coordinatorTokenBalancesDidUpdate(balances: balances)
  }

  func appCoordinatorUSDRateUpdate() {
    self.sendTokenCoordinator?.coordinatorDidUpdateTrackerRate()
  }

  func appCoordinatorTokenObjectListDidUpdate(_ tokenObjects: [TokenObject]) {
    self.sendTokenCoordinator?.coordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  func appCoordinatorUpdateTransaction(_ tx: KNTransaction?, txID: String) -> Bool {
    return self.sendTokenCoordinator?.coordinatorDidUpdateTransaction(tx, txID: txID) ?? false
  }
}

extension KNSettingsCoordinator: KNSettingsTabViewControllerDelegate {
  func settingsTabViewController(_ controller: KNSettingsTabViewController, run event: KNSettingsTabViewEvent) {
    switch event {
    case .manageWallet:
      self.settingsViewControllerWalletsButtonPressed()
    case .manageAlerts:
      if let _ = IEOUserStorage.shared.user {
        self.manageAlertCoordinator = KNManageAlertCoordinator(navigationController: self.navigationController)
        self.manageAlertCoordinator?.start()
      } else {
        self.navigationController.showWarningTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
          time: 1.5
        )
      }
    case .alertMethods:
      if let _ = IEOUserStorage.shared.user {
        let alertMethodsVC = KNNotificationMethodsViewController()
        alertMethodsVC.loadViewIfNeeded()
        self.navigationController.pushViewController(alertMethodsVC, animated: true)
      } else {
        self.navigationController.showWarningTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: NSLocalizedString("You must sign in to use Price Alert feature", comment: ""),
          time: 1.5
        )
      }
    case .contact:
      self.navigationController.pushViewController(self.contactVC, animated: true)
    case .support:
      self.openMailSupport()
    case .about:
      self.openCommunityURL("https://medium.com/kyberswap/get-started-on-kyberswap-ios-app-942ee1dffdc4")
    case .changePIN:
      self.passcodeCoordinator = KNPasscodeCoordinator(
        navigationController: self.navigationController,
        type: .authenticate(isUpdating: true)
      )
      self.passcodeCoordinator.delegate = self
      self.passcodeCoordinator.start()
    case .community:
      let url = "https://kyber.network/community"
      self.openCommunityURL(url)
    case .shareWithFriends:
      self.openShareWithFriends()
    case .telegram:
      self.openCommunityURL("https://t.me/KyberSwapOfficial")
    case .github:
      self.openCommunityURL("https://github.com/KyberNetwork/KyberSwap-iOS")
    case .twitter:
      self.openCommunityURL("https://twitter.com/KyberSwap/")
    case .facebook:
      self.openCommunityURL("https://www.facebook.com/kybernetwork")
    case .medium:
      self.openCommunityURL("https://medium.com/@kyberswap")
    case .reddit:
      self.openCommunityURL("https://www.reddit.com/r/kybernetwork")
    case .linkedIn:
      self.openCommunityURL("https://www.linkedin.com/company/kybernetwork")
    case .reportBugs:
      self.navigationController.openSafari(with: "https://goo.gl/forms/ZarhiV7MPE0mqr712")
    case .rateOurApp:
      self.navigationController.openSafari(with: "https://apps.apple.com/us/app/id1521778973")
    case .liveChat:
      Freshchat.sharedInstance().showConversations(self.navigationController)
    }
  }

  fileprivate func openCommunityURL(_ url: String) {
    self.navigationController.openSafari(with: url)
  }

  fileprivate func openShareWithFriends() {
    let text = NSLocalizedString(
      "share.with.friends.text",
      value: "I just found an awesome wallet app. Check out here https://apps.apple.com/us/app/id1521778973",
      comment: ""
    )
    let activitiy = UIActivityViewController(activityItems: [text], applicationActivities: nil)
    activitiy.title = NSLocalizedString("share.with.friends", value: "Share with friends", comment: "")
    activitiy.popoverPresentationController?.sourceView = self.rootViewController.shareWithFriendsButton
    self.navigationController.present(activitiy, animated: true, completion: nil)
  }

  func settingsViewControllerDidClickExit() {
    self.delegate?.settingsCoordinatorUserDidSelectExit()
  }

  func settingsViewControllerWalletsButtonPressed() {
    self.listWalletsCoordinator.start()
  }

  func settingsViewControllerPasscodeDidChange(_ isOn: Bool) {
    if isOn {
      self.passcodeCoordinator.start()
    } else {
      KNPasscodeUtil.shared.deletePasscode()
    }
  }

  func openMailSupport() {
    if MFMailComposeViewController.canSendMail() {
      let emailVC = MFMailComposeViewController()
      emailVC.mailComposeDelegate = self
      emailVC.setToRecipients(["support@kyberswap.com"])
      self.navigationController.present(emailVC, animated: true, completion: nil)
    } else {
      let message = NSLocalizedString(
        "please.send.your.request.to.support",
        value: "Please send your request to support@kyberswap.com",
        comment: ""
      )
      self.navigationController.showWarningTopBannerMessage(with: "", message: message, time: 1.5)
    }
  }

  func settingsViewControllerOpenDebug() {
    let debugVC = KNDebugMenuViewController()
    self.navigationController.present(debugVC, animated: true, completion: nil)
  }

  func settingsViewControllerBackUpButtonPressed(wallet: KNWalletObject) {
    let alertController = KNPrettyAlertController(
      title: NSLocalizedString("export.at.your.own.risk", value: "Export at your own risk!", comment: ""),
      message: "⚠️NEVER share Keystore/Private Key/Mnemonic with anyone (including KyberSwap). These data grant access to all your funds and they may get stolen".toBeLocalised(),
      secondButtonTitle: NSLocalizedString("continue", value: "Continue", comment: ""),
      firstButtonTitle: NSLocalizedString("cancel", value: "Cancel", comment: ""),
      secondButtonAction: {
        self.selectedWallet = wallet
        self.showAuthPasscode()
      }, firstButtonAction: {
      }
    )
    self.navigationController.present(alertController, animated: true, completion: nil)
  }

  fileprivate func showActionSheetBackupPhrase(wallet: KNWalletObject) {
    guard let wallet = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == wallet.address.lowercased() }) else { return }
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      let alertController = UIAlertController(
        title: NSLocalizedString("export.at.your.own.risk", value: "Export at your own risk!", comment: ""),
        message: nil,
        preferredStyle: .actionSheet
      )
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("backup.keystore", value: "Backup Keystore", comment: ""),
        style: .default,
        handler: { _ in
          self.backupKeystore(wallet: wallet)
        }
      ))
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("backup.private.key", value: "Backup Private Key", comment: ""),
        style: .default,
        handler: { _ in
          self.backupPrivateKey(wallet: wallet)
        }
      ))
      if case .real(let account) = wallet.type, case .success = self.session.keystore.exportMnemonics(account: account) {
        alertController.addAction(UIAlertAction(
          title: NSLocalizedString("backup.mnemonic", value: "Backup Mnemonic", comment: ""),
          style: .default,
          handler: { _ in
            self.backupMnemonic(wallet: wallet)
          }
        ))
      }
      alertController.addAction(UIAlertAction(
        title: NSLocalizedString("cancel", value: "Cancel", comment: ""),
        style: .cancel,
        handler: nil)
      )
      self.navigationController.hideLoading()
      self.navigationController.topViewController?.present(alertController, animated: true, completion: nil)
    }
  }

  fileprivate func showAuthPasscode() {
    self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: self.navigationController, type: .verifyPasscode)
    self.passcodeCoordinator.delegate = self
    self.passcodeCoordinator.start()
  }

  fileprivate func backupKeystore(wallet: Wallet) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_show_back_up_keystore", customAttributes: nil)
    let createPassword = KNCreatePasswordViewController(wallet: wallet, delegate: self)
    createPassword.modalPresentationStyle = .overCurrentContext
    createPassword.modalTransitionStyle = .crossDissolve
    self.navigationController.topViewController?.present(createPassword, animated: true, completion: nil)
  }

  fileprivate func backupPrivateKey(wallet: Wallet) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_show_back_up_private_key", customAttributes: nil)
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      if case .real(let account) = wallet.type {
        let result = self.session.keystore.exportPrivateKey(account: account)
        self.navigationController.hideLoading()
        switch result {
        case .success(let data):
          self.openShowBackUpView(data: data.hexString, wallet: wallet)
        case .failure(let error):
          self.navigationController.topViewController?.displayError(error: error)
        }
      } else {
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func backupMnemonic(wallet: Wallet) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_show_back_up_mnemonic", customAttributes: nil)
    self.navigationController.displayLoading()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      if case .real(let account) = wallet.type {
        let result = self.session.keystore.exportMnemonics(account: account)
        self.navigationController.hideLoading()
        switch result {
        case .success(let data):
          self.openShowBackUpView(data: data, wallet: wallet)
        case .failure(let error):
          self.navigationController.topViewController?.displayError(error: error)
        }
      } else {
        self.navigationController.hideLoading()
      }
    }
  }

  fileprivate func openShowBackUpView(data: String, wallet: Wallet) {
    let showBackUpVC = KNShowBackUpDataViewController(
      wallet: wallet.address.description,
      backupData: data
    )
    showBackUpVC.loadViewIfNeeded()
    self.navigationController.pushViewController(showBackUpVC, animated: true)
  }

  fileprivate func copyAddress(wallet: Wallet) {
    KNCrashlyticsUtil.logCustomEvent(withName: "setting_show_back_up_copy_address", customAttributes: nil)
    UIPasteboard.general.string = wallet.address.description
  }

  fileprivate func exportDataString(_ value: String, wallet: Wallet) {
    let fileName = "kyberswap_backup_\(wallet.address.description)_\(DateFormatterUtil.shared.backupDateFormatter.string(from: Date())).json"
    let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
    do {
      try value.data(using: .utf8)!.write(to: url)
    } catch { return }

    let activityViewController = UIActivityViewController(
      activityItems: [url],
      applicationActivities: nil
    )
    activityViewController.completionWithItemsHandler = { _, result, _, error in
      do { try FileManager.default.removeItem(at: url)
      } catch { }
    }
    activityViewController.popoverPresentationController?.sourceView = navigationController.view
    activityViewController.popoverPresentationController?.sourceRect = navigationController.view.centerRect
    self.navigationController.topViewController?.present(activityViewController, animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNCreatePasswordViewControllerDelegate {
  func createPasswordUserDidFinish(_ password: String, wallet: Wallet) {
    if case .real(let account) = wallet.type {
      if let currentPassword = self.session.keystore.getPassword(for: account) {
        self.navigationController.topViewController?.displayLoading(text: "\(NSLocalizedString("preparing.data", value: "Preparing data", comment: ""))...", animated: true)
        self.session.keystore.export(account: account, password: currentPassword, newPassword: password, completion: { [weak self] result in
          self?.navigationController.topViewController?.hideLoading()
          switch result {
          case .success(let value):
            self?.exportDataString(value, wallet: wallet)
          case .failure(let error):
            self?.navigationController.topViewController?.displayError(error: error)
          }
        })
      }
    }
  }

  func createPasswordDidCancel(sender: KNCreatePasswordViewController) {
    sender.dismiss(animated: true, completion: nil)
  }
}

extension KNSettingsCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    switch event {
    case .back:
      self.navigationController.popViewController(animated: true)
    case .send(let address):
      self.openSendToken(address: address)
    case .select(let contact):
      self.openNewContact(address: contact.address, ens: nil)
    }
  }

  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel = KNNewContactViewModel(address: address, ens: ens)
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }

  fileprivate func openSendToken(address: String) {
    if self.session.transactionStorage.kyberPendingTransactions.isEmpty {
      let from: TokenObject = {
        guard let destToken = KNWalletPromoInfoStorage.shared.getDestinationToken(from: self.session.wallet.address.description), let token = self.session.tokenStorage.tokens.first(where: { return $0.symbol == destToken }) else {
          return self.session.tokenStorage.ethToken
        }
        return token
      }()
      self.sendTokenCoordinator = KNSendTokenViewCoordinator(
        navigationController: self.navigationController,
        session: self.session,
        balances: self.balances,
        from: from
      )
      self.sendTokenCoordinator?.start()
      self.sendTokenCoordinator?.coordinatorOpenSendView(to: address)
    } else {
      let message = NSLocalizedString("Please wait for other transactions to be mined before making a transfer", comment: "")
      self.navigationController.showWarningTopBannerMessage(
        with: "",
        message: message,
        time: 2.0
      )
    }
  }
}

extension KNSettingsCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    switch event {
    case .dismiss: self.navigationController.popViewController(animated: true)
    case .send(let address):
      self.openSendToken(address: address)
    }
  }
}

extension KNSettingsCoordinator: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCreatePasscode() {
    self.passcodeCoordinator.stop {
      self.navigationController.showSuccessTopBannerMessage(
        with: NSLocalizedString("success", value: "Success", comment: ""),
        message: NSLocalizedString("your.pin.has.been.update.successfully", value: "Your PIN has been updated successfully!", comment: ""),
        time: 1.5
      )
    }
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    if case .verifyPasscode = self.passcodeCoordinator.type {
      self.passcodeCoordinator.stop {
        guard let wallet = self.selectedWallet else { return }
        self.showActionSheetBackupPhrase(wallet: wallet)
        self.selectedWallet = nil
      }
    } else {
      self.passcodeCoordinator.stop {
        self.passcodeCoordinator = KNPasscodeCoordinator(
          navigationController: self.navigationController,
          type: .setPasscode(cancellable: true)
        )
        self.passcodeCoordinator.delegate = self
        self.passcodeCoordinator.start()
      }
    }
  }

  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator.stop {
      self.selectedWallet = nil
    }
  }
}

extension KNSettingsCoordinator: KNListWalletsCoordinatorDelegate {
  func listWalletsCoordinatorDidClickBack() {
    self.listWalletsCoordinator.stop()
  }

  func listWalletsCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.listWalletsCoordinator.stop()
    if wallet == self.session.wallet { return }
    self.delegate?.settingsCoordinatorUserDidSelectNewWallet(wallet)
  }

  func listWalletsCoordinatorDidSelectRemoveWallet(_ wallet: Wallet) {
    self.delegate?.settingsCoordinatorUserDidRemoveWallet(wallet)
  }

  func listWalletsCoordinatorDidUpdateWalletObjects() {
    self.delegate?.settingsCoordinatorUserDidUpdateWalletObjects()
  }

  func listWalletsCoordinatorDidSelectAddWallet() {
    self.delegate?.settingsCoordinatorUserDidSelectAddWallet()
  }

  func listWalletsCoordinatorShouldBackUpWallet(_ wallet: KNWalletObject) {
    self.settingsViewControllerBackUpButtonPressed(wallet: wallet)
  }
}

extension KNSettingsCoordinator: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    if case .sent = result {
      KNCrashlyticsUtil.logCustomEvent(withName: "setting_support_email_sent", customAttributes: nil)
    }
    controller.dismiss(animated: true, completion: nil)
  }
}
