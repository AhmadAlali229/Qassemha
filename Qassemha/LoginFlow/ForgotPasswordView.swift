//
//  ForgotPasswordView.swift
//  Qassemha
//
//  Created by Harjot Singh on 19/09/25.
//

import SwiftUI
import CoreData

struct ForgotPasswordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showingForgotPassword: Bool
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var isUsingPhone = false
    @State private var isAnimating = false
    @State private var showingCodeEntry = false
    @State private var verificationCode = ""
    @State private var codeError = ""
    @State private var showingPasswordResetSuccess = false
    @State private var showingNewPassword = false
    @State private var sendCodeError = ""
    @FocusState private var fieldFocus: Field?
    @FocusState private var codeFieldFocus: Bool

    enum Field {
        case email, phoneNumber
    }

    /// Formats phone number with US standard (###) ###-#### format
    /// Removes non-numeric characters and applies mask for consistent display
    private func formatPhoneNumber(_ input: String) -> String {
        let cleanNumber = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

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

    /// Validates phone number has exactly 10 digits
    /// Required for sending password reset code via SMS
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let cleanNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanNumber.count == 10
    }

    /// Validates email format using regex pattern
    /// Ensures email meets standard format requirements for password reset
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    var body: some View {
        NavigationView {
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
                                            showingForgotPassword = false
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 44, height: 44)

                                            Image(systemName: "xmark")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                        }
                                    }

                                    Spacer()

                                    Text("Reset Password")
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

                                if !showingCodeEntry {
                                    // Logo and Instructions Section
                                    VStack(spacing: 24) {
                                        ZStack {
                                            // Background blur circle
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .frame(width: 100, height: 100)
                                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                                            Image(systemName: "key.fill")
                                                .font(.system(size: 40, weight: .medium))
                                                .foregroundColor(.blue)
                                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                        }

                                        VStack(spacing: 8) {
                                            Text("Forgot Password?")
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)

                                            Text("Enter your email address or phone number to receive a 6-digit verification code")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 10)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                } else {
                                    // Code Entry Section
                                    VStack(spacing: 24) {
                                        ZStack {
                                            Circle()
                                                .fill(.blue.opacity(0.1))
                                                .frame(width: 100, height: 100)

                                            Image(systemName: "lock.shield")
                                                .font(.system(size: 40, weight: .medium))
                                                .foregroundColor(.blue)
                                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                                        }

                                        VStack(spacing: 8) {
                                            Text("Enter Verification Code")
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)

                                            Text("We've sent a 6-digit code to your \(isUsingPhone ? "phone number" : "email address").")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 10)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .frame(minHeight: geometry.size.height * 0.4)

                            if !showingCodeEntry {
                                // Form Card Section
                                VStack(spacing: 0) {
                                    VStack(spacing: 24) {
                                        // Contact Method Selector
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Reset method")
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

                                        // Input Field
                                        if !isUsingPhone {
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
                                                                    .stroke(
                                                                        fieldFocus == .email ?
                                                                        (isValidEmail(email) ? Color.blue : Color.red) :
                                                                        (!email.isEmpty && !isValidEmail(email) ? Color.red : Color.clear),
                                                                        lineWidth: 2
                                                                    )
                                                            )
                                                    )
                                                    .onTapGesture {
                                                        fieldFocus = .email
                                                    }

                                                // Email validation message
                                                if !email.isEmpty && !isValidEmail(email) {
                                                    HStack {
                                                        Image(systemName: "exclamationmark.triangle.fill")
                                                            .foregroundColor(.red)
                                                            .font(.caption)
                                                        Text("Please enter a valid email address")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                        Spacer()
                                                    }
                                                    .padding(.leading, 4)
                                                }
                                            }
                                        } else {
                                            // Phone Field
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
                                        }

                                        // Error message for send code
                                        if !sendCodeError.isEmpty {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption)
                                                Text(sendCodeError)
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                Spacer()
                                            }
                                            .padding(.leading, 4)
                                        }

                                        // Send Reset Button
                                        Button(action: {
                                            sendCodeError = ""

                                            let success = PasswordResetService.shared.sendVerificationCode(
                                                email: isUsingPhone ? nil : email,
                                                phoneNumber: isUsingPhone ? phoneNumber : nil,
                                                context: viewContext
                                            )

                                            if success {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                    showingCodeEntry = true
                                                }
                                            } else {
                                                sendCodeError = "No account found with this \(isUsingPhone ? "phone number" : "email address")"
                                            }

                                            fieldFocus = nil
                                        }) {
                                            HStack {
                                                Text("Send Code")
                                                    .font(.system(size: 18, weight: .semibold))

                                                Image(systemName: "message.fill")
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
                                        .disabled(isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : (email.isEmpty || !isValidEmail(email)))
                                        .opacity((isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : (email.isEmpty || !isValidEmail(email))) ? 0.6 : 1.0)
                                        .scaleEffect((isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : (email.isEmpty || !isValidEmail(email))) ? 0.98 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: (isUsingPhone ? (phoneNumber.isEmpty || !isValidPhoneNumber(phoneNumber)) : (email.isEmpty || !isValidEmail(email))))
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
                            } else {
                                // Code Entry Form
                                VStack(spacing: 0) {
                                    VStack(spacing: 24) {
                                        // Code Input Field
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "lock.fill")
                                                    .foregroundColor(codeFieldFocus ? .blue : .secondary)
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("Verification Code")
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(codeFieldFocus ? .blue : .secondary)
                                            }
                                            .animation(.easeInOut(duration: 0.2), value: codeFieldFocus)

                                            TextField("Enter 6-digit code", text: $verificationCode)
                                                .textFieldStyle(.plain)
                                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                                .keyboardType(.numberPad)
                                                .textContentType(.oneTimeCode)
                                                .focused($codeFieldFocus)
                                                .onChange(of: verificationCode) { _, newValue in
                                                    // Limit to 6 digits
                                                    let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                                                    if filtered != verificationCode {
                                                        verificationCode = filtered
                                                    }
                                                    // Clear error when user starts typing
                                                    if !verificationCode.isEmpty {
                                                        codeError = ""
                                                    }
                                                }
                                                .multilineTextAlignment(.center)
                                                .padding(.vertical, 16)
                                                .padding(.horizontal, 20)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .fill(.white)
                                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .stroke(
                                                                    codeFieldFocus ?
                                                                    (!codeError.isEmpty ? Color.red : Color.blue) :
                                                                    (!codeError.isEmpty ? Color.red : Color.clear),
                                                                    lineWidth: 2
                                                                )
                                                        )
                                                )
                                                .onTapGesture {
                                                    codeFieldFocus = true
                                                }

                                            // Error message
                                            if !codeError.isEmpty {
                                                HStack {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .foregroundColor(.red)
                                                        .font(.caption)
                                                    Text(codeError)
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                    Spacer()
                                                }
                                                .padding(.leading, 4)
                                            }
                                        }

                                        // Verify Button
                                        Button(action: {
                                            let success = PasswordResetService.shared.verifyCode(
                                                verificationCode,
                                                email: isUsingPhone ? nil : email,
                                                phoneNumber: isUsingPhone ? phoneNumber : nil
                                            )

                                            if success {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                                    showingNewPassword = true
                                                    codeError = ""
                                                }
                                            } else {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    codeError = "Invalid or expired verification code. Please try again."
                                                }
                                            }
                                            codeFieldFocus = false
                                        }) {
                                            HStack {
                                                Text("Verify Code")
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
                                        .disabled(verificationCode.count != 6)
                                        .opacity(verificationCode.count != 6 ? 0.6 : 1.0)
                                        .scaleEffect(verificationCode.count != 6 ? 0.98 : 1.0)
                                        .animation(.easeInOut(duration: 0.2), value: verificationCode.count != 6)

                                        // Resend Code Button
                                        Button(action: {
                                            let success = PasswordResetService.shared.sendVerificationCode(
                                                email: isUsingPhone ? nil : email,
                                                phoneNumber: isUsingPhone ? phoneNumber : nil,
                                                context: viewContext
                                            )

                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                verificationCode = ""
                                                if success {
                                                    codeError = ""
                                                } else {
                                                    codeError = "Failed to resend code. Please try again."
                                                }
                                            }
                                        }) {
                                            Text("Resend Code")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.blue)
                                        }

                                        // Back Button
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                showingCodeEntry = false
                                                verificationCode = ""
                                                codeError = ""
                                            }
                                        }) {
                                            Text("Back to Contact Info")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
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
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if fieldFocus != nil || codeFieldFocus {
                        Spacer()
                        Button("Done") {
                            fieldFocus = nil
                            codeFieldFocus = false
                        }
                    }
                }
            }
            .onAppear {
                isAnimating = true
            }
            .onTapGesture {
                fieldFocus = nil
                codeFieldFocus = false
            }
            .sheet(isPresented: $showingNewPassword) {
                NewPasswordView(
                    showingNewPassword: $showingNewPassword,
                    showingPasswordResetSuccess: $showingPasswordResetSuccess,
                    showingForgotPassword: $showingForgotPassword,
                    contactMethod: isUsingPhone ? phoneNumber : email,
                    isPhone: isUsingPhone
                )
            }
            .sheet(isPresented: $showingPasswordResetSuccess) {
                PasswordResetSuccessView(
                    showingPasswordResetSuccess: $showingPasswordResetSuccess,
                    showingForgotPassword: $showingForgotPassword,
                    contactMethod: isUsingPhone ? phoneNumber : email
                )
            }
        }
    }
}

#Preview("Forgot Password") {
    ForgotPasswordView(showingForgotPassword: .constant(true))
}