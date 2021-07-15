// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import SwipeCellKit

enum KNContactTableViewEvent {
  case select(contact: KNContact)
  case send(address: String)
  case delete(contact: KNContact)
  case edit(contact: KNContact)
  case update(height: CGFloat)
  case copiedAddress
  case addContact
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

    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 156))
    containerView.backgroundColor = UIColor.clear
    let button = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 36))
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle(
      NSLocalizedString("add.contact", value: "Add Contact", comment: ""),
      for: .normal
    )
    button.titleLabel?.font = UIFont.Kyber.bold(with: 14)
    button.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
    button.setImage(UIImage(named: "add_blue_icon"), for: .normal)
    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
    button.tintColor = UIColor(named: "normalTextColor")
    containerView.addSubview(button)
    let contraints = [
      button.widthAnchor.constraint(equalToConstant: 150),
      button.heightAnchor.constraint(equalToConstant: 36),
      button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ]
    NSLayoutConstraint.activate(contraints)
    button.rounded(color: UIColor(named: "normalTextColor")!, width: 1, radius: button.frame.size.height / 2)
    button.addTarget(self, action: #selector(addContactTapped(_:)), for: .touchUpInside)
    self.tableView.tableFooterView = containerView
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

  @objc func addContactTapped(_ sender: UIButton) {
    self.delegate?.contactTableView(
      self.tableView,
      run: .addContact
    )
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

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kContactTableViewCellID, for: indexPath) as! KNContactTableViewCell
    cell.delegate = self
    let contact: KNContact = self.contacts[indexPath.row]
    let viewModel = KNContactTableViewCellModel(
      contact: contact,
      index: isFull ? indexPath.row : 0
    )
    cell.update(with: viewModel)
    return cell
  }
}

extension KNContactTableView: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard orientation == .right else { return nil }
    let bgImg = UIImage(named: "history_cell_edit_bg")!
    let resized = bgImg.resizeImage(to: CGSize(width: 1000, height: 60))!

    let transfer = SwipeAction(style: .default, title: nil) { (_, idx) in
      self.delegate?.contactTableView(
        tableView,
        run: .send(address: self.contacts[idx.row].address)
      )
    }
    transfer.hidesWhenSelected = true
    transfer.title = "transfer".toBeLocalised().uppercased()
    transfer.textColor = UIColor(named: "normalTextColor")
    transfer.font = UIFont.Kyber.medium(with: 12)
    transfer.backgroundColor = UIColor(patternImage: resized)

    let edit = SwipeAction(style: .default, title: nil) { (_, idx) in
      self.delegate?.contactTableView(
        tableView,
        run: .edit(contact: self.contacts[idx.row])
      )
    }
    edit.hidesWhenSelected = true
    edit.title = "edit".toBeLocalised().uppercased()
    edit.textColor = UIColor(named: "normalTextColor")
    edit.font = UIFont.Kyber.medium(with: 12)
    edit.backgroundColor = UIColor(patternImage: resized)

    let delete = SwipeAction(style: .default, title: nil) { (_, idx) in
      self.delegate?.contactTableView(
        tableView,
        run: .delete(contact: self.contacts[idx.row])
      )
    }
    delete.hidesWhenSelected = true
    delete.title = "delete".toBeLocalised().uppercased()
    delete.textColor = UIColor(named: "normalTextColor")
    delete.font = UIFont.Kyber.medium(with: 12)
    delete.backgroundColor = UIColor(patternImage: resized)
    return [delete, edit, transfer]
  }

  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
