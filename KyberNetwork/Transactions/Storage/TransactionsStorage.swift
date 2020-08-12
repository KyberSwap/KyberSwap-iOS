// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import TrustKeystore
import TrustCore

class TransactionsStorage {

    let realm: Realm

    init(
        realm: Realm
    ) {
        self.realm = realm
    }

    var count: Int {
        return objects.count
    }

    var objects: [Transaction] {
      if realm.objects(Transaction.self).isInvalidated { return [] }
      let data: [Transaction] = realm.objects(Transaction.self)
            .filter { !$0.id.isEmpty }
      return data.sorted(by: { (tx0, tx1) -> Bool in
        return tx0.date > tx1.date
      })
    }

    var completedObjects: [Transaction] {
        return objects.filter { $0.state == .completed }
    }

    var pendingObjects: [Transaction] {
        return objects.filter { $0.state == TransactionState.pending }
    }

    func get(forPrimaryKey: String) -> Transaction? {
        return realm.object(ofType: Transaction.self, forPrimaryKey: forPrimaryKey)
    }

    @discardableResult
    func add(_ items: [Transaction]) -> [Transaction] {
        realm.beginWrite()
        realm.add(items, update: .modified)
        try! realm.commitWrite()
        self.deleteOutOfDateTransactionIfNeeded()
        return items
    }

    func delete(_ items: [Transaction]) {
        try! realm.write {
            realm.delete(items)
        }
    }

    @discardableResult
    func update(state: TransactionState, for transaction: Transaction) -> Transaction {
        realm.beginWrite()
        transaction.internalState = state.rawValue
        try! realm.commitWrite()
        return transaction
    }

    func removeTransactions(for states: [TransactionState]) {
        if realm.objects(Transaction.self).isInvalidated { return }
        let objects = realm.objects(Transaction.self).filter { states.contains($0.state) }
        try! realm.write {
            realm.delete(objects)
        }
    }

    func deleteAll() {
      self.deleteAllTransactions()
      self.deleteAllTokenTransactions()
      self.deleteAllHistoryTransactions()
      self.deleteAllKyberTransactions()
    }

    func deleteAllTransactions() {
      if realm.objects(Transaction.self).isInvalidated { return }
      try! realm.write {
        realm.delete(realm.objects(Transaction.self))
      }
    }

    func deleteOutOfDateTransactionIfNeeded() {
      if self.transferNonePendingObjects.count > Constants.klimitNumberOfTransactionInDB {
        let sortedTxObjects = self.transferNonePendingObjects.sorted { (left, right) -> Bool in
          return left.date > right.date
        }
        let suffixedObject = sortedTxObjects.suffix(from: Constants.klimitNumberOfTransactionInDB)
        self.delete(Array(suffixedObject))
      }
    }
}
