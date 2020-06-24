// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNBaseViewController: UIViewController {

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did present: \(self.className)")
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NSLog("Did dismiss: \(self.className)")
  }
}

class KNTabBarController: UITabBarController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    tabBar.tintColor = UIColor.Kyber.tabbarActive
    KNAppTracker.updateShouldOpenLimitOrderAfterSignedIn(false)
  }
}

class KNNavigationController: UINavigationController {
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}

extension KNBaseViewController {
  func createOverlay(frame: CGRect,
                     contentText: NSAttributedString,
                     contentTopOffset: CGFloat,
                     pointsAndRadius: [(CGPoint, CGFloat)],
                     nextButtonTitle: String = "Next".toBeLocalised()
  ) -> UIView {
    let overlayView = UIView(frame: frame)
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    let path = CGMutablePath()
    pointsAndRadius.forEach { (point) in
      path.addArc(center: point.0,
                  radius: point.1,
                  startAngle: 0.0,
                  endAngle: 2.0 * .pi,
                  clockwise: false)
    }
    path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))
    let maskLayer = CAShapeLayer()
    maskLayer.backgroundColor = UIColor.black.cgColor
    maskLayer.path = path

    maskLayer.fillRule = kCAFillRuleEvenOdd
    overlayView.layer.mask = maskLayer
    overlayView.clipsToBounds = true

    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.attributedText = contentText
    label.numberOfLines = 0
    label.font = UIFont.Kyber.regular(with: 18)
    label.isUserInteractionEnabled = true

    let nextButton = UIButton()
    nextButton.translatesAutoresizingMaskIntoConstraints = false
    nextButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    nextButton.rounded(color: UIColor(red: 184, green: 186, blue: 190), width: 1)
    nextButton.setTitle(nextButtonTitle, for: .normal)
    nextButton.titleLabel?.font = UIFont.Kyber.bold(with: 14)
    nextButton.addTarget(self, action: #selector(quickTutorialNextAction), for: .touchUpInside)

    overlayView.addSubview(label)
    overlayView.addSubview(nextButton)

    let views: [String: Any] = [
      "label": label,
      "nextButton": nextButton,
    ]

    var allConstraints: [NSLayoutConstraint] = []

    let verticalContraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(contentTopOffset)-[label]-20-[nextButton(36)]", metrics: nil, views: views)
    allConstraints += verticalContraints

    let horizontalContraintsForLabel = NSLayoutConstraint.constraints(withVisualFormat: "H:|-36-[label]-36-|", metrics: nil, views: views)
    allConstraints += horizontalContraintsForLabel

    let horizontalContraintsForButton = NSLayoutConstraint.constraints(withVisualFormat: "H:|-36-[nextButton(107)]", metrics: nil, views: views)
    allConstraints += horizontalContraintsForButton

    NSLayoutConstraint.activate(allConstraints)

    overlayView.tag = 1000

    let tapGestureForContentLable = UITapGestureRecognizer(target: self, action: #selector(quickTutorialContentLabelTapped))
    label.gestureRecognizers = [tapGestureForContentLable]

    return overlayView
  }

  @objc func dismissTutorialOverlayer() {
    if let view = self.tabBarController?.view.viewWithTag(1000) {
      view.removeFromSuperview()
    }
  }

  @objc func quickTutorialNextAction() {}

  @objc func quickTutorialContentLabelTapped() {}
}
