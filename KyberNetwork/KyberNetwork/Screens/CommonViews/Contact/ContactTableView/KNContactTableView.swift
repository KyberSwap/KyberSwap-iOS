// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNContactTableViewEvent {
  case select(contact: KNContact)
  case send(address: String)
  case delete(contact: KNContact)
  case edit(contact: KNContact)
  case update(height: CGFloat)
  case copiedAddress
}

protocol KNContactTableViewDelegate: class {
  func contactTableView(_ tableView: UITableView, run event: KNContactTableViewEvent)
}

class KNContactTableView: XibLoaderView {

  let kContactTableViewCellID: String = "kContactTableViewCellID"
  @IBOutlet weak var tableView: UITableView!

  fileprivate var contacts: [KNContact] = []
  fileprivate var isFull: Bool = false

  weak var delegate: KNContactTableViewDelegate?
  fileprivate var longPressTimer: Timer?

  deinit {
    self.removeNotificationObserve()
  }

  override func commonInit() {
    super.commonInit()
    let nib = UINib(nibName: KNContactTableViewCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: kContactTableViewCellID)
    self.tableView.rowHeight = KNContactTableViewCell.height
    self.tableView.delegate = self
    self.tableView.dataSource = self

    let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressedContactTableView(_:)))
    self.tableView.addGestureRecognizer(longPressGesture)
    self.tableView.isUserInteractionEnabled = true

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.shouldUpdateContacts(_:)),
      name: NSNotification.Name(rawValue: kUpdateListContactNotificationKey),
      object: nil
    )
  }

  func removeNotificationObserve() {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kUpdateListContactNotificationKey),
      object: nil
    )
  }

  func updateScrolling(isEnabled: Bool) {
    self.tableView.isScrollEnabled = isEnabled
    self.tableView.showsVerticalScrollIndicator = isEnabled
    self.tableView.showsHorizontalScrollIndicator = isEnabled
  }

  @objc func shouldUpdateContacts(_ sender: Notification?) {
    self.updateView(with: KNContactStorage.shared.contacts, isFull: self.isFull)
  }

  @objc func handleLongPressedContactTableView(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] _ in
            guard let strongSelf = self else { return }
            let touch = sender.location(in: strongSelf.tableView)
            guard let indexPath = strongSelf.tableView.indexPathForRow(at: touch) else { return }
            if indexPath.row >= strongSelf.contacts.count { return }
            let contact = strongSelf.contacts[indexPath.row]
            UIPasteboard.general.string = contact.address
            strongSelf.delegate?.contactTableView(strongSelf.tableView, run: .copiedAddress)
            strongSelf.longPressTimer?.invalidate()
            strongSelf.longPressTimer = nil
        })
    }
    if sender.state == .ended {
        if longPressTimer != nil {
            longPressTimer?.fire()
        }
    }
  }

  func updateView(with contacts: [KNContact], isFull: Bool = false) {
    self.isFull = isFull
    self.contacts = isFull ? contacts : Array(contacts.prefix(2))
    self.tableView.reloadData()
    self.delegate?.contactTableView(
      self.tableView,
      run: .update(height: self.tableView.rowHeight * CGFloat(self.contacts.count))
    )
  }
}

extension KNContactTableView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.delegate?.contactTableView(
      tableView,
      run: .select(contact: self.contacts[indexPath.row])
    )
  }
}

extension KNContactTableView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.contacts.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath) as! KNContactTableViewCell
    let contact: KNContact = self.contacts[indexPath.row]
    let viewModel = KNContactTableViewCellModel(
      contact: contact,
      index: isFull ? indexPath.row : 0
    )
    cell.update(with: viewModel)
    return cell
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let send = UITableViewRowAction(style: .normal, title: NSLocalizedString("transfer", value: "Transfer", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .send(address: self.contacts[indexPath.row].address)
      )
    }
    send.backgroundColor = UIColor.Kyber.shamrock
    let edit = UITableViewRowAction(style: .normal, title: NSLocalizedString("edit", value: "Edit", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .edit(contact: self.contacts[indexPath.row])
      )
    }
    edit.backgroundColor = UIColor.Kyber.blueGreen
    let delete = UITableViewRowAction(style: .destructive, title: NSLocalizedString("delete", value: "Delete", comment: "")) { (_, _) in
      self.delegate?.contactTableView(
        tableView,
        run: .delete(contact: self.contacts[indexPath.row])
      )
    }
    delete.backgroundColor = UIColor.Kyber.strawberry
    return [delete, edit, send]
  }
}
