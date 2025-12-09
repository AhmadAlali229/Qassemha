//
//  PasswordResetSuccessView.swift
//  Qassemha
//
//  Created by Harjot Singh on 19/09/25.
//

import SwiftUI

struct PasswordResetSuccessView: View {
    @Binding var showingPasswordResetSuccess: Bool
    @Binding var showingForgotPassword: Bool
    let contactMethod: String

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.1),
                        Color.mint.opacity(0.05),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Success Section
                    VStack(spacing: 32) {
                        // Success Icon
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.green)
                                .scaleEffect(isAnimating ? 1.02 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                        }

                        // Success Message
                        VStack(spacing: 16) {
                            Text("Password Updated Successfully!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text("Your new password has been set for \(contactMethod). You can now sign in with your new password.")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineLimit(nil)
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // Action Button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingPasswordResetSuccess = false
                            showingForgotPassword = false
                        }
                    }) {
                        HStack {
                            Text("Back to Login")
                                .font(.system(size: 18, weight: .semibold))

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .mint]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

#Preview("Password Reset Success") {
    PasswordResetSuccessView(
        showingPasswordResetSuccess: .constant(true),
        showingForgotPassword: .constant(true),
        contactMethod: "test@example.com"
    )
}