import Foundation

enum MFValue: Equatable {
  case string(String)
  case number(String)
  case bool(Bool)
  case url(URL)
  case data(Data)
  case date(Date)
  
  case array([MFValue])
  case object([String: MFValue])
}


extension MFValue {
  var isValue: Bool {
    switch self {
    case .array, .object:
      return false
    default:
      return true
    }
  }
  
  var isContainer: Bool {
    switch self {
    case .array, .object:
      return true
    default:
      return false
    }
  }
}

extension MFValue {
  struct Writer {
    var formData = FormData()
    
    func append(path: [String], value: CustomStringConvertible) {
      precondition(!path.isEmpty, "Root element should be object")
      formData.append(name: path.joined(separator: "."), value: value)
    }
    
    func append(path: [String], value: URL) {
      precondition(!path.isEmpty, "Root element should be object")
      formData.append(name: path.joined(separator: "."), value: value)
    }
    func append(path: [String], value: Data) {
      precondition(!path.isEmpty, "Root element should be object")
      formData.append(name: path.joined(separator: "."), value: value)
    }
    func append(path: [String], value: Date) {
      precondition(!path.isEmpty, "Root element should be object")
      formData.append(name: path.joined(separator: "."), value: value)
    }
    
    func fillFormData(_ value: MFValue, path: [String] = []) {
      switch value {
      case .object(let object):
        for (key, value) in object {
          
          var nextPath = path
          nextPath.append(key)
          fillFormData(value, path: nextPath)
        }
      case .array(let array):
        precondition(!path.isEmpty, "Root element should be object")
        for (index, value) in array.enumerated() {
          var nextPath = path
          nextPath[nextPath.endIndex-1] = ("\(nextPath.last!)[\(index)]")
          fillFormData(value, path: nextPath)
        }
        
      case .number(let n):
        append(path: path, value: n)
      case .string(let s):
        append(path: path, value: s)
      case .bool(let b):
        append(path: path, value: b)
        
      case .url(let url):
        append(path: path, value: url)
      case .data(let data):
        append(path: path, value: data)
      case .date(let date):
        append(path: path, value: date)
        
      }
    }
  }
  
  func write() -> FormData {
    let writer = MFValue.Writer()
    writer.fillFormData(self)
    return writer.formData
    
  }
}
