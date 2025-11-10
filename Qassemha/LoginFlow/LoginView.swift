//
//  LoginView.swift
//  Qassemha
//
//  Created by Harjot Singh on 19/09/25.
//

import SwiftUI
import CoreData

struct LoginView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var isAnimating = false
    @State private var isUsingPhone = false
    @State private var showingForgotPassword = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoggingIn = false
    @FocusState private var fieldFocus: Field?

    enum Field {
        case email, phoneNumber, password
    }

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

    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // Support US format (10 digits) or international format (11-15 digits with country code)
        return cleanNumber.count == 10 || (cleanNumber.count >= 11 && cleanNumber.count <= 15)
    }

    private func validateAndLogin() {
        isLoggingIn = true
        errorMessage = ""
        showingError = false

        let userValidationService = UserValidationService.shared

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoggingIn = false

            // First check if user exists
            let existingUser: User?
            if isUsingPhone {
                existingUser = userValidationService.findUser(phoneNumber: phoneNumber, context: viewContext)
            } else {
                existingUser = userValidationService.findUser(email: email, context: viewContext)
            }

            guard existingUser != nil else {
                errorMessage = isUsingPhone ? "No account found with this phone number. Please check your phone number or create a new account." : "No account found with this email address. Please check your email or create a new account."
                showingError = true
                return
            }

            // Now validate with password
            let validUser: User?
            if isUsingPhone {
                validUser = userValidationService.validateUser(phoneNumber: phoneNumber, password: password, context: viewContext)
            } else {
                validUser = userValidationService.validateUser(email: email, password: password, context: viewContext)
            }

            guard let user = validUser else {
                errorMessage = "Incorrect password."
                showingError = true
                return
            }

            // Login successful
            let loginEmail = user.email ?? (isUsingPhone ? phoneNumber : email)
            let userName = user.fullName ?? "User"
            authManager.login(email: loginEmail, name: userName)
            print("Login successful for user: \(user.fullName ?? "Unknown"), Email: \(user.email ?? "N/A")")
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

                VStack(spacing: 0) {
                    // Top Section with Logo and Welcome
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Spacer()

                            // Floating Logo Section
                            VStack(spacing: 12) {
                                ZStack {
                                    // Background blur circle
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 110, height: 110)
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                                    Image("QassemhaLogo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                }

                                VStack(spacing: 4) {
                                    Text("Welcome Back")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Sign in to continue")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)

                                    if #available(iOS 18.0, *) {
                                        LiquidGlassAttributionView()
                                            .padding(.top, 12)
                                    } else {
                                        FallbackAttributionView()
                                            .padding(.top, 12)
                                    }
                                }
                            }
                            Spacer()
                        }
                        Spacer()
                    }

                    // Card Container
                    VStack(spacing: 20) {
                        // Form Fields
                        VStack(spacing: 16) {
                            // Login Method Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Login with")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                HStack(spacing: 0) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isUsingPhone = false
                                            fieldFocus = nil
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "envelope")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Email")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(isUsingPhone ? .secondary : .white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isUsingPhone ? Color.clear : Color.blue)
                                        )
                                    }

                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isUsingPhone = true
                                            fieldFocus = nil
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "phone")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Phone")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(isUsingPhone ? .white : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isUsingPhone ? Color.blue : Color.clear)
                                        )
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }

                            // Email or Phone Field
                            if !isUsingPhone {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "envelope")
                                            .foregroundColor(fieldFocus == .email ? .blue : .secondary)
                                            .font(.system(size: 15, weight: .medium))
                                        Text("Email Address")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(fieldFocus == .email ? .blue : .secondary)
                                    }
                                    .animation(.easeInOut(duration: 0.2), value: fieldFocus)

                                    TextField("", text: $email)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 16))
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .focused($fieldFocus, equals: .email)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(fieldFocus == .email ? Color.blue : Color.clear, lineWidth: 2)
                                                )
                                        )
                                        .onTapGesture {
                                            fieldFocus = .email
                                        }
                                }
                            } else {
                                // Phone Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "phone")
                                            .foregroundColor(fieldFocus == .phoneNumber ? .blue : .secondary)
                                            .font(.system(size: 15, weight: .medium))
                                        Text("Phone Number")
                                            .font(.system(size: 14, weight: .medium))
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
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 18)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(.white)
                                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14)
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
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(fieldFocus == .password ? .blue : .secondary)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Password")
                                        .font(.system(size: 14, weight: .medium))
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
                                            .font(.system(size: 15))
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(fieldFocus == .password ? Color.blue : Color.clear, lineWidth: 2)
                                        )
                                )
                                .onTapGesture {
                                    fieldFocus = .password
                                }
                            }
                        }

                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot password?") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showingForgotPassword = true
                                }
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                        }

                        // Error Message
                        if showingError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 14, weight: .medium))

                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .animation(.easeInOut(duration: 0.3), value: showingError)
                        }

                        // Sign In Button
                        Button(action: {
                            fieldFocus = nil
                            validateAndLogin()
                        }) {
                            HStack {
                                if isLoggingIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)

                                    Text("Signing In...")
                                        .font(.system(size: 17, weight: .semibold))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .semibold))

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .disabled(isLoggingIn || (isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : email.isEmpty) || password.isEmpty)
                        .opacity(isLoggingIn || (isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : email.isEmpty) || password.isEmpty ? 0.6 : 1.0)
                        .scaleEffect(isLoggingIn || (isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : email.isEmpty) || password.isEmpty ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isLoggingIn || (isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : email.isEmpty) || password.isEmpty)

                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: -3)
                    )
                    .padding(.horizontal, 16)

                    Spacer()

                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("New to Qassemha?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Button("Create Account") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                authManager.showSignup()
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 30)
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
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(showingForgotPassword: $showingForgotPassword)
        }
    }
}

#Preview("Login") {
    LoginView()
}