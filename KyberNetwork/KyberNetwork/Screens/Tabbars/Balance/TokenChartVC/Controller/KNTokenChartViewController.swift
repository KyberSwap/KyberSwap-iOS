// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Result
import BigInt
import EasyTipView
import Charts

enum KNTokenChartType: Int {
  case day = 0
  case week = 1
  case month = 2
  case year = 3
  case all = 4

  var resolution: String {
    switch self {
    case .day: return "15"
    case .week: return "60"
    case .month: return "240"
    case .year, .all: return "D"
    }
  }

  func displayString() -> String {
    switch self {
    case .day:
      return "24h"
    case .week:
      return "7 days"
    case .month:
      return "month"
    case .year:
      return "year"
    case .all:
      return "all"
    }
  }

  func fromTime(for toTime: Int64) -> Int64 {
    switch self {
    case .day:
      return toTime - 24 * 60 * 60
    case .week:
      return toTime - 7 * 24 * 60 * 60
    case .month:
      return toTime - 30 * 24 * 60 * 60
    case .year:
      return toTime - 365 * 24 * 60 * 60
    case .all:
      return 1
    }
  }

  var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    switch self {
    case .day:
      formatter.dateFormat = "HH:mm"
    case .week, .month:
      formatter.dateFormat = "dd/MM HH:MM"
    case .year, .all:
      formatter.dateFormat = "dd/MM"
    }
    return formatter
  }

  func label(for time: Double) -> String {
    let date = Date(timeIntervalSince1970: time)
    return self.dateFormatter.string(from: date)
  }

  var scaleUnit: Double {
    switch self {
    case .day: return 15 * 60
    case .week: return 60 * 60
    case .month: return 4 * 60 * 60
    case .year, .all: return 24 * 60 * 60
    }
  }
}

enum KNTokenChartViewEvent {
  case back
  case buy(token: TokenObject)
  case sell(token: TokenObject)
  case send(token: TokenObject)
  case openEtherscan(token: TokenObject)
  case addNewAlert(token: TokenObject)
}

protocol KNTokenChartViewControllerDelegate: class {
  func tokenChartViewController(_ controller: KNTokenChartViewController, run event: KNTokenChartViewEvent)
}

struct KNLimitOrderChartData {
  let market: KNMarket
  let isBuy: Bool
}

class KNTokenChartViewModel {
  let token: TokenObject
  var type: KNTokenChartType = .day
  var chartDataLO: KNLimitOrderChartData? // not nil if opening from LO view
  var data: [KNChartObject] = []
  var balance: BigInt = BigInt(0)
  var pendingBalance: BigInt = BigInt(0) // use only for LO-chart
  var volume24h: String = "---"
  let currencyType: KWalletCurrencyType = KNAppTracker.getCurrencyType()

  var availableBalance: BigInt {
    return max(BigInt(0), balance - pendingBalance)
  }

  init(token: TokenObject, chartDataLO: KNLimitOrderChartData? = nil) {
    self.token = token
    self.data = []
    self.chartDataLO = chartDataLO
  }

  var navigationTitle: String {
    if let market = self.chartDataLO?.market {
      var quoteToken = market.pair.components(separatedBy: "_").first ?? ""
      if quoteToken == "ETH" || quoteToken == "WETH" { quoteToken = "ETH*" }
      var tokenSymbol = self.token.symbol
      if tokenSymbol == "ETH" || tokenSymbol == "WETH" { tokenSymbol = "ETH*" }
      return "\(tokenSymbol)/\(quoteToken)"
    }
    return "\(self.token.symbol.prefix(8))"
  }
  var isTokenSupported: Bool { return self.token.isSupported }

  var rateChangeString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else {
      return ""
    }
    let chartData = self.chartDataLO
    let change24h: Double = {
      if let market = chartData?.market {
        // data from LO
        return market.change
      }
      return currencyType == .eth ? trackerRate.changeETH24h : trackerRate.changeUSD24h
    }()
    let change24hString: String = {
      if self.type == .day || chartData != nil {
        let string = NumberFormatterUtil.shared.displayPercentage(from: fabs(change24h))
        return "\(string)%"
      }
      if let firstData = self.data.first, let lastData = self.data.last {
        if firstData.close == 0 || lastData.close == 0 { return "" }
        let change = (lastData.close - firstData.close) / firstData.close * 100.0
        let string = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
        return "\(string)%"
      }
      return ""
    }()
    return change24hString
  }

  var rateAttributedString: NSAttributedString {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else {
      return NSMutableAttributedString()
    }
    let chartData = self.chartDataLO
    let rateNow: Double = {
      if let data = chartData {
        // data from LO
        return data.isBuy ? data.market.buyPrice : data.market.sellPrice
      }
      return currencyType == .eth ? trackerRate.rateETHNow : trackerRate.rateUSDNow
    }()
    let rateString: String = {
      let rate = BigInt(rateNow * Double(EthereumUnit.ether.rawValue))
      return rate.displayRate(decimals: 18)
    }()
    let change24h: Double = {
      if let market = chartData?.market {
        // data from LO
        return market.change
      }
      return currencyType == .eth ? trackerRate.changeETH24h : trackerRate.changeUSD24h
    }()
    let change24hString: String = {
      if self.type == .day || chartData != nil {
        let string = NumberFormatterUtil.shared.displayPercentage(from: fabs(change24h))
        return "\(string)%"
      }
      if let firstData = self.data.first, let lastData = self.data.last {
        if firstData.close == 0 || lastData.close == 0 { return "" }
        let change = (lastData.close - firstData.close) / firstData.close * 100.0
        let string = NumberFormatterUtil.shared.displayPercentage(from: fabs(change))
        return "\(string)%"
      }
      return ""
    }()
    let changeColor: UIColor = {
      if self.type == .day || chartData != nil {
        if change24h == 0.0 { return UIColor.Kyber.grayChateau }
        return change24h > 0 ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
      }
      if let firstData = self.data.first, let lastData = self.data.last, firstData.close != 0, lastData.close != 0 {
        let change = (lastData.close - firstData.close) / firstData.close * 100.0
        if change == 0 { return UIColor.Kyber.grayChateau }
        return change > 0 ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
      }
      return UIColor.Kyber.grayChateau
    }()
    let rateAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
      NSAttributedStringKey.kern: 0.0,
    ]
    let changeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: changeColor,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
      NSAttributedStringKey.kern: 0.0,
    ]
    let volume24hTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 139, green: 142, blue: 147),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let volume24hValueAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 29, green: 48, blue: 58),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 12),
      NSAttributedStringKey.kern: 0.0,
    ]
    let currencyTypeString: String = {
      if let market = chartData?.market {
        // data from LO
        let pair = market.pair.components(separatedBy: "_")
        var quoteToken = pair.first ?? ""
        if quoteToken == "ETH" || quoteToken == "WETH" { quoteToken = "ETH*" }
        return quoteToken
      }
      return currencyType == .eth ? "ETH" : "USD"
    }()
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "\(rateString) \(currencyTypeString) ", attributes: rateAttributes))
    attributedString.append(NSAttributedString(string: "\(change24hString)", attributes: changeAttributes))
    attributedString.append(NSAttributedString(string: "\n24h Vol: ", attributes: volume24hTextAttributes))
    attributedString.append(NSAttributedString(string: "\(self.volume24h) \(currencyTypeString)", attributes: volume24hValueAttributes))

    return attributedString
  }

  var balanceAttributedString: NSAttributedString {
    let balance: String = self.availableBalance.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    )
    let balanceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 18),
      NSAttributedStringKey.kern: 0.0,
    ]
    let attributedString = NSMutableAttributedString()
    if self.chartDataLO != nil {
      let availableTextAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor(red: 139, green: 142, blue: 147),
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 10),
        NSAttributedStringKey.kern: 0.0,
      ]
      attributedString.append(NSAttributedString(string: "\("Available Balance".toBeLocalised())\n", attributes: availableTextAttributes))
    }
    attributedString.append(NSAttributedString(string: balance, attributes: balanceAttributes))
    return attributedString
  }

  var totalValueString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let value: BigInt = {
      let balance: BigInt = {
        let balanceString: String = self.availableBalance.string(
          decimals: self.token.decimals,
          minFractionDigits: 0,
          maxFractionDigits: min(self.token.decimals, 6)
        )
        if balanceString.fullBigInt(decimals: self.token.decimals)?.isZero == true { return BigInt(0) }
        return self.balance
      }()
      return trackerRate.rateETHBigInt * balance / BigInt(10).power(self.token.decimals)
    }()
    if value.isZero { return "0 ETH" }
    let valueString: String = "\(value.displayRate(decimals: 18).prefix(12))"
    if valueString.fullBigInt(decimals: 18)?.isZero == true { return "0 ETH" }
    return self.token.isETH ? "\(valueString) ETH" : "~\(valueString) ETH"
  }

  var totalUSDAmount: BigInt? {
    if let usdRate = KNRateCoordinator.shared.usdRate(for: self.token) {
      let balance: BigInt = {
        let balanceString: String = self.availableBalance.string(
          decimals: self.token.decimals,
          minFractionDigits: 0,
          maxFractionDigits: min(self.token.decimals, 6)
        )
        if balanceString.fullBigInt(decimals: self.token.decimals)?.isZero == true { return BigInt(0) }
        return self.balance
      }()
      return usdRate.rate * balance / BigInt(10).power(self.token.decimals)
    }
    return nil
  }

  var displayTotalUSDAmount: String? {
    guard let amount = self.totalUSDAmount else { return nil }
    if amount.isZero { return "$0 USD" }
    let value = "\(amount.displayRate(decimals: 18).prefix(12))"
    if value.fullBigInt(decimals: 18)?.isZero == true { return "$0 USD" }
    return "~ $\(value) USD"
  }

  func updateType(_ newType: KNTokenChartType) {
    self.type = newType
    self.data = []
  }

  func updateBalance(_ balance: BigInt) {
    self.balance = balance
  }

  func updatePendingBalance(_ balance: BigInt) {
    self.pendingBalance = balance
  }

  func updateMarket(_ market: KNMarket) {
    guard let chartData = self.chartDataLO, chartData.market.pair == market.pair else {
      return
    }
    self.chartDataLO = KNLimitOrderChartData(market: market, isBuy: chartData.isBuy)
  }

  func updateData(_ newData: JSONDictionary, symbol: String, resolution: String) {
    var objects: [KNChartObject] = KNChartObject.objects(
      from: newData,
      symbol: symbol,
      resolution: resolution
    )
    if self.token.symbol == symbol && self.type.resolution == resolution && !objects.isEmpty {
      objects = objects.sorted(by: { $0.time < $1.time })
      if self.data.isEmpty || self.data.last!.time < objects.first!.time {
        self.data.append(contentsOf: objects)
      }
      let fromTime = self.type.fromTime(for: Int64(floor(Date().timeIntervalSince1970)))
      for id in 0..<self.data.count where self.data[id].time >= fromTime {
        self.data = Array(self.data.suffix(from: id)) as [KNChartObject]
        return
      }
      // no data between from and to time to display
      self.data = []
    }
  }

  var scaleXFactor: CGFloat {
    //Test on device see that with 48 elements looks good so use this value to calculate the scale factor base on number of element
    let totalCount = self.data.count
    return CGFloat(totalCount) / CGFloat(48)
  }

  var displayChartData: CandleChartData {
    if let object = self.data.first {
      self.data = self.data.filter({ return $0.time >= self.type.fromTime(for: object.time) })
    }
    guard let first = self.data.first else {
      return CandleChartData(dataSet: nil)
    }
    let candleStickEntries = self.data.map { (element) -> CandleChartDataEntry in
      let xAxis = Double(element.time - first.time) / type.scaleUnit
      return CandleChartDataEntry(x: xAxis, shadowH: element.high, shadowL: element.low, open: element.open, close: element.close)
    }
    let set1 = CandleChartDataSet(entries: candleStickEntries, label: "Data Set")
    set1.axisDependency = .left
    set1.setColor(UIColor(white: 80/255, alpha: 1))
    set1.drawIconsEnabled = false
    set1.shadowColor = .darkGray
    set1.shadowWidth = 0.7
    set1.decreasingColor = UIColor.Kyber.red
    set1.decreasingFilled = true
    set1.increasingColor = UIColor.Kyber.green
    set1.increasingFilled = true
    set1.neutralColor = .blue
    set1.drawValuesEnabled = false

    let candleStickData = CandleChartData(dataSet: set1)
    return candleStickData
  }

  var xDoubleLabels: [Double] {
    guard let first = self.data.first else {
      return []
    }
    let data = self.data.map { return Double($0.time - first.time) / type.scaleUnit }
    return data
  }

  var yDoubleLables: [Double] {
    if self.data.isEmpty { return [] }
    var minDouble: Double = self.data.first!.close
    var maxDouble: Double = self.data.first!.close
    self.data.forEach({
      minDouble = min(minDouble, $0.close)
      maxDouble = max(maxDouble, $0.close)
    })
    return [minDouble, maxDouble]
  }

  func fetch24hVolume(for token: TokenObject, completion: @escaping (Result<Double, AnyError>) -> Void) {
    if !token.isSupported {
      self.volume24h = "---"
      completion(.success(0))
      return
    }

    if let chartData = self.chartDataLO {
      // chart from LO, use data from market object
      let formatter = NumberFormatterUtil.shared.doubleFormatter
      let totalVolume = KNRateCoordinator.shared.getMarketVolume(pair: chartData.market.pair)
      self.volume24h = "\(formatter.string(from: NSNumber(value: fabs(totalVolume))) ?? "---")"
      completion(.success(chartData.market.volume))
      return
    }

    let provider = MoyaProvider<KNTrackerService>()
    let symbol = token.symbol
    DispatchQueue.global(qos: .background).async {
      provider.request(.getTokenVolumne) { [weak self] result in
        guard let `self` = self else {
          completion(.success(0))
          return
        }
        DispatchQueue.main.async {
          if self.token.symbol != symbol {
            completion(.success(0))
            return
          }
          switch result {
          case .success(let resp):
            do {
              let _ = try resp.filterSuccessfulStatusCodes()
              let json = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
              let volumeKey = self.currencyType == .eth ? "eth_24h_volume" : "usd_24h_volume"
              if let jsonArr = json["data"] as? [JSONDictionary],
                let info = jsonArr.first(where: { return $0["base_symbol"] as? String ?? "" == symbol }),
                let volume24h = info[volumeKey] as? Double {
                self.volume24h = BigInt(volume24h * pow(10.0, 18.0)).string(
                  decimals: 18,
                  minFractionDigits: 6,
                  maxFractionDigits: 6
                )
                completion(.success(volume24h))
              }
            } catch let error {
              self.volume24h = "---"
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            self.volume24h = "---"
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func fetchNewData(for token: TokenObject, type: KNTokenChartType, completion: @escaping ((Result<Bool, AnyError>) -> Void)) {
    let to: Int64 = Int64(floor(Date().timeIntervalSince1970))
    let from: Int64 = {
      let fromTime: Int64 = type.fromTime(for: to)
      if let time = self.data.last?.time {
        return max(time + 60, fromTime)
      }
      return fromTime
    }()
    var symbol = token.symbol
    if let market = self.chartDataLO?.market {
      let quoteToken = market.pair.components(separatedBy: "_").first?.uppercased() ?? ""
      symbol += quoteToken == "WETH" ? "_ETH" : "_\(quoteToken)"
    } else {
      symbol += self.currencyType == .usd ? "_USDC" : "_ETH"
    }
    let provider = MoyaProvider<KNTrackerService>()
    let service = KNTrackerService.getChartHistory(
      symbol: symbol,
      resolution: type.resolution,
      from: from,
      to: to,
      rateType: "mid"
    )
    if isDebug { print("------ Chart history: Fetching for \(token.symbol) resolution \(type.resolution) ------") }
    DispatchQueue.global(qos: .background).async {
      provider.request(service) { response in
        DispatchQueue.main.async {
          switch response {
          case .success(let result):
            do {
              _ = try result.filterSuccessfulStatusCodes()
              if let data = try result.mapJSON(failsOnEmptyData: false) as? JSONDictionary {
                self.updateData(data, symbol: token.symbol, resolution: type.resolution)
                if isDebug { print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) ------") }
                completion(.success(true))
              } else {
                if isDebug { print("------ Chart history: Failed parse data for \(token.symbol) resolution \(type.resolution) ------") }
                completion(.success(false))
              }
            } catch let error {
              if isDebug { print("------ Chart history: Failed map JSON data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError)------") }
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            if isDebug { print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError) ------") }
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}

//swiftlint:disable file_length
class KNTokenChartViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationLabel: UILabel!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!

  @IBOutlet weak var ethRateLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!
  @IBOutlet weak var totalUSDValueLabel: UILabel!

  @IBOutlet weak var noDataLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var addAlertButton: UIButton!
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var sellButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var dataTypeButtonContainerView: UIView!
  @IBOutlet var dataTypeButtons: [UIButton]!

  @IBOutlet weak var bottomPaddingConstraintForButton: NSLayoutConstraint!
  weak var delegate: KNTokenChartViewControllerDelegate?
  fileprivate var viewModel: KNTokenChartViewModel

  fileprivate var timer: Timer?
  @IBOutlet weak var touchPriceLabel: UILabel!
  @IBOutlet weak var leftPaddingForTouchPriceLabelConstraint: NSLayoutConstraint!
  @IBOutlet weak var chartView: CandleStickChartView!

  lazy var preferences: EasyTipView.Preferences = {
    var preferences = EasyTipView.Preferences()
    preferences.drawing.font = UIFont.Kyber.medium(with: 14)
    preferences.drawing.textAlignment = .left
    preferences.drawing.foregroundColor = UIColor.Kyber.mirage
    preferences.drawing.backgroundColor = UIColor.white
    preferences.animating.dismissDuration = 0
    return preferences
  }()

  fileprivate var sourceTipView: UIView!
  fileprivate func tipView(with value: Double, at index: Int, for type: KWalletCurrencyType) -> EasyTipView {
    let formatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm dd MMM yyyy"
      return formatter
    }()
    let timeString = formatter.string(from: self.viewModel.data[index].date)
    let timeText = NSLocalizedString("time", value: "Time", comment: "")
    let priceText = NSLocalizedString("price", value: "Price", comment: "")
    let numberFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.maximumFractionDigits = self.viewModel.token.decimals
      formatter.minimumIntegerDigits = 1
      return formatter
    }()
    let rate = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
    let currencyType = type == .eth ? "ETH" : "USD"
    return EasyTipView(text: "\(timeText): \(timeString)\n\(priceText): \(currencyType) \(rate.displayRate())")
  }

  init(viewModel: KNTokenChartViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTokenChartViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if self.viewModel.isTokenSupported {
      self.startTimer()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.stopTimer()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  //swiftlint:disable function_body_length
  fileprivate func setupUI() {
    self.touchPriceLabel.isHidden = true

    self.bottomPaddingConstraintForButton.constant = 16.0 + self.bottomPaddingSafeArea()
    let style = KNAppStyleType.current
    self.view.backgroundColor = style.chartBackgroundColor
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)

    self.iconImageView.setTokenImage(
      token: self.viewModel.token,
      size: self.iconImageView.frame.size
    )
    self.navigationLabel.text = self.viewModel.navigationTitle
    self.navigationLabel.addLetterSpacing()
    self.symbolLabel.text = {
      if self.viewModel.chartDataLO != nil {
        // open from LO, change eth or weth to eth*
        if self.viewModel.token.isETH || self.viewModel.token.isWETH { return "ETH*" }
      }
      return "\(self.viewModel.token.symbol.prefix(8))"
    }()
    self.symbolLabel.addLetterSpacing()
    self.nameLabel.text = {
      if self.viewModel.chartDataLO != nil {
        // open from LO, change eth or weth to eth*
        if self.viewModel.token.isETH || self.viewModel.token.isWETH { return "Ethereum" }
      }
      return self.viewModel.token.name
    }()
    self.nameLabel.addLetterSpacing()

    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    self.ethRateLabel.textAlignment = .center
    self.ethRateLabel.numberOfLines = 0

    self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
    self.totalValueLabel.text = self.viewModel.totalValueString
    self.totalValueLabel.addLetterSpacing()
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()

    self.noDataLabel.isHidden = false

    self.chartView.delegate = self
    self.chartView.chartDescription?.enabled = false
    self.chartView.autoScaleMinMaxEnabled = true
    self.chartView.dragEnabled = true
    self.chartView.setScaleEnabled(true)
    self.chartView.maxVisibleCount = 200
    self.chartView.pinchZoomEnabled = true
    self.chartView.legend.enabled = false
    self.chartView.rightAxis.labelFont = UIFont.Kyber.light(with: 10)
    self.chartView.leftAxis.enabled = false
    self.chartView.xAxis.labelPosition = .bottom
    self.chartView.xAxis.labelFont = UIFont.Kyber.light(with: 10)
    self.chartView.xAxis.valueFormatter = CustomAxisValueFormatter(.day)
    self.sendButton.rounded()
    self.sendButton.backgroundColor = UIColor.Kyber.marketBlue
    self.buyButton.rounded()
    self.buyButton.backgroundColor = UIColor.Kyber.marketGreen
    self.sellButton.rounded()
    if self.viewModel.chartDataLO != nil { //Is from LO2
      self.sendButton.removeFromSuperview()
      self.buyButton.removeConstraints(self.buyButton.constraints)
      self.sellButton.removeConstraints(self.sellButton.constraints)
      var allConstraints: [NSLayoutConstraint] = []
      let views: [String: Any] = ["buyButton": self.buyButton, "sellButton": self.sellButton, "chartView": self.chartView]
      let horizontalContraints = NSLayoutConstraint.constraints(
        withVisualFormat: "H:|-16-[buyButton]-8-[sellButton]-16-|",
        metrics: nil,
        views: views)
      let verticalContraints = NSLayoutConstraint.constraints(
        withVisualFormat: "V:[chartView]-16-[buyButton(45)]",
        metrics: nil,
        views: views)
      allConstraints += horizontalContraints
      allConstraints += verticalContraints
      let yCenterConstraint = NSLayoutConstraint(item: self.buyButton,
                                                 attribute: .centerY,
                                                 relatedBy: .equal,
                                                 toItem: self.sellButton,
                                                 attribute: .centerY,
                                                 multiplier: 1,
                                                 constant: 0)
      let equalWidth = NSLayoutConstraint(item: self.buyButton,
                                          attribute: .width,
                                          relatedBy: .equal,
                                          toItem: self.sellButton,
                                          attribute: .width,
                                          multiplier: 1,
                                          constant: 0)
      let equalHeight = NSLayoutConstraint(item: self.buyButton,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: self.sellButton,
                                           attribute: .height,
                                           multiplier: 1,
                                           constant: 0)
      allConstraints += [yCenterConstraint, equalWidth, equalHeight]
      NSLayoutConstraint.activate(allConstraints)
      self.sellButton.setTitle(
        "Sell Limit Order".toBeLocalised(),
        for: .normal
      )
      self.buyButton.setTitle(
        "Buy Limit Order".toBeLocalised(),
        for: .normal
      )
    } else {
      self.sendButton.setTitle(
        NSLocalizedString("transfer", value: "Transfer", comment: ""),
        for: .normal
      )
      self.buyButton.setTitle(
        NSLocalizedString("buy", value: "Buy", comment: ""),
        for: .normal
      )
      self.sellButton.setTitle(
        NSLocalizedString("sell", value: "Sell", comment: ""),
        for: .normal
      )
      self.sellButton.backgroundColor = UIColor.Kyber.marketRed
    }

    self.dataTypeButtons.forEach { button in
      let title: String = {
        switch button.tag {
        case 0: return "24H"
        case 1: return "7 \(NSLocalizedString("days", value: "Days", comment: ""))"
        case 2: return "\(NSLocalizedString("month", value: "Month", comment: ""))"
        case 3: return "\(NSLocalizedString("year", value: "Year", comment: ""))"
        case 4: return "\(NSLocalizedString("all", value: "All", comment: ""))"
        default: return ""
        }
      }()
      button.setTitle(title, for: .normal)
    }

    if self.viewModel.isTokenSupported {
      self.noDataLabel.text = "\(NSLocalizedString("updating.data", value: "Updating data", comment: "")) ..."
      self.updateDisplayDataType(.day)
    } else {
      self.dataTypeButtonContainerView.isHidden = true
      self.noDataLabel.text = NSLocalizedString("this.token.is.not.supported", value: "This token is not supported by KyberSwap", comment: "")
      self.chartView.isHidden = true
      self.buyButton.isHidden = true
      self.sellButton.isHidden = true
      self.sendButton.isHidden = true
    }
    self.noDataLabel.addLetterSpacing()

    EasyTipView.globalPreferences = self.preferences

    // Add gestures to open token in etherscan
    self.iconImageView.isUserInteractionEnabled = true
    self.iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))
    self.nameLabel.isUserInteractionEnabled = true
    self.nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))
    self.symbolLabel.isUserInteractionEnabled = true
    self.symbolLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openTokenOnEtherscanPressed(_:))))

    self.addAlertButton.isHidden = !KNAppTracker.isPriceAlertEnabled || !self.viewModel.isTokenSupported
  }

  fileprivate func updateDisplayDataType(_ type: KNTokenChartType) {
    self.viewModel.updateType(type)
    for button in self.dataTypeButtons {
      button.rounded(
        color: button.tag == type.rawValue ? UIColor.Kyber.shamrock : UIColor.clear,
        width: 2,
        radius: 4.0
      )
    }
    self.noDataLabel.text = "\(NSLocalizedString("updating.data", value: "Updating data", comment: "")) ..."
    self.reloadViewDataDidUpdate(isReloading: true)
    self.startTimer()
  }

  @objc func openTokenOnEtherscanPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "chart_token_tapped", customAttributes: nil)
    self.delegate?.tokenChartViewController(self, run: .openEtherscan(token: self.viewModel.token))
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "chart_token_tapped", customAttributes: nil)
    self.delegate?.tokenChartViewController(self, run: .back)
  }

  @IBAction func actionButtonDidPress(_ sender: UIButton) {
    if !self.viewModel.isTokenSupported {
      KNCrashlyticsUtil.logCustomEvent(withName: "chart_send_tapped", customAttributes: ["token": self.viewModel.token.symbol])
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
      return
    }
    if sender.tag == 0 {
      KNCrashlyticsUtil.logCustomEvent(withName: "chart_buy", customAttributes: ["token_pair_rate_change": self.viewModel.rateChangeString])
      self.delegate?.tokenChartViewController(self, run: .buy(token: self.viewModel.token))
    } else if sender.tag == 1 {
       KNCrashlyticsUtil.logCustomEvent(withName: "chart_sell", customAttributes: ["token_pair_rate_change": self.viewModel.rateChangeString])
      self.delegate?.tokenChartViewController(self, run: .sell(token: self.viewModel.token))
    } else {
      KNCrashlyticsUtil.logCustomEvent(withName: "chart_transfer", customAttributes: ["token_pair_rate_change": self.viewModel.rateChangeString])
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
    }
  }

  @IBAction func dataTypeDidChange(_ sender: UIButton) {
    let type = KNTokenChartType(rawValue: sender.tag) ?? .day
    self.updateDisplayDataType(type)
    KNCrashlyticsUtil.logCustomEvent(withName: "chart_time_frame", customAttributes: ["time": type.displayString()])
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
  }

  @IBAction func priceAlertButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "chart_alert", customAttributes: ["token_name": self.viewModel.token.name])
    self.delegate?.tokenChartViewController(self, run: .addNewAlert(token: self.viewModel.token))
  }

  fileprivate func shouldUpdateData(for type: KNTokenChartType, token: TokenObject) {
    self.noDataLabel.text = "\(NSLocalizedString("updating.data", value: "Updating data", comment: ""))..."
    self.noDataLabel.addLetterSpacing()
    self.viewModel.fetchNewData(
      for: self.viewModel.token,
      type: self.viewModel.type) { [weak self] result in
        switch result {
        case .success(let isSuccess):
          if isSuccess {
            self?.reloadViewDataDidUpdate()
          } else {
            self?.noDataLabel.text = NSLocalizedString("can.not.update.data", value: "Can not update data", comment: "")
          }
        case .failure:
          self?.noDataLabel.text = NSLocalizedString("can.not.update.data", value: "Can not update data", comment: "")
        }
        self?.noDataLabel.addLetterSpacing()
    }
    self.viewModel.fetch24hVolume(for: self.viewModel.token) { [weak self] _ in
      self?.reloadViewDataDidUpdate(isReloading: true)
    }
  }

  fileprivate func updateChartXAxisFormater(for type: KNTokenChartType, data: [KNChartObject]) {
    guard let formatter = self.chartView.xAxis.valueFormatter as? CustomAxisValueFormatter else {
      return
    }
    guard let first = self.viewModel.data.first else {
      return
    }
    formatter.update(type: type, origin: first)
  }

  fileprivate func startTimer() {
    self.stopTimer()
    // Immediately call fetch data
    self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 60,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
      }
    )
  }

  fileprivate func stopTimer() {
    self.timer?.invalidate()
  }

  fileprivate func reloadViewDataDidUpdate(isReloading: Bool = false) {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    if self.viewModel.data.isEmpty {
      if !isReloading {
        self.noDataLabel.text = NSLocalizedString("no.data.for.this.token", value: "There is no data for this token", comment: "")
      }
      self.noDataLabel.isHidden = false
      self.noDataLabel.addLetterSpacing()
      self.chartView.isHidden = true
    } else {
      self.touchPriceLabel.isHidden = true
      self.noDataLabel.isHidden = true
      self.chartView.clear()
      self.chartView.rightAxis.removeAllLimitLines()
      self.updateChartXAxisFormater(for: self.viewModel.type, data: self.viewModel.data)
      self.chartView.isHidden = false
      self.chartView.data = self.viewModel.displayChartData
      self.addChartLimitLines()
      self.updateChartInfoLabel()
      if self.viewModel.type == .day || self.viewModel.type == .week || self.viewModel.type == .month {
        self.chartView.zoomAndCenterViewAnimated(scaleX: self.viewModel.scaleXFactor, scaleY: 1, xValue: self.chartView.highestVisibleX, yValue: 1, axis: .right, duration: 1)
      } else {
        self.chartView.zoomAndCenterViewAnimated(scaleX: 1, scaleY: 1, xValue: 1, yValue: 1, axis: .right, duration: 1)
      }
      self.chartView.setNeedsLayout()
    }
    self.view.layoutIfNeeded()
  }

  func addChartLimitLines() {
    let maxHigh = self.viewModel.data.map { $0.high }.max()
    let minLow = self.viewModel.data.map { $0.low }.min()
    guard let lower = minLow, let upper = maxHigh else {
      return
    }
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    let displayUpper = formatter.string(from: NSNumber(value: upper)) ?? ""
    let ll1 = ChartLimitLine(limit: upper, label: "\u{2192}\(displayUpper)")
    ll1.lineColor = UIColor.Kyber.orangeDarker
    ll1.valueTextColor = UIColor.Kyber.orangeDarker
    ll1.lineWidth = 1
    ll1.lineDashLengths = [5, 5]
    ll1.labelPosition = .topRight
    ll1.valueFont = UIFont.Kyber.bold(with: 9)

    let displayLower = formatter.string(from: NSNumber(value: lower)) ?? ""
    let ll2 = ChartLimitLine(limit: lower, label: "\u{2192}\(displayLower)")
    ll2.lineColor = UIColor.Kyber.orangeDarker
    ll2.valueTextColor = UIColor.Kyber.orangeDarker
    ll2.lineWidth = 1
    ll2.lineDashLengths = [5, 5]
    ll2.labelPosition = .bottomRight
    ll2.valueFont = UIFont.Kyber.bold(with: 9)
    self.chartView.rightAxis.addLimitLine(ll1)
    self.chartView.rightAxis.addLimitLine(ll2)
  }

  func coordinatorUpdateRate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()
  }

  fileprivate func updateChartInfoLabel() {
    guard let last = self.viewModel.data.last else {
      return
    }
    guard let first = self.viewModel.data.first else {
      return
    }
    let time = Double(last.time - first.time) / self.viewModel.type.scaleUnit
    let detailText = self.buildTextForData(openNumber: last.open,
                                           highNumber: last.high,
                                           lowNumber: last.low,
                                           closeNumber: last.close,
                                           timeStampNumber: time)
    self.touchPriceLabel.attributedText = detailText
    self.touchPriceLabel.isHidden = false
  }

  func coordinatorUpdateBalance(balance: [String: Balance]) {
    let bal: BigInt = {
      if self.viewModel.chartDataLO == nil {
        // normal chart opens from Balance tab
        return balance[self.viewModel.token.contract]?.value ?? BigInt(0)
      }
      if self.viewModel.token.isETH || self.viewModel.token.isWETH {
        let firstBal = balance[self.viewModel.token.contract]?.value ?? BigInt(0)
        let secondBal: BigInt = {
          if let token = self.viewModel.token.isETH ?
            KNSupportedTokenStorage.shared.supportedTokens.first(where: { return $0.isWETH }) :
            KNSupportedTokenStorage.shared.supportedTokens.first(where: { return $0.isETH }) {
            return balance[token.contract]?.value ?? BigInt(0)
          }
          return BigInt(0)
        }()
        return firstBal + secondBal
      }
      return balance[self.viewModel.token.contract]?.value ?? BigInt(0)
    }()
    self.viewModel.updateBalance(bal)
    self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
    self.totalValueLabel.text = self.viewModel.totalValueString
    self.totalValueLabel.addLetterSpacing()
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()
  }

  func coordinatorUpdatePendingBalance(balance: BigInt) {
    self.viewModel.updatePendingBalance(balance)
    self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
    self.totalValueLabel.text = self.viewModel.totalValueString
    self.totalValueLabel.addLetterSpacing()
    self.totalUSDValueLabel.text = self.viewModel.displayTotalUSDAmount
    self.totalUSDValueLabel.addLetterSpacing()
  }

  func coordinatorUpdateMarketPair(market: KNMarket) {
    self.viewModel.updateMarket(market)
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
  }

  fileprivate func buildTextForData(openNumber: Double, highNumber: Double, lowNumber: Double, closeNumber: Double, timeStampNumber: Double) -> NSAttributedString {
    guard let first = self.viewModel.data.first else {
      return NSAttributedString()
    }
    let attributedText = NSMutableAttributedString()
    let formatter = NumberFormatterUtil.shared.doubleFormatter
    let open = formatter.string(from: NSNumber(value: openNumber)) ?? ""
    let high = formatter.string(from: NSNumber(value: highNumber)) ?? ""
    let close = formatter.string(from: NSNumber(value: closeNumber)) ?? ""
    let low = formatter.string(from: NSNumber(value: lowNumber)) ?? ""
    let timeStamp = timeStampNumber * self.viewModel.type.scaleUnit + Double(first.time)
    let date = Date(timeIntervalSince1970: timeStamp)
    let dateString = DateFormatterUtil.shared.chartViewDateFormatter.string(from: date)
    let changeEntry = closeNumber - openNumber
    let change = formatter.string(from: NSNumber(value: changeEntry)) ?? ""
    let percentEntry = changeEntry / openNumber * 100.0
    let percent = formatter.string(from: NSNumber(value: percentEntry)) ?? ""
    let dateAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.bold(with: 11),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    ]
    let titleAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 11),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.gray,
    ]
    let infoTextAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 11),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.orange,
    ]
    let downAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 11),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.red,
    ]
    let upAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 11),
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.green,
    ]
    let valueAttribute = changeEntry > 0 ? upAttributes : downAttributes
    attributedText.append(NSAttributedString(string: " O ", attributes: titleAttributes))
    attributedText.append(NSAttributedString(string: open, attributes: infoTextAttributes))
    attributedText.append(NSAttributedString(string: " H ", attributes: titleAttributes))
    attributedText.append(NSAttributedString(string: high, attributes: infoTextAttributes))
    attributedText.append(NSAttributedString(string: " L ", attributes: titleAttributes))
    attributedText.append(NSAttributedString(string: low, attributes: infoTextAttributes))
    attributedText.append(NSAttributedString(string: " C ", attributes: titleAttributes))
    attributedText.append(NSAttributedString(string: close, attributes: infoTextAttributes))
    attributedText.append(NSAttributedString(string: "\n\(dateString)", attributes: dateAttributes))
    attributedText.append(NSAttributedString(string: " \("Change".toBeLocalised()) ", attributes: titleAttributes))
    attributedText.append(NSAttributedString(string: "\(change) (\(percent)%)", attributes: valueAttribute))
    return attributedText
  }
}

extension KNTokenChartViewController: ChartViewDelegate {
  func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
    guard let candleStickEntry = entry as? CandleChartDataEntry else {
      return
    }
    if self.touchPriceLabel.isHidden {
      self.touchPriceLabel.isHidden = false
    }
    let detailText = self.buildTextForData(openNumber: candleStickEntry.open,
                                           highNumber: candleStickEntry.high,
                                           lowNumber: candleStickEntry.low,
                                           closeNumber: candleStickEntry.close,
                                           timeStampNumber: candleStickEntry.x)
    self.touchPriceLabel.attributedText = detailText
  }

  func chartViewDidEndPanning(_ chartView: ChartViewBase) {
    KNCrashlyticsUtil.logCustomEvent(withName: "chart_interact", customAttributes: nil)
  }
}
