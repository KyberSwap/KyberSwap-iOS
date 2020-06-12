// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MessageUI

protocol KNTransferConsentViewControllerDelegate: class {
  // yes/no/undecide
  func transferConsentViewController(
    _ controller: KNTransferConsentViewController,
    answer: Bool?,
    isForceLogout: Bool,
    authInfo: JSONDictionary,
    userInfo: JSONDictionary
  )
}

class KNTransferConsentViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var descriptionTextLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var backButton: UIButton!

  let isForceLogout: Bool
  let authInfo: JSONDictionary
  let userInfo: JSONDictionary

  weak var delegate: KNTransferConsentViewControllerDelegate?

  init(isForceLogout: Bool, authInfo: JSONDictionary, userInfo: JSONDictionary) {
    self.isForceLogout = isForceLogout
    self.authInfo = authInfo
    self.userInfo = userInfo
    super.init(nibName: KNTransferConsentViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = "KyberSwap is moving to BVI".toBeLocalised()
    self.noButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0
    )
    self.noButton.setTitle("No".toBeLocalised(), for: .normal)
    self.yesButton.setTitle("Yes".toBeLocalised(), for: .normal)
    self.yesButton.rounded()
    self.yesButton.applyGradient()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.backButton.isHidden = true

    self.descriptionTextLabel.attributedText = {
      if Locale.current.kyberSupportedLang == "vi" {
        return self.createAttributedStringTransferConsentTextVi()
      }
      if Locale.current.kyberSupportedLang == "kr" {
        return self.createAttributedStringTransferConsentTextKr()
      }
      return self.createAttributedStringTransferConsentText()
    }()
    self.scrollView.delegate = self

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapDescriptionLabel(_:)))
    self.descriptionTextLabel.addGestureRecognizer(tapGesture)
    self.descriptionTextLabel.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.yesButton.removeSublayer(at: 0)
    self.yesButton.applyGradient()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  @IBAction func yesButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_yes_tapped", customAttributes: nil)
    self.delegate?.transferConsentViewController(
      self,
      answer: true,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }

  @IBAction func noButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_no_tapped", customAttributes: nil)
    let alert = UIAlertController(
      title: "Your profile will not be copied",
      message: "\nYou would have to create a new profile to use some services like Limit Order, Price Alerts, Notifications, etc. \n\nDo you want to continue?".toBeLocalised(),
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Go back".toBeLocalised(), style: .cancel, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_transfer_consent", customAttributes: ["action": "go_back_no"])
    }))
    alert.addAction(UIAlertAction(title: NSLocalizedString("confirm", value: "Confirm", comment: ""), style: .destructive, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_confirm_no_tapped", customAttributes: nil)
      self.delegate?.transferConsentViewController(
        self,
        answer: false,
        isForceLogout: self.isForceLogout,
        authInfo: self.authInfo,
        userInfo: self.userInfo
      )
    }))
    self.present(alert, animated: true, completion: nil)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_dismiss_popup", customAttributes: nil)
    self.delegate?.transferConsentViewController(
      self,
      answer: nil,
      isForceLogout: self.isForceLogout,
      authInfo: self.authInfo,
      userInfo: self.userInfo
    )
  }

  @objc func didTapDescriptionLabel(_ sender: UITapGestureRecognizer) {
    let rangeEmail = ((self.descriptionTextLabel.text ?? "") as NSString).range(of: "support@kyberswap.com")
    if sender.didTapAttributedTextInLabel(label: self.descriptionTextLabel, inRange: rangeEmail) {
      self.openMailSupport()
      return
    }
    let rangeLink = ((self.descriptionTextLabel.text ?? "") as NSString).range(of: "https://t.me/kyberswapofficial")
    if sender.didTapAttributedTextInLabel(label: self.descriptionTextLabel, inRange: rangeLink) {
      KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_open_telegram", customAttributes: nil)
      self.openSafari(with: "https://t.me/kyberswapofficial")
      return
    }
  }

  fileprivate func createAttributedStringTransferConsentText() -> NSMutableAttributedString {
    // swiftlint:disable line_length
    let attributedString = NSMutableAttributedString(string: "On Jan 24, 2020, KyberSwap.com and- related interfaces (the “Platform”) will no longer be operated by Kyber Network International Limited (“Kyber Network”) and will be operated by KYRD International Limited (“KYRD International”), a sister company incorporated and based in the British Virgin Islands (“BVI”). There are no other changes apart from the new operating entity of KyberSwap.com being changed to KYRD International.\n\nKYRD International is a company in BVI and as such, the country is not subject to an adequacy decision by the EU Commission on the processing of personal data. If you wish to continue using KyberSwap.com without providing personal data again, Kyber Network will transfer your current personal data to KYRD International upon your explicit consent. Please rest assured that KYRD International respects your privacy and is committed to protecting your personal data. For questions, please email support@kyberswap.com or reach out to us at https://t.me/kyberswapofficial \n\nKindly select:\n\n•  “Yes” if you wish to allow KyberSwap.com to copy your personal data to KYRD International; or\n\n•  “No” if you do not wish to copy your personal data to KYRD International. Note that if you click “No”, your personal data shall be erased in accordance with the retention periods specified in Kyber Network’s Privacy Policy. You will have to create a new profile on KyberSwap.com in order to, but not limited to, access Limit Orders, price alerts, personalized notifications and other benefits.", attributes: [
      .font: UIFont.Kyber.medium(with: 14),
      .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    ])
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 102, length: 35))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 180, length: 26))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 278, length: 22))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 428, length: 18))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 921, length: 21))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 965, length: 30))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 998, length: 14))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1014, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1018, length: 3))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1112, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1116, length: 2))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 3
    attributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )

    return attributedString
  }

  fileprivate func createAttributedStringTransferConsentTextVi() -> NSMutableAttributedString {
    // swiftlint:disable line_length
    let attributedString = NSMutableAttributedString(string: "Thông báo:\n\nVào ngày 24/01/2020, nền tảng KyberSwap.com sẽ không còn được vận hành bởi Kyber Network International Limited (sau đây gọi là “Kyber Network”) mà sẽ được vận hành bởi KYRD International Limited (sau đây gọi là “KYRD International”), một công ty con được thành lập và hoạt động tại British Virgin Islands (\"BVI\"). Ngoài việc thay đổi pháp nhân từ Kyber Network sang KYRD International, KyberSwap.com không còn thay đổi nào khác.\n\nKYRD International là một công ty tại BVI và quốc gia này không nằm trong số các quốc gia phải tuân thủ quy định về xử lý dữ liệu cá nhân của Ủy ban Châu Âu. Nếu bạn muốn tiếp tục sử dụng KyberSwap.com mà không phải cung cấp lại thông tin cá nhân, Kyber Network sẽ chuyển tất cả dữ liệu cá nhân của bạn cho KYRD International dựa trên sự chấp thuận của bạn. KYRD International tôn trọng và cam kết bảo vệ thông tin cá nhân của bạn. Nếu có bất kỳ thắc mắc, vui lòng liên hệ email support@kyberswap.com hoặc telegram https://t.me/kyberswapofficial\n\nVui lòng chọn:\n\n•  “Đồng ý” nếu bạn đồng ý để KyberSwap.com chuyển đổi dữ liệu của bạn cho KYRD International; hoặc\n\n•  “Không” nếu bạn không đồng ý để KyberSwap.com chuyển đổi dữ liệu của bạn cho KYRD International.\n\nLưu ý rằng nếu bạn chọn “Không”, thông tin cá nhân của bạn sẽ bị xóa theo các quy định về lưu trữ thông tin của Kyber Network. Bạn sẽ phải tạo một tài khoản mới trên KyberSwap.com để có thể sử dụng các tính năng Limit Order, Price alert, các thông báo cá nhân và các lợi ích khác.", attributes: [
      .font: UIFont.Kyber.medium(with: 14),
      .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    ])
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 87, length: 35))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 180, length: 26))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 294, length: 22))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 442, length: 18))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 921, length: 21))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 957, length: 30))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 989, length: 14))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1005, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1009, length: 6))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 1106, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 1110, length: 5))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 3
    attributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )

    return attributedString
  }

  fileprivate func createAttributedStringTransferConsentTextKr() -> NSMutableAttributedString {
    // swiftlint:disable line_length
    let attributedString = NSMutableAttributedString(string: "2020 년 1 월 24 일 부터 KyberSwap.com 및 관련 인터페이스 ( \"플랫폼\")는 더 이상 Kyber Network International Limited ( \"Kyber Network\") 소속이 아니며, 영국령 버진 아일랜드 (“BVI”)에 설립된 자매 회사 KYRD International Limited ( \"KYRD International\")에 의해 관리됩니다. KyberSwap.com의 새로운 상호  KYRD International로 변경되는 것 외에 다른 변경 사항은 없습니다. KYRD International은 BVI의 회사이므로 개인 정보 처리에 관한 EU위원회의 직정성 결정 규정 대상에 포함되지 않습니다.\n\n개인 데이터를 다시 제공하지 않고 KyberSwap.com을 계속 사용하려는 사용자를 위하여,  Kyber Network는 귀하의 동의에 따라 현재 개인 데이터를 KYRD International로 전송하려 합니다. KYRD International은 귀하의 개인 정보를 존중하며 귀하의 개인 정보를 보호하기 위해 최선을 다하고 있습니다. 질문이 있으시면 support@kyberswap.com으로 이메일을 보내거나 https://t.me/kyberswapofficial로 문의하십시오.\n\n선택하기:\n\n•  KyberSwap.com이 개인 데이터를 KYRD International에 전송하도록 허용하시려면\"Yes\";\n\n•  데이터 전송을 원하지 않을 경우에는\"No\"를 선택하시면 됩니다. \n\n\"No\"를 선택하시면 Kyber Network의 개인 정보 보호 정책에 따라 현재 모든 개인 데이터가 삭제됩니다. 데이터 삭제 후, KyberSwap.com에서 리밋오더, 가격 알림, 커스텀 알림 및 기타 혜택을 사용하기 위해 새 프로필을 만들어야 합니다.", attributes: [
      .font: UIFont.Kyber.medium(with: 14),
      .foregroundColor: UIColor(red: 20, green: 25, blue: 39),
    ])
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 59, length: 35))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 153, length: 27))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 285, length: 18))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 561, length: 21))
    attributedString.addAttribute(.foregroundColor, value: UIColor(red: 239, green: 129, blue: 2), range: NSRange(location: 595, length: 30))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 636, length: 4))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 643, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 702, length: 3))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 18), range: NSRange(location: 709, length: 1))
    attributedString.addAttribute(.font, value: UIFont.Kyber.bold(with: 14), range: NSRange(location: 732, length: 2))
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 3
    attributedString.addAttribute(
      .paragraphStyle,
      value: paragraphStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )

    return attributedString
  }

  func openMailSupport() {
    if MFMailComposeViewController.canSendMail() {
      let emailVC = MFMailComposeViewController()
      emailVC.mailComposeDelegate = self
      emailVC.setToRecipients(["support@kyberswap.com"])
      self.present(emailVC, animated: true, completion: nil)
    } else {
      let message = NSLocalizedString(
        "please.send.your.request.to.support",
        value: "Please send your request to support@kyberswap.com",
        comment: ""
      )
      self.showWarningTopBannerMessage(with: "", message: message, time: 1.5)
    }
  }
}

extension KNTransferConsentViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
      self.backButton.isHidden = false // show back button, allow to back
    }
  }
}

extension KNTransferConsentViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    if case .sent = result {
      KNCrashlyticsUtil.logCustomEvent(withName: "transfer_consent_support_email_sent", customAttributes: nil)
    }
    controller.dismiss(animated: true, completion: nil)
  }
}

extension UITapGestureRecognizer {
  func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
    guard let attrString = label.attributedText else { return false }

    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: .zero)
    let textStorage = NSTextStorage(attributedString: attrString)

    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)

    textContainer.lineFragmentPadding = 0
    textContainer.lineBreakMode = label.lineBreakMode
    textContainer.maximumNumberOfLines = label.numberOfLines
    let labelSize = label.bounds.size
    textContainer.size = labelSize

    let locationOfTouchInLabel = self.location(in: label)
    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    let textContainerOffset = CGPoint(
      x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
      y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
    )
    let locationOfTouchInTextContainer = CGPoint(
      x: locationOfTouchInLabel.x - textContainerOffset.x,
      y: locationOfTouchInLabel.y - textContainerOffset.y
    )
    let indexOfCharacter = layoutManager.characterIndex(
      for: locationOfTouchInTextContainer,
      in: textContainer,
      fractionOfDistanceBetweenInsertionPoints: nil
    )
    return NSLocationInRange(indexOfCharacter, targetRange)
  }
}
