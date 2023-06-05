//: A UIKit based Playground for presenting user interface
import SwiftUI
import AppKit
import PlaygroundSupport
import UniformTypeIdentifiers


struct FormValues {
  
  init() {
    self.username = ""
    self.password = ""
    self.rank = 0
  }
  var username: String
  var password: String
  var rank: Int
  var avatar: URL?
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
      }.padding()
      
      
    }
    .padding()
    .frame(width: 400)
  }
}


PlaygroundPage.current.setLiveView(ContentView())



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





