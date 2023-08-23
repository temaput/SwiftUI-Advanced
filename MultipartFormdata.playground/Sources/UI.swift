import Foundation

import SwiftUI
import AppKit
import PlaygroundSupport
import UniformTypeIdentifiers


//let apiURL = "https://httpbin.org/post"
let apiURL = "http://127.0.0.1:8000/form_data/flat-form-raw/"

struct FormValues: Encodable {
  
  var username: String = ""
  var password: String = ""
  var rank: Int = 0
  var active: Bool = false
  var avatar: URL?
}

func testHttpFormSubmit(formValues: FormValues) async {
  let formData = FormData()
  formData.append(name: "username", value: formValues.username)
  formData.append(name: "password", value: formValues.password)
  formData.append(name: "rank", value: formValues.rank)
  formData.append(name: "active", value: formValues.active)
  if let avatar = formValues.avatar {
    formData.append(name: "avatar", value: avatar)
  }
  await submitFormData(formData: formData)
}

func testEncodedFormSubmit(formValues: FormValues) async {
  let encoder = MFEncoder()
  if let data = try? encoder.encode(formValues), let contentTypeForHttpRequest = encoder.contentTypeForHttpRequest {
    
    guard let url = URL(string: apiURL) else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = data
    request.setValue(contentTypeForHttpRequest, forHTTPHeaderField: "Content-Type")
    await submitHttpRequest(request)
    
  }
      
      
}

func submitFormData(formData: FormData)  async {
  guard let url = URL(string: apiURL) else { return }
  let request = formData.asHttpRequest(url: url)
  await submitHttpRequest(request)
}

func submitHttpRequest(_ request: URLRequest) async {
  do {
    print("Sending request...")
    let (data, response) = try await URLSession.shared.data(for: request)
    // Handle data and response.
    print("Got response!")
    print(String(data: data, encoding: .utf8) ?? "Data not readable")
    print(response)
  } catch {
    // Handle error.
    print("Error: \(error)")
  }
}

func openFolderOrFile(canChooseDirectories: Bool = false, _ action: (_ url: URL) -> Void) {
  let openPanel = NSOpenPanel()
  openPanel.title = "Choose a directory"
  openPanel.showsResizeIndicator = true
  openPanel.showsHiddenFiles = false
  openPanel.canChooseDirectories = canChooseDirectories
  openPanel.canCreateDirectories = false
  openPanel.allowsMultipleSelection = false
  openPanel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
  
  if openPanel.runModal() == NSApplication.ModalResponse.OK {
    if let url = openPanel.url {
      action(url)
    }
  }
  
}




func walkFolder(_ directoryURL: URL) {
  let fileManager = FileManager.default
  
  do {
    let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    for url in contents {
      if let mime = getMimeTypeFromURL(url) {
        print(url.lastPathComponent) // print file name
        print("\n\t---\(mime) \n")
      }
    }
  } catch {
    print("Error: \(error)")
  }
}






struct ContentView: View {
  
  @State private var formValues: FormValues = FormValues()
  
  var body: some View {
    VStack {
      Text("Check files mime types in the folder").font(.title).multilineTextAlignment(.center).padding()
      
      Button("Select Folder") {
        openFolderOrFile(canChooseDirectories: true) {
          url in
          print("Selected directory: \(url.path)")
          walkFolder(url)
          
        }
      }
      Text("Fill Form Inputs").font(.title).padding()
      Form {
        TextField(
          "User name",
          text: $formValues.username
        ).padding()
        SecureField(
          "User password",
          text: $formValues.password
        ).padding()
        
        
        Stepper("User rank: \(formValues.rank)", value: $formValues.rank).padding()
        Toggle("User is active", isOn: $formValues.active).padding()
        LabeledContent("User avatar") {
          Button("Pick Avatar") {
            openFolderOrFile {
              url in
              formValues.avatar = url
            }
          }
        }
        
        
        
      }
      Button("Submit Form") {
        print("Submitting \(formValues)")
        Task {
          await testEncodedFormSubmit(formValues:formValues)
        }
      }.padding()
      
      
    }
    .padding()
    .frame(width: 400)
  }
}



public func testThis() {
  
    PlaygroundPage.current.setLiveView(ContentView())
  
}
