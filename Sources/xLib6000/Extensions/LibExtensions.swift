//
//  LibExtensions.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

typealias NC                    = NotificationCenter

public typealias KeyValuesArray = [(key:String, value:String)]
public typealias ValuesArray    = [String]
public typealias StreamId       = UInt32
public typealias Handle         = UInt32
public typealias ObjectId       = UInt16

public let kControlMin = 0
public let kControlMax = 100
public let kMinPitch = 100
public let kMaxPitch = 6000
public let kMinWpm = 5
public let kMaxWpm = 60
public let kMinBreakInDelay = 0
public let kMaxBreakInDelay = 2_000

public let kMinApfQ = 0
public let kMaxApfQ = 33


public extension Date {
  
  /// Create a Date/Time in the local time zone
  ///
  /// - Returns: a DateTime string
  ///
  func currentTimeZoneDate() -> String {
    let dtf = DateFormatter()
    dtf.timeZone = TimeZone.current
    dtf.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    return dtf.string(from: self)
  }
}

public extension NotificationCenter {
  
  /// post a Notification by Name
  ///
  /// - Parameters:
  ///   - notification:   Notification Name
  ///   - object:         associated object
  ///
  class func post(_ name: String, object: Any?) {
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: name), object: object)
    
  }
  /// post a Notification by Type
  ///
  /// - Parameters:
  ///   - notification:   Notification Type
  ///   - object:         associated object
  ///
  class func post(_ notification: NotificationType, object: Any?) {
    NotificationCenter.default.post(name: Notification.Name(rawValue: notification.rawValue), object: object)
    
  }
  /// setup a Notification Observer by Name
  ///
  /// - Parameters:
  ///   - observer:       the object receiving Notifications
  ///   - selector:       a Selector to receive the Notification
  ///   - type:           Notification name
  ///   - object:         associated object (if any)
  ///
  class func makeObserver(_ observer: Any, with selector: Selector, of name: String, object: Any? = nil) {
    NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name), object: object)
  }
  /// setup a Notification Observer by Type
  ///
  /// - Parameters:
  ///   - observer:       the object receiving Notifications
  ///   - selector:       a Selector to receive the Notification
  ///   - type:           Notification type
  ///   - object:         associated object (if any)
  ///
  class func makeObserver(_ observer: Any, with selector: Selector, of type: NotificationType, object: Any? = nil) {
    NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: type.rawValue), object: object)
  }
  /// remove a Notification Observer by Type
  ///
  /// - Parameters:
  ///   - observer:       the object receiving Notifications
  ///   - type:           Notification type
  ///   - object:         associated object (if any)
  ///
  class func deleteObserver(_ observer: Any, of type: NotificationType, object: Any?) {
    NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: type.rawValue), object: object)
  }
}

public extension Sequence {
  
  /// Find an element in an array
  ///
  /// - Parameters:
  ///   - match:      comparison closure
  /// - Returns:      the element (or nil)
  ///
  func findElement(_ match:(Iterator.Element)->Bool) -> Iterator.Element? {
    
    for element in self where match(element) {
      return element
    }
    return nil
  }
}

public extension String {
  
  var bValue          : Bool            { (Int(self) ?? 0) == 1 ? true : false }
  var cgValue         : CGFloat         { CGFloat(self) }
  var dValue          : Double          { Double(self) ?? 0 }
  var fValue          : Float           { Float(self) ?? 0 }
  var handle          : Handle?         { self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16) }
  var iValue          : Int             { Int(self) ?? 0 }
  var list            : [String]        { self.components(separatedBy: ",") }
  var mhzToHz         : Hz              { Hz( (Double(self) ?? 0) * 1_000_000 ) }
  var objectId        : ObjectId?       { UInt16(self, radix: 10) }
  var sequenceNumber  : SequenceNumber  { UInt(self, radix: 10) ?? 0 }
  var streamId        : StreamId?       { self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16) }
  var trimmed         : String          { self.trimmingCharacters(in: CharacterSet.whitespaces) }
  var tValue          : Bool            { self.lowercased() == "true" ? true : false }
  var uValue          : UInt            { UInt(self) ?? 0 }
  var uValue32        : UInt32          { UInt32(self) ?? 0 }

  /// Replace spaces with a specified value
  ///
  /// - Parameters:
  ///   - value:      the String to replace spaces
  /// - Returns:      the adjusted String
  ///
  func replacingSpaces(with value: String = "\u{007F}") -> String {
    return self.replacingOccurrences(of: " ", with: value)
  }
  /// Parse a String of <key=value>'s separated by the given Delimiter
  ///
  /// - Parameters:
  ///   - delimiter:          the delimiter between key values (defaults to space)
  ///   - keysToLower:        convert all Keys to lower case (defaults to YES)
  ///   - valuesToLower:      convert all values to lower case (defaults to NO)
  /// - Returns:              a KeyValues array
  ///
  func keyValuesArray(delimiter: String = " ", keysToLower: Bool = true, valuesToLower: Bool = false) -> KeyValuesArray {
    var kvArray = KeyValuesArray()
    
    // split it into an array of <key=value> values
    let keyAndValues = self.components(separatedBy: delimiter)
    
    for index in 0..<keyAndValues.count {
      // separate each entry into a Key and a Value
      var kv = keyAndValues[index].components(separatedBy: "=")
      
      // when "delimiter" is last character there will be an empty entry, don't include it
      if kv[0] != "" {
        
        // if no "=", set value to empty String (helps with strings with a prefix to KeyValues)
        // make sure there are no whitespaces before or after the entries
        if kv.count == 1 {
          
          // remove leading & trailing whitespace
          kvArray.append( (kv[0].trimmingCharacters(in: NSCharacterSet.whitespaces),"") )
        }
        if kv.count == 2 {
          
          // lowercase as needed
          if keysToLower { kv[0] = kv[0].lowercased() }
          if valuesToLower { kv[1] = kv[1].lowercased() }
          
          // remove leading & trailing whitespace
          kvArray.append( (kv[0].trimmingCharacters(in: NSCharacterSet.whitespaces),kv[1].trimmingCharacters(in: NSCharacterSet.whitespaces)) )
        }
      }
    }
    return kvArray
  }
  /// Parse a String of <value>'s separated by the given Delimiter
  ///
  /// - Parameters:
  ///   - delimiter:          the delimiter between values (defaults to space)
  ///   - valuesToLower:      convert all values to lower case (defaults to NO)
  /// - Returns:              a values array
  ///
  func valuesArray(delimiter: String = " ", valuesToLower: Bool = false) -> ValuesArray {
    
    guard self != "" else {return [String]() }
    
    // split it into an array of <value> values, lowercase as needed
    var array = valuesToLower ? self.components(separatedBy: delimiter).map {$0.lowercased()} : self.components(separatedBy: delimiter)
    array = array.map { $0.trimmingCharacters(in: .whitespaces) }
    
    return array
  }
  /// Replace spaces and equal signs in a CWX Macro with alternate characters
  ///
  /// - Returns:      the String after processing
  ///
  func fix(spaceReplacement: String = "\u{007F}", equalsReplacement: String = "*") -> String {
    var newString: String = ""
    var quotes = false
    
    // We could have spaces inside quotes, so we have to convert them to something else for key/value parsing.
    // We could also have an equal sign '=' (for Prosign BT) inside the quotes, so we're converting to a '*' so that the split on "="
    // will still work.  This will prevent the character '*' from being stored in a macro.  Using the ascii byte for '=' will not work.
    for char in self {
      if char == "\"" {
        quotes = !quotes
        
      } else if char == " " && quotes {
        newString += spaceReplacement
        
      } else if char == "=" && quotes {
        newString += equalsReplacement
        
      } else {
        newString.append(char)
      }
    }
    return newString
  }
  /// Undo any changes made to a Cwx Macro string by the fix method    ///
  ///
  /// - Returns:          the String after undoing the fixString changes
  ///
  func unfix(spaceReplacement: String = "\u{007F}", equalsReplacement: String = "*") -> String {
    var newString: String = ""
    
    for char in self {
      
      if char == Character(spaceReplacement) {
        newString += " "
        
      } else if char == Character(equalsReplacement) {
        newString += "="
        
      } else {
        newString.append(char)
      }
    }
    return newString
  }
  /// Check if a String is a valid IP4 address
  ///
  /// - Returns:          the result of the check as Bool
  ///
  func isValidIP4() -> Bool {
    
    // check for 4 values separated by period
    let parts = self.components(separatedBy: ".")
    
    // convert each value to an Int
    #if swift(>=4.1)
      let nums = parts.compactMap { Int($0) }
    #else
      let nums = parts.flatMap { Int($0) }
    #endif
    
    // must have 4 values containing 4 numbers & 0 <= number < 256
    return parts.count == 4 && nums.count == 4 && nums.filter { $0 >= 0 && $0 < 256}.count == 4
  }
}

public extension Bool {
  
  var as1or0Int   : Int     { self ? 1 : 0 }
  var as1or0      : String  { self ? "1" : "0" }
  var asTrueFalse : String  { self ? "True" : "False" }
  var asTF        : String  { self ? "T" : "F" }
  var asOnOff     : String  { self ? "on" : "off" }
  var asPassFail  : String  { self ? "PASS" : "FAIL" }
  var asYesNo     : String  { self ? "YES" : "NO" }
}

public extension Float {
  /// Determine if a value is between two other values (inclusive)
  ///
  /// - Parameters:
  ///   - value1:     low value (may be + or -)
  ///   - value2:     high value (may be + or -)
  /// - Returns:      true - self within two values
  ///
  func within(_ value1: Float, _ value2: Float) -> Bool { (self >= value1) && (self <= value2) }
}

public extension Int {
  
  var hzToMhz     : String { String(format: "%02.6f", Float(self) / 1_000_000.0) }
  /// Determine if a value is between two other values (inclusive)
  ///
  /// - Parameters:
  ///   - value1:     low value (may be + or -)
  ///   - value2:     high value (may be + or -)
  /// - Returns:      true - self within two values
  ///
  func within(_ value1: Int, _ value2: Int) -> Bool { (self >= value1) && (self <= value2) }

  /// Force a value to be between two other values (inclusive)
  ///
  /// - Parameters:
  ///   - value1:     the Minimum
  ///   - value2:     the Maximum
  /// - Returns:      the coerced value
  ///
  func bound(_ value1: Int, _ value2: Int) -> Int {
    let newValue = self < value1 ? value1 : self
    return newValue > value2 ? value2 : newValue
  }

  func rangeCheck(_ range: ClosedRange<Int>) -> Int {
    
    if self < range.lowerBound { return range.lowerBound }
    if self > range.upperBound { return range.upperBound }
    return self
  }
}

public extension UInt {
  
  var hzToMhz : String { String(format: "%02.6f", Float(self) / 1_000_000.0) }
}

public extension UInt16 {
  
  var hex: String { return String(format: "0x%04X", self) }

  func toHex(_ format: String = "0x%04X") -> String { String(format: format, self) }
}
public extension UInt32 {
  
  var hex: String { return String(format: "0x%08X", self) }

  func toHex(_ format: String = "0x%08X") -> String { String(format: format, self) }
}

public extension CGFloat {
  
  /// Force a CGFloat to be within a min / max value range
  ///
  /// - Parameters:
  ///   - min:        min CGFloat value
  ///   - max:        max CGFloat value
  /// - Returns:      adjusted value
  ///
  func bracket(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
    
    var value = self
    if self < min { value = min }
    if self > max { value = max }
    return value
  }
  /// Create a CGFloat from a String
  ///
  /// - Parameters:
  ///   - string:     a String
  ///
  /// - Returns:      CGFloat value of String or 0
  ///
  init(_ string: String) {
    
    self = CGFloat(Float(string) ?? 0)
  }
  /// Format a String with the value of a CGFloat
  ///
  /// - Parameters:
  ///   - width:      number of digits before the decimal point
  ///   - precision:  number of digits after the decimal point
  ///   - divisor:    divisor
  /// - Returns:      a String representation of the CGFloat
  ///
  private func floatToString(width: Int, precision: Int, divisor: CGFloat) -> String {
    
    return String(format: "%\(width).\(precision)f", self / divisor)
  }
}

// ----------------------------------------------------------------------------

/// Struct to hold a Semantic Version number
///     with provision for a Build Number
///
public struct Version {
  var major     : Int = 1
  var minor     : Int = 0
  var patch     : Int = 0
  var build     : Int = 1

  public init(_ versionString: String = "1.0.0") {
    
    let components = versionString.components(separatedBy: ".")
    switch components.count {
    case 3:
      major = Int(components[0]) ?? 1
      minor = Int(components[1]) ?? 0
      patch = Int(components[2]) ?? 0
      build = 1
    case 4:
      major = Int(components[0]) ?? 1
      minor = Int(components[1]) ?? 0
      patch = Int(components[2]) ?? 0
      build = Int(components[3]) ?? 1
    default:
      major = 1
      minor = 0
      patch = 0
      build = 1
    }
  }
  
  public init() {
    // only useful for Apps & Frameworks (which have a Bundle), not Packages
    let versions = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    let build   = Bundle.main.infoDictionary![kCFBundleVersionKey as String] as! String
    self.init(versions + ".\(build)")
   }
  
  public var longString       : String  { "\(major).\(minor).\(patch) (\(build))" }
  public var string           : String  { "\(major).\(minor).\(patch)" }

  public var isV3             : Bool    { major >= 3 }
  public var isV2NewApi       : Bool    { major == 2 && minor >= 5 }
  public var isGreaterThanV22 : Bool    { major >= 2 && minor >= 2 }
  public var isV2             : Bool    { major == 2 && minor < 5 }
  public var isV1             : Bool    { major == 1 }
  
  public var isNewApi         : Bool    { isV3 || isV2NewApi }
  public var isOldApi         : Bool    { isV1 || isV2 }

  static func ==(lhs: Version, rhs: Version) -> Bool { lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch }
  
  static func <(lhs: Version, rhs: Version) -> Bool {
    
    switch (lhs, rhs) {
      
    case (let l, let r) where l == r: return false
    case (let l, let r) where l.major < r.major: return true
    case (let l, let r) where l.major == r.major && l.minor < r.minor: return true
    case (let l, let r) where l.major == r.major && l.minor == r.minor && l.patch < r.patch: return true
    default: return false
    }
  }
}

// ----------------------------------------------------------------------------

/// Create a String representing a Hex Dump of a UInt8 array
///
/// - Parameters:
///   - data:           an array of UInt8
///   - len:            the number of elements to be processed
/// - Returns:          a String
///
public func hexDump(data: [UInt8], len: Int) -> String {
  var string = ""
  for i in 1...len {
    string += String(format: "%02X", data[i-1]) + " "
    if (i % 8) == 0 { string += "  " }
    if (i % 16) == 0 { string += "\n" }
  }
  return string
}

/// Determine if status is for this client
///
/// - Parameters:
///   - properties:     a KeyValuesArray
///   - clientHandle:   the handle of ???
/// - Returns:          true if a mtch
///
public func isForThisClient(_ properties: KeyValuesArray, connectionHandle: Handle?) -> Bool {
  var clientHandle : Handle = 0
  
  guard connectionHandle != nil else { return false }
  
  // allow a Tester app to see all Streams
  guard Api.sharedInstance.testerModeEnabled == false else { return true }
  
  // find the handle property
  for property in properties.dropFirst(2) where property.key == "client_handle" {
    
    clientHandle = property.value.handle ?? 0
  }
  return clientHandle == connectionHandle
}


@propertyWrapper
/// Protect a property using a concurrent queue and a barrier for writes
///
public struct Barrier<Element> {
  private var _value      : Element

  public var wrappedValue: Element {
    get { Api.objectQ.sync { _value }}
    set { Api.objectQ.sync(flags: .barrier) { _value = newValue }}
  }
  
  public init(wrappedValue: Element) {
    _value = wrappedValue
  }
}

@propertyWrapper
/// Protect a property using a concurrent queue and a barrier for writes
///     while limiting its value to arange
///
struct BarrierClamped<Element: Comparable> {
  private var _value      : Element
  private let _q          : DispatchQueue
  private let _range      : ClosedRange<Element>
  
  var wrappedValue: Element {
    get { _q.sync { _value }}
    set { Api.objectQ.sync(flags: .barrier) { _value = min( max(_range.lowerBound, newValue), _range.upperBound) }}
  }
  
  init(_ value: Element, _ queue: DispatchQueue, range: ClosedRange<Element>) {

    _q = queue
    _range = range
    _value = min( max(_range.lowerBound, value), _range.upperBound)
  }
}

/// Function to change a value and signal KVO
///
//func update<S:NSObject, T>(_ object: S, _ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<S,T>) {
//  object.willChangeValue(for: keyPath)
//  property.pointee = value
//  object.didChangeValue(for: keyPath)
//}

/// Compare the properties of two instances of the same class
/// - Parameters:
///   - lhs:          one instance
///   - rhs:          another instance
///   - ignoring:     property names to ignore
///
public func compare<T>(_ a: T, to b: T, ignoring: [String] ) {
  
  func printProperty(_ label: String, _ bValue: Any, _ aValue: Any) {
    Swift.print(label.padding(toLength: 25, withPad: " ", startingAt: 0) + ": " + "\(aValue)".padding(toLength: 25, withPad: " ", startingAt: 0) + " -> " +  "\(bValue)".padding(toLength: 25, withPad: " ", startingAt: 0))
  }
  
  for aProperty in Mirror(reflecting: a).children {
    
    if !ignoring.contains( aProperty.label!) {
      
      for bProperty in Mirror(reflecting: b).children where bProperty.label == aProperty.label {
        
        if let value = bProperty.value as? String {
          if value != aProperty.value as? String { printProperty(aProperty.label!, bProperty.value, aProperty.value) }
          
        } else if let value = bProperty.value as? Int {
          if value != aProperty.value as? Int { printProperty(aProperty.label!, bProperty.value, aProperty.value) }
          
        } else if let value = bProperty.value as? Float {
            if value != aProperty.value as? Float { printProperty(aProperty.label!, bProperty.value, aProperty.value) }
            
        } else if let value = bProperty.value as? Bool {
          if value != aProperty.value as? Bool { printProperty(aProperty.label!, bProperty.value, aProperty.value) }
          
        } else if let value = bProperty.value as? Date {
          if value != aProperty.value as? Date { printProperty(aProperty.label!, bProperty.value, aProperty.value) }
          
        } else {
          Swift.print("aProperty.label >\(aProperty.label!)< has unknown type")
        }
      }
    }
  }
}
