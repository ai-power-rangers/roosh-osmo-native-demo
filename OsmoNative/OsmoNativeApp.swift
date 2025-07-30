//
//  OsmoNativeApp.swift
//  OsmoNative
//
//  Created by Roosh on 7/30/25.
//

import SwiftUI

@main
struct OsmoNativeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
