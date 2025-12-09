//
//  SignupView.swift
//  Qassemha
//
//  Created by Harjot Singh on 19/09/25.
//

import SwiftUI
import CoreData

struct SignupView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var fullName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var agreeToTerms = false
    @FocusState private var fieldFocus: Field?
    @State private var isAnimating = false

    enum Field {
        case fullName, email, phoneNumber, password, confirmPassword
    }

    /// Formats phone number input with proper US/international formatting
    /// Supports both US format (###) ###-#### and international format with country code
    private func formatPhoneNumber(_ input: String) -> String {
        let cleanNumber = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        // International format (with country code)
        if cleanNumber.count > 10 {
            var result = "("
            var index = cleanNumber.startIndex

            // Add country code (first 2-3 digits)
            let countryCodeLength = min(3, cleanNumber.count)
            for i in 0..<countryCodeLength {
                if index < cleanNumber.endIndex {
                    result.append(cleanNumber[index])
                    index = cleanNumber.index(after: index)
                }
                // Stop country code at 3 digits or if we've used all digits
                if i == 2 || cleanNumber.distance(from: index, to: cleanNumber.endIndex) <= 0 {
                    break
                }
            }
            result.append(")")

            // Add remaining digits
            while index < cleanNumber.endIndex {
                result.append(cleanNumber[index])
                index = cleanNumber.index(after: index)
            }

            return result
        }

        // US format (10 digits)
        let mask = "(###) ###-####"
        var result = ""
        var index = cleanNumber.startIndex

        for ch in mask where index < cleanNumber.endIndex {
            if ch == "#" {
                result.append(cleanNumber[index])
                index = cleanNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }

        return result
    }

    /// Validates phone number format for US and international numbers
    /// Ensures phone number has correct digit count for registration
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Support US format (10 digits) or international format (11-15 digits with country code)
        return cleanNumber.count == 10 || (cleanNumber.count >= 11 && cleanNumber.count <= 15)
    }

    /// Saves new user data to Core Data storage
    /// Creates User entity with trimmed/formatted data and auto-login on success
    private func saveUserData() {
        let newUser = User(context: viewContext)
        newUser.userID = UUID()
        newUser.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        newUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        newUser.phoneNumber = phoneNumber
        newUser.password = password
        newUser.createdAt = Date()

        do {
            try viewContext.save()
            print("User data saved successfully: \(newUser.fullName ?? ""), \(newUser.email ?? ""), \(newUser.phoneNumber ?? "")")
        } catch {
            print("Failed to save user data: \(error.localizedDescription)")
        }
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
                                        authManager.showLogin()
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                }

                                Spacer()

                                Text("Create Account")
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

                            // Logo and Welcome Section
                            VStack(spacing: 24) {
                                ZStack {
                                    // Background blur circle
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                                    Image("QassemhaLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70, height: 70)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                }

                                VStack(spacing: 8) {
                                    Text("Join Qassemha")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Create your account and start exploring")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(minHeight: geometry.size.height * 0.3)

                        // Form Card Section
                        VStack(spacing: 0) {
                            VStack(spacing: 24) {
                                // Form Fields
                                VStack(spacing: 20) {
                                    // Full Name Field
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "person")
                                                .foregroundColor(fieldFocus == .fullName ? .blue : .secondary)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Full Name")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(fieldFocus == .fullName ? .blue : .secondary)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                        TextField("", text: $fullName)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 16))
                                            .focused($fieldFocus, equals: .fullName)
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(.white)
                                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(fieldFocus == .fullName ? Color.blue : Color.clear, lineWidth: 2)
                                                    )
                                            )
                                            .onTapGesture {
                                                fieldFocus = .fullName
                                            }
                                    }

                                    // Email Field
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "envelope")
                                                .foregroundColor(fieldFocus == .email ? .blue : .secondary)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Email Address")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(fieldFocus == .email ? .blue : .secondary)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                        TextField("", text: $email)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 16))
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                            .focused($fieldFocus, equals: .email)
                                            .padding(.vertical, 16)
                                            .padding(.horizontal, 20)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(.white)
                                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(fieldFocus == .email ? Color.blue : Color.clear, lineWidth: 2)
                                                    )
                                            )
                                            .onTapGesture {
                                                fieldFocus = .email
                                            }
                                    }

                                    // Phone Number Field
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "phone")
                                                .foregroundColor(fieldFocus == .phoneNumber ? .blue : .secondary)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Phone Number")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(fieldFocus == .phoneNumber ? .blue : .secondary)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                        TextField("", text: $phoneNumber)
                                            .textFieldStyle(.plain)
                                            .font(.system(size: 16))
                                            .keyboardType(.phonePad)
                                            .focused($fieldFocus, equals: .phoneNumber)
                                            .onChange(of: phoneNumber) { _, newValue in
                                                phoneNumber = formatPhoneNumber(newValue)
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
                                                                fieldFocus == .phoneNumber ?
                                                                (isValidPhoneNumber(phoneNumber) ? Color.blue : Color.red) :
                                                                (!phoneNumber.isEmpty && !isValidPhoneNumber(phoneNumber) ? Color.red : Color.clear),
                                                                lineWidth: 2
                                                            )
                                                    )
                                            )
                                            .onTapGesture {
                                                fieldFocus = .phoneNumber
                                            }

                                        // Phone validation message
                                        if !phoneNumber.isEmpty && !isValidPhoneNumber(phoneNumber) {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                                Text("Please enter a valid phone number")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                Spacer()
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }

                                    // Password Field
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "lock")
                                                .foregroundColor(fieldFocus == .password ? .blue : .secondary)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Password")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(fieldFocus == .password ? .blue : .secondary)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                        HStack {
                                            if showingPassword {
                                                TextField("", text: $password)
                                                    .textFieldStyle(.plain)
                                                    .font(.system(size: 16))
                                                    .focused($fieldFocus, equals: .password)
                                            } else {
                                                SecureField("", text: $password)
                                                    .textFieldStyle(.plain)
                                                    .font(.system(size: 16))
                                                    .focused($fieldFocus, equals: .password)
                                            }

                                            Button(action: {
                                                showingPassword.toggle()
                                            }) {
                                                Image(systemName: showingPassword ? "eye.slash" : "eye")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 16))
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
                                                        .stroke(fieldFocus == .password ? Color.blue : Color.clear, lineWidth: 2)
                                                )
                                        )
                                        .onTapGesture {
                                            fieldFocus = .password
                                        }
                                    }

                                    // Confirm Password Field
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "lock.shield")
                                                .foregroundColor(fieldFocus == .confirmPassword ? .blue : .secondary)
                                                .font(.system(size: 16, weight: .medium))
                                            Text("Confirm Password")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(fieldFocus == .confirmPassword ? .blue : .secondary)
                                        }
                                        .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                        HStack {
                                            if showingConfirmPassword {
                                                TextField("", text: $confirmPassword)
                                                    .textFieldStyle(.plain)
                                                    .font(.system(size: 16))
                                                    .focused($fieldFocus, equals: .confirmPassword)
                                            } else {
                                                SecureField("", text: $confirmPassword)
                                                    .textFieldStyle(.plain)
                                                    .font(.system(size: 16))
                                                    .focused($fieldFocus, equals: .confirmPassword)
                                            }

                                            Button(action: {
                                                showingConfirmPassword.toggle()
                                            }) {
                                                Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                                    .foregroundColor(.secondary)
                                                    .font(.system(size: 16))
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
                                                            (passwordsMatch ? Color.blue : Color.red) :
                                                            (!confirmPassword.isEmpty && !passwordsMatch ? Color.red : Color.clear),
                                                            lineWidth: 2
                                                        )
                                                )
                                        )
                                        .onTapGesture {
                                            fieldFocus = .confirmPassword
                                        }

                                        // Password validation message
                                        if !confirmPassword.isEmpty && !passwordsMatch {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                                Text("Passwords do not match")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                Spacer()
                                            }
                                            .padding(.leading, 4)
                                        }
                                    }
                                }

                                // Terms and Conditions
                                HStack(alignment: .top, spacing: 12) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            agreeToTerms.toggle()
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(agreeToTerms ? Color.blue : Color.clear)
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(agreeToTerms ? Color.blue : Color.secondary, lineWidth: 2)
                                                )

                                            if agreeToTerms {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("I agree to the Terms of Service and Privacy Policy")
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()
                                }

                                // Create Account Button
                                Button(action: {
                                    fieldFocus = nil

                                    // Save user data to Core Data
                                    saveUserData()

                                    // Save authentication state
                                    authManager.login(
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                                        name: fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    )
                                }) {
                                    HStack {
                                        Text("Create Account")
                                            .font(.system(size: 18, weight: .semibold))

                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
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
                                .disabled(!isFormValid)
                                .opacity(isFormValid ? 1.0 : 0.6)
                                .scaleEffect(isFormValid ? 1.0 : 0.98)
                                .animation(.easeInOut(duration: 0.2), value: isFormValid)
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

    /// Checks if password and confirm password fields match
    /// Provides real-time validation feedback for password entry
    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    /// Validates entire signup form for completeness and correctness
    /// Ensures all required fields meet validation criteria before submission
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        isValidPhoneNumber(phoneNumber) &&
        !password.isEmpty &&
        passwordsMatch &&
        agreeToTerms &&
        password.count >= 6
    }
}

#Preview("Signup") {
    SignupView()
}