//
//  LibExtensions.swift
//  xLib6000
//
//  Created by Douglas Adams on 8/15/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

typealias NC = NotificationCenter

public typealias KeyValuesArray = [(key:String, value:String)]
public typealias ValuesArray = [String]
public typealias StreamId = UInt32
public typealias Handle = UInt32
public typealias ObjectId = UInt16


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
  
  /// Convert a String to a UInt16
  ///
  /// - Returns:      the UInt6 equivalent or nil
  ///
  var objectId: ObjectId? {
    return UInt16(self, radix: 10)
  }
  /// Convert a String to a UInt32
  ///
  /// - Returns:      the UInt32 equivalent or nil
  ///
  var streamId: StreamId? {
    return self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16)
  }
  /// Convert a String to a UInt32
  ///
  /// - Returns:      the UInt32 equivalent or nil
  ///
  var handle: Handle? {
    return self.hasPrefix("0x") ? UInt32(String(self.dropFirst(2)), radix: 16) : UInt32(self, radix: 16)
  }
  /// Convert a Mhz string to a Hz Int
  ///
  /// - Returns:      the Int equivalent
  ///
  var mhzToHz : Int {
    return Int( (Double(self) ?? 0) * 1_000_000 )
  }
  /// Convert a Mhz string to a Hz UInt
  ///
  /// - Returns:      the Int equivalent
  ///
  var mhzToHzUInt : UInt {
    return UInt( (Double(self) ?? 0) * 1_000_000 )
  }
  /// Convert a String to a UInt16
  ///
  /// - Returns:      the UInt6 equivalent or nil
  ///
  var sequenceNumber: SequenceNumber {
    return UInt(self, radix: 10) ?? 0
  }
  /// Return the Integer value (or 0 if invalid)
  ///
  /// - Returns:      the Int equivalent
  ///
  var iValue : Int {
    return Int(self) ?? 0
  }
  /// Return the Bool value (or false if invalid)
  ///
  /// - Returns:      a Bool equivalent
  ///
  var bValue : Bool {
    return (Int(self) ?? 0) == 1 ? true : false
  }
  /// Return the Bool value (or false if invalid)
  ///
  /// - Returns:      a Bool equivalent
  ///
  var tValue : Bool {
    return self.lowercased() == "true" ? true : false
  }
  /// Return the Float value (or 0 if invalid)
  ///
  /// - Returns:      a Float equivalent
  ///
  var fValue : Float {
    return Float(self) ?? 0
  }
  /// Return the Double value (or 0 if invalid)
  ///
  /// - Returns:      a Double equivalent
  ///
  var dValue : Double {
    return Double(self) ?? 0
  }
  /// Return the Unsigned Int value (or 0 if invalid)
  ///
  /// - Returns:      a Uint equivalent
  ///
  var uValue : UInt {
    return UInt(self) ?? 0
  }
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
  
  /// Return 1 / 0 for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var as1or0Int : Int {
    return (self ? 1 : 0)
  }
  /// Return "1" / "0" for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var as1or0 : String {
    return (self ? "1" : "0")
  }
  /// Return "True" / "False" Strings for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var asTrueFalse : String {
    return (self ? "True" : "False")
  }
  /// Return "T" / "F" Strings for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var asTF : String {
    return (self ? "T" : "F")
  }
  /// Return "on" / "off" Strings for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var asOnOff : String {
    return (self ? "on" : "off")
  }
  /// Return "PASS" / "FAIL" Strings for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var asPassFail : String  {
    return self == true ? "PASS" : "FAIL"
  }
  /// Return "YES" / "NO" Strings for true / false Booleans
  ///
  /// - Returns:      a String
  ///
  var asYesNo : String {
    return self == true ? "YES" : "NO"
  }
}

public extension Int {
  
  /// Convert an Int Hz value to a Mhz string
  ///
  /// - Returns:      the String equivalent
  ///
  var hzToMhz : String {
    
    // convert to a String with up to 2 leading & with 6 trailing places
    return String(format: "%02.6f", Float(self) / 1_000_000.0)
  }
  /// Convert a UInt Hz value to a Mhz string
  ///
  /// - Returns:      the String equivalent
  ///
  var hzToMhzUInt : String {
    
    // convert to a String with up to 2 leading & with 6 trailing places
    return String(format: "%02.6f", Float(self) / 1_000_000.0)
  }
  /// Determine if a value is between two other values (inclusive)
  ///
  /// - Parameters:
  ///   - value1:     low value (may be + or -)
  ///   - value2:     high value (may be + or -)
  /// - Returns:      true - self within two values
  ///
  func within(_ value1: Int, _ value2: Int) -> Bool {
    
    return (self >= value1) && (self <= value2)
  }
  
  /// Force a value to be between two other values (inclusive)
  ///
  /// - Parameters:
  ///   - value1:     the Minimum
  ///   - value2:     the Maximum
  /// - Returns:      the coerced value
  ///
//  func bound(_ value1: Int, _ value2: Int) -> Int {
//    let newValue = self < value1 ? value1 : self
//    return newValue > value2 ? value2 : newValue
//  }
}

public extension UInt {
  
  /// Convert a UInt Hz value to a Mhz string
  ///
  /// - Returns:      the String equivalent
  ///
  var hzToMhz : String {
    
    // convert to a String with up to 2 leading & with 6 trailing places
    return String(format: "%02.6f", Float(self) / 1_000_000.0)
  }
}

//public extension UInt16 {
//  var 
//}

public extension UInt32 {
  
  // convert a UInt32 to a hax String (defaults to "0xXXXXXXXX")
  func toHex(_ format: String = "0x%08X") -> String {
    
    return String(format: format, self)
  }
  
  // convert a UInt32 to a hex String (uppercase, leading zeros, 8 characters, 0x prefix)
  var hex: String { return String(format: "0x%08X", self) }
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

/// Struct to hold a Version number
///
public struct Version {
  var major     : Int = 1
  var minor     : Int = 0
  var build     : Int = 0
  var revision  : String = "x"
  
  public init(_ versionString: String = "1.0.0.x") {
    
    let components = versionString.components(separatedBy: ".")
    if components.count == 4 {
      major = Int(components[0]) ?? 0
      minor = Int(components[1]) ?? 0
      build = Int(components[2]) ?? 0
      revision = components[3]
    } else if components.count == 3 {
      major = Int(components[0]) ?? 0
      minor = Int(components[1]) ?? 0
      build = Int(components[2]) ?? 0
      revision = "x"
    }
  }
  
  public var string : String {
    return "\(major).\(minor).\(build).\(revision)"
  }
  
  public var shortString : String {
    return "\(major).\(minor).\(build).x"
  }
  
  public var isV3 : Bool {
    return major >= 2 && minor >= 5
  }

  public var isV2 : Bool {
    return major >= 2 && minor < 5
  }

  public var isV1 : Bool {
    return major == 1
  }

  static func ==(lhs: Version, rhs: Version) -> Bool {
    return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.build == rhs.build
  }
  
  static func <(lhs: Version, rhs: Version) -> Bool {
    
    switch (lhs, rhs) {
      
    case (let l, let r) where l == r:
      return false
    case (let l, let r) where l.major < r.major:
      return true
    case (let l, let r) where l.major == r.major && l.minor < r.minor:
      return true
    case (let l, let r) where l.major == r.major && l.minor == r.minor && l.build < r.build:
      return true
    default:
      return false
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
/// - Parameter properties:   a collectio of Key Values
/// - Returns:                true if a match
///
public func isForThisClient(_ properties: KeyValuesArray) -> Bool {
  
  // allow a Tester app to see all Streams
  guard Api.sharedInstance.testerModeEnabled == false else { return true }
  
  // make sure we have a connection
  guard Api.sharedInstance.connectionHandle != nil else { return false }
  
  // find the handle property
  for property in properties where property.key == DaxRxAudioStream.Token.clientHandle.rawValue {
    // is it equal to mine?
    return property.value.handle == Api.sharedInstance.connectionHandle
  }
  return false
}


@propertyWrapper
/// Protect a property using a concurrent queue and a barrier for writes
///
public struct Barrier<Element> {
  private var _value      : Element
  private let _q          : DispatchQueue
  
  public var wrappedValue: Element {
    get { return _q.sync { _value }}
    set { _q.sync(flags: .barrier) { _value = newValue }}
  }
  
  init(_ value: Element, _ queue: DispatchQueue) {
    _value = value
    _q = queue
  }
}

@propertyWrapper
/// Protect a property using a concurrent queue and a barrier for writes
///
struct BarrierClamped<Element: Comparable> {
  private var _value      : Element
  private let _q          : DispatchQueue
  private let _range      : ClosedRange<Element>
  
  var wrappedValue: Element {
    get { return _q.sync { _value }}
    set { _q.sync(flags: .barrier) { _value = min( max(_range.lowerBound, newValue), _range.upperBound) }}
  }
  
  init(_ value: Element, _ queue: DispatchQueue, range: ClosedRange<Element>) {

    _q = queue
    _range = range
    _value = min( max(_range.lowerBound, value), _range.upperBound)
  }
}

/*
@propertyWrapper
/// Protect a property by "clamping" it within prescribed bounds
///
struct Clamping<Value: Comparable> {
  private var _value    : Value
  private let _range    : ClosedRange<Value>
  
  init(_ value: Value, _ range: ClosedRange<Value>) {
    precondition(range.contains(value))
    _value = value
    _range = range
  }
  var wrappedValue: Value {
    get { _value }
    set { _value = min( max(_range.lowerBound, newValue), _range.upperBound) }
  }
}

@propertyWrapper
/// Protect a property using a concurrent queue and a barrier for writes
///
struct ClampingBarrier {
  private var _value    : Int
  private var _q        : DispatchQueue
  
  var wrappedValue: Int {
    get { return _q.sync { _value }}
    set { _q.sync(flags: .barrier) { _value = min( max(Api.kControlMin, newValue ), Api.kControlMax) }
    }
  }
  
  init(_ value: Int, _ queue: DispatchQueue) {
    _value = value
    _q = queue
  }
}
*/
// function to change value and signal KVO
func update<S:NSObject, T>(_ object: S, _ property: UnsafeMutablePointer<T>, to value: T, signal keyPath: KeyPath<S,T>) {
  object.willChangeValue(for: keyPath)
  property.pointee = value
  object.didChangeValue(for: keyPath)
}
