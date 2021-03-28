// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSplashScreenCoordinator: Coordinator {

  let splashWindow: UIWindow = UIWindow()

  var coordinators: [Coordinator] = []

  lazy var splashVC: KNSplashScreenViewController = {
    return KNSplashScreenViewController()
  }()

  init() {
    self.splashWindow.windowLevel = UIWindowLevelStatusBar + 2.0
  }

  func start() {
    self.splashWindow.rootViewController = self.splashVC
//    self.splashWindow.isHidden = false
//    self.splashVC.rotateSplashLogo(duration: 1.6) {
//      self.splashWindow.isHidden = true
//    }
  }

  func stop() {
    self.splashWindow.isHidden = true
  }
}
