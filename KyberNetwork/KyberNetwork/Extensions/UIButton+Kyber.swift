// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIButton {
  func addTextSpacing(value: CGFloat = 0) {
    let text = self.titleLabel?.text ?? ""
    if text.isEmpty { return }
    let attributedString = NSMutableAttributedString(string: text)
    attributedString.addAttribute(NSAttributedStringKey.kern, value: value, range: NSRange(location: 0, length: text.count))
    self.setAttributedTitle(attributedString, for: .normal)
  }

  func setImage(
    with url: URL,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    if let cachedImg = UIImage.imageCache.object(forKey: url as AnyObject) as? UIImage {
      self.setImage(cachedImg.resizeImage(to: size), for: .normal)
      self.layoutIfNeeded()
      return
    }
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    self.layoutIfNeeded()
    URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
      guard let `self` = self else { return }
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          UIImage.imageCache.setObject(image, forKey: url as AnyObject)
          self.setImage(image.resizeImage(to: size), for: .normal)
          self.layoutIfNeeded()
        }
      }
    }.resume()
  }

  func setImage(
    with string: String,
    placeHolder: UIImage?,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    self.setImage(placeHolder?.resizeImage(to: size), for: state)
    guard let url = URL(string: string) else { return }
    self.setImage(
      with: url,
      placeHolder: placeHolder,
      size: size,
      state: state
    )
  }

  func setTokenImage(
    token: TokenObject,
    size: CGSize? = nil,
    state: UIControlState = .normal
    ) {
    if !token.isSupported {
      self.setImage(UIImage(named: "default_token"), for: .normal)
      self.layoutIfNeeded()
      return
    }
    let icon = token.icon.isEmpty ? token.symbol.lowercased() : token.icon
    let image = UIImage(named: icon.lowercased())
    let placeHolderImg = image ?? UIImage(named: "default_token")
    self.setImage(
      with: token.iconURL,
      placeHolder: placeHolderImg,
      size: size,
      state: state
    )
  }

  func centerVertically(padding: CGFloat = 6.0) {
    guard
      let imageViewSize = self.imageView?.frame.size,
      let titleLabelSize = self.titleLabel?.frame.size else {
        return
    }

    let totalHeight = imageViewSize.height + titleLabelSize.height + padding

    self.imageEdgeInsets = UIEdgeInsets(
      top: -(totalHeight - imageViewSize.height),
      left: 0.0,
      bottom: 0.0,
      right: -titleLabelSize.width
    )

    self.titleEdgeInsets = UIEdgeInsets(
      top: 0.0,
      left: -imageViewSize.width,
      bottom: -(totalHeight - titleLabelSize.height),
      right: 0.0
    )

    self.contentEdgeInsets = UIEdgeInsets(
      top: (self.frame.height - totalHeight) / 2.0,
      left: 0.0,
      bottom: titleLabelSize.height,
      right: 0.0
    )
  }

  func applyGradient() {
    self.applyGradient(with: UIColor.Kyber.buttonColors)
  }
}
