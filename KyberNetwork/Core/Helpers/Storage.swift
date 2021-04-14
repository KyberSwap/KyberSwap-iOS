//
//  Storage.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/20/21.
//

import Foundation

class Storage {
  static func getDocumentsDirectory() -> URL {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      return paths[0]
  }

  static func retrieve<T: Decodable>(_ fileName: String, as type: T.Type) -> T? {
    let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
    if !FileManager.default.fileExists(atPath: url.path) {
      return nil
    }

    if let data = FileManager.default.contents(atPath: url.path) {
      let decoder = JSONDecoder()
      do {
        let model = try decoder.decode(type, from: data)
        return model
      } catch {
        return nil
      }
    } else {
      return nil
    }
  }

  static func store<T: Encodable>(_ object: T, as fileName: String) {
    let url = getDocumentsDirectory().appendingPathComponent(fileName, isDirectory: false)
    
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(object)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
    } catch {
      print(error.localizedDescription)
    }
  }
}
