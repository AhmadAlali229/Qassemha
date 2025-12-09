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
    @Published var currentUserName: String?
    @Published var currentUserPhoneNumber: String?
    @Published var shouldShowLogin = true

    private let userDefaults = UserDefaults.standard
    private let isAuthenticatedKey = "isAuthenticated"
    private let userEmailKey = "currentUserEmail"
    private let userNameKey = "currentUserName"
    private let userPhoneKey = "currentUserPhoneNumber"

    static let shared = AuthenticationManager()

    private init() {
        checkAuthenticationStatus()
    }

    /// Loads saved authentication state from UserDefaults and restores user session
    /// Maintains persistent login across app launches for better user experience
    func checkAuthenticationStatus() {
        isAuthenticated = userDefaults.bool(forKey: isAuthenticatedKey)
        currentUserEmail = userDefaults.string(forKey: userEmailKey)
        currentUserName = userDefaults.string(forKey: userNameKey)
        currentUserPhoneNumber = userDefaults.string(forKey: userPhoneKey)

        // Initialize wallet with example transactions if authenticated
        if isAuthenticated {
            DispatchQueue.main.async {
                WalletManager.shared.createExampleWalletEntries()
                WalletManager.shared.refresh()
            }
        }
    }

    /// Authenticates user and saves credentials to persistent storage
    /// Creates new user session and initializes wallet with sample data for demo purposes
    func login(email: String, name: String? = nil) {
        userDefaults.set(true, forKey: isAuthenticatedKey)
        userDefaults.set(email, forKey: userEmailKey)
        if let name = name {
            userDefaults.set(name, forKey: userNameKey)
        }

        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUserEmail = email
            self.currentUserName = name

            // Initialize wallet with example transactions for new users
            WalletManager.shared.createExampleWalletEntries()
            WalletManager.shared.refresh()
        }
    }

    /// Clears all user data and returns to login screen
    /// Ensures secure session termination when user explicitly logs out
    func logout() {
        userDefaults.removeObject(forKey: isAuthenticatedKey)
        userDefaults.removeObject(forKey: userEmailKey)
        userDefaults.removeObject(forKey: userNameKey)
        userDefaults.removeObject(forKey: userPhoneKey)

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.currentUserName = nil
            self.currentUserPhoneNumber = nil
            self.shouldShowLogin = true
        }
    }

    /// Updates user's display name in profile and persistent storage
    /// Allows users to modify their profile information after account creation
    func updateUserName(_ name: String) {
        userDefaults.set(name, forKey: userNameKey)
        DispatchQueue.main.async {
            self.currentUserName = name
        }
    }

    /// Updates user's phone number in profile and persistent storage
    /// Required for bill split participant identification and payment requests
    func updateUserPhoneNumber(_ phoneNumber: String) {
        userDefaults.set(phoneNumber, forKey: userPhoneKey)
        DispatchQueue.main.async {
            self.currentUserPhoneNumber = phoneNumber
        }
    }

    /// Switches authentication view to signup mode
    /// Enables new user registration from login screen
    func showSignup() {
        shouldShowLogin = false
    }

    /// Switches authentication view to login mode
    /// Allows existing users to access their accounts from signup screen
    func showLogin() {
        shouldShowLogin = true
    }
}