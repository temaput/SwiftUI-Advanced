//
//  SwiftUI__AdvancedApp.swift
//  SwiftUI  Advanced
//
//  Created by Artem Putilov on 12.04.23.
//

import SwiftUI

@main
struct SwiftUI__AdvancedApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
