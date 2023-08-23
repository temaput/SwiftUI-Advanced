import Foundation


enum ContainedValue {
  case value(MFValue)
  case object(RefObject)
  case list(RefList)
  
  
  
  class RefList {
    var l: [ContainedValue] = []
    
    init() {}
    
    func append(_ value: MFValue) {
      l.append(.value(value))
      
    }
    
    func appendList() -> RefList {
      let result = RefList()
      l.append(.list(result))
      return result
      
    }
    
    func appendObject() -> RefObject {
      let result = RefObject()
      l.append(.object(result))
      return result
    }
    
    var mfValue: MFValue {
      var result: [MFValue] = []
      for item in l {
        switch item {
        case .value(let v):
          result.append(v)
        case .list(let nestedList):
          result.append(nestedList.mfValue)
        case .object(let nestedContainer):
          result.append(nestedContainer.mfValue)
        }
      }
      return .array(result)
      
    }
    
  }
  
  class RefObject {
    var obj: [String: ContainedValue] = [:]
    
    init() {}
    
    
    
    func setObject(forKey key: String) -> RefObject {
      let container = RefObject()
      obj[key] = .object(container)
      return container
    }
    
    func set(_ value: MFValue, forKey key: String) {
      obj[key] = .value(value)
    }
    
    func setList(forKey key: String) -> RefList {
      let list = RefList()
      obj[key] = .list(list)
      return list
    }
    
    var mfValue: MFValue {
      var result: [String: MFValue] = [:]
      
      for (key, item) in obj {
        switch item {
        case .value(let v):
          result[key] = v
        case .object(let c):
          result[key] = c.mfValue
        case .list(let nestedList):
          result[key] = nestedList.mfValue
        }
      }
      return .object(result)
      
    }
    
    
  }
  
}




public class MFEncoder: Encoder {
  public var codingPath: [CodingKey] = []
  public var userInfo: [CodingUserInfoKey: Any] = [:]
  open var dateEncodingStrategy: FormData.DateEncodingStrategy = .deferredToDate
  
  fileprivate var root: ContainedValue?
  
  private var formData: FormData?
  
  init() {
    self.codingPath = []
  }
  init(codingPath: [CodingKey]) {
    self.codingPath = codingPath
  }
  
  
  /**
   You must use only one kind of top-level encoding container. This method must not be called after a call to `unkeyedContainer()` or after encoding a value through a call to `singleValueContainer()`
   **/
  public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
    let obj = ContainedValue.RefObject()
    let container = MFKeyedEncodingContainer<Key>(obj: obj, impl: self, codingPath: codingPath)
    self.root = .object(obj)
    return KeyedEncodingContainer(container)
  }
  
  /*You must use only one kind of top-level encoding container. This method must not be called after a call to `container(keyedBy:)`or after encoding a value through a call to `singleValueContainer()`
   */
  public func unkeyedContainer() -> UnkeyedEncodingContainer {
    let list = ContainedValue.RefList()
    root = .list(list)
    return MFUnkeyedEncodingContainer(impl: self, codingPath: codingPath, list: list)
  }
  
  /* Discussion
   
   You must use only one kind of top-level encoding container. This method must not be called after a call to `unkeyedContainer()` or `container(keyedBy:)`, or after encoding a value through a call to `singleValueContainer()`
   */
  public func singleValueContainer() -> SingleValueEncodingContainer {
    return MFSingleValueEncodingContainer(codingPath: codingPath, impl: self)
  }
  
  
  open func encode<T: Encodable>(_ value: T) throws -> Data {
    let value: MFValue = try encodeAsMFValue(value, for: nil)
    formData = value.write()
    return formData!.bodyForHttpRequest
    
  }
  
  var contentTypeForHttpRequest: String? {
    return formData?.contentTypeForHttpRequest
  }
  
  func encodeAsMFValue<T: Encodable>(_ encodable: T, for additionalKey: CodingKey?) throws -> MFValue {
    switch encodable {
    case let date as Date:
      return try self.wrapDate(date, for: additionalKey)
    case let data as Data:
      return .data(data)
    case let url as URL:
      return .url(url)
    case let decimal as Decimal:
      return .number(decimal.description) // NB! decimal is converted to string
    case let object as Dictionary<String, Encodable>:
      return try self.wrapObject(object, for: additionalKey)
    default:
      // this should be run first if struct was passed
      let encoder = self.getEncoder(for: additionalKey)
      // encoder = JSONEncoderImpl
      try encodable.encode(to: encoder) // this method is either customized or provided by compiler
      return encoder.mfValue
      // value is JSONValue (array, dict or single value)
    }
    
  }
  
  func wrapDate(_ date: Date, for additionalKey: CodingKey?) throws -> MFValue {
    switch dateEncodingStrategy {
    case .deferredToDate:
      let encoder = self.getEncoder(for: additionalKey)
      try date.encode(to: encoder)
      return encoder.mfValue
    default:
      return .date(date)
    }
  }
  
  fileprivate func getEncoder(for additionalKey: CodingKey?) -> MFEncoder {
    if let additionalKey = additionalKey {
      return MFEncoder(codingPath: self.codingPath + [additionalKey])
    }
    
    return self
  }
  
  func wrapObject(_ obj: Dictionary<String, Encodable>, for additionalKey: CodingKey?) throws -> MFValue {
    var result: [String: MFValue] = [:]
    for (key, value) in obj {
      result[key] = try encodeAsMFValue(value, for: nil)
    }
    return .object(result)
    
  }
  
  var mfValue: MFValue {
    if let root = root {
      switch root {
      case .value(let value):
        return value
      case .list(let list):
        return list.mfValue
      case .object(let obj):
        return obj.mfValue
      }
      
      
    }
    return .string("null")
  }
}




struct MFKeyedEncodingContainer<K> : KeyedEncodingContainerProtocol where K : CodingKey {
  var obj: ContainedValue.RefObject
  public typealias Key = K
  var impl: MFEncoder
  
  
  var codingPath: [CodingKey]
  
  // MARK: nested
  
  mutating func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
    let mfValue = try self.impl.encodeAsMFValue(value, for: nil)
    obj.set(mfValue, forKey: key.stringValue)
  }
  
  mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    let nestedObj = obj.setObject(forKey: key.stringValue)
    let nestedPath = codingPath + [key]
    let result = MFKeyedEncodingContainer<NestedKey>(obj: nestedObj, impl: self.impl, codingPath: nestedPath)
    return KeyedEncodingContainer(result)
  }
  
  mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
    let nestedList = obj.setList(forKey: key.stringValue)
    let nestedPath = codingPath + [key]
    return MFUnkeyedEncodingContainer(impl: self.impl, codingPath: nestedPath, list: nestedList)
    
  }
  
  mutating func superEncoder(forKey key: K) -> Encoder {
    // FIXME: fix this?
    return self.impl.getEncoder(for: key)
  }
  
  
  
  mutating func superEncoder() -> Encoder {
    // FIXME: fix this?
    return self.impl.getEncoder(for: nil)
  }
  
  
  // MARK: nil, bool, string
  
  mutating func encodeNil(forKey key: K) throws {
    obj.set(.string("null"), forKey: key.stringValue)
  }
  
  mutating func encode(_ value: Bool, forKey key: K) throws {
    obj.set(.bool(value), forKey: key.stringValue)
  }
  
  mutating func encode(_ value: String, forKey key: K) throws {
    obj.set(.string(value), forKey: key.stringValue)
  }
  
  
  // MARK: numbers
  
  private func encodeNumber(_ value: any Numeric, forKey key: K) {
    obj.set(.number("\(value)"), forKey: key.stringValue)
  }
  
  mutating func encode(_ value: Double, forKey key: K) throws {
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Float, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Int, forKey key: K) throws {
    
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Int8, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Int16, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Int32, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: Int64, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: UInt, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: UInt8, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: UInt16, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: UInt32, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  mutating func encode(_ value: UInt64, forKey key: K) throws {
    
    encodeNumber(value, forKey: key)
  }
  
  
}


struct MFUnkeyedEncodingContainer: UnkeyedEncodingContainer {
  
  var impl: MFEncoder
  
  var codingPath: [CodingKey]
  
  var count: Int {
    return list.l.count
  }
  
  var list: ContainedValue.RefList
  
  // MARK: nested
  
  mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
    let nestedObj = list.appendObject()
    let result = MFKeyedEncodingContainer<NestedKey>(obj: nestedObj, impl: self.impl, codingPath: codingPath)
    return KeyedEncodingContainer(result)
  }
  
  mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
    let nestedList = list.appendList()
    let result = MFUnkeyedEncodingContainer(impl: self.impl, codingPath: codingPath,  list: nestedList)
    return result
  }
  
  mutating func superEncoder() -> Encoder {
    // TODO: fix this?
    var newCodingPath: [CodingKey] = codingPath
    newCodingPath.append("super" as! any CodingKey)
    return MFEncoder(codingPath: newCodingPath)
  }
  mutating func encode<T>(_ value: T) throws where T : Encodable {
    let mfValue = try impl.encodeAsMFValue(value, for: nil)
    list.append(mfValue)
    
  }
  
  // MARK: bool, nil, string
  
  mutating func encode(_ value: Bool) throws {
    list.append(.bool(value))
  }
  mutating func encodeNil() throws {
    list.append(.string("null"))
  }
  
  
  mutating func encode(_ value: String) throws {
    list.append(.string(value))
  }
  
  // MARK: numbers
  
  private func encodeNumber(_ value: any Numeric) {
    list.append(.number("\(value)"))
  }
  mutating func encode(_ value: Double) throws {
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Float) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int8) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int16) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int32) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int64) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt8) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt16) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt32) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt64) throws {
    
    encodeNumber(value)
  }
  
  
  
  
}


struct MFSingleValueEncodingContainer: SingleValueEncodingContainer {
  var codingPath: [CodingKey]
  var impl: MFEncoder
  
  // MARK: nested
  
  mutating func encode<T>(_ value: T) throws where T : Encodable {
    let encoded = try impl.encodeAsMFValue(value, for: nil)
    impl.root = .value(encoded)
  }
  
  // MARK: nil, string, bool
  
  mutating func encodeNil() throws {
    impl.root = .value(.string("null"))
  }
  
  mutating func encode(_ value: Bool) throws {
    
    impl.root = .value(.bool(value))
  }
  
  mutating func encode(_ value: String) throws {
    
    impl.root = .value(.string(value))
  }
  
  // MARK: numbers
  
  private mutating func encodeNumber(_ value: any Numeric) {
    impl.root = .value(.number("\(value)"))
  }
  mutating func encode(_ value: Double) throws {
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Float) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int8) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int16) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int32) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: Int64) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt8) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt16) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt32) throws {
    
    encodeNumber(value)
  }
  
  mutating func encode(_ value: UInt64) throws {
    
    encodeNumber(value)
  }
  
  
  
}
