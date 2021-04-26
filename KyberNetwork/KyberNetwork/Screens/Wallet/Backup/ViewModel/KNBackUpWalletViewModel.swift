// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNBackUpWalletState {
  case backup
  case testBackup
}

class KNBackUpWalletViewModel {
  let seeds: [String]
  var state: KNBackUpWalletState = .backup

  var firstWordID: Int
  var secondWordID: Int

  var numberWrongs: Int = 0

  let numberWords: Int = 4
  fileprivate let maxWords: Int = 12
  fileprivate(set) var currentWordIndex: Int = 0

  init(seeds: [String]) {
    self.seeds = seeds
    self.firstWordID = Int(arc4random() % 11) + 1
    self.secondWordID = self.firstWordID + 1 + Int(arc4random() % UInt32(12 - self.firstWordID))
  }

  func backupAgain() {
    self.state = .backup
    self.currentWordIndex = 0
    self.numberWrongs = 0
  }

  lazy var defaultTime: Int = {
    return KNEnvironment.default.isMainnet ? 15 : 3
  }()

  func attributedString(for id: Int) -> NSAttributedString {
    let wordID: Int = id + self.currentWordIndex + 1
    if wordID > self.seeds.count { return NSMutableAttributedString() }
    let word: String = self.seeds[wordID - 1]
    let attributedString: NSMutableAttributedString = {
      let idAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.kern: 0.0,
      ]
      let wordAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor.white,
        NSAttributedStringKey.kern: 0.0,
      ]
      let attributedString = NSMutableAttributedString()
      attributedString.append(NSAttributedString(string: "\(wordID).", attributes: idAttributes))
      attributedString.append(NSAttributedString(string: "  \(word)", attributes: wordAttributes))
      return attributedString
    }()
    return attributedString
  }

  func updateNextBackUpWords() {
    self.currentWordIndex += self.numberWords
    if self.currentWordIndex >= self.maxWords - 1 {
      self.state = .testBackup
      self.firstWordID = Int(arc4random() % 11) + 1
      self.secondWordID = self.firstWordID + 1 + Int(arc4random() % UInt32(12 - self.firstWordID))
    } else {
      self.state = .backup
    }
  }

  func updateModelBackPressed() {
    if self.currentWordIndex == 0 { return }
    if self.state == .testBackup {
      self.backupAgain()
    } else {
      self.currentWordIndex = max(self.currentWordIndex - self.numberWords, 0)
    }
  }

  lazy var backUpWalletText: String = {
    return NSLocalizedString("backup.your.wallet", value: "Backup Your Wallet", comment: "")
  }()

  var backUpTitleText: String {
    return self.currentWordIndex == 0 ? NSLocalizedString("paper.only", value: "Paper Only", comment: "") : ""
  }

  var backUpDescAttributedString: NSMutableAttributedString {
    if self.currentWordIndex > 0 { return NSMutableAttributedString() }
    let regularttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let boldAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.bold(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    let listOfWords = NSLocalizedString("we.will.give.you.a.list.of.random.words", value: "We will give you a list of 12 random words. Please", comment: "")
    attributedString.append(NSAttributedString(string: "\(listOfWords) ", attributes: regularttributes))
    let writeDownOnPaper = NSLocalizedString("write.them.down.on.paper", value: "write them down on paper", comment: "")
    attributedString.append(NSAttributedString(string: "\(writeDownOnPaper) ", attributes: boldAttributes))
    let keepSafe = NSLocalizedString("and.keep.safe.this.paper.key", value: "and keep safe.\n\nThis paper key is", comment: "")
    attributedString.append(NSAttributedString(string: "\(keepSafe) ", attributes: regularttributes))
    let theOnlyWay = NSLocalizedString("the.only.way", value: "the only way", comment: "")
    attributedString.append(NSAttributedString(string: "\(theOnlyWay) ", attributes: boldAttributes))
    let restoreText = "to restore your Wallet if you lose your device or forget your password."
    attributedString.append(NSAttributedString(string: restoreText, attributes: regularttributes))
    return attributedString
  }

  var writeDownWordsText: String {
    let text = NSLocalizedString("write.down.the.words.from", value: "Write down the words from", comment: "")
    return "\(text) \(self.currentWordIndex + 1)-\(self.currentWordIndex + self.numberWords)"
  }

  var wroteDownButtonTitle: String {
    let text = NSLocalizedString("i.wrote.down.the.words.from", value: "I wrote down the words from", comment: "")
    return "\(text) \(self.currentWordIndex + 1) \(NSLocalizedString("to", value: "To", comment: "")) \(self.currentWordIndex + self.numberWords)"
  }

  lazy var testingBackUpText: String = {
    return NSLocalizedString("test.your.backup", value: "Test your Backup", comment: "")
  }()

  lazy var testingBackUpDescText: NSMutableAttributedString = {
    let regularttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    let key = "make.sure.you.have.written.down.all.your.backup.words"
    let text = "To make sure you have written down all of your backup words. Please enter the following."
    attributedString.append(NSAttributedString(
      string: NSLocalizedString(key, value: text, comment: ""),
      attributes: regularttributes
    ))
    return attributedString
  }()

  lazy var completeButtonText: String = {
    return NSLocalizedString("complete", value: "Complete", comment: "")
  }()

  var iconName: String {
    return self.state == .backup ? "back_up_icon" : "test_back_up_icon"
  }

  var headerText: String {
    return self.state == .backup ? self.backUpWalletText : self.testingBackUpText
  }

  var titleText: String {
    return self.state == .backup ? self.backUpTitleText : ""
  }

  var descriptionAttributedText: NSAttributedString {
    return self.state == .backup ? self.backUpDescAttributedString : self.testingBackUpDescText
  }

  var isWriteDownWordsLabelHidden: Bool {
    return self.state == .testBackup
  }

  var isListWordsLabelsHidden: Bool {
    return self.state == .testBackup
  }

  var isBackButtonHidden: Bool {
    return self.state == .backup && self.currentWordIndex == 0
  }

  var isNextButtonHidden: Bool {
    return self.state == .testBackup
  }

  var isTestWordsTextFieldHidden: Bool {
    return self.state == .backup
  }

  var firstWordTextFieldPlaceholder: NSAttributedString {
    return NSAttributedString(string: "\(NSLocalizedString("word", value: "Word", comment: "")) #\(self.firstWordID)",
                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
  }

  var secondWordTextFieldPlaceholder: NSAttributedString {
    return NSAttributedString(string: "\(NSLocalizedString("word", value: "Word", comment: "")) #\(self.secondWordID)",
                              attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
  }

  var isCompleteButtonHidden: Bool {
    return self.state == .backup
  }

  func isTestPassed(firstWord: String, secondWord: String) -> Bool {
    return self.seeds[self.firstWordID - 1] == firstWord && self.seeds[self.secondWordID - 1] == secondWord
  }
}
