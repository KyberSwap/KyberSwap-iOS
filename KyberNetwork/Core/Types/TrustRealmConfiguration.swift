// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import TrustKeystore
import TrustCore

struct RealmConfiguration {

    static func configuration(for account: Wallet, chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
        return RealmConfiguration.configuration(
          for: account.address.description,
          chainID: chainID
        )
    }

    static func configuration(for address: String, chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("\(address.lowercased())-\(chainID).realm")
      config.schemaVersion = 1
      config.migrationBlock = { migration, oldVersion in
        migration.enumerateObjects(ofType: "Transaction") { (_, new) in
          new?["internalType"] = TransactionType.normal.rawValue
        }
        migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
          new?["internalType"] = TransactionType.normal.rawValue
        }
      }
      return config
    }

    static func globalConfiguration(for chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
      var config = Realm.Configuration()
      config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-global-\(chainID).realm")
      config.schemaVersion = 1
      config.migrationBlock = { migration, oldVersion in
        migration.enumerateObjects(ofType: "Transaction") { (_, new) in
          new?["internalType"] = TransactionType.normal.rawValue
        }
        migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
          new?["internalType"] = TransactionType.normal.rawValue
        }
      }
      return config
    }

  static func kyberGOConfiguration(for userID: Int, chainID: Int = KNEnvironment.default.chainID) -> Realm.Configuration {
    var config = Realm.Configuration()
    config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("kybernetworkwallet-kybergo-\(userID)-\(chainID).realm")
    config.schemaVersion = 1
    config.migrationBlock = { migration, oldVersion in
      migration.enumerateObjects(ofType: "Transaction") { (_, new) in
        new?["internalType"] = TransactionType.normal.rawValue
      }
      migration.enumerateObjects(ofType: "KNTransaction") { (_, new) in
        new?["internalType"] = TransactionType.normal.rawValue
      }
    }
    return config
  }
}
