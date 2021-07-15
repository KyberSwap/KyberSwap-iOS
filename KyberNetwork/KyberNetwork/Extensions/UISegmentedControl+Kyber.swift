//
//  UISegmentedControl+Kyber.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 7/1/21.
//

import Foundation
import UIKit

import UIKit

class SegmentedControl: UISegmentedControl {
  func removeBorder(){
    let background = UIImage.getSegRect(color: UIColor.clear.cgColor, andSize: self.bounds.size) // segment background color and size
    self.setBackgroundImage(background, for: .normal, barMetrics: .default)
    self.setBackgroundImage(background, for: .selected, barMetrics: .default)
    self.setBackgroundImage(background, for: .highlighted, barMetrics: .default)
    
    let deviderLine = UIImage.getSegRect(color: UIColor.clear.cgColor, andSize: CGSize(width: 1.0, height: 5))
    self.setDividerImage(deviderLine, forLeftSegmentState: .selected, rightSegmentState: .normal, barMetrics: .default)
    self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!, NSAttributedString.Key.font: UIFont.Kyber.regular(with: 16)], for: .normal)
    self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!, NSAttributedString.Key.font: UIFont.Kyber.regular(with: 16)], for: .selected)
  }
  
  func highlightSelectedSegment() {
    removeBorder()
    let lineWidth: CGFloat = self.frame.size.width / CGFloat(self.numberOfSegments)
    let lineHeight: CGFloat = 2.0
    let lineXPosition = CGFloat(selectedSegmentIndex * Int(lineWidth))
    let lineYPosition = self.bounds.size.height - 6.0
    let underlineFrame = CGRect(x: lineXPosition, y: lineYPosition, width: lineWidth, height: lineHeight)
    let underLine = UIView(frame: underlineFrame)
    underLine.backgroundColor = UIColor(named: "buttonBackgroundColor")
    underLine.tag = 1
    self.addSubview(underLine)
  }
  
  func underlinePosition() {
    guard let underLine = self.viewWithTag(1) else { return }
    let xPosition = (self.frame.width / CGFloat(self.numberOfSegments)) * CGFloat(selectedSegmentIndex)
    UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
      underLine.frame.origin.x = xPosition
    })
  }
}

extension UIImage {
  class func getSegRect(color: CGColor, andSize size: CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(color)
    let rectangle = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
    context?.fill(rectangle)
    
    let rectangleImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return rectangleImage!
  }
}
