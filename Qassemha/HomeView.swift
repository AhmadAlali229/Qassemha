//
//  HomeView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @StateObject private var billSplitManager = BillSplitManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var walletBalance: Double = 248.50
    @State private var pendingAmount: Double = 67.25
    @State private var isAnimating = false
    @State private var showingProfile = false
    @State private var showingAllSplits = false
    @State private var recentActivity: [(receipt: Receipt, config: SplitConfiguration)] = []
    @State private var selectedSplitReceipt: Receipt?

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
                                    action: {
                                        navigationCoordinator.switchToScanTab()
                                    }
                                )

                                // Create Group Action
                                QuickActionCard(
                                    icon: "person.3.fill",
                                    title: "New Group",
                                    subtitle: "Add friends",
                                    color: .purple,
                                    action: {
                                        navigationCoordinator.switchToGroupsTab()
                                    }
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
                    if !recentActivity.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)

                                Spacer()

                                Button("See All") {
                                    showingAllSplits = true
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                ForEach(recentActivity.prefix(5), id: \.receipt.id) { activity in
                                    BillSplitCard(
                                        receipt: activity.receipt,
                                        configuration: activity.config,
                                        onTap: {
                                            selectedSplitReceipt = activity.receipt
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
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
                loadRecentActivity()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BillSplitUpdated"))) { _ in
                loadRecentActivity()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingAllSplits) {
                AllBillSplitsView()
            }
            .fullScreenCover(item: $selectedSplitReceipt, onDismiss: {
                // Reload data when returning from split view
                loadRecentActivity()
            }) { receipt in
                if let config = billSplitManager.getConfiguration(for: receipt.id) {
                    SplitSummaryView(receipt: receipt, configuration: config)
                } else {
                    BillSplitView(receipt: receipt)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadRecentActivity() {
        let receipts = CoreDataManager.shared.getSavedReceipts()

        recentActivity = receipts.compactMap { receipt in
            if let config = billSplitManager.getConfiguration(for: receipt.id),
               !config.participants.isEmpty {
                return (receipt: receipt, config: config)
            }
            return nil
        }
        .sorted { $0.config.updatedAt > $1.config.updatedAt }
        .prefix(10)
        .map { $0 }
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
    let receipt: Receipt
    let configuration: SplitConfiguration
    let onTap: () -> Void

    private var participantCount: Int {
        configuration.participants.count
    }

    private var relativeTime: String {
        let calendar = Calendar.current
        let now = Date()
        let updateDate = configuration.updatedAt

        let components = calendar.dateComponents([.day, .hour], from: updateDate, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "Yesterday"
            } else {
                return "\(days) days ago"
            }
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }

    private var status: String {
        let calendar = Calendar.current
        let now = Date()
        let updateDate = configuration.updatedAt

        if let days = calendar.dateComponents([.day], from: updateDate, to: now).day {
            if days >= 2 {
                return "completed"
            } else if days >= 1 {
                return "pending"
            } else {
                return "recent"
            }
        }
        return "recent"
    }

    private var statusColor: Color {
        switch status {
        case "pending":
            return .orange
        case "recent":
            return .blue
        case "completed":
            return .green
        default:
            return .secondary
        }
    }

    private var statusIcon: String {
        switch status {
        case "pending":
            return "clock.fill"
        case "recent":
            return "sparkles"
        case "completed":
            return "checkmark.circle.fill"
        default:
            return "circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(receipt.category.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: receipt.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(receipt.category.color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.storeName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Split with \(participantCount) \(participantCount == 1 ? "person" : "people")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(relativeTime)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Amount and Status
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(receipt.total, specifier: "%.2f")")
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false

    var userName: String {
        return authManager.currentUserName ?? "User"
    }

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

                            if let phone = authManager.currentUserPhoneNumber, !phone.isEmpty {
                                Text(phone)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 20)

                    // Profile Options
                    VStack(spacing: 16) {
                        ProfileOptionCard(
                            icon: "person.fill",
                            title: "Edit Profile",
                            subtitle: "Update your personal information",
                            action: {
                                showingEditProfile = true
                            }
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
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
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

// MARK: - Bill Split Card

struct BillSplitCard: View {
    let receipt: Receipt
    let configuration: SplitConfiguration
    let onTap: () -> Void

    private var participantCount: Int {
        configuration.participants.count
    }

    private var totalAmount: Double {
        receipt.total
    }

    private var splitMethod: String {
        configuration.splitType.rawValue
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Receipt Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(receipt.category.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    VStack(spacing: 2) {
                        Image(systemName: receipt.category.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(receipt.category.color)

                        Image(systemName: "person.3.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(receipt.category.color)
                    }
                }

                // Split Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(receipt.storeName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text("$\(totalAmount, specifier: "%.2f")")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 8) {
                        // Split method badge
                        HStack(spacing: 4) {
                            Image(systemName: configuration.splitType.icon)
                                .font(.system(size: 11, weight: .medium))

                            Text(splitMethod)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.1))
                        )

                        // Participants count
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11, weight: .medium))

                            Text("\(participantCount)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.1))
                        )

                        Spacer()

                        // Date
                        Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Participants preview
                    if !configuration.participants.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(configuration.participants.prefix(4), id: \.id) { participant in
                                Circle()
                                    .fill(Color(hex: participant.avatarColor) ?? .blue)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(participant.name.prefix(1).uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }

                            if configuration.participants.count > 4 {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("+\(configuration.participants.count - 4)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.secondary)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }

                            Spacer()

                            // Arrow
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView()
}