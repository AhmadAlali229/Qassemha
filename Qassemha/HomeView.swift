//
//  HomeView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var walletBalance: Double = 248.50
    @State private var pendingAmount: Double = 67.25
    @State private var isAnimating = false
    @State private var showingProfile = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    VStack(spacing: 16) {
                        // Welcome Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text("Ready to split some bills?")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            // Profile Button
                            Button(action: {
                                showingProfile = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Balance Cards
                        HStack(spacing: 12) {
                            // Wallet Balance Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "wallet.pass.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)

                                    Text("Wallet Balance")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()
                                }

                                Text("$\(walletBalance, specifier: "%.2f")")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.green.opacity(0.3), lineWidth: 1)
                                    )
                            )

                            // Pending Payments Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.orange)

                                    Text("Pending")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()
                                }

                                Text("$\(pendingAmount, specifier: "%.2f")")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Quick Actions")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Scan Receipt Action
                                QuickActionCard(
                                    icon: "camera.fill",
                                    title: "Scan Receipt",
                                    subtitle: "Start splitting",
                                    color: .blue,
                                    action: {}
                                )

                                // Create Group Action
                                QuickActionCard(
                                    icon: "person.3.fill",
                                    title: "New Group",
                                    subtitle: "Add friends",
                                    color: .purple,
                                    action: {}
                                )

                                // Add Funds Action
                                QuickActionCard(
                                    icon: "plus.circle.fill",
                                    title: "Add Funds",
                                    subtitle: "Top up wallet",
                                    color: .green,
                                    action: {}
                                )

                                // Send Reminder Action
                                QuickActionCard(
                                    icon: "bell.fill",
                                    title: "Send Reminder",
                                    subtitle: "Nudge friends",
                                    color: .orange,
                                    action: {}
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Recent Activity Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Activity")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button("See All") {
                                // See all action
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            // Recent Activity Items
                            RecentActivityCard(
                                icon: "fork.knife",
                                title: "Dinner at Olive Garden",
                                subtitle: "Split with 3 friends",
                                amount: "$67.25",
                                status: "pending",
                                time: "2 hours ago"
                            )

                            RecentActivityCard(
                                icon: "cup.and.saucer.fill",
                                title: "Coffee & Brunch",
                                subtitle: "You paid $45.80",
                                amount: "$11.45",
                                status: "received",
                                time: "Yesterday"
                            )

                            RecentActivityCard(
                                icon: "film.fill",
                                title: "Movie Night",
                                subtitle: "Split with Movie Crew",
                                amount: "$28.50",
                                status: "completed",
                                time: "3 days ago"
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.05),
                        Color.cyan.opacity(0.02),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarHidden(true)
            .onAppear {
                isAnimating = true
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(width: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: String
    let status: String
    let time: String

    private var statusColor: Color {
        switch status {
        case "pending":
            return .orange
        case "received":
            return .green
        case "completed":
            return .blue
        default:
            return .secondary
        }
    }

    private var statusIcon: String {
        switch status {
        case "pending":
            return "clock.fill"
        case "received":
            return "arrow.down.circle.fill"
        case "completed":
            return "checkmark.circle.fill"
        default:
            return "circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Text(time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Amount and Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(statusColor)

                    Text(status.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var userName = "Harjot Singh"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Close Button
                    HStack {
                        Spacer()
                        Button("Done") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)

                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
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

                            Text(String(userName.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // User Info
                        VStack(spacing: 8) {
                            Text(userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text(authManager.currentUserEmail ?? "No email")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    // Profile Options
                    VStack(spacing: 16) {
                        ProfileOptionCard(
                            icon: "person.fill",
                            title: "Edit Profile",
                            subtitle: "Update your personal information",
                            action: {}
                        )

                        ProfileOptionCard(
                            icon: "arrow.right.square.fill",
                            title: "Logout",
                            subtitle: "Sign out of your account",
                            action: {
                                dismiss()
                                authManager.logout()
                            }
                        )


                    }
                    .padding(.horizontal, 20)

                    // App Info
                    VStack(spacing: 8) {
                        Text("Qassemha")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text("Version 1.0.0")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
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
            .navigationBarHidden(true)
        }
    }
}

struct ProfileOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}