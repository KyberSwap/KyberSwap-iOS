// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIImageView {
  func setImage(with url: URL, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false) {
    if let cachedImg = UIImage.imageCache.object(forKey: url as AnyObject) as? UIImage {
      self.image = applyNoir ? cachedImg.resizeImage(to: size)?.noir : cachedImg.resizeImage(to: size)
      self.layoutIfNeeded()
      return
    }
    self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
    self.layoutIfNeeded()
    URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
      guard let `self` = self else { return }
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          UIImage.imageCache.setObject(image, forKey: url as AnyObject)
          self.image = applyNoir ? image.resizeImage(to: size)?.noir : image.resizeImage(to: size)
          self.layoutIfNeeded()
        }
      }
    }.resume()
  }

  func setImage(with urlString: String, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false) {
    guard let url = URL(string: urlString) else {
      self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
      self.layoutIfNeeded()
      return
    }
    self.setImage(with: url, placeholder: placeholder, size: size, applyNoir: applyNoir)
  }

  func setTokenImage(
    token: TokenObject,
    size: CGSize? = nil
    ) {
    if !token.isSupported {
      self.image = UIImage(named: "default_token")
      self.layoutIfNeeded()
      return
    }
    let icon = token.icon.isEmpty ? token.symbol.lowercased() : token.icon
    let image = UIImage(named: icon.lowercased())
    let placeHolderImg = image ?? UIImage(named: "default_token")!
    self.setImage(
      with: token.iconURL,
      placeholder: placeHolderImg,
      size: size
    )
  }

  func setTokenImage(with alert: KNAlertObject, size: CGSize? = nil, applyNoir: Bool = false) {
     let url = "https://raw.githubusercontent.com/KyberNetwork/KyberNetwork.github.io/master/DesignAssets/tokens/iOS/\(alert.token.lowercased()).png"
     let assetImage = UIImage(named: alert.token.lowercased())
     let defaultImage = UIImage(named: "default_token")!
     let placeholder = assetImage ?? defaultImage
     setImage(with: url, placeholder: placeholder, size: size, applyNoir: applyNoir)
  }
}
