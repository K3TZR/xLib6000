//
//  xLibClientExtensions.swift
//  xLibClient package
//
//  Created by Douglas Adams on 10/12/20.
//

import Foundation

extension String {
    var expandingTilde: String { NSString(string: self).expandingTildeInPath }
}

extension FileManager {
  
  /// Get / create the Application Support folder
  ///
  static var appFolder : URL {
    let fileManager = FileManager.default
    let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask )
    let appFolderUrl = urls.first!.appendingPathComponent( Bundle.main.bundleIdentifier! )
    
    // does the folder exist?
    if !fileManager.fileExists( atPath: appFolderUrl.path ) {
      
      // NO, create it
      do {
        try fileManager.createDirectory( at: appFolderUrl, withIntermediateDirectories: false, attributes: nil)
      } catch let error as NSError {
        fatalError("Error creating App Support folder: \(error.localizedDescription)")
      }
    }
    return appFolderUrl
  }
}

extension URL {
  
  /// setup the Support folders
  ///
  public static var appSupport : URL { return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first! }
  
  static func createLogFolder(domain: String, appName: String) -> URL {
    return createAsNeeded(domain + "." + appName + "/Logs")
  }
  
  static func createAsNeeded(_ folder: String) -> URL {
    let fileManager = FileManager.default
    let folderUrl = appSupport.appendingPathComponent( folder )
    
    // does the folder exist?
    if fileManager.fileExists( atPath: folderUrl.path ) == false {
      
      // NO, create it
      do {
        try fileManager.createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
      } catch let error as NSError {
        fatalError("Error creating App Support folder: \(error.localizedDescription)")
      }
    }
    return folderUrl
  }
}

extension String {
  
  /// Retrun a random collection of character as a String
  /// - Parameter length:     the desired number of characters
  /// - Returns:              a String of the requested length
  ///
  static func random(length:Int)->String{
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    var randomString = ""
    
    while randomString.utf8.count < length{
      let randomLetter = letters.randomElement()
      randomString += randomLetter?.description ?? ""
    }
    return randomString
  }
}

extension URLSession {
  //  Created by Mario Illgen on 11.02.18.
  //  Copyright © 2018 Mario Illgen. All rights reserved.
  //

  func synchronousDataTask(with urlRequest: URLRequest) -> (Data?, URLResponse?, Error?) {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let dataTask = self.dataTask(with: urlRequest) {
      data = $0
      response = $1
      error = $2
      
      semaphore.signal()
    }
    dataTask.resume()
    
    _ = semaphore.wait(timeout: .distantFuture)
    return (data, response, error)
  }
}

extension String {
  //  Created by Mario Illgen on 27.01.18.
  //  Copyright © 2018 Mario Illgen. All rights reserved.
  //

  var parametersFromQueryString: [String: String] {
    return dictionaryBySplitting("&", keyValueSeparator: "=")
  }
  
  /// Encodes url string making it ready to be passed as a query parameter. This encodes pretty much everything apart from
  /// alphanumerics and a few other characters compared to standard query encoding.
  var urlEncoded: String {
    let customAllowedSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
    return self.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
  }

  fileprivate func dictionaryBySplitting(_ elementSeparator: String, keyValueSeparator: String) -> [String: String] {
    var string = self
    var parameters = [String: String]()

    if hasPrefix(elementSeparator) { string = String(dropFirst(1)) }

    let properties = string.keyValuesArray(delimiter: elementSeparator)
    for property in properties {
      parameters[property.key] = property.value
    }
    return parameters
  }
}

//  Created by Mario Illgen on 27.01.18.
//  Copyright © 2018 Mario Illgen. All rights reserved.
//
func +=<K: RangeReplaceableCollection, V: RangeReplaceableCollection> (left: inout [K: V], right: [K: V]) { left.merge(right) }

extension Dictionary {
  //  Created by Mario Illgen on 27.01.18.
  //  Copyright © 2018 Mario Illgen. All rights reserved.
  //

  func join(_ other: Dictionary) -> Dictionary {
    var joinedDictionary = Dictionary()

    for (key, value) in self {
      joinedDictionary.updateValue(value, forKey: key)
    }

    for (key, value) in other {
      joinedDictionary.updateValue(value, forKey: key)
    }
    return joinedDictionary
  }
  
  mutating func merge<K, V>(_ dictionaries: Dictionary<K, V>...) {
    for dict in dictionaries {
      for (key, value) in dict {
        if let v = value as? Value, let k = key as? Key {
          self.updateValue(v, forKey: k)
        }
      }
    }
  }
}

