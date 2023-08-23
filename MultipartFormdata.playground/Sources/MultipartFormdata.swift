import Foundation
import UniformTypeIdentifiers

func getMimeTypeFromURL(_ fileURL: URL) -> String? {
  do {
    let resourceValues = try fileURL.resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey])
    if resourceValues.isDirectory ?? false {
      return nil
    }
    
    if let type = resourceValues.contentType, let mime = type.preferredMIMEType  {
      return mime
    } else {
      return "application/octet-stream"
    }
  } catch {
    return nil
  }
}



public class FormData {
  
  
  struct FormDataItem {
    var name: String
    var value: Data
    var filename: String?
    var mime: String?
  }
  
  enum ValueOutput {
    case stringCase(String)
    case blobCase(Data)
    
    init?(_ item: FormDataItem) {
      if item.filename != nil {
        self = .blobCase(item.value)
      } else {
        if let stringValue = String(data: item.value, encoding: .utf8) {
          self = .stringCase(stringValue)
          
        } else {
          return nil
        }
      }
      
    }
  }
  
  public enum DateEncodingStrategy {
    /// Defer to `Date` for choosing an encoding. This is the default strategy.
    case deferredToDate
    
    /// Encode the `Date` as a UNIX timestamp (as a JSON number).
    case secondsSince1970
    
    /// Encode the `Date` as UNIX millisecond timestamp (as a JSON number).
    case millisecondsSince1970
    
    /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    case iso8601
    
    /// Encode the `Date` as a string formatted by the given formatter.
    case formatted(DateFormatter)
    
  }
  
  struct ValuesIterator: IteratorProtocol {
    typealias Element = ValueOutput
    private var current = 0
    private let elements: Array<FormDataItem>
    init(_ elements: Array<FormDataItem>) {
      self.elements = elements
    }
    
    mutating func next() -> ValueOutput? {
      defer {
        current += 1
      }
      guard current < elements.count else {
        return nil
      }
      return ValueOutput(elements[current])
    }
  }
  struct EntriesIterator: IteratorProtocol {
    typealias Element = (String, ValueOutput)
    private var current = 0
    private let elements: Array<FormDataItem>
    init(_ elements: Array<FormDataItem>) {
      self.elements = elements
    }
    
    mutating func next() -> Element? {
      defer {
        current += 1
      }
      guard current < elements.count else {
        return nil
      }
      if let valueOutput = ValueOutput(elements[current]) {
        return (elements[current].name, valueOutput)
      } else {
        return nil
      }
    }
  }
  
  struct KeysIterator: IteratorProtocol {
    typealias Element = String
    
    private var current = 0
    private let elements: Array<FormDataItem>
    init(_ elements: Array<FormDataItem>) {
      self.elements = elements
    }
    
    mutating func next() -> String? {
      defer {
        current += 1
        while current < elements.count && elements[current - 1].name == elements[current].name {
          current += 1
        }
      }
      return current < elements.count ? elements[current].name : nil
    }
  }
  
  private var data: Array<FormDataItem> = []
  
  private var boundary: String
  
  open var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
  
  init() {
    boundary = "Boundary-\(UUID().uuidString)"
  }
  
  func wrapDate(_ date: Date) -> String {
    switch self.dateEncodingStrategy {
    case .deferredToDate:
      return "" // this case should be processed in encoder
      
    case .secondsSince1970:
      return date.timeIntervalSince1970.description
      
    case .millisecondsSince1970:
      return (date.timeIntervalSince1970 * 1000).description
      
    case .iso8601:
      if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withInternetDateTime
        
        return formatter.string(from: date)
      } else {
        fatalError("ISO8601DateFormatter is unavailable on this platform.")
      }
      
    case .formatted(let formatter):
      
      return formatter.string(from: date)
      
      
    }
  }
  
  
  
  func append(name: String, value: CustomStringConvertible) {
    
    if let value = "\(value)".data(using: .utf8), let name = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      data.append(FormDataItem(name: name, value: value))
    }
  }
  
  
  func append(name: String, value: URL) {
    
    if !value.isFileURL {
      append(name: name, value: value.absoluteString)
    }
    if let fileData = try? Data(contentsOf: value), let mime = getMimeTypeFromURL(value), let name = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      data.append(FormDataItem(name: name, value: fileData, filename: value.lastPathComponent, mime: mime))
    }
  }
  
  func append(name: String, value: Data) {
    data.append(FormDataItem(name: name, value: value, filename: "data", mime: "application/octet-stream"))
  }
  
  func append(name: String, value: Date) {
    let serializedDate = wrapDate(value)
    append(name: name, value: serializedDate)
  }
  
  func set(name: String, value: CustomStringConvertible) {
    
    delete(name: name)
    append(name: name, value: value)
  }
  func set(name: String, value: URL) {
    delete(name: name)
    append(name: name, value: value)
  }
  func set(name: String, value: Data) {
    delete(name: name)
    append(name: name, value: value)
  }
  
  func has(name: String) -> Bool {
    return data.contains(where: {$0.name == name})
  }
  
  func keys() -> KeysIterator {
    return KeysIterator(data)
  }
  
  func entries() -> EntriesIterator {
    return EntriesIterator(data)
  }
  
  func values() -> ValuesIterator {
    return ValuesIterator(data)
  }
  
  func get(name: String) -> ValueOutput? {
    if let item = data.first(where: { $0.name == name }) {
      return ValueOutput(item)
    } else {
      return nil
    }
  }
  
  func getAll(name: String) -> Array<ValueOutput> {
    return data.filter({ $0.name == name }).compactMap({ ValueOutput($0) })
  }
  
  func delete(name: String) {
    data.removeAll { formDataItem in
      formDataItem.name == name
    }
    
  }
  
  
  var bodyForHttpRequest: Data {
    
    var body = Data()
    
    data.forEach { formDataItem in
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      if let fileName = formDataItem.filename, let mime = formDataItem.mime {
        body.append("Content-Disposition: form-data; name=\"\(formDataItem.name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
      } else {
        body.append("Content-Disposition: form-data; name=\"\(formDataItem.name)\"\r\n\r\n".data(using: .utf8)!)
      }
      body.append(formDataItem.value)
      body.append("\r\n".data(using: .utf8)!)
      
      
    }
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    return body
    
    
  }
  
  var contentTypeForHttpRequest: String {
    return "multipart/form-data; boundary=\(boundary)"
  }
  
  
  func asHttpRequest(url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = bodyForHttpRequest
    request.setValue(contentTypeForHttpRequest, forHTTPHeaderField: "Content-Type")
    return request
  }
  
  
}
