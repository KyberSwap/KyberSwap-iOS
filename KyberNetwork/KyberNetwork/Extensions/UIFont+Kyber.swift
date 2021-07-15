// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIFont {
  enum Kyber {
    static func black(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Karla-Black", size: size)! }
      return UIFont(name: "Karla-BlackItalic", size: size)!
    }

    static func bold(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Karla-Bold", size: size)! }
      return UIFont(name: "Karla-BoldItalic", size: size)!
    }

    static func light(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Karla-Light", size: size)! }
      return UIFont(name: "Karla-LightItalic", size: size)!
    }

    static func italic(with size: CGFloat) -> UIFont {
      return UIFont(name: "Karla-Italic", size: size)!
    }

    static func medium(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Karla-Medium", size: size)! }
      return UIFont(name: "Karla-MediumItalic", size: size)!
    }

    static func regular(with size: CGFloat) -> UIFont {
      return UIFont(name: "Karla-Regular", size: size)!
    }

    static func thin(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Roboto-Thin", size: size)! }
      return UIFont(name: "Roboto-ThinItalic", size: size)!
    }

    static func latoBold(with size: CGFloat) -> UIFont {
      return UIFont(name: "Lato-Bold", size: size)!
    }

    static func latoRegular(with size: CGFloat) -> UIFont {
      return UIFont(name: "Lato-Regular", size: size)!
    }
  }
}
