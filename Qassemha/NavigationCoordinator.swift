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

    func switchToScanTab() {
        selectedTab = 1
        // Delay to ensure tab switch completes before triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldTriggerScan = true
        }
    }

    func switchToGroupsTab() {
        selectedTab = 2
        // Delay to ensure tab switch completes before triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldShowNewGroup = true
        }
    }

    func resetScanTrigger() {
        shouldTriggerScan = false
    }

    func resetGroupTrigger() {
        shouldShowNewGroup = false
    }
}
