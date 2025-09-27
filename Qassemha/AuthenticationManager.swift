//
//  AuthenticationManager.swift
//  Qassemha
//
//  Created by Harjot Singh on 23/09/25.
//

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserEmail: String?
    @Published var shouldShowLogin = true

    private let userDefaults = UserDefaults.standard
    private let isAuthenticatedKey = "isAuthenticated"
    private let userEmailKey = "currentUserEmail"

    static let shared = AuthenticationManager()

    private init() {
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        isAuthenticated = userDefaults.bool(forKey: isAuthenticatedKey)
        currentUserEmail = userDefaults.string(forKey: userEmailKey)
    }

    func login(email: String) {
        userDefaults.set(true, forKey: isAuthenticatedKey)
        userDefaults.set(email, forKey: userEmailKey)

        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUserEmail = email
        }
    }

    func logout() {
        userDefaults.removeObject(forKey: isAuthenticatedKey)
        userDefaults.removeObject(forKey: userEmailKey)

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.shouldShowLogin = true
        }
    }

    func showSignup() {
        shouldShowLogin = false
    }

    func showLogin() {
        shouldShowLogin = true
    }
}