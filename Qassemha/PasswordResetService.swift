//
//  PasswordResetService.swift
//  Qassemha
//
//  Created by Harjot Singh on 25/09/25.
//

import Foundation
import CoreData

class PasswordResetService {
    static let shared = PasswordResetService()

    private init() {}

    // Store verification codes temporarily
    private var verificationCodes: [String: VerificationCode] = [:]

    struct VerificationCode {
        let code: String
        let email: String?
        let phoneNumber: String?
        let expiryDate: Date
        let isUsed: Bool

        init(code: String, email: String? = nil, phoneNumber: String? = nil, expiryMinutes: Int = 10) {
            self.code = code
            self.email = email
            self.phoneNumber = phoneNumber
            self.expiryDate = Date().addingTimeInterval(TimeInterval(expiryMinutes * 60))
            self.isUsed = false
        }

        var isExpired: Bool {
            return Date() > expiryDate
        }
    }

    // Send verification code (hardcoded as 123456)
    func sendVerificationCode(email: String? = nil, phoneNumber: String? = nil, context: NSManagedObjectContext) -> Bool {
        // Check if user exists
        let user = UserValidationService.shared.findUser(email: email, phoneNumber: phoneNumber, context: context)

        guard user != nil else {
            print("User not found")
            return false
        }

        // Use hardcoded verification code
        let code = "123456"

        // Create verification code entry
        let key = email ?? phoneNumber ?? ""
        let verificationCode = VerificationCode(code: code, email: email, phoneNumber: phoneNumber)
        verificationCodes[key] = verificationCode

        // Simulate sending email/SMS
        print("Verification code sent to \(email ?? phoneNumber ?? ""): \(code)")

        return true
    }

    // Verify the code
    func verifyCode(_ inputCode: String, email: String? = nil, phoneNumber: String? = nil) -> Bool {
        let key = email ?? phoneNumber ?? ""

        guard let storedCode = verificationCodes[key] else {
            print("No verification code found for \(key)")
            return false
        }

        guard !storedCode.isExpired else {
            print("Verification code expired")
            verificationCodes.removeValue(forKey: key)
            return false
        }

        guard !storedCode.isUsed else {
            print("Verification code already used")
            return false
        }

        guard storedCode.code == inputCode else {
            print("Invalid verification code")
            return false
        }

        // Mark code as used (we'll remove it after password reset)
        return true
    }

    // Reset password
    func resetPassword(newPassword: String, email: String? = nil, phoneNumber: String? = nil, context: NSManagedObjectContext) -> Bool {
        let key = email ?? phoneNumber ?? ""

        // Verify code is still valid and not used
        guard let storedCode = verificationCodes[key],
              !storedCode.isExpired,
              !storedCode.isUsed else {
            print("Invalid or expired verification session")
            return false
        }

        // Find user
        guard let user = UserValidationService.shared.findUser(email: email, phoneNumber: phoneNumber, context: context) else {
            print("User not found")
            return false
        }

        // Update password
        user.password = newPassword

        // Save to Core Data
        do {
            try context.save()
            print("Password reset successful for user: \(user.email)")

            // Remove used verification code
            verificationCodes.removeValue(forKey: key)

            return true
        } catch {
            print("Failed to save password: \(error.localizedDescription)")
            return false
        }
    }

    // Clean up expired codes (should be called periodically)
    func cleanupExpiredCodes() {
        verificationCodes = verificationCodes.filter { !$0.value.isExpired }
    }

    // Get stored verification code for debugging
    func getStoredCode(for key: String) -> String? {
        return verificationCodes[key]?.code
    }
}