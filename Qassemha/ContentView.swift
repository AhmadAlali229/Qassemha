//
//  ContentView.swift
//  Qassemha
//
//  Created by Harjot Singh on 16/09/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared

    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            NavigationView {
                if authManager.shouldShowLogin {
                    LoginView()
                } else {
                    SignupView()
                }
            }
            .navigationViewStyle(.stack)
        }
    }
}

#Preview {
    ContentView()
}