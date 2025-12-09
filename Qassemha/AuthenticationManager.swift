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

    func checkAuthenticationStatus() {
        isAuthenticated = userDefaults.bool(forKey: isAuthenticatedKey)
        currentUserEmail = userDefaults.string(forKey: userEmailKey)
        currentUserName = userDefaults.string(forKey: userNameKey)
        currentUserPhoneNumber = userDefaults.string(forKey: userPhoneKey)
    }

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
        }
    }

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

    func updateUserName(_ name: String) {
        userDefaults.set(name, forKey: userNameKey)
        DispatchQueue.main.async {
            self.currentUserName = name
        }
    }

    func updateUserPhoneNumber(_ phoneNumber: String) {
        userDefaults.set(phoneNumber, forKey: userPhoneKey)
        DispatchQueue.main.async {
            self.currentUserPhoneNumber = phoneNumber
        }
    }

    func showSignup() {
        shouldShowLogin = false
    }

    func showLogin() {
        shouldShowLogin = true
    }
}