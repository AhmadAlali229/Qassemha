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

    init() {
        // Initialize notification manager and setup actions
        NotificationManager.shared.setupNotificationActions()

        // Request notification permission if not already granted
        NotificationManager.shared.checkNotificationPermission()

        // Schedule daily check for overdue payments
        scheduleOverdueChecks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.light)
                .onAppear {
                    // Update badge count when app becomes active
                    NotificationManager.shared.updateBadgeCount()
                }
        }
    }

    private func scheduleOverdueChecks() {
        // Check for overdue payments daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            NotificationManager.shared.checkForOverduePayments()
        }

        // Also check on launch
        NotificationManager.shared.checkForOverduePayments()
    }
}
