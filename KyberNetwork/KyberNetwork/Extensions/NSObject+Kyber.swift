// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwiftMessages

extension NSObject {
  func showWarningTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5, tapHandler: (() -> Void)? = nil) {
    self.showTopBannerView(with: title, message: message, theme: .warning, time: time, tapHandler: tapHandler)
  }

  func showSuccessTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5, tapHandler: (() -> Void)? = nil) {
    self.showTopBannerView(with: title, message: message, theme: .success, time: time, tapHandler: tapHandler)
  }

  func showErrorTopBannerMessage(with title: String = "", message: String = "", time: TimeInterval = 1.5, tapHandler: (() -> Void)? = nil) {
    self.showTopBannerView(with: title, message: message, theme: .error, time: time, tapHandler: tapHandler)
  }

  func showTopBannerView(with title: String = "", message: String = "", icon: UIImage? = nil, theme: Theme = .success, layout: MessageView.Layout = .cardView, time: TimeInterval = 1.5, tapHandler: (() -> Void)? = nil) {
    let view: MessageView = {
      let view = MessageView.viewFromNib(layout: layout)
      view.configureTheme(backgroundColor: UIColor.white, foregroundColor: UIColor.black.withAlphaComponent(0.6), iconImage: nil, iconText: nil)
      view.configureDropShadow()
      view.button?.isHidden = true
      if let iconImage = icon {
        view.configureContent(title: title, body: message, iconImage: iconImage)
      } else {
        if theme == .success {
          let iconText = ""//["😁", "😄", "😆", "😉", "😎", "😍"].sm_random()!
          view.configureContent(title: title, body: message, iconText: iconText)
        } else {
          let iconText = ""//["🤔", "😳", "🙄", "😶", "😰", "😢", "😥"].sm_random()!
          view.configureContent(title: title, body: message, iconText: iconText)
        }
      }
      return view
    }()
    view.tapHandler = { _ in
      SwiftMessages.hide()
      tapHandler?()
    }
    let config: SwiftMessages.Config = {
      var config = SwiftMessages.Config()
      config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
      config.duration = time == -1 ? .forever : .seconds(seconds: time)
      config.dimMode = .gray(interactive: true)
      config.interactiveHide = true
      config.preferredStatusBarStyle = .lightContent
      return config
    }()
    SwiftMessages.show(config: config, view: view)
  }

  func showBottomBannerView(with title: String = "", message: String = "", icon: UIImage = UIImage(), time: TimeInterval = 1.5, tapHandler: (() -> Void)? = nil) {
    let view: MessageView = {
      let view: MessageView = try! SwiftMessages.viewFromNib()
      view.configureContent(title: title, body: message, iconImage: icon)
      view.button?.isHidden = true
      if title.isEmpty {
        view.titleLabel?.isHidden = true
      }
      view.bodyLabel?.font = UIFont.Kyber.regular(with: 14)
      view.configureTheme(backgroundColor: UIColor.white, foregroundColor: UIColor(red: 20, green: 25, blue: 39), iconImage: icon, iconText: nil)
      return view
    }()
    view.tapHandler = { _ in
      SwiftMessages.hide()
      tapHandler?()
    }

    let config: SwiftMessages.Config = {
      var config = SwiftMessages.defaultConfig
      config.presentationStyle = .bottom
      config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
      config.duration = time == -1 ? .forever : .seconds(seconds: time)
      config.dimMode = .gray(interactive: true)
      config.interactiveHide = true
      config.preferredStatusBarStyle = .lightContent
      return config
    }()
    SwiftMessages.show(config: config, view: view)
  }
}
