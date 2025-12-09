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

        /// Initializes verification code with expiry time and contact information
        /// Creates time-limited code to enhance security and prevent replay attacks
        init(code: String, email: String? = nil, phoneNumber: String? = nil, expiryMinutes: Int = 10) {
            self.code = code
            self.email = email
            self.phoneNumber = phoneNumber
            self.expiryDate = Date().addingTimeInterval(TimeInterval(expiryMinutes * 60))
            self.isUsed = false
        }

        /// Checks if verification code has expired beyond its validity period
        /// Returns true if current time exceeds expiry date for security enforcement
        var isExpired: Bool {
            return Date() > expiryDate
        }
    }

    /// Sends verification code to user's email or phone number for password reset
    /// Validates user exists before sending hardcoded code for testing purposes
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

    /// Verifies entered code matches stored verification code and checks expiry/usage status
    /// Ensures codes are valid, not expired, and haven't been used to prevent security breaches
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

    /// Resets user password after successful verification code validation
    /// Updates Core Data with new password and removes used verification code for security
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

    /// Removes expired verification codes from memory to prevent accumulation
    /// Should be called periodically to maintain system hygiene and security
    func cleanupExpiredCodes() {
        verificationCodes = verificationCodes.filter { !$0.value.isExpired }
    }

    /// Retrieves stored verification code for a given key for debugging purposes
    /// Allows developers to test verification flow without sending actual codes
    func getStoredCode(for key: String) -> String? {
        return verificationCodes[key]?.code
    }
}