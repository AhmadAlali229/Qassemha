//
//  BillSplitView.swift
//  Qassemha
//
//  Main interface for smart bill splitting
//

import SwiftUI

struct BillSplitView: View {
    let receipt: Receipt
    @StateObject private var manager = BillSplitManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var configuration: SplitConfiguration
    @State private var showingParticipantSelection = false
    @State private var showingItemAssignment = false
    @State private var showingSplitSummary = false
    @State private var showingCustomSplit = false
    @State private var showingResetConfirmation = false
    @Environment(\.dismiss) private var dismiss

    init(receipt: Receipt) {
        self.receipt = receipt
        var config = BillSplitManager.shared.getConfiguration(for: receipt.id) ?? SplitConfiguration(receiptId: receipt.id)

        // For sent receipts, ensure current user is added as admin if not already set
        if receipt.receiptType == .sent && config.adminId == nil {
            // Find if there's already a "You" participant
            if let youParticipant = config.participants.first(where: { $0.name == "You" }) {
                config.adminId = youParticipant.id
            }
        }

        _configuration = State(initialValue: config)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Receipt Header
                    receiptHeaderSection

                    // Split Type Selection
                    splitTypeSection

                    // Participants Section
                    participantsSection

                    // Action Buttons based on split type
                    actionButtonsSection

                    // Validation Warnings
                    validationSection

                    // Summary Preview
                    summaryPreviewSection

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
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
            .navigationTitle("Split Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Menu {
                            Button(role: .destructive, action: {
                                showingResetConfirmation = true
                            }) {
                                Label("Reset Split", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.blue)
                        }

                        Button("View Split") {
                            ensureAdminIsSet()
                            showingSplitSummary = true
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .disabled(configuration.participants.isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingParticipantSelection) {
            ParticipantSelectionView(configuration: $configuration, receipt: receipt)
        }
        .sheet(isPresented: $showingItemAssignment) {
            ItemAssignmentView(receipt: receipt, configuration: $configuration)
        }
        .sheet(isPresented: $showingSplitSummary) {
            SplitSummaryView(receipt: receipt, configuration: configuration)
        }
        .sheet(isPresented: $showingCustomSplit) {
            CustomSplitOptionsView(receipt: receipt, configuration: $configuration)
        }
        .onChange(of: configuration) { newConfig in
            manager.updateConfiguration(newConfig)
        }
        .onAppear {
            // Ensure admin is set when view appears
            ensureAdminIsSet()
        }
        .alert("Reset Bill Split", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetSplit()
            }
        } message: {
            Text("Are you sure you want to reset this bill split? All participants, assignments, and custom splits will be cleared. This action cannot be undone.")
        }
    }

    // MARK: - Helper Methods

    private func resetSplit() {
        configuration = SplitConfiguration(receiptId: receipt.id)
        manager.updateConfiguration(configuration)
    }

    private func ensureAdminIsSet() {
        // For sent receipts, ensure adminId is set
        if receipt.receiptType == .sent && configuration.adminId == nil {
            // Try to find participant named "You" first
            if let youParticipant = configuration.participants.first(where: { $0.name == "You" }) {
                configuration.adminId = youParticipant.id
                configuration.updatedAt = Date()
                return
            }

            // Try to find participant with current user's phone number
            if let currentPhone = authManager.currentUserPhoneNumber,
               let matchingParticipant = configuration.participants.first(where: { $0.phoneNumber == currentPhone }) {
                configuration.adminId = matchingParticipant.id
                configuration.updatedAt = Date()
                return
            }

            // If no "You" participant exists, add one and set as admin
            let youParticipant = Participant(
                name: "You",
                phoneNumber: authManager.currentUserPhoneNumber,
                avatarColor: "#45B7D1"
            )
            configuration.participants.insert(youParticipant, at: 0)
            configuration.adminId = youParticipant.id
            configuration.updatedAt = Date()
        }
    }

    // MARK: - Receipt Header Section

    private var receiptHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(currencyManager.format(amount: receipt.total))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Items")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(receipt.items.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 2) {
                    Text("Tax")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: receipt.tax))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Tip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: receipt.tip))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
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

    // MARK: - Split Type Section

    private var splitTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Split Method")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SplitType.allCases, id: \.self) { type in
                        SplitTypeButton(
                            type: type,
                            isSelected: configuration.splitType == type
                        ) {
                            configuration.splitType = type
                            configuration.updatedAt = Date()
                        }
                    }
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

    // MARK: - Participants Section

    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Participants")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(configuration.participants.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            if configuration.participants.isEmpty {
                Button(action: {
                    showingParticipantSelection = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text("Add Participants")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 2)
                    )
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(configuration.participants) { participant in
                        ParticipantRow(participant: participant)
                    }

                    Button(action: {
                        showingParticipantSelection = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 16, weight: .medium))

                            Text("Manage Participants")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.blue, lineWidth: 1.5)
                        )
                    }
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

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        Group {
            if !configuration.participants.isEmpty {
                VStack(spacing: 12) {
                    switch configuration.splitType {
                    case .equal:
                        equalSplitOptions

                    case .individual:
                        // "Assign Items to People" button hidden per user request
                        EmptyView()

                    case .percentage, .custom:
                        Button(action: {
                            showingCustomSplit = true
                        }) {
                            HStack {
                                Image(systemName: configuration.splitType.icon)
                                    .font(.system(size: 18, weight: .medium))

                                Text(configuration.splitType == .percentage ? "Set Percentages" : "Set Custom Amounts")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private var equalSplitOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Options")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            Toggle(isOn: $configuration.includeTax) {
                Text("Include Tax")
                    .font(.system(size: 16, weight: .medium))
            }
            .tint(.blue)

            Toggle(isOn: $configuration.includeTip) {
                Text("Include Tip")
                    .font(.system(size: 16, weight: .medium))
            }
            .tint(.blue)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Validation Section

    private var validationSection: some View {
        Group {
            let warnings = manager.validateSplit(receipt: receipt, config: configuration)
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)

                            Text(warning)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Summary Preview Section

    private var summaryPreviewSection: some View {
        Group {
            // Hide Quick Preview for "By Item" split type
            if !configuration.participants.isEmpty && configuration.splitType != .individual {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Preview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)

                    let summaries = manager.generateSplitSummaries(receipt: receipt, config: configuration)

                    VStack(spacing: 8) {
                        ForEach(summaries) { summary in
                            HStack {
                                Circle()
                                    .fill(Color(hex: summary.participant.avatarColor) ?? .blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(summary.participant.name.prefix(1).uppercased())
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )

                                Text(summary.participant.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(currencyManager.format(amount: summary.total))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
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
        }
    }
}

// MARK: - Split Type Button

struct SplitTypeButton: View {
    let type: SplitType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : .blue)
                }

                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(type.description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(width: 120)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: Participant

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: participant.avatarColor) ?? .blue)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if let phone = participant.phoneNumber {
                    Text(phone)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    BillSplitView(receipt: Receipt(
        storeName: "Olive Garden",
        date: Date(),
        items: [
            ReceiptItem(name: "Fettuccine Alfredo", quantity: 1, unitPrice: 16.99, totalPrice: 16.99, category: .main, tags: []),
            ReceiptItem(name: "Caesar Salad", quantity: 1, unitPrice: 8.99, totalPrice: 8.99, category: .appetizer, tags: [])
        ],
        subtotal: 25.98,
        tax: 2.60,
        tip: 5.00,
        total: 33.58,
        currency: "USD",
        scanType: .manual,
        category: .food
    ))
}
