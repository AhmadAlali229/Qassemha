//
//  EditProfileView.swift
//  Qassemha
//
//  Edit user profile information
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthenticationManager.shared

    @State private var name: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var showingSaveSuccess = false

    /// Initializes view with current user profile data
    /// Pre-populates form fields from AuthenticationManager
    init() {
        _name = State(initialValue: AuthenticationManager.shared.currentUserName ?? "")
        _email = State(initialValue: AuthenticationManager.shared.currentUserEmail ?? "")
        _phoneNumber = State(initialValue: AuthenticationManager.shared.currentUserPhoneNumber ?? "")
    }

    /// Checks if any profile field has been modified
    /// Enables save button only when changes are detected
    var hasChanges: Bool {
        name != (authManager.currentUserName ?? "") ||
        email != (authManager.currentUserEmail ?? "") ||
        phoneNumber != (authManager.currentUserPhoneNumber ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Avatar
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Text(String(name.prefix(1).isEmpty ? "U" : name.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }

                        Text("Profile Picture")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                TextField("Enter your name", text: $name)
                                    .font(.system(size: 16, weight: .medium))
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }

                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                TextField("Enter your email", text: $email)
                                    .font(.system(size: 16, weight: .medium))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disabled(true) // Email typically can't be changed
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )

                            Text("Email cannot be changed")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)

                                TextField("Enter your phone number", text: $phoneNumber)
                                    .font(.system(size: 16, weight: .medium))
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))

                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(hasChanges ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!hasChanges)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.02),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Profile Updated", isPresented: $showingSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been successfully updated.")
        }
    }

    // MARK: - Helper Methods

    /// Saves modified profile data to AuthenticationManager
    /// Shows success feedback and dismisses view after save
    private func saveProfile() {
        // Update user information
        authManager.updateUserName(name)
        authManager.updateUserPhoneNumber(phoneNumber)

        // Show success alert
        showingSaveSuccess = true
    }
}

#Preview {
    EditProfileView()
}
