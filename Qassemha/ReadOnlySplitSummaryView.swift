//
//  ReadOnlySplitSummaryView.swift
//  Qassemha
//
//  Read-only view for example/demo receipts that shouldn't be saved to database
//

import SwiftUI

struct ReadOnlySplitSummaryView: View {
    let receipt: Receipt
    let configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BillSplitManager.shared
    @StateObject private var walletManager = WalletManager.shared

    @State private var selectedSummary: SplitSummary?
    @State private var localConfig: SplitConfiguration
    @State private var showInsufficientFundsAlert = false
    @State private var insufficientAmount: Double = 0.0
    @State private var showAddFunds = false
    @State private var showItemSelection = false
    @State private var paymentData: PaymentData?
    @State private var selectedItemsForPayment: Set<UUID> = []

    struct PaymentData: Identifiable {
        let id = UUID()
        let amount: Double
        let selectedItems: Set<UUID>
    }

    init(receipt: Receipt, configuration: SplitConfiguration) {
        self.receipt = receipt
        self.configuration = configuration
        _localConfig = State(initialValue: configuration)
    }

    var summaries: [SplitSummary] {
        manager.generateSplitSummaries(receipt: receipt, config: localConfig)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.05),
                        Color.blue.opacity(0.02),
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Main Content
                ScrollView {
                    VStack(spacing: 20) {
                        // All content sections
                        Group {
                            receiptOverviewCard
                            splitMethodCard
                            paymentOverviewCard
                            whoOwesWhatCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Split Summary")
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
        .sheet(item: $selectedSummary) { summary in
            NavigationStack {
                ParticipantDetailView(summary: summary, receipt: receipt)
            }
        }
        .sheet(isPresented: $showAddFunds) {
            AddFundsView(isPresented: $showAddFunds)
        }
        .sheet(isPresented: $showItemSelection) {
            SelectItemsForPaymentView(
                receipt: receipt,
                configuration: localConfig,
                onConfirm: { selectedItems, amount in
                    selectedItemsForPayment = selectedItems
                    showItemSelection = false
                    // Small delay to allow sheet dismissal animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        paymentData = PaymentData(amount: amount, selectedItems: selectedItems)
                    }
                }
            )
        }
        .sheet(item: $paymentData) { data in
            PaymentMethodSelectionView(
                isPresented: Binding(
                    get: { paymentData != nil },
                    set: { if !$0 { paymentData = nil } }
                ),
                amount: data.amount,
                payeeName: "Receipt Items",
                billSplitID: receipt.id.uuidString,
                onPaymentComplete: { result in
                    handlePaymentCompletion(for: data.selectedItems, result: result)
                }
            )
        }
        .alert("Insufficient Funds", isPresented: $showInsufficientFundsAlert) {
            Button("Add Funds") {
                showAddFunds = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You need $\(insufficientAmount, specifier: "%.2f") to complete this payment. Your current wallet balance is $\(walletManager.walletBalance, specifier: "%.2f"). Please add funds to continue.")
        }
    }

    // MARK: - Receipt Overview Card

    private var receiptOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(receipt.category.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: receipt.category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(receipt.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.storeName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            // Amount Details
            HStack(spacing: 0) {
                // Subtotal
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subtotal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(receipt.currency)\(receipt.subtotal, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tax
                VStack(alignment: .center, spacing: 4) {
                    Text("Tax")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(receipt.currency)\(receipt.tax, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Tip
                VStack(alignment: .center, spacing: 4) {
                    Text("Tip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(receipt.currency)\(receipt.tip, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Total
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(receipt.currency)\(receipt.total, specifier: "%.2f")")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Split Method Card

    private var splitMethodCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: configuration.splitType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Split Method")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text(configuration.splitType.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Participants")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text("\(configuration.participants.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Payment Overview Card

    private var paymentOverviewCard: some View {
        let paidCount = summaries.filter { $0.isPaid }.count
        let totalCount = summaries.count
        let paidAmount = summaries.filter { $0.isPaid }.reduce(0.0) { $0 + $1.total }
        let totalAmount = receipt.total

        return HStack(spacing: 12) {
            // Paid Status
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)

                    Text("Paid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Text("\(paidCount)/\(totalCount) people")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(receipt.currency)\(paidAmount, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                    )
            )

            // Pending Status
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)

                    Text("Pending")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Text("\(totalCount - paidCount) people")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(receipt.currency)\(totalAmount - paidAmount, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }

    // MARK: - Who Owes What Card

    private var whoOwesWhatCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - No title or green tick for received receipts

            // Participant Cards
            VStack(spacing: 12) {
                ForEach(summaries) { summary in
                    ReceivedReceiptParticipantCard(
                        summary: summary,
                        currency: receipt.currency,
                        isAdmin: localConfig.adminId == summary.participant.id,
                        onTap: {
                            selectedSummary = summary
                        },
                        onPayNow: {
                            handlePayNowClick(for: summary)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Helper Methods

    private func handlePayNowClick(for summary: SplitSummary) {
        // Show item selection for payment
        showItemSelection = true
    }

    private func handlePaymentCompletion(for selectedItems: Set<UUID>, result: PaymentCompletionResult) {
        // Handle payment completion after payment method selection
        guard result.success else { return }

        let youParticipant = localConfig.participants.first(where: { $0.name == "You" })
        guard let youId = youParticipant?.id else { return }

        // Mark participant as paid locally
        if !localConfig.paidParticipants.contains(youId) {
            localConfig.paidParticipants.append(youId)
        }
        localConfig.updatedAt = Date()

        // Refresh wallet data
        walletManager.refresh()
    }
}

// MARK: - Received Receipt Participant Card Component

struct ReceivedReceiptParticipantCard: View {
    let summary: SplitSummary
    let currency: String
    let isAdmin: Bool
    let onTap: () -> Void
    let onPayNow: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main Content (Tappable)
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Avatar
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color(hex: summary.participant.avatarColor) ?? .blue)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(summary.participant.name.prefix(1).uppercased())
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        // Admin badge
                        if isAdmin {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 18, height: 18)

                                Text("👑")
                                    .font(.system(size: 10))
                            }
                            .offset(x: 2, y: -2)
                        }
                    }

                    // Name and Items
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(summary.participant.name)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            // Admin badge
                            if isAdmin {
                                Text("Admin")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.yellow.opacity(0.15))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 8) {
                            Text("\(summary.itemsCount) item\(summary.itemsCount == 1 ? "" : "s")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary.opacity(0.7))
                                .fixedSize()

                            // Status Badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(summary.isPaid ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)
                                Text(summary.isPaid ? "Paid" : "Pending")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(summary.isPaid ? .green : .orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(summary.isPaid ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            )
                            .fixedSize()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 8)

                    // Amount
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(currency)\(summary.total, specifier: "%.2f")")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .fixedSize()

                        Text("owes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize()
                    }
                    .fixedSize()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            // Only show Pay Now button if not paid AND participant is "You"
            if !summary.isPaid && summary.participant.name == "You" {
                Divider()

                Button(action: onPayNow) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .medium))

                        Text("Pay Now")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            summary.isPaid ? Color.green.opacity(0.5) : Color.gray.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReadOnlySplitSummaryView(
        receipt: Receipt(
            storeName: "Pizza Palace",
            date: Date(),
            items: [
                ReceiptItem(name: "Large Pizza", quantity: 1, unitPrice: 18.99, totalPrice: 18.99, category: .main, tags: [])
            ],
            subtotal: 18.99,
            tax: 1.52,
            tip: 3.50,
            total: 23.01,
            currency: CurrencyManager.shared.currencySymbol,
            scanType: .qrCode,
            category: .food,
            receiptType: .received
        ),
        configuration: SplitConfiguration(
            receiptId: UUID(),
            splitType: .equal,
            participants: [
                Participant(name: "Sarah", phoneNumber: "+1234567890", avatarColor: "#FF6B6B"),
                Participant(name: "Mike", phoneNumber: "+1234567891", avatarColor: "#4ECDC4")
            ]
        )
    )
}
