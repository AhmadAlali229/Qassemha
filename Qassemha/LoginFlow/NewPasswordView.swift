//
//  NewPasswordView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI
import CoreData

struct NewPasswordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showingNewPassword: Bool
    @Binding var showingPasswordResetSuccess: Bool
    @Binding var showingForgotPassword: Bool
    let contactMethod: String
    let isPhone: Bool

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isAnimating = false
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var resetError = ""
    @FocusState private var fieldFocus: Field?

    enum Field {
        case newPassword, confirmPassword
    }

    /// Checks if password is not empty
    /// Basic password validation for password reset flow
    private func isValidPassword(_ password: String) -> Bool {
        return !password.isEmpty
    }

    /// Validates both password fields meet requirements and match
    /// Ensures password confirmation matches and provides specific error messages
    private func validatePasswords() -> Bool {
        passwordError = ""
        confirmPasswordError = ""

        if newPassword.isEmpty {
            passwordError = "Password is required"
            return false
        }


        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password"
            return false
        }

        if newPassword != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            return false
        }

        return true
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.cyan.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(spacing: 20) {
                            // Custom Header
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showingNewPassword = false
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }

                                Spacer()

                                Text("New Password")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)

                                Spacer()

                                // Invisible spacer for balance
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)

                            // Logo and Instructions Section
                            VStack(spacing: 24) {
                                ZStack {
                                    // Background blur circle
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                                    Image(systemName: "lock.rotation")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(.blue)
                                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                }

                                VStack(spacing: 8) {
                                    Text("Create New Password")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Enter a strong password that you'll remember for your account")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(minHeight: geometry.size.height * 0.4)

                        // Form Card Section
                        VStack(spacing: 0) {
                            VStack(spacing: 24) {
                                // New Password Field
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(fieldFocus == .newPassword ? .blue : .secondary)
                                            .font(.system(size: 16, weight: .medium))
                                        Text("New Password")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(fieldFocus == .newPassword ? .blue : .secondary)
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                    HStack {
                                        if showPassword {
                                            TextField("Enter new password", text: $newPassword)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 16))
                                                .focused($fieldFocus, equals: .newPassword)
                                                .onChange(of: newPassword) { _, _ in
                                                    if !passwordError.isEmpty {
                                                        passwordError = ""
                                                    }
                                                }
                                        } else {
                                            SecureField("Enter new password", text: $newPassword)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 16))
                                                .focused($fieldFocus, equals: .newPassword)
                                                .onChange(of: newPassword) { _, _ in
                                                    if !passwordError.isEmpty {
                                                        passwordError = ""
                                                    }
                                                }
                                        }

                                        Button(action: {
                                            showPassword.toggle()
                                        }) {
                                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        fieldFocus == .newPassword ?
                                                        (!passwordError.isEmpty ? Color.red : Color.blue) :
                                                        (!passwordError.isEmpty ? Color.red : Color.clear),
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                    .onTapGesture {
                                        fieldFocus = .newPassword
                                    }

                                    // Password validation message
                                    if !passwordError.isEmpty {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                            Text(passwordError)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                            Spacer()
                                        }
                                        .padding(.leading, 4)
                                    }
                                }

                                // Confirm Password Field
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(fieldFocus == .confirmPassword ? .blue : .secondary)
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Confirm Password")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(fieldFocus == .confirmPassword ? .blue : .secondary)
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                    HStack {
                                        if showConfirmPassword {
                                            TextField("Confirm new password", text: $confirmPassword)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 16))
                                                .focused($fieldFocus, equals: .confirmPassword)
                                                .onChange(of: confirmPassword) { _, _ in
                                                    if !confirmPasswordError.isEmpty {
                                                        confirmPasswordError = ""
                                                    }
                                                }
                                        } else {
                                            SecureField("Confirm new password", text: $confirmPassword)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 16))
                                                .focused($fieldFocus, equals: .confirmPassword)
                                                .onChange(of: confirmPassword) { _, _ in
                                                    if !confirmPasswordError.isEmpty {
                                                        confirmPasswordError = ""
                                                    }
                                                }
                                        }

                                        Button(action: {
                                            showConfirmPassword.toggle()
                                        }) {
                                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        fieldFocus == .confirmPassword ?
                                                        (!confirmPasswordError.isEmpty ? Color.red : (confirmPassword == newPassword && !confirmPassword.isEmpty ? Color.green : Color.blue)) :
                                                        (!confirmPasswordError.isEmpty ? Color.red : (confirmPassword == newPassword && !confirmPassword.isEmpty ? Color.green : Color.clear)),
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                    .onTapGesture {
                                        fieldFocus = .confirmPassword
                                    }

                                    // Confirm password validation message
                                    if !confirmPasswordError.isEmpty {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                            Text(confirmPasswordError)
                                                .font(.caption)
                                                .foregroundColor(.red)
                                            Spacer()
                                        }
                                        .padding(.leading, 4)
                                    } else if !confirmPassword.isEmpty && confirmPassword == newPassword {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text("Passwords match")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                            Spacer()
                                        }
                                        .padding(.leading, 4)
                                    }
                                }

                                // Error message for reset
                                if !resetError.isEmpty {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                        Text(resetError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.leading, 4)
                                }

                                // Reset Password Button
                                Button(action: {
                                    if validatePasswords() {
                                        resetError = ""

                                        let success = PasswordResetService.shared.resetPassword(
                                            newPassword: newPassword,
                                            email: isPhone ? nil : contactMethod,
                                            phoneNumber: isPhone ? contactMethod : nil,
                                            context: viewContext
                                        )

                                        if success {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                showingNewPassword = false
                                                showingPasswordResetSuccess = true
                                            }
                                        } else {
                                            resetError = "Failed to reset password. Please try again."
                                        }
                                    }
                                    fieldFocus = nil
                                }) {
                                    HStack {
                                        Text("Reset Password")
                                            .font(.system(size: 18, weight: .semibold))

                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .cyan]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                                .opacity((newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword) ? 0.6 : 1.0)
                                .scaleEffect((newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword) ? 0.98 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: (newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword))
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 32)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
                            )
                            .padding(.horizontal, 20)

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if fieldFocus != nil {
                    Spacer()
                    Button("Done") {
                        fieldFocus = nil
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onTapGesture {
            fieldFocus = nil
        }
    }
}

#Preview("New Password") {
    NewPasswordView(
        showingNewPassword: .constant(true),
        showingPasswordResetSuccess: .constant(false),
        showingForgotPassword: .constant(true),
        contactMethod: "test@example.com",
        isPhone: false
    )
}