// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIFont {
  enum Kyber {
    static func black(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Black", size: size)! }
      return UIFont(name: "Roboto-BlackItalic", size: size)!
    }

    static func bold(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Bold", size: size)! }
      return UIFont(name: "Roboto-BoldItalic", size: size)!
    }

    static func light(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Light", size: size)! }
      return UIFont(name: "Roboto-LightItalic", size: size)!
    }

    static func italic(with size: CGFloat) -> UIFont {
      return UIFont(name: "Roboto-Italic", size: size)!
    }

    static func medium(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Medium", size: size)! }
      return UIFont(name: "Roboto-MediumItalic", size: size)!
    }

    static func regular(with size: CGFloat) -> UIFont {
      return UIFont(name: "Roboto-Regular", size: size)!
    }

    static func thin(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Thin", size: size)! }
      return UIFont(name: "Roboto-ThinItalic", size: size)!
    }
  }
}
