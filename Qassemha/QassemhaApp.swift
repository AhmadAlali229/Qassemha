//
//  QassemhaApp.swift
//  Qassemha
//
//  Created by Harjot Singh on 16/09/25.
//

import SwiftUI

@main
struct QassemhaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
