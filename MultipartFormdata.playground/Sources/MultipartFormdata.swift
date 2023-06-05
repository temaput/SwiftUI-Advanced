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
