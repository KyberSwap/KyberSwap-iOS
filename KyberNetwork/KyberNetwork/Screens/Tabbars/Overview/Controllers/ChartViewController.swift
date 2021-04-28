//
//  ChartViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/24/21.
//

import UIKit
import SwiftChart
import BigInt


class ChartViewModel {
  var dataSource: [(x: Double, y: Double)] = []
  var xLabels: [Double] = []
  let token: Token
  var periodType: ChartPeriodType = .oneDay
  var detailInfo: TokenDetailData?
  var chartData: ChartData?
  var chartOriginTimeStamp: Double = 0
  var currency: String
  
  init(token: Token, currency: String) {
    self.token = token
    self.currency = currency
  }
  
  func updateChartData(_ data: ChartData) {
    guard !data.prices.isEmpty else { return }
    self.chartData = data
    let originTimeStamp = data.prices[0][0]
    self.chartOriginTimeStamp = originTimeStamp
    self.dataSource = data.prices.map { (item) -> (x: Double, y: Double) in
      return (x: item[0] - originTimeStamp, y: item[1])
    }
    if let lastTimeStamp = data.prices.last?[0] {
      let interval = lastTimeStamp - originTimeStamp
      let divide = interval / 7
      self.xLabels = [0, divide, divide * 2, divide * 3, divide * 4, divide * 5, divide * 6]
    }
  }
  
  var series: ChartSeries {
    let series = ChartSeries(data: self.dataSource)
    series.area = true
    series.colors = (above: UIColor(red: 35, green: 167, blue: 181), below: UIColor(red: 36, green: 83, blue: 98), 0)
    return series
  }
  
  var displayPrice: String {
    guard let unwrapped = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address) else {
      return "---"
    }
    if self.currency == "eth" {
      return "\(unwrapped.usd) ETH"
    } else if self.currency == "btc" {
      return "\(unwrapped.usd) BTC"
    } else {
      return "$\(unwrapped.usd)"
    }
  }

  var display24hVol: String {
    guard let lastVol = self.chartData?.totalVolumes.last?[1] else { return "---" }
    return "\(self.formatPoints(lastVol)) \(self.token.symbol.uppercased())"
  }
  
  var displayDiffPercent: String {
    guard let firstPrice = self.chartData?.prices.first?[1], let lastPrice =  self.chartData?.prices.last?[1] else {
      return "---"
    }
    let diff = (lastPrice - firstPrice) * 100.0
    return String(format: "%.2f", diff / firstPrice) + "%"
  }
  
  var displayDiffColor: UIColor {
    guard let firstPrice = self.chartData?.prices.first?[1], let lastPrice =  self.chartData?.prices.last?[1] else {
      return UIColor.clear
    }
    let diff = lastPrice - firstPrice
    return diff > 0 ? UIColor.Kyber.SWGreen : UIColor.Kyber.SWRed
  }
  
  var diplayBalance: String {
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address), let balanceBigInt = BigInt(balance.balance) else { return "---" }
    
    return balanceBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 6)) + " \(self.token.symbol.uppercased())"
  }
  
  var displayUSDBalance: String {
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address), let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address), let balanceBigInt = BigInt(balance.balance) else { return "---" }
    let rateBigInt = BigInt(rate.usd * pow(10.0, 18.0))
    let valueBigInt = balanceBigInt * rateBigInt / BigInt(10).power(18)
    return "$" + valueBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 6))
  }
  
  var displayMarketCap: String {
    guard let lastMC = self.chartData?.marketCaps.last?[1] else {
      return "---"
    }
    if self.currency == "eth" {
      return "\(self.formatPoints(lastMC)) ETH"
    } else if self.currency == "btc" {
      return "\(self.formatPoints(lastMC)) BTC"
    } else {
      return "$\(self.formatPoints(lastMC))"
    }
  }
  
  var displayAllTimeHigh: String {
    guard let ath = self.detailInfo?.marketData.ath?[self.currency] else { return "---"}
    if self.currency == "eth" {
      return "\(ath) ETH"
    } else if self.currency == "btc" {
      return "\(ath) BTC"
    } else {
      return "$\(ath)"
    }
  }
  
  var displayAllTimeLow: String {
    guard let atl = self.detailInfo?.marketData.atl?[self.currency] else { return "---"}
    if self.currency == "eth" {
      return "\(atl) ETH"
    } else if self.currency == "btc" {
      return "\(atl) BTC"
    } else {
      return "$\(atl)"
    }
  }
  
  var displayDescription: String {
    guard let description = self.detailInfo?.tokenDetailDataDescription.en, !description.isEmpty else {
      return self.detailInfo?.icoData?.icoDataDescription ?? ""
    }
    return description
  }

  var displayDescriptionAttribution: NSAttributedString? {
    guard let attributedString = try? NSAttributedString(
      data: self.displayDescription.data(using: .utf8) ?? Data(),
      options: [.documentType: NSAttributedString.DocumentType.html],
      documentAttributes: nil
    ) else {
      return nil
    }
    let string = NSMutableAttributedString(attributedString: attributedString)
    string.addAttributes([
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 14),
    ], range: NSRange(location: 0, length: attributedString.length)
    )
    return string
  }
  
  var headerTitle: String {
    return "\(self.token.symbol.uppercased())/\(self.currency.uppercased())"
  }
  
  func formatPoints(_ number: Double) -> String {
    let thousand = number / 1000
    let million = number / 1000000
    let billion = number / 1000000000
    
    if billion >= 1.0 {
      return "\(round(billion*10)/10)B"
    } else if million >= 1.0 {
      return "\(round(million*10)/10)M"
    } else if thousand >= 1.0 {
      return ("\(round(thousand*10/10))K")
    } else {
      return "\(Int(number))"
    }
  }
  
  func displayChartDetaiInfoAt(index: Int) -> NSAttributedString {
    guard let priceItem = self.chartData?.prices[index],
    let volumeItem = self.chartData?.totalVolumes[index],
    let price = priceItem.last,
    let volume = volumeItem.last,
    let timestamp = priceItem.first
    else {
      return NSAttributedString()
    }
    let date = Date(timeIntervalSince1970: timestamp * 0.001)
    let dateFormater = DateFormatterUtil.shared.chartViewDateFormatter
    let dateString = dateFormater.string(from: date)
    let normalAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoRegular(with: 10),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let boldAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.latoBold(with: 10),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let priceBigInt = BigInt(price * pow(10.0, 18.0))
    let volumeBigInt = BigInt(volume * pow(10.0, 18.0))
    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: dateString + " ", attributes: boldAttributes))
    attributedText.append(NSAttributedString(string: "  Price" + ": ", attributes: boldAttributes))
    attributedText.append(NSAttributedString(string: "$\(priceBigInt.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4))", attributes: normalAttributes))
    attributedText.append(NSAttributedString(string: "  Volume" + ": ", attributes: boldAttributes))
    attributedText.append(NSAttributedString(string: "$\(volumeBigInt.string(decimals: 18, minFractionDigits: 4, maxFractionDigits: 4))", attributes: normalAttributes))
    return attributedText
  }
}

enum ChartViewEvent {
  case getChartData(address: String, from: Int, to: Int, currency: String)
  case getTokenDetailInfo(address: String)
  case transfer(token: Token)
  case swap(token: Token)
  case invest(token: Token)
  case openEtherscan(address: String)
  case openWebsite(url: String)
  case openTwitter(name: String)
  
}

enum ChartPeriodType: Int {
  case oneDay = 1
  case sevenDay
  case oneMonth
  case threeMonth
  case oneYear
  
  func getFromTimeStamp() -> Int {
    let current = NSDate().timeIntervalSince1970
    var interval = 0
    switch self {
    case .oneDay:
      interval = 24 * 60 * 60
    case .sevenDay:
      interval = 7 * 24 * 60 * 60
    case .oneMonth:
      interval = 30 * 24 * 60 * 60
    case .threeMonth:
      interval = 3 * 30 * 24 * 60 * 60
    case .oneYear:
      interval = 12 * 30 * 24 * 60 * 60
    }
    return Int(current) - interval
  }
}

protocol ChartViewControllerDelegate: class {
  func chartViewController(_ controller: ChartViewController, run event: ChartViewEvent)
}

class ChartViewController: KNBaseViewController {
  @IBOutlet weak var chartView: Chart!
  @IBOutlet var periodChartSelectButtons: [UIButton]!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var priceDiffPercentageLabel: UILabel!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var ethBalanceLabel: UILabel!
  @IBOutlet weak var usdBalanceLabel: UILabel!
  @IBOutlet weak var marketCapLabel: UILabel!
  @IBOutlet weak var atlLabel: UILabel!
  @IBOutlet weak var athLabel: UILabel!
  @IBOutlet weak var titleView: UILabel!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!
  @IBOutlet weak var investButton: UIButton!
  @IBOutlet weak var descriptionTextView: GrowingTextView!
  @IBOutlet weak var chartDetailLabel: UILabel!
  @IBOutlet weak var noDataLabel: UILabel!
  
  weak var delegate: ChartViewControllerDelegate?
  let viewModel: ChartViewModel

  init(viewModel: ChartViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ChartViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.chartView.showYLabelsAndGrid = false
    self.chartView.labelColor = UIColor(red: 164, green: 171, blue: 187)
    self.chartView.labelFont = UIFont.Kyber.latoRegular(with: 10)
    self.chartView.axesColor = .clear
    self.chartView.gridColor = .clear
    self.chartView.backgroundColor = .clear
    self.chartView.delegate = self
    self.updateUIPeriodSelectButtons()
    self.titleView.text = self.viewModel.headerTitle
    self.transferButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.transferButton.frame.size.height / 2)
    self.swapButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.transferButton.frame.size.height / 2)
    self.investButton.rounded(color: UIColor.Kyber.SWButtonBlueColor, width: 1, radius: self.transferButton.frame.size.height / 2)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.loadChartData()
    self.loadTokenDetailInfo()
    self.updateUIChartInfo()
    self.updateUITokenInfo()
  }

  @IBAction func changeChartPeriodButtonTapped(_ sender: UIButton) {
    guard let type = ChartPeriodType(rawValue: sender.tag), type != self.viewModel.periodType else {
      return
    }
    self.viewModel.periodType = type
    self.loadChartData()
    self.updateUIPeriodSelectButtons()
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func transferButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .transfer(token: self.viewModel.token))
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .swap(token: self.viewModel.token))
  }
  
  @IBAction func investButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .invest(token: self.viewModel.token))
  }
  
  @IBAction func etherscanButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openEtherscan(address: self.viewModel.token.address))
  }
  
  @IBAction func websiteButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openWebsite(url: self.viewModel.detailInfo?.links.homepage.first ?? ""))
  }
  
  @IBAction func twitterButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openTwitter(name: self.viewModel.detailInfo?.links.twitterScreenName ?? ""))
  }
  
  fileprivate func updateUIChartInfo() {
    self.volumeLabel.text = self.viewModel.display24hVol
    self.ethBalanceLabel.text = self.viewModel.diplayBalance
    self.usdBalanceLabel.text = self.viewModel.displayUSDBalance
    self.marketCapLabel.text = self.viewModel.displayMarketCap
    self.priceDiffPercentageLabel.text = self.viewModel.displayDiffPercent
    self.priceDiffPercentageLabel.textColor = self.viewModel.displayDiffColor
  }

  fileprivate func updateUITokenInfo() {
    self.atlLabel.text = self.viewModel.displayAllTimeLow
    self.athLabel.text = self.viewModel.displayAllTimeHigh
    self.descriptionTextView.attributedText = self.viewModel.displayDescriptionAttribution
    self.priceLabel.text = self.viewModel.displayPrice
  }

  fileprivate func loadChartData() {
    let current = NSDate().timeIntervalSince1970
    self.delegate?.chartViewController(self, run: .getChartData(address: self.viewModel.token.address, from: self.viewModel.periodType.getFromTimeStamp(), to: Int(current), currency: self.viewModel.currency))
  }

  fileprivate func loadTokenDetailInfo() {
    self.delegate?.chartViewController(self, run: .getTokenDetailInfo(address: self.viewModel.token.address))
  }

  fileprivate func updateUIPeriodSelectButtons() {
    self.periodChartSelectButtons.forEach { (button) in
      if button.tag == self.viewModel.periodType.rawValue {
        button.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
      } else {
        button.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      }
    }
  }

  func coordinatorDidUpdateChartData(_ data: ChartData) {
    self.noDataLabel.isHidden = !data.prices.isEmpty
    self.viewModel.updateChartData(data)
    self.chartView.removeAllSeries()
    self.chartView.add(self.viewModel.series)
    self.chartView.xLabels = self.viewModel.xLabels
    self.updateUIChartInfo()
    self.chartView.xLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
      let timestamp = labelValue + self.viewModel.chartOriginTimeStamp
      let date = Date(timeIntervalSince1970: timestamp * 0.001)
      let calendar = Calendar.current
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "EE"
      let hour = calendar.component(.hour, from: date)
      let minutes = calendar.component(.minute, from: date)
      let day = calendar.component(.day, from: date)
      let month = calendar.component(.month, from: date)
      let year = calendar.component(.year, from: date)
      switch self.viewModel.periodType {
      case .oneDay:
        return "\(hour):\(minutes)"
      case .sevenDay:
        return "\(dateFormatter.string(from: date)) \(hour)"
      case .oneMonth, .threeMonth:
        return "\(day)/\(month)"
      case .oneYear:
        return "\(month)/\(year)"
      }
    }
  }

  func coordinatorFailUpdateApi(_ error: Error) {
    self.showErrorTopBannerMessage(with: "", message: error.localizedDescription)
  }

  func coordinatorDidUpdateTokenDetailInfo(_ detailInfo: TokenDetailData) {
    self.viewModel.detailInfo = detailInfo
    self.updateUITokenInfo()
  }
}

extension ChartViewController: ChartDelegate {
  func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
    guard let index = indexes.first, let unwrappedIdx = index else {
      return
    }
    self.chartDetailLabel.attributedText = self.viewModel.displayChartDetaiInfoAt(index: unwrappedIdx)
  }
  
  func didFinishTouchingChart(_ chart: Chart) {
    
  }
  
  func didEndTouchingChart(_ chart: Chart) {
    
  }
}
