//
//  KrystalActionSheetCell.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 6/8/21.
//

import UIKit

class KrystalActionSheetCell: ActionCell {
  @IBOutlet weak var checkMarkImage: UIImageView!
  @IBOutlet weak var selectedBackground: UIView!
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

class KrystalActionSheetHeader: UICollectionReusableView {
  
  lazy var label: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.backgroundColor = .clear
    label.font = UIFont.boldSystemFont(ofSize: 20)
    label.textColor = .white
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor(named: "popupBackgroundColor")
    addSubview(label)
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["label": label]))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["label": label]))
    
    layer.cornerRadius = 20
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

class KrystalActionSheetController: ActionController<KrystalActionSheetCell, ActionData, KrystalActionSheetHeader, String, UICollectionReusableView, Void> {
  public override init(nibName nibNameOrNil: String? = nil, bundle nibBundleOrNil: Bundle? = nil) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    
    settings.behavior.hideOnScrollDown = false
    settings.animation.scale = nil
    settings.animation.present.duration = 0.6
    settings.animation.dismiss.duration = 0.6
    settings.animation.dismiss.offset = 30
    settings.animation.dismiss.options = .curveLinear
    
    headerSpec = .cellClass(height: { _ -> CGFloat in return 90 })
    
    cellSpec = .nibFile(nibName: "KrystalActionSheetCell", bundle: Bundle(for: KrystalActionSheetCell.self), height: { _  in 50 })
    
    onConfigureCellForAction = { cell, action, indexPath in
      cell.setup(action.data?.title, detail: action.data?.subtitle, image: action.data?.image)
      cell.alpha = action.enabled ? 1.0 : 0.5
      if action.style == .destructive {
        cell.actionTitleLabel?.textColor = .red
      }
      cell.checkMarkImage.isHidden = action.style != .selected
      cell.selectedBackground.isHidden = action.style != .selected
    }
    
    onConfigureHeader = { header, title in
        header.label.text = title
    }
    
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
