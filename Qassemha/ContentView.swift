//
//  ContentView.swift
//  Qassemha
//
//  Created by Harjot Singh on 16/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSignup = false

    var body: some View {
        NavigationView {
            if showingSignup {
                SignupView(showingSignup: $showingSignup)
            } else {
                LoginView(showingSignup: $showingSignup)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct LoginView: View {
    @Binding var showingSignup: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var isAnimating = false
    @FocusState private var fieldFocus: Field?

    enum Field {
        case email, password
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
                                // Handle forgot password
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                        }

                        // Sign In Button
                        Button(action: {
                            print("Login attempted with email: \\(email)")
                            fieldFocus = nil
                        }) {
                            HStack {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .semibold))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
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
                        .disabled(email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        .scaleEffect(email.isEmpty || password.isEmpty ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: email.isEmpty || password.isEmpty)

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
                                showingSignup = true
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
    }
}

struct SignupView: View {
    @Binding var showingSignup: Bool
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var agreeToTerms = false
    @FocusState private var fieldFocus: Field?
    @State private var isAnimating = false

    enum Field {
        case fullName, email, password, confirmPassword
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
                                        showingSignup = false
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
                                    print("Signup attempted for: \\(fullName), \\(email)")
                                    fieldFocus = nil
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

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        passwordsMatch &&
        agreeToTerms &&
        password.count >= 6
    }
}

#Preview {
    ContentView()
}

#Preview("Login") {
    LoginView(showingSignup: .constant(false))
}

#Preview("Signup") {
    SignupView(showingSignup: .constant(true))
}
