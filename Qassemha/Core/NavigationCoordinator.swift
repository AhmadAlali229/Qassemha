//
//  NavigationCoordinator.swift
//  Qassemha
//
//  Coordinator for managing navigation and tab switching
//

import Foundation
import SwiftUI

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()

    @Published var selectedTab: Int = 0
    @Published var shouldTriggerScan: Bool = false
    @Published var shouldShowNewGroup: Bool = false

    private init() {}

    /// Switches to scan tab and triggers camera scan after brief delay
    /// Enables seamless navigation to scanning from anywhere in the app (e.g., quick actions)
    func switchToScanTab() {
        selectedTab = 1
        // Delay to ensure tab switch completes before triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldTriggerScan = true
        }
    }

    /// Switches to groups tab and shows new group creation sheet after brief delay
    /// Provides quick access to group creation from other parts of the app
    func switchToGroupsTab() {
        selectedTab = 2
        // Delay to ensure tab switch completes before triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldShowNewGroup = true
        }
    }

    /// Resets scan trigger flag to prevent repeated camera launches
    /// Maintains clean state after scan action is completed
    func resetScanTrigger() {
        shouldTriggerScan = false
    }

    /// Resets group creation trigger flag to prevent repeated sheet presentations
    /// Maintains clean state after group creation action is completed
    func resetGroupTrigger() {
        shouldShowNewGroup = false
    }
}
