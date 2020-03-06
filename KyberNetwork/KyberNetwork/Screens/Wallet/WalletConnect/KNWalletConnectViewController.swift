// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import WalletConnect
import BigInt
import QRCodeReaderViewController
import Starscream

class KNWalletConnectViewController: KNBaseViewController {

  let kTransferPrefix = "a9059cbb"
  let kApprovePrefix = "095ea7b3"
  let kTradeWithHintPrefix = "29589f61"

  let clientMeta = WCPeerMeta(name: "WalletConnect SDK", url: "https://github.com/TrustWallet/wallet-connect-swift")
  fileprivate var wcSession: WCSession
  let knSession: KNSession
  fileprivate var interactor: WCInteractor?
  fileprivate var shouldRecover: Bool = false
  fileprivate var isShowLoading: Bool = false

  private var backgroundTaskId: UIBackgroundTaskIdentifier?
  private weak var backgroundTimer: Timer?

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var logoImageView: UIImageView!
  @IBOutlet weak var nameTextLabel: UILabel!
  @IBOutlet weak var connectionStatusLabel: UILabel!

  @IBOutlet weak var connectedToTextLabel: UILabel!
  @IBOutlet weak var urlLabel: UILabel!
  @IBOutlet weak var addressTextLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!

  init(wcSession: WCSession, knSession: KNSession) {
    self.wcSession = wcSession
    self.knSession = knSession
    super.init(nibName: KNWalletConnectViewController.className, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    let address = self.knSession.wallet.address.description
    self.addressLabel.text = "\(address.prefix(12))...\(address.suffix(10))"
    self.urlLabel.text = ""
    self.connectionStatusLabel.text = ""
    self.connect(session: self.wcSession)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.interactor?.killSession().cauterize()
    self.shouldRecover = false
  }

  //swiftlint:disable function_body_length
  func connect(session: WCSession) {
    if !self.isShowLoading {
      self.displayLoading(text: "Connecting...", animated: true)
      self.isShowLoading = true
    }
    let interactor = WCInteractor(session: self.wcSession, meta: self.clientMeta, uuid: UIDevice.current.identifierForVendor ?? UUID())
    if interactor.state == .connected {
      self.interactor?.killSession().cauterize()
      self.interactor?.disconnect()
    }
    let accounts = [self.knSession.wallet.address.description]
    let chainId = KNEnvironment.default.chainID

    interactor.killSession().cauterize()

    interactor.onError = { [weak self] error in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "connection_error"])
      let alert = UIAlertController(title: "Error", message: "Do you want to re-connect?", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Reconnect", style: .default, handler: { _ in
        guard let session = self?.wcSession else { return }
        self?.connect(session: session)
      }))
      alert.addAction(UIAlertAction(title: "Scan QR Code", style: .default, handler: { action in
        self?.scanQRCodeButtonPressed(action)
      }))
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      self?.present(alert, animated: true, completion: nil)
    }

    interactor.onSessionRequest = { [weak self] (id, peerParam) in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      let peer = peerParam.peerMeta
      let message = [peer.description, peer.url].joined(separator: "\n")
      self?.nameTextLabel.text = peer.name
      self?.urlLabel.text = peer.url
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "connected_\(peer.url)"])
      self?.logoImageView.setImage(with: peer.icons.first ?? "", placeholder: nil)
      let alert = UIAlertController(title: peer.name, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "reject_\(peer.url)"])
        self?.interactor?.rejectSession().cauterize()
        self?.interactor?.killSession().cauterize()
        self?.shouldRecover = false
      }))
      alert.addAction(UIAlertAction(title: "Approve", style: .default, handler: { _ in
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "approved_\(peer.url)"])
        self?.interactor?.approveSession(accounts: accounts, chainId: chainId).cauterize()
      }))
      self?.show(alert, sender: nil)
    }

    interactor.onDisconnect = { [weak self] (error) in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "disconnect"])
      self?.connectionStatusUpdated(self?.interactor?.state == .connected)
      guard let err = error as? WSError, err.code == 1000 else {
        if self?.shouldRecover == true {
          self?.reconnectIfNeeded(nil)
        }
        return
      }
      self?.interactor?.killSession().cauterize()
      self?.shouldRecover = false
    }

    interactor.eth.onSign = { [weak self] (id, payload) in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "sign_data"])
      let alert = UIAlertController(title: "Sign data".toBeLocalised(), message: payload.message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "sign_data_reject"])
        self?.interactor?.rejectRequest(id: id, message: "User canceled").cauterize()
      }))
      alert.addAction(UIAlertAction(title: "Sign", style: .default, handler: { _ in
        KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "sign_data_approved"])
        self?.signEth(id: id, payload: payload)
      }))
      self?.present(alert, animated: true, completion: nil)
    }

    interactor.eth.onTransaction = { [weak self] (id, event, transaction) in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "transaction"])
      let data = try! JSONEncoder().encode(transaction)
      self?.sendTransaction(id, data: data)
    }

    interactor.connect().done { [weak self] connected in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      self?.connectionStatusUpdated(connected)
    }.catch { [weak self] error in
      if self?.isShowLoading == true {
        self?.isShowLoading = false
        self?.hideLoading()
      }
      self?.displayError(error: error)
    }

    self.interactor = interactor
  }

  fileprivate func sendTransaction(_ id: Int64, data: Data) {
    guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? JSONDictionary, let json = jsonData else {
      return
    }
    guard let from = json["from"] as? String, let to = json["to"] as? String,
      let value = (json["value"] as? String ?? "").fullBigInt(decimals: 0),
      from.lowercased() == self.knSession.wallet.address.description.lowercased() else {
      return
    }

    let message: String = {
      if let msg = self.tryParseTransactionData(json) { return msg }
      if let networkProxy = KNEnvironment.default.knCustomRPC?.networkAddress.lowercased(),
        networkProxy == to.lowercased() {
        return "Interact with Kyber Network Proxy: transfer \(value.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)) ETH to \(to). Please check your transaction details carefully."
      }
      if let token = KNSupportedTokenStorage.shared.supportedTokens.first(where: { return $0.contract.lowercased() == to.lowercased() }) {
        if value.isZero { return "Interact with \(token.symbol) contract. Please check your transaction details carefully." }
        return "Interact with \(token.symbol): transfer \(value.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)) ETH to \(to). Please check your transaction details carefully."
      }
      return "Transfer \(value.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)) ETH to \(to). Please check your transaction details carefully."
    }()
    let alert = UIAlertController(title: "Approve transaction", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Reject", style: .destructive, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "transaction_rejected"])
      self.interactor?.rejectRequest(id: id, message: "User cancelled").cauterize()
    }))
    alert.addAction(UIAlertAction(title: "Approve", style: .default, handler: { _ in
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["action": "transaction_approved"])
      self.displayLoading(text: "Submitting...", animated: true)
      self.knSession.externalProvider.sendTxWalletConnect(txData: json) { [weak self] result in
        guard let `self` = self else { return }
        self.hideLoading()
        switch result {
        case .success(let txHash):
          if let txID = txHash {
            self.interactor?.approveRequest(id: id, result: txID).cauterize()
            self.addTransactionToPendingListIfNeeded(
              json: json,
              hash: txID,
              nonce: self.knSession.externalProvider.minTxCount - 1
            )
            self.showTopBannerView(with: "Broadcasted", message: "Your transaction has been broadcasted successfully!", time: 2.0) {
              self.openSafari(with: KNEnvironment.default.etherScanIOURLString + "tx/\(txID)")
            }
          } else {
            self.interactor?.rejectRequest(id: id, message: "Something went wrong, please try again").cauterize()
            self.showTopBannerView(with: "Error", message: "Something went wrong, please try again", time: 1.5)
          }
        case .failure(let error):
          self.interactor?.rejectRequest(id: id, message: error.prettyError).cauterize()
          self.displayError(error: error)
        }
      }
    }))
    self.present(alert, animated: true, completion: nil)
  }

  func approve(accounts: [String], chainId: Int) {
    self.interactor?.approveSession(accounts: accounts, chainId: chainId).done {
      print("<== approveSession done")
    }.catch { [weak self] error in
      self?.displayError(error: error)
    }
  }

  func signEth(id: Int64, payload: WCEthereumSignPayload) {
    let signData: Data = {
        switch payload {
        case .sign(let data, _):
            return data
        case .personalSign(let data, _):
            let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
            return prefix + data
        case .signTypeData(_, let data, _):
            return data
        }
    }()
    if case .real(let account) = self.knSession.wallet.type {
      self.displayLoading(text: "Signing...", animated: true)
      let result = self.knSession.keystore.signMessage(signData, for: account)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.hideLoading()
        switch result {
        case .success(let data):
          self.interactor?.approveRequest(id: id, result: data.hexEncoded).cauterize()
        case .failure(let error):
          self.interactor?.rejectRequest(id: id, message: error.prettyError).cauterize()
          self.displayError(error: error)
        }
      }
    }
  }

  func connectionStatusUpdated(_ connected: Bool) {
    self.connectionStatusLabel.text = connected ? "Online" : "Offline"
    self.connectionStatusLabel.textColor = connected ? UIColor.Kyber.green : UIColor.Kyber.red
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    if self.interactor?.state != .connected {
      self.dismiss(animated: true, completion: nil)
      return
    }

    let alert = UIAlertController(title: "Disconnect session?", message: "Do you want to disconnect this session?", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Disconnect", style: .default, handler: { _ in
      self.dismiss(animated: true, completion: nil)
    }))
    self.present(alert, animated: true, completion: nil)
  }

  @IBAction func scanQRCodeButtonPressed(_ sender: Any) {
    if interactor?.state == .connected {
      let alert = UIAlertController(title: "Disconnect current session?", message: "Do you want to disconnect your current session and start a new one?", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
        self.interactor?.killSession().cauterize()
        self.interactor?.disconnect()
        let qrCode = QRCodeReaderViewController()
        qrCode.delegate = self
        self.present(qrCode, animated: true, completion: nil)
      }))
      self.present(alert, animated: true, completion: nil)
    } else {
      let qrCode = QRCodeReaderViewController()
      qrCode.delegate = self
      self.present(qrCode, animated: true, completion: nil)
    }
  }

  fileprivate func tryParseTransactionData(_ json: JSONDictionary) -> String? {
    let data = (json["data"] as? String ?? "").drop0x
    let to = (json["to"] as? String ?? "").lowercased()
    let value = (json["value"] as? String ?? "").fullBigInt(decimals: 0) ?? BigInt(0)
    if data.isEmpty {
      return "Transfer \(value.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)) ETH to \(to)"
    }
    if data.starts(with: kApprovePrefix),
      let token = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == to }) {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "transaction_type_approve"])
      let address = data.substring(to: 72).substring(from: 32).add0x.lowercased()
      let contractName: String = {
        if let networkAddr = KNEnvironment.default.knCustomRPC?.networkAddress, networkAddr.lowercased() == address {
          return "Kyber Network Proxy"
        }
        if let limitOrder = KNEnvironment.default.knCustomRPC?.limitOrderAddress, limitOrder.lowercased() == address {
          return "KyberSwap Limit Order"
        }
        return address
      }()
      return "You need to grant permission for \(contractName) to interact with \(token.symbol)"
    }
    if data.starts(with: kTransferPrefix),
      let token = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == to }) {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "transaction_type_transfer"])
      let address = data.substring(to: 72).substring(from: 32).add0x.lowercased()
      let amount = data.substring(from: 72).add0x.fullBigInt(decimals: 0) ?? BigInt(0)
      return "Transfer \(amount.string(decimals: token.decimals, minFractionDigits: 0, maxFractionDigits: min(token.decimals, 6))) \(token.symbol) to \(address)"
    }
    if data.starts(with: kTradeWithHintPrefix),
      let networkAddr = KNEnvironment.default.knCustomRPC?.networkAddress, networkAddr.lowercased() == to {
      KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "transaction_type_swap"])
      // swap
      let fromToken = data.substring(to: 8 + 64).substring(from: 8 + 24).add0x.lowercased()
      let fromAmount = data.substring(to: 8 + 64 * 2).substring(from: 8 + 64).add0x.fullBigInt(decimals: 0) ?? BigInt(0)
      let toToken = data.substring(to: 8 + 64 * 3).substring(from: 8 + 24 + 64 * 2).add0x.lowercased()
      guard let from = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == fromToken }),
        let to = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == toToken }) else {
          return nil
      }
      return "Swap \(fromAmount.string(decimals: from.decimals, minFractionDigits: 0, maxFractionDigits: min(6, from.decimals))) \(from.symbol) to \(to.symbol)"
    }
    KNCrashlyticsUtil.logCustomEvent(withName: "screen_wallet_connect", customAttributes: ["info": "transaction_type_unknown"])
    return nil
  }

  fileprivate func addTransactionToPendingListIfNeeded(json: JSONDictionary, hash: String, nonce: Int, type: TransactionType = .normal) {
    let data = (json["data"] as? String ?? "").drop0x
    let value = (json["value"] as? String ?? "").fullBigInt(decimals: 0) ?? BigInt(0)
    let gasLimit: String = {
      let gasBigInt = (json["gasLimit"] as? String ?? "").fullBigInt(decimals: 0) ?? BigInt(0)
      return gasBigInt.string(decimals: 0, minFractionDigits: 0, maxFractionDigits: 0).removeGroupSeparator()
    }()
    let gasPrice: String = {
      let gasBigInt = (json["gasPrice"] as? String ?? "").fullBigInt(decimals: 0) ?? BigInt(0)
      return gasBigInt.string(decimals: 0, minFractionDigits: 0, maxFractionDigits: 0).removeGroupSeparator()
    }()
    let to = (json["to"] as? String ?? "").lowercased()
    let from = json["from"] as? String ?? ""
    if data.isEmpty || data.starts(with: kTransferPrefix) {
      // transfer
      let (token, amount, toAddr): (TokenObject, BigInt, String) = {
        guard !data.isEmpty, let token = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == to }) else {
          return (KNSupportedTokenStorage.shared.ethToken, value, to)
        }
        let address = data.substring(to: 72).substring(from: 32).add0x.lowercased()
        let amount = data.substring(from: 72).add0x.fullBigInt(decimals: 0) ?? BigInt(0)
        return (token, amount, address)
      }()
      let localised = LocalizedOperationObject(
        from: token.contract,
        to: "",
        contract: nil,
        type: "transfer",
        value: amount.fullString(decimals: token.decimals),
        symbol: token.symbol,
        name: token.name,
        decimals: token.decimals
      )
      let tx = Transaction(
        id: hash,
        blockNumber: 0,
        from: from,
        to: toAddr,
        value: amount.fullString(decimals: token.decimals),
        gas: gasLimit,
        gasPrice: gasPrice,
        gasUsed: gasLimit,
        nonce: "\(nonce)",
        date: Date(),
        localizedOperations: [localised],
        state: .pending,
        type: type
      )
      self.knSession.addNewPendingTransaction(tx)
    } else if data.starts(with: kTradeWithHintPrefix) {
      // swap
      guard let networkAddr = KNEnvironment.default.knCustomRPC?.networkAddress, networkAddr.lowercased() == to else {
        return
      }
      // swap
      let fromToken = data.substring(to: 8 + 64).substring(from: 8 + 24).add0x.lowercased()
      let fromAmount = data.substring(to: 8 + 64 * 2).substring(from: 8 + 64).add0x.fullBigInt(decimals: 0) ?? BigInt(0)
      let toToken = data.substring(to: 8 + 64 * 3).substring(from: 8 + 24 + 64 * 2).add0x.lowercased()
      guard let tokenFrom = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == fromToken }),
        let tokenTo = self.knSession.tokenStorage.tokens.first(where: { return $0.contract.lowercased() == toToken }) else {
          return
      }
      let minRate: BigInt = {
        let rate = data.substring(to: 8 + 64 * 6).substring(from: 8 + 64 * 5).add0x
        return (rate.fullBigInt(decimals: 0) ?? BigInt(0)) / BigInt(10).power(18 - tokenTo.decimals)
      }()
      // expected min amount
      let expectedAmount = fromAmount * minRate / BigInt(10).power(tokenFrom.decimals)
      let localObject = LocalizedOperationObject(
        from: tokenFrom.contract,
        to: tokenTo.contract,
        contract: nil,
        type: "exchange",
        value: expectedAmount.fullString(decimals: tokenTo.decimals),
        symbol: tokenFrom.symbol,
        name: tokenTo.symbol,
        decimals: tokenTo.decimals
      )
      let tx = Transaction(
        id: hash,
        blockNumber: 0,
        from: from,
        to: to,
        value: fromAmount.fullString(decimals: tokenFrom.decimals),
        gas: gasLimit,
        gasPrice: gasPrice,
        gasUsed: gasLimit,
        nonce: "\(nonce)",
        date: Date(),
        localizedOperations: [localObject],
        state: .pending,
        type: type
      )
      self.knSession.addNewPendingTransaction(tx)
    }
  }

  @objc func reconnectIfNeeded(_ sender: Any?) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
      if self.interactor?.state == .connected { return }
      if !self.isShowLoading {
        self.isShowLoading = true
        self.displayLoading(text: "Connecting...", animated: true)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.interactor?.connect().done { [weak self] connected in
          if self?.isShowLoading == true {
            self?.isShowLoading = false
            self?.hideLoading()
          }
          self?.connectionStatusUpdated(connected)
        }.catch { [weak self] _ in
          if self?.isShowLoading == true {
            self?.isShowLoading = false
            self?.hideLoading()
          }
          self?.showAlertCannotReconnect()
        }
      }
    }
  }

  fileprivate func showAlertCannotReconnect() {
    let alert = UIAlertController(title: "Reconnect failed", message: "Do you want to reconnect again", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Reconnect", style: .default, handler: { _ in
      self.reconnectIfNeeded(nil)
    }))
    self.present(alert, animated: true, completion: nil)
  }
}

extension KNWalletConnectViewController {
  func applicationWillTerminate() {
    self.interactor?.killSession().cauterize()
  }

  func applicationDidEnterBackground() {
    if self.interactor?.state != .connected { return }
    self.interactor?.pause()
    self.shouldRecover = true
  }

  func applicationWillEnterForeground() {
    if !self.shouldRecover { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.reconnectIfNeeded(nil)
    }
  }
}

extension KNWalletConnectViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      guard let newSession = WCSession.from(string: result) else {
        self.showTopBannerView(
          with: "Invalid session".toBeLocalised(),
          message: "Your session is invalid, please try with another QR code".toBeLocalised(),
          time: 1.5
        )
        return
      }
      self.interactor?.killSession().cauterize()
      self.wcSession = newSession
      self.connect(session: newSession)
    }
  }
}
