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
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var isAnimating = false
    @State private var showingProfile = false
    @State private var showingAllSplits = false
    @State private var showingAddFunds = false
    @State private var recentActivity: [(receipt: Receipt, config: SplitConfiguration)] = []
    @State private var selectedSplitReceipt: Receipt?
    @State private var selectedReceiptTab: ReceiptTab = .received

    enum ReceiptTab {
        case received
        case sent
    }

    // Example receipts for demonstration (not saved to database)
    private var exampleReceivedReceipts: [(receipt: Receipt, config: SplitConfiguration)] {
        // Example 1: Equal Split
        let receipt1 = Receipt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            storeName: "Pizza Palace",
            storeAddress: "123 Main St",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            items: [
                ReceiptItem(name: "Large Pepperoni Pizza", quantity: 1, unitPrice: 18.99, totalPrice: 18.99, category: .main, tags: []),
                ReceiptItem(name: "Garlic Bread", quantity: 1, unitPrice: 5.99, totalPrice: 5.99, category: .side, tags: []),
                ReceiptItem(name: "Coca Cola 2L", quantity: 1, unitPrice: 3.49, totalPrice: 3.49, category: .beverage, tags: [])
            ],
            subtotal: 28.47,
            tax: 2.28,
            tip: 5.00,
            total: 35.75,
            currency: currencyManager.currencySymbol,
            scanType: .qrCode,
            category: .food,
            receiptType: .received
        )

        // Example 1 participants
        let sarah = Participant(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Sarah", phoneNumber: "+1234567890", avatarColor: "#FF6B6B")
        let mike = Participant(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, name: "Mike", phoneNumber: "+1234567891", avatarColor: "#4ECDC4")
        let you1 = Participant(id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!, name: "You", phoneNumber: authManager.currentUserPhoneNumber ?? "+1234567892", avatarColor: "#45B7D1")

        let config1 = SplitConfiguration(
            receiptId: receipt1.id,
            splitType: .equal,
            participants: [sarah, mike, you1],
            includeTax: true,
            includeTip: true,
            paidParticipants: [sarah.id],  // Sarah has already paid
            adminId: sarah.id  // Sarah created this bill
        )

        // Example 2: By Item Assignment (5 participants)
        let receipt2 = Receipt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            storeName: "Coffee Corner",
            storeAddress: "456 Oak Ave",
            date: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
            items: [
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Caramel Latte", quantity: 1, unitPrice: 5.50, totalPrice: 5.50, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, name: "Cappuccino", quantity: 1, unitPrice: 4.75, totalPrice: 4.75, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!, name: "Iced Americano", quantity: 1, unitPrice: 4.25, totalPrice: 4.25, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!, name: "Matcha Latte", quantity: 1, unitPrice: 6.00, totalPrice: 6.00, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!, name: "Espresso", quantity: 1, unitPrice: 3.50, totalPrice: 3.50, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!, name: "Chocolate Muffin", quantity: 2, unitPrice: 3.25, totalPrice: 6.50, category: .food, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000007")!, name: "Croissant", quantity: 2, unitPrice: 3.50, totalPrice: 7.00, category: .food, tags: [])
            ],
            subtotal: 37.50,
            tax: 3.00,
            tip: 6.50,
            total: 47.00,
            currency: currencyManager.currencySymbol,
            scanType: .qrCode,
            category: .food,
            receiptType: .received
        )

        let participant1 = Participant(id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, name: "Emma", phoneNumber: "+1234567893", avatarColor: "#95E1D3")
        let participant2 = Participant(id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!, name: "John", phoneNumber: "+1234567894", avatarColor: "#F38181")
        let participant3 = Participant(id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!, name: "Rachel", phoneNumber: "+1234567895", avatarColor: "#FF9A8B")
        let participant4 = Participant(id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!, name: "David", phoneNumber: "+1234567896", avatarColor: "#6A89CC")
        let participant5 = Participant(id: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!, name: "You", phoneNumber: authManager.currentUserPhoneNumber ?? "+1234567897", avatarColor: "#AA96DA")

        var config2 = SplitConfiguration(
            receiptId: receipt2.id,
            splitType: .individual,
            participants: [participant1, participant2, participant3, participant4, participant5],
            includeTax: true,
            includeTip: true,
            paidParticipants: [participant1.id, participant2.id],  // Emma and John have already paid
            adminId: participant1.id  // Emma created this bill
        )

        // Assign items to participants
        config2.itemAssignments = [
            // Emma's Caramel Latte
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                participants: [participant1.id],
                splitType: .equal
            ),
            // John's Cappuccino
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
                participants: [participant2.id],
                splitType: .equal
            ),
            // Rachel's Iced Americano
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
                participants: [participant3.id],
                splitType: .equal
            ),
            // David's Matcha Latte
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
                participants: [participant4.id],
                splitType: .equal
            ),
            // Your Espresso
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
                participants: [participant5.id],
                splitType: .equal
            ),
            // Chocolate Muffins (shared by Emma, Rachel, and You)
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!,
                participants: [participant1.id, participant3.id, participant5.id],
                splitType: .equal
            ),
            // Croissants (shared by John, David, and You)
            ItemAssignment(
                itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000007")!,
                participants: [participant2.id, participant4.id, participant5.id],
                splitType: .equal
            )
        ]

        return [
            (receipt: receipt1, config: config1),
            (receipt: receipt2, config: config2)
        ]
    }

    private var exampleSentReceipts: [(receipt: Receipt, config: SplitConfiguration)] {
        // Example 1: Restaurant Split (Equal)
        let receipt1 = Receipt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            storeName: "Bella Italia",
            storeAddress: "789 Main St",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            items: [
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!, name: "Pasta Carbonara", quantity: 2, unitPrice: 16.50, totalPrice: 33.00, category: .main, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!, name: "Margherita Pizza", quantity: 1, unitPrice: 14.00, totalPrice: 14.00, category: .main, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!, name: "Caesar Salad", quantity: 2, unitPrice: 8.50, totalPrice: 17.00, category: .appetizer, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000004")!, name: "Tiramisu", quantity: 1, unitPrice: 7.50, totalPrice: 7.50, category: .dessert, tags: [])
            ],
            subtotal: 71.50,
            tax: 5.72,
            tip: 12.00,
            total: 89.22,
            currency: currencyManager.currencySymbol,
            scanType: .qrCode,
            category: .food,
            receiptType: .sent
        )

        let alex1 = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!, name: "Alex", phoneNumber: "+1234567898", avatarColor: "#66D9EF")
        let maria1 = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!, name: "Maria", phoneNumber: "+1234567899", avatarColor: "#F92672")
        let you3 = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000003")!, name: "You", phoneNumber: authManager.currentUserPhoneNumber ?? "+1234567900", avatarColor: "#A6E22E")

        let config1 = SplitConfiguration(
            receiptId: receipt1.id,
            splitType: .equal,
            participants: [alex1, maria1, you3],
            includeTax: true,
            includeTip: true,
            paidParticipants: [you3.id],  // You have already paid
            adminId: you3.id  // You created this bill
        )

        // Example 2: Movie Night (By Item - 4 participants)
        let receipt2 = Receipt(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            storeName: "CineMax Theater",
            storeAddress: "321 Cinema Blvd",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            items: [
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000005")!, name: "Movie Ticket", quantity: 4, unitPrice: 12.50, totalPrice: 50.00, category: .other, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000006")!, name: "Large Popcorn", quantity: 2, unitPrice: 8.00, totalPrice: 16.00, category: .food, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000007")!, name: "Soda", quantity: 4, unitPrice: 5.50, totalPrice: 22.00, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "30000000-0000-0000-0000-000000000008")!, name: "Nachos", quantity: 1, unitPrice: 6.50, totalPrice: 6.50, category: .food, tags: [])
            ],
            subtotal: 94.50,
            tax: 7.56,
            tip: 0.00,
            total: 102.06,
            currency: currencyManager.currencySymbol,
            scanType: .qrCode,
            category: .entertainment,
            receiptType: .sent
        )

        let chris = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000004")!, name: "Chris", phoneNumber: "+1234567901", avatarColor: "#FD971F")
        let sam = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000005")!, name: "Sam", phoneNumber: "+1234567902", avatarColor: "#AE81FF")
        let taylor = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000006")!, name: "Taylor", phoneNumber: "+1234567903", avatarColor: "#E6DB74")
        let you4 = Participant(id: UUID(uuidString: "40000000-0000-0000-0000-000000000007")!, name: "You", phoneNumber: authManager.currentUserPhoneNumber ?? "+1234567904", avatarColor: "#A6E22E")

        var config2 = SplitConfiguration(
            receiptId: receipt2.id,
            splitType: .individual,
            participants: [chris, sam, taylor, you4],
            includeTax: true,
            includeTip: false,
            paidParticipants: [you4.id, chris.id, sam.id],  // You, Chris, and Sam have paid
            adminId: you4.id  // You created this bill
        )

        // Assign items to participants
        config2.itemAssignments = [
            // Movie tickets - everyone gets one
            ItemAssignment(
                itemId: UUID(uuidString: "30000000-0000-0000-0000-000000000005")!,
                participants: [chris.id, sam.id, taylor.id, you4.id],
                splitType: .equal
            ),
            // Popcorn - shared by Chris and Sam
            ItemAssignment(
                itemId: UUID(uuidString: "30000000-0000-0000-0000-000000000006")!,
                participants: [chris.id, sam.id],
                splitType: .equal
            ),
            // Sodas - everyone gets one
            ItemAssignment(
                itemId: UUID(uuidString: "30000000-0000-0000-0000-000000000007")!,
                participants: [chris.id, sam.id, taylor.id, you4.id],
                splitType: .equal
            ),
            // Nachos - just Taylor
            ItemAssignment(
                itemId: UUID(uuidString: "30000000-0000-0000-0000-000000000008")!,
                participants: [taylor.id],
                splitType: .equal
            )
        ]

        return [
            (receipt: receipt1, config: config1),
            (receipt: receipt2, config: config2)
        ]
    }

    var filteredRecentActivity: [(receipt: Receipt, config: SplitConfiguration)] {
        // Get current user's phone number for filtering
        let currentUserPhone = authManager.currentUserPhoneNumber

        var activities = recentActivity.filter { activity in
            // Filter by receipt type
            let matchesTab = switch selectedReceiptTab {
            case .received:
                activity.receipt.receiptType == .received
            case .sent:
                activity.receipt.receiptType == .sent
            }

            // For sent receipts, only show if current user is the admin
            if selectedReceiptTab == .sent {
                // Check if current user created this receipt
                if let adminId = activity.config.adminId {
                    let isCurrentUserAdmin = activity.config.participants.contains { participant in
                        // Match if participant is the admin AND either:
                        // 1. The participant is named "You", OR
                        // 2. The phone number matches the current user's phone number
                        participant.id == adminId && (
                            participant.name == "You" ||
                            participant.phoneNumber == currentUserPhone
                        )
                    }
                    return matchesTab && isCurrentUserAdmin
                }
                // For backward compatibility, also show sent receipts without adminId
                // (these are receipts created before the admin feature was added)
                return matchesTab
            }

            return matchesTab
        }

        // Add example receipts to their respective tabs
        if selectedReceiptTab == .received {
            activities = exampleReceivedReceipts + activities
        } else if selectedReceiptTab == .sent {
            activities = exampleSentReceipts + activities
        }

        return activities
    }

    var body: some View {
        NavigationView {
            ZStack {
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

                            // Currency Switcher and Profile Button
                            HStack(spacing: 12) {
                                // Currency Switcher
                                CurrencySwitcherView()

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

                                Text(currencyManager.format(amount: walletManager.walletBalance))
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

                                Text(currencyManager.format(amount: billSplitManager.calculateTotalPendingPayments()))
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
                                    action: {
                                        showingAddFunds = true
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Recent Activity Section
                    if !filteredRecentActivity.isEmpty {
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

                            // Tab Selector
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation {
                                        selectedReceiptTab = .received
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text("Received")
                                            .font(.system(size: 15, weight: selectedReceiptTab == .received ? .semibold : .medium))
                                            .foregroundColor(selectedReceiptTab == .received ? .blue : .secondary)

                                        Rectangle()
                                            .fill(selectedReceiptTab == .received ? Color.blue : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                Button(action: {
                                    withAnimation {
                                        selectedReceiptTab = .sent
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Text("Sent")
                                            .font(.system(size: 15, weight: selectedReceiptTab == .sent ? .semibold : .medium))
                                            .foregroundColor(selectedReceiptTab == .sent ? .blue : .secondary)

                                        Rectangle()
                                            .fill(selectedReceiptTab == .sent ? Color.blue : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                ForEach(filteredRecentActivity.prefix(5), id: \.receipt.id) { activity in
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

            // Fixed attribution text at bottom
            VStack {
                Spacer()

                if #available(iOS 18.0, *) {
                    LiquidGlassAttributionView()
                        .padding(.bottom, 10) // Space above tab bar
                } else {
                    FallbackAttributionView()
                        .padding(.bottom, 10) // Space above tab bar
                }
            }
            }
            .onAppear {
                isAnimating = true
                loadRecentActivity()
                walletManager.createExampleWalletEntries()
                walletManager.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BillSplitUpdated"))) { _ in
                loadRecentActivity()
                walletManager.refresh()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingAllSplits) {
                AllBillSplitsView()
            }
            .sheet(isPresented: $showingAddFunds) {
                AddFundsView(isPresented: $showingAddFunds)
            }
            .fullScreenCover(item: $selectedSplitReceipt, onDismiss: {
                // Reload data when returning from split view
                loadRecentActivity()
                walletManager.refresh()
            }) { receipt in
                // Check if this is an example receipt (should not be saved)
                let isExampleReceipt = receipt.id.uuidString.hasPrefix("00000000-0000-0000-0000")

                if isExampleReceipt {
                    // For example receipts, find the example config
                    if let exampleActivity = exampleReceivedReceipts.first(where: { $0.receipt.id == receipt.id }) {
                        ReadOnlySplitSummaryView(receipt: receipt, configuration: exampleActivity.config)
                    } else if let exampleActivity = exampleSentReceipts.first(where: { $0.receipt.id == receipt.id }) {
                        SentReceiptView(receipt: receipt, configuration: exampleActivity.config)
                    }
                } else if let config = billSplitManager.getConfiguration(for: receipt.id) {
                    if receipt.receiptType == .sent {
                        SentReceiptView(receipt: receipt, configuration: config)
                    } else {
                        SplitSummaryView(receipt: receipt, configuration: config)
                    }
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
    @ObservedObject private var currencyManager = CurrencyManager.shared

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
        // For sent receipts, check if all participants have paid
        if receipt.receiptType == .sent {
            let summaries = BillSplitManager.shared.generateSplitSummaries(receipt: receipt, config: configuration)
            let allPaid = summaries.allSatisfy { $0.isPaid }

            if allPaid {
                return "completed"
            } else {
                // Check if there's any paid participant
                let anyPaid = summaries.contains { $0.isPaid }
                return anyPaid ? "pending" : "pending"
            }
        } else {
            // For received receipts, check payment status
            let summaries = BillSplitManager.shared.generateSplitSummaries(receipt: receipt, config: configuration)
            let userSummary = summaries.first { $0.participant.name == "You" }

            if let userSummary = userSummary {
                return userSummary.isPaid ? "completed" : "pending"
            }

            return "pending"
        }
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
                    Text(currencyManager.format(amount: receipt.total))
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
    @State private var showingNotificationSettings = false

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
                            icon: "bell.fill",
                            title: "Notification Settings",
                            subtitle: "Manage payment reminders",
                            action: {
                                showingNotificationSettings = true
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
                    .padding(.top, 10)

                    // Attribution
                    if #available(iOS 18.0, *) {
                        LiquidGlassAttributionView()
                            .padding(.top, -5)
                    } else {
                        FallbackAttributionView()
                            .padding(.top, -5)
                    }

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
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
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
    @ObservedObject private var currencyManager = CurrencyManager.shared

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

                        Text(currencyManager.format(amount: totalAmount))
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

// MARK: - Attribution Views

struct FallbackAttributionView: View {
    var body: some View {
        Text("By: Ahmad Alali & Bader alqahtani")
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [.blue, .cyan, .purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.5), .cyan.opacity(0.5), .purple.opacity(0.5)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

@available(iOS 18.0, *)
struct LiquidGlassAttributionView: View {
    @State private var positions: [SIMD2<Float>] = [
        .init(x: 0, y: 0), .init(x: 0.5, y: 0), .init(x: 1, y: 0),
        .init(x: 0, y: 0.5), .init(x: 0.5, y: 0.5), .init(x: 1, y: 0.5),
        .init(x: 0, y: 1), .init(x: 0.5, y: 1), .init(x: 1, y: 1)
    ]

    let timer = Timer.publish(every: 1/10, on: .current, in: .common).autoconnect()

    var body: some View {
        Text("By: Ahmad Alali & Bader alqahtani")
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // iOS 18 Mesh Gradient for liquid effect
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: positions,
                        colors: [
                            .blue, .blue.opacity(0.8), .cyan,
                            .purple.opacity(0.7), .blue.opacity(0.9), .cyan.opacity(0.8),
                            .purple, .purple.opacity(0.8), .blue
                        ]
                    )

                    // Frosted glass overlay
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        .white.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 2)) {
                    // Animate middle points for fluid effect
                    positions[1] = randomizePosition(base: SIMD2<Float>(x: 0.5, y: 0))
                    positions[3] = randomizePosition(base: SIMD2<Float>(x: 0, y: 0.5))
                    positions[4] = randomizePosition(base: SIMD2<Float>(x: 0.5, y: 0.5))
                    positions[5] = randomizePosition(base: SIMD2<Float>(x: 1, y: 0.5))
                    positions[7] = randomizePosition(base: SIMD2<Float>(x: 0.5, y: 1))
                }
            }
    }

    private func randomizePosition(base: SIMD2<Float>) -> SIMD2<Float> {
        let range: Float = 0.15
        return SIMD2<Float>(
            x: base.x + Float.random(in: -range...range),
            y: base.y + Float.random(in: -range...range)
        )
    }
}

#Preview {
    HomeView()
}