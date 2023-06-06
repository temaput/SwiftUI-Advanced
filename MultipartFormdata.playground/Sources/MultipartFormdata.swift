import Foundation
import UniformTypeIdentifiers

public func getMimeTypeFromURL(_ fileURL: URL) -> String? {
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
  
  
  func append(name: String, value: CustomStringConvertible) {
    if let value = "\(value)".data(using: .utf8) {
      data.append(FormDataItem(name: name, value: value))
    }
  }
  
  func append(name: String, value: Bool) {
    
  }
  
  func append(name: String, value: URL) {
    if let fileData = try? Data(contentsOf: value), let mime = getMimeTypeFromURL(value) {
      data.append(FormDataItem(name: name, value: fileData, filename: value.lastPathComponent, mime: mime))
    }
  }
  
  func set(name: String, value: CustomStringConvertible) {
    
    delete(name: name)
    append(name: name, value: value)
  }
  func set(name: String, value: URL) {
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
  
  
  
  
}
