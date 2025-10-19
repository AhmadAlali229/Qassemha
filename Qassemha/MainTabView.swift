//
//  MainTabView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared

    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            ScanReceiptView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 1 ? "camera.fill" : "camera")
                    Text("Scan")
                }
                .tag(1)

            GroupsView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 2 ? "person.3.fill" : "person.3")
                    Text("Groups")
                }
                .tag(2)

            WalletView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 3 ? "wallet.pass.fill" : "wallet.pass")
                    Text("Wallet")
                }
                .tag(3)

            HistoryView()
                .tabItem {
                    Image(systemName: navigationCoordinator.selectedTab == 4 ? "clock.fill" : "clock")
                    Text("History")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}