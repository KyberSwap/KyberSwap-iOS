// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import FSPagerView
import MessageUI

protocol KNMigrationTutorialViewControllerDelegate: class {
  func kMigrationTutorialViewControllerDidClickKyberSupportContact(_ controller: KNMigrationTutorialViewController)
}

class KNMigrationTutorialViewModel {
  var currentStep: Int = 1
  var currentSubStepIndex: Int = 0

  var step1DataSource: [String: NSMutableAttributedString] {
    let step1AttributeString = NSMutableAttributedString(
      string: "Go to Settings → Manage Wallet.",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )

    let step2AttributeString = NSMutableAttributedString(
      string: "Choose the wallet you want to back up → Select Edit ",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )

    let step3AttributeString = NSMutableAttributedString(
      string: "Select Show Backup Phrase → Choose your desired back up method (Private key, Keystore, Mnemonic)",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )

    let step4AttributeString = NSMutableAttributedString(
      string: "Save your backup safely\nNEVER share your backup with anyone",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )
    step4AttributeString.string.enumerateSubstrings(in: step4AttributeString.string.startIndex..<step4AttributeString.string.endIndex, options: .byWords) { (substring, substringRange, _, _) in
      if substring == "NEVER" {
        step4AttributeString.addAttribute(.font, value: UIFont.Kyber.medium(with: 14), range: NSRange(substringRange, in: step4AttributeString.string))
      }
    }

    return [
      "tutorial_1_1": step1AttributeString,
      "tutorial_1_2": step2AttributeString,
      "tutorial_1_3": step3AttributeString,
      "tutorial_1_4": step4AttributeString,
    ]
  }

  var step1HeaderTitle: String {
    return "In your old KyberSwap app"
  }

  var step1ToolBarTitle: String {
    return "Backup your wallets"
  }

  var step2DataSource: [String: NSMutableAttributedString] {
    let step1AttributeString = NSMutableAttributedString(
      string: "Select Import Wallet",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )

    let step2AttributeString = NSMutableAttributedString(
      string: "Choose your desired import method (Keystore, Private Key, Seeds)",
      attributes: [
        .font: UIFont.Kyber.regular(with: 14),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )
    return [
      "tutorial_2_1": step1AttributeString,
      "tutorial_2_2": step2AttributeString,
    ]
  }

  var step2HeaderTitle: String {
    return "Within this New KyberSwap app"
  }

  var step2ToolBarTitle: String {
    return "Use your backup to import wallet "
  }

  var step3HeaderTitle: String {
    return "Within this New KyberSwap app"
  }

  var step3ToolBarTitle: String {
    return "Check your Balance"
  }

  var optionalContentString: NSAttributedString {
    let stringList = [
      "Make a simple transfer/swap transaction to make sure everything is working as expected.",
      "You can either keep or delete the old iOS app.",
    ]
    let indentation: CGFloat = 20
    let lineSpacing: CGFloat = 2
    let paragraphSpacing: CGFloat = 12
    let bullet: String = "\u{2022}"
    let bulletAttributes: [NSAttributedStringKey: Any] = [NSAttributedStringKey.foregroundColor: UIColor.Kyber.orange, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20)]
    let textAttributes: [NSAttributedStringKey: Any] = [
      .font: UIFont.Kyber.regular(with: 14),
      .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
      .kern: 0.0,
    ]
    let paragraphStyle = NSMutableParagraphStyle()
    let nonOptions = [NSTextTab.OptionKey: Any]()
    paragraphStyle.tabStops = [
      NSTextTab(
        textAlignment: .left,
        location: indentation,
        options: nonOptions
      ),
    ]
    paragraphStyle.defaultTabInterval = indentation
    paragraphStyle.lineSpacing = lineSpacing
    paragraphStyle.paragraphSpacing = paragraphSpacing
    paragraphStyle.headIndent = indentation
    let bulletList = NSMutableAttributedString()
    for string in stringList {
      let formattedString = "\(bullet)\t\(string)\n"
      let attributedString = NSMutableAttributedString(string: formattedString)

      attributedString.addAttributes(
        [NSAttributedStringKey.paragraphStyle: paragraphStyle],
        range: NSRange(location: 0, length: attributedString.length)
      )

      attributedString.addAttributes(
        textAttributes,
        range: NSRange(location: 0, length: attributedString.length)
      )

      let string: NSString = NSString(string: formattedString)
      let rangeForBullet: NSRange = string.range(of: bullet)
      attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
      bulletList.append(attributedString)
    }
    return bulletList
  }

  var bottomContactText: NSAttributedString {
    let attributedString = NSMutableAttributedString(
      string: "Send email to support@kyberswap.com if you have any issues.",
      attributes: [
        .font: UIFont.Kyber.regular(with: 12),
        .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
        .kern: 0.0,
      ]
    )
    attributedString.string.enumerateSubstrings(in: attributedString.string.startIndex..<attributedString.string.endIndex, options: .byWords) { (substring, substringRange, _, _) in
        if substring == "support@kyberswap.com" {
          attributedString.addAttribute(.foregroundColor, value: UIColor.Kyber.orange, range: NSRange(substringRange, in: attributedString.string))
        }
    }

    attributedString.addAttribute(.foregroundColor, value: UIColor.Kyber.orange, range: NSRange(location: 14, length: 21))
    return attributedString
  }
}

class KNMigrationTutorialViewController: KNBaseViewController {
  @IBOutlet weak var headerTitleLabel: UILabel!
  @IBOutlet weak var stepIndicatorLabel: UILabel!
  @IBOutlet weak var pageNameLabel: UILabel!
  @IBOutlet weak var pagerContainerView: FSPagerView! {
    didSet {
      self.pagerContainerView.register(UINib(nibName: "KNTutorialPagerCell", bundle: .main), forCellWithReuseIdentifier: "tutorialCell")
      self.pagerContainerView.register(UINib(nibName: "KNTutorialPagerWithAccessoryCell", bundle: .main), forCellWithReuseIdentifier: "tutorialCellWithAccessory")
    }
  }
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var nextBottomButton: UIButton!

  @IBOutlet weak var finalStepContainerView: UIView!
  @IBOutlet weak var finalStepHeaderLabel: UILabel!
  @IBOutlet weak var finalStepContent1Label: UILabel!
  @IBOutlet weak var finalStepOptionalLabel: UILabel!
  @IBOutlet weak var finalStepContent2Label: UILabel!
  @IBOutlet weak var finalStepBottomLabel: UILabel!
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var pageControl: FSPageControl!

  weak var delegate: KNMigrationTutorialViewControllerDelegate?

  var viewModel: KNMigrationTutorialViewModel

  init(viewModel: KNMigrationTutorialViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNMigrationTutorialViewController.className, bundle: nil)
    self.modalPresentationStyle = .overFullScreen
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.stepIndicatorLabel.rounded(radius: self.stepIndicatorLabel.frame.size.height / 2)
    self.finalStepContent2Label.attributedText = self.viewModel.optionalContentString
    self.finalStepBottomLabel.attributedText = self.viewModel.bottomContactText
    self.view.sendSubview(toBack: self.finalStepContainerView)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.pageControl.numberOfPages = self.viewModel.step1DataSource.keys.count
    self.pageControl.setFillColor(UIColor.Kyber.orange, for: .selected)
    self.pageControl.setFillColor(UIColor.Kyber.lightPeriwinkle, for: .normal)
    self.pageControl.itemSpacing = 9.6
    self.pagerContainerView.alpha = 0
    self.finalStepContainerView.alpha = 0
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.pagerContainerView.itemSize = self.pagerContainerView.frame.size.applying(CGAffineTransform(scaleX: 0.85, y: 1.0))
    self.pagerContainerView.interitemSpacing = 15
    UIView.animate(withDuration: 0.1, animations: {
      self.pagerContainerView.alpha = 1
    }, completion: { (_) in
      self.finalStepContainerView.alpha = 1
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  fileprivate func moveBackMainStep() {
    if self.viewModel.currentStep == 3 {
      self.view.bringSubview(toFront: self.pagerContainerView)
    }
    self.viewModel.currentStep -= 1
    self.refreshUI()
    self.pagerContainerView.reloadData()
  }

  @IBAction func previousStepButtonTapped(_ sender: UIButton) {
    if (self.viewModel.currentStep == 1 && self.viewModel.currentSubStepIndex != 0) || (self.viewModel.currentStep == 2 && self.viewModel.currentSubStepIndex != 0) {
      self.viewModel.currentSubStepIndex -= 1
      self.pagerContainerView.scrollToItem(at: self.viewModel.currentSubStepIndex, animated: true)
      self.pageControl.currentPage = self.viewModel.currentSubStepIndex
    } else {
      self.moveBackMainStep()
      if self.viewModel.currentStep == 1 {
        self.viewModel.currentSubStepIndex = 3
      } else if self.viewModel.currentStep == 2 {
        self.viewModel.currentSubStepIndex = 1
      }
      self.pageControl.currentPage = self.viewModel.currentSubStepIndex
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self.pagerContainerView.scrollToItem(at: self.viewModel.currentSubStepIndex, animated: false)
      }
    }
    self.nextButton.isEnabled = true
    if self.viewModel.currentStep == 1 && self.viewModel.currentSubStepIndex == 0 {
      self.previousButton.isEnabled = false
    }
  }

  fileprivate func moveToNextMainStep() {
    self.viewModel.currentStep += 1
    if self.viewModel.currentStep == 3 {
      self.nextButton.isEnabled = false
      self.view.bringSubview(toFront: self.finalStepContainerView)
    }
    self.refreshUI()
    if self.viewModel.currentStep < 3 {
      self.pagerContainerView.scrollToItem(at: 0, animated: false)
      self.pageControl.currentPage = 0
      self.pagerContainerView.reloadData()
    }
  }

  @IBAction func nextStepButtonTapped(_ sender: UIButton) {
    if (self.viewModel.currentStep == 1 && self.viewModel.currentSubStepIndex <= 2) || (self.viewModel.currentStep == 2 && self.viewModel.currentSubStepIndex == 0) {
      self.viewModel.currentSubStepIndex += 1
      self.pagerContainerView.scrollToItem(at: self.viewModel.currentSubStepIndex, animated: true)
      self.pageControl.currentPage = self.viewModel.currentSubStepIndex
    } else {
      self.viewModel.currentSubStepIndex = 0
      self.moveToNextMainStep()
      self.pageControl.currentPage = self.viewModel.currentSubStepIndex
    }
    self.previousButton.isEnabled = true
  }

  @IBAction func nextButtonTapped(_ sender: UIButton) {
    if self.viewModel.currentStep == 3 {
      self.dismiss(animated: true, completion: nil)
    } else {
      self.nextStepButtonTapped(sender)
    }
  }

  @IBAction func contactLabelTapped(_ sender: UITapGestureRecognizer) {
    self.delegate?.kMigrationTutorialViewControllerDidClickKyberSupportContact(self)
  }

  fileprivate func refreshUI() {
    switch self.viewModel.currentStep {
    case 1:
      self.stepIndicatorLabel.text = "1"
      self.pageNameLabel.text = self.viewModel.step1ToolBarTitle
      self.nextBottomButton.setTitle("next".toBeLocalised().uppercased(), for: .normal)
      self.pageControl.numberOfPages = self.viewModel.step1DataSource.keys.count
    case 2:
      self.stepIndicatorLabel.text = "2"
      self.pageNameLabel.text = self.viewModel.step2ToolBarTitle
      self.nextBottomButton.setTitle("next".toBeLocalised().uppercased(), for: .normal)
      self.pageControl.numberOfPages = self.viewModel.step2DataSource.keys.count
    case 3:
      self.stepIndicatorLabel.text = "3"
      self.pageNameLabel.text = self.viewModel.step3ToolBarTitle
      self.nextBottomButton.setTitle("done".toBeLocalised().uppercased(), for: .normal)
    default:
      break
    }
  }
}

extension KNMigrationTutorialViewController: FSPagerViewDataSource {
  public func numberOfItems(in pagerView: FSPagerView) -> Int {
    switch self.viewModel.currentStep {
    case 1:
      return self.viewModel.step1DataSource.keys.count
    case 2:
      return self.viewModel.step2DataSource.keys.count
    default:
      return 0
    }
  }

  public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    if self.viewModel.currentStep == 1 && index == 3 {
      let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "tutorialCellWithAccessory", at: index) as! KNTutorialPagerCell
      let imageName = "tutorial_1_4"
      cell.contentImageView.image = UIImage(named: imageName)
      if let text = self.viewModel.step1DataSource[imageName] {
        cell.contentLabel.attributedText = text
      } else {
        cell.contentLabel.attributedText = NSAttributedString()
      }
      return cell
    }
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "tutorialCell", at: index) as! KNTutorialPagerCell
    let step = self.viewModel.currentStep
    let imageName = "tutorial_\(step)_\(index + 1)"
    cell.contentImageView.image = UIImage(named: imageName)
    switch self.viewModel.currentStep {
    case 1:
      cell.headerTitleLabel.text = self.viewModel.step1HeaderTitle
      if let text = self.viewModel.step1DataSource[imageName] {
        cell.contentLabel.attributedText = text
      } else {
        cell.contentLabel.attributedText = NSAttributedString()
      }
    case 2:
      cell.headerTitleLabel.text = self.viewModel.step2HeaderTitle
      if let text = self.viewModel.step2DataSource[imageName] {
        cell.contentLabel.attributedText = text
      } else {
        cell.contentLabel.attributedText = NSAttributedString()
      }
    default:
      break
    }
    return cell
  }
}

extension KNMigrationTutorialViewController: FSPagerViewDelegate {
  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    self.pageControl.currentPage = targetIndex
    self.viewModel.currentSubStepIndex = targetIndex
    if self.viewModel.currentStep == 1 && self.viewModel.currentSubStepIndex == 0 {
      self.previousButton.isEnabled = false
    } else {
      self.previousButton.isEnabled = true
    }
  }
}
