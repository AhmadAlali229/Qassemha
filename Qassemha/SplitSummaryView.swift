//
//  SplitSummaryView.swift
//  Qassemha
//
//  Final split summary with real-time balance calculation per person
//

import SwiftUI

struct SplitSummaryView: View {
    let receipt: Receipt
    @State var configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BillSplitManager.shared

    @State private var selectedSummary: SplitSummary?
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditSplit = false

    var summaries: [SplitSummary] {
        manager.generateSplitSummaries(receipt: receipt, config: configuration)
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
                            detailedBreakdownCard

                            if !manager.validateSplit(receipt: receipt, config: configuration).isEmpty {
                                validationWarningsCard
                            }
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

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingEditSplit = true
                        }) {
                            Label("Edit Split", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            showingResetConfirmation = true
                        }) {
                            Label("Reset Split", systemImage: "arrow.counterclockwise")
                        }

                        Button(role: .destructive, action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Split", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(item: $selectedSummary) { summary in
            ParticipantDetailView(summary: summary, receipt: receipt)
        }
        .fullScreenCover(isPresented: $showingEditSplit) {
            BillSplitView(receipt: receipt)
        }
        .alert("Reset Bill Split", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetSplit()
            }
        } message: {
            Text("Are you sure you want to reset this bill split? All participants, assignments, and custom splits will be cleared.")
        }
        .alert("Delete Bill Split", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSplit()
            }
        } message: {
            Text("Are you sure you want to delete this bill split configuration? This action cannot be undone.")
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
            // Header
            HStack {
                Text("Who Owes What")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
            }

            // Participant Cards
            VStack(spacing: 12) {
                ForEach(summaries) { summary in
                    ParticipantCard(
                        summary: summary,
                        currency: receipt.currency,
                        onTap: {
                            selectedSummary = summary
                        },
                        onTogglePaid: {
                            togglePaymentStatus(for: summary.participant.id)
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

    // MARK: - Detailed Breakdown Card

    private var detailedBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(summaries) { summary in
                    VStack(alignment: .leading, spacing: 8) {
                        // Participant Header
                        HStack {
                            Circle()
                                .fill(Color(hex: summary.participant.avatarColor) ?? .blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(summary.participant.name.prefix(1).uppercased())
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            Text(summary.participant.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()
                        }

                        // Breakdown Details
                        VStack(spacing: 6) {
                            HStack {
                                Text("Items (\(summary.itemsCount))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("\(receipt.currency)\(summary.subtotal, specifier: "%.2f")")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            if configuration.includeTax && summary.tax > 0 {
                                HStack {
                                    Text("Tax")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("\(receipt.currency)\(summary.tax, specifier: "%.2f")")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if configuration.includeTip && summary.tip > 0 {
                                HStack {
                                    Text("Tip")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("\(receipt.currency)\(summary.tip, specifier: "%.2f")")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Divider()
                                .padding(.vertical, 4)

                            HStack {
                                Text("Total")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)

                                Spacer()

                                Text("\(receipt.currency)\(summary.total, specifier: "%.2f")")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.leading, 40)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color(hex: summary.participant.avatarColor)?.opacity(0.3) ??
                                        Color.blue.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
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

    // MARK: - Validation Warnings Card

    private var validationWarningsCard: some View {
        let warnings = manager.validateSplit(receipt: receipt, config: configuration)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)

                Text("Attention Required")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)

                        Text(warning)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    // MARK: - Helper Methods

    private func resetSplit() {
        var resetConfig = SplitConfiguration(receiptId: receipt.id)
        manager.updateConfiguration(resetConfig)
        dismiss()
    }

    private func deleteSplit() {
        manager.deleteConfiguration(for: receipt.id)
        dismiss()
    }

    private func togglePaymentStatus(for participantId: UUID) {
        manager.togglePaymentStatus(participantId: participantId, config: &configuration)
        manager.updateConfiguration(configuration)
    }
}

// MARK: - Participant Card Component

struct ParticipantCard: View {
    let summary: SplitSummary
    let currency: String
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main Content (Tappable)
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Avatar
                    Circle()
                        .fill(Color(hex: summary.participant.avatarColor) ?? .blue)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(summary.participant.name.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )

                    // Name and Items
                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.participant.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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

            Divider()

            // Payment Toggle Button
            Button(action: onTogglePaid) {
                HStack {
                    Image(systemName: summary.isPaid ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))

                    Text(summary.isPaid ? "Mark as Unpaid" : "Mark as Paid")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(summary.isPaid ? Color.orange : Color.green)
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

// MARK: - Participant Detail View

struct ParticipantDetailView: View {
    let summary: SplitSummary
    let receipt: Receipt
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: summary.participant.avatarColor)?.opacity(0.1) ?? Color.blue.opacity(0.1),
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color(hex: summary.participant.avatarColor) ?? .blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(summary.participant.name.prefix(1).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(spacing: 4) {
                                Text(summary.participant.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)

                                if let phone = summary.participant.phoneNumber {
                                    Text(phone)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("\(receipt.currency)\(summary.total, specifier: "%.2f")")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 20)

                        // Items Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Items (\(summary.items.count))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            VStack(spacing: 8) {
                                ForEach(summary.items) { item in
                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Text("\(receipt.currency)\(item.totalPrice, specifier: "%.2f")")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
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

                        // Breakdown Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Breakdown")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(receipt.currency)\(summary.subtotal, specifier: "%.2f")")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                HStack {
                                    Text("Tax")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(receipt.currency)\(summary.tax, specifier: "%.2f")")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Tip")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(receipt.currency)\(summary.tip, specifier: "%.2f")")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }

                                Divider()
                                    .padding(.vertical, 4)

                                HStack {
                                    Text("Total")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text("\(receipt.currency)\(summary.total, specifier: "%.2f")")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    SplitSummaryView(
        receipt: Receipt(
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
            currency: "$",
            scanType: .manual,
            category: .food
        ),
        configuration: SplitConfiguration(
            receiptId: UUID(),
            splitType: .equal,
            participants: [
                Participant(name: "John", phoneNumber: "555-0100", avatarColor: "#FF6B6B"),
                Participant(name: "Sarah", phoneNumber: "555-0101", avatarColor: "#4ECDC4")
            ]
        )
    )
}