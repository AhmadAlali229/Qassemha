//
//  SentReceiptView.swift
//  Qassemha
//
//  View for displaying sent receipts (receipts scanned by the user)
//  Similar to SplitSummaryView but without Pay button, only Mark as Paid
//

import SwiftUI

struct SentReceiptView: View {
    let receipt: Receipt
    @State var configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BillSplitManager.shared
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared

    @State private var selectedSummary: SplitSummary?
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditSplit = false
    @State private var showingDueDatePicker = false
    @State private var participantToMarkPaid: Participant?
    @StateObject private var notificationManager = NotificationManager.shared

    /// Generates split summaries for all participants based on configuration
    /// Provides real-time calculation of what each person owes
    var summaries: [SplitSummary] {
        manager.generateSplitSummaries(receipt: receipt, config: configuration)
    }

    /// Checks if receipt is an example/demo receipt by ID prefix
    /// Example receipts have special handling (no persistence/modifications)
    var isExampleReceipt: Bool {
        receipt.id.uuidString.hasPrefix("00000000-0000-0000-0000")
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
                            dueDateCard
                            paymentOverviewCard
                            whoOwesWhatCard

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

                // Hide three dots menu for example receipts
                if !isExampleReceipt {
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
        }
        .sheet(item: $selectedSummary) { summary in
            NavigationStack {
                ParticipantDetailView(summary: summary, receipt: receipt)
            }
        }
        .sheet(item: $participantToMarkPaid) { participant in
            SelectItemsForMarkAsPaidView(
                receipt: receipt,
                configuration: configuration,
                participant: participant,
                onConfirm: { selectedItems in
                    markItemsAsPaid(for: participant.id, items: selectedItems)
                    participantToMarkPaid = nil
                }
            )
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
                    Text(currencyManager.format(amount: receipt.subtotal))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Tax
                VStack(alignment: .center, spacing: 4) {
                    Text("Tax")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: receipt.tax))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Tip
                VStack(alignment: .center, spacing: 4) {
                    Text("Tip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: receipt.tip))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Total
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(currencyManager.format(amount: receipt.total))
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

    // MARK: - Due Date Card

    private var dueDateCard: some View {
        Button(action: {
            showingDueDatePicker = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(configuration.dueDate != nil ? Color.purple.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: configuration.dueDate != nil ? "calendar.badge.clock" : "calendar.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(configuration.dueDate != nil ? .purple : .gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment Due Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    if let dueDate = configuration.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    } else {
                        Text("Set a due date")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if configuration.dueDate != nil {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.purple)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.purple.opacity(0.1))
                        )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.dueDate != nil ? Color.purple.opacity(0.05) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(configuration.dueDate != nil ? Color.purple.opacity(0.2) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDueDatePicker) {
            DueDatePickerView(
                dueDate: Binding(
                    get: {
                        if let existingDate = configuration.dueDate {
                            return existingDate
                        } else {
                            // Default: 7 days from now at 9:00 AM
                            let calendar = Calendar.current
                            let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: sevenDaysFromNow) ?? sevenDaysFromNow
                        }
                    },
                    set: { newDate in
                        configuration.dueDate = newDate
                        configuration.updatedAt = Date()
                    }
                ),
                reminderSchedule: Binding(
                    get: { configuration.reminderSchedule ?? "multipleDays" },
                    set: { newSchedule in
                        configuration.reminderSchedule = newSchedule
                        configuration.updatedAt = Date()
                    }
                ),
                isPresented: $showingDueDatePicker,
                onSet: {
                    // Save configuration and schedule notifications when user confirms
                    manager.updateConfiguration(configuration)
                    cancelNotificationsForParticipants()
                    scheduleNotificationsForParticipants()
                },
                onClear: {
                    configuration.dueDate = nil
                    configuration.reminderSchedule = nil
                    configuration.updatedAt = Date()
                    manager.updateConfiguration(configuration)
                    cancelNotificationsForParticipants()
                }
            )
        }
    }

    // MARK: - Payment Overview Card

    private var paymentOverviewCard: some View {
        let paidCount = summaries.filter { $0.isPaid }.count
        let totalCount = summaries.count

        // Calculate paid amount based on split type
        let paidAmount: Double
        if configuration.splitType == .individual {
            print("📤 [CALCULATION] By Item split - calculating based on paid items")
            // For "By Item" splits, calculate based on paid items
            paidAmount = summaries.filter { $0.isPaid }.reduce(0.0) { sum, summary in
                print("📤   Processing participant: \(summary.participant.name)")
                let paidItems = configuration.paidItems[summary.participant.id] ?? []
                print("📤   Paid items count: \(paidItems.count)")
                var participantPaidAmount: Double = 0.0

                for itemId in paidItems {
                    if let item = receipt.items.first(where: { $0.id == itemId }) {
                        print("📤     Item: \(item.name), price: $\(String(format: "%.2f", item.totalPrice))")
                        let itemAmount: Double

                        if let assignment = configuration.itemAssignments.first(where: { $0.itemId == itemId }) {
                            // Item has an assignment
                            if assignment.participants.contains(summary.participant.id) {
                                // Participant is assigned - use their specific share
                                switch assignment.splitType {
                                case .equal:
                                    itemAmount = item.totalPrice / Double(assignment.participants.count)
                                case .percentage:
                                    let percentage = assignment.customSplits[summary.participant.id] ?? 0
                                    itemAmount = item.totalPrice * (percentage / 100.0)
                                case .custom:
                                    itemAmount = assignment.customSplits[summary.participant.id] ?? 0
                                }
                            } else {
                                // Participant not in assignment - use equal share based on assignment
                                itemAmount = item.totalPrice / Double(assignment.participants.count)
                            }
                        } else {
                            // No assignment - divide by all participants (default for sent receipts)
                            let totalParticipants = configuration.participants.count
                            itemAmount = totalParticipants > 0 ? item.totalPrice / Double(totalParticipants) : item.totalPrice
                        }

                        print("📤       -> Item amount: $\(String(format: "%.2f", itemAmount))")
                        participantPaidAmount += itemAmount
                    }
                }

                print("📤   Subtotal for participant: $\(String(format: "%.2f", participantPaidAmount))")

                // For "By Item" sent receipts, don't add tax/tip to match individual participant display
                // Tax/tip are NOT tracked at item level in this mode
                print("📤   Total for participant (no tax/tip added): $\(String(format: "%.2f", participantPaidAmount))")
                return sum + participantPaidAmount
            }
        } else {
            // For other split types, use the summary total
            paidAmount = summaries.filter { $0.isPaid }.reduce(0.0) { $0 + $1.total }
        }

        // Always use full receipt total (including tax/tip)
        let totalAmount = receipt.total

        // Clamp pending amount to 0 minimum (cannot be negative)
        let pendingAmount = max(0, totalAmount - paidAmount)

        print("📤 [SENT RECEIPT] Paid count: \(paidCount)/\(totalCount)")
        print("📤 [SENT RECEIPT] Split type: \(configuration.splitType)")
        print("📤 [SENT RECEIPT] Paid amount: $\(String(format: "%.2f", paidAmount))")
        print("📤 [SENT RECEIPT] Total amount: $\(String(format: "%.2f", totalAmount))")
        print("📤 [SENT RECEIPT] Pending amount: $\(String(format: "%.2f", pendingAmount))")

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

                Text(currencyManager.format(amount: paidAmount))
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

                Text(currencyManager.format(amount: pendingAmount))
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
                Text("Split Overview")
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
                    SentReceiptParticipantCard(
                        summary: summary,
                        receipt: receipt,
                        configuration: configuration,
                        totalReceiptItems: receipt.items.count,
                        isAdmin: configuration.adminId == summary.participant.id,
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

    /// Resets split configuration to default empty state
    /// Clears all participants and assignments
    private func resetSplit() {
        var resetConfig = SplitConfiguration(receiptId: receipt.id)
        manager.updateConfiguration(resetConfig)
        dismiss()
    }

    /// Deletes split configuration permanently
    /// Removes configuration from storage and dismisses view
    private func deleteSplit() {
        manager.deleteConfiguration(for: receipt.id)
        dismiss()
    }

    /// Toggles payment status for a participant
    /// Shows item selection for "By Item" splits or marks fully paid otherwise
    private func togglePaymentStatus(for participantId: UUID) {
        // Check if we're marking as paid (not unpaid)
        let wasUnpaid = !configuration.paidParticipants.contains(participantId)

        // Find the participant
        guard let participant = configuration.participants.first(where: { $0.id == participantId }) else { return }

        // If marking as paid and split type is "By Item", show item selection
        if wasUnpaid && configuration.splitType == .individual {
            participantToMarkPaid = participant
        } else if wasUnpaid {
            // For other split types, mark as fully paid
            configuration.paidParticipants.append(participantId)
            configuration.updatedAt = Date()
            manager.updateConfiguration(configuration)

            // Reload configuration to trigger view refresh
            if let updatedConfig = manager.getConfiguration(for: receipt.id) {
                configuration = updatedConfig
            }

            // Record wallet entry if not "You" and not an example
            if participant.name != "You" && !isExampleReceipt {
                if let summary = summaries.first(where: { $0.participant.id == participantId }) {
                    walletManager.recordReceivedPayment(
                        from: participant.name,
                        amount: summary.total,
                        storeName: receipt.storeName,
                        receiptId: receipt.id
                    )
                }
            }
        } else {
            // Mark as unpaid
            if let index = configuration.paidParticipants.firstIndex(of: participantId) {
                configuration.paidParticipants.remove(at: index)
            }
            // Also remove all paid items for this participant
            configuration.paidItems.removeValue(forKey: participantId)
            configuration.updatedAt = Date()
            manager.updateConfiguration(configuration)

            // Reload configuration to trigger view refresh
            if let updatedConfig = manager.getConfiguration(for: receipt.id) {
                configuration = updatedConfig
            }
        }
    }

    /// Marks specific items as paid for a participant
    /// Records payment in wallet if applicable
    private func markItemsAsPaid(for participantId: UUID, items: Set<UUID>) {
        // Find the participant
        guard let participant = configuration.participants.first(where: { $0.id == participantId }) else { return }

        // Update paid items
        configuration.paidItems[participantId] = items

        // Mark as paid if at least one item is paid
        if !items.isEmpty {
            if !configuration.paidParticipants.contains(participantId) {
                configuration.paidParticipants.append(participantId)
            }
        } else {
            // Remove from paid if no items are paid
            if let index = configuration.paidParticipants.firstIndex(of: participantId) {
                configuration.paidParticipants.remove(at: index)
            }
        }

        configuration.updatedAt = Date()
        manager.updateConfiguration(configuration)

        // Reload configuration to trigger view refresh
        if let updatedConfig = manager.getConfiguration(for: receipt.id) {
            configuration = updatedConfig
        }

        // Calculate the amount for the paid items
        var paidAmount: Double = 0.0
        for itemId in items {
            if let item = receipt.items.first(where: { $0.id == itemId }) {
                let itemAmount: Double

                if let assignment = configuration.itemAssignments.first(where: { $0.itemId == itemId }) {
                    // Item has an assignment
                    if assignment.participants.contains(participantId) {
                        // Participant is assigned - use their specific share
                        switch assignment.splitType {
                        case .equal:
                            itemAmount = item.totalPrice / Double(assignment.participants.count)
                        case .percentage:
                            let percentage = assignment.customSplits[participantId] ?? 0
                            itemAmount = item.totalPrice * (percentage / 100.0)
                        case .custom:
                            itemAmount = assignment.customSplits[participantId] ?? 0
                        }
                    } else {
                        // Participant not in assignment - use equal share based on assignment
                        itemAmount = item.totalPrice / Double(assignment.participants.count)
                    }
                } else {
                    // No assignment - divide by all participants (default for sent receipts)
                    let totalParticipants = configuration.participants.count
                    itemAmount = totalParticipants > 0 ? item.totalPrice / Double(totalParticipants) : item.totalPrice
                }

                paidAmount += itemAmount
            }
        }

        // Add proportional tax and tip
        if paidAmount > 0 && receipt.subtotal > 0 {
            let proportionalFactor = paidAmount / receipt.subtotal
            if proportionalFactor.isFinite {
                let taxAmount = configuration.includeTax ? receipt.tax * proportionalFactor : 0
                let tipAmount = configuration.includeTip ? receipt.tip * proportionalFactor : 0
                paidAmount += taxAmount + tipAmount
            }
        }

        // Record wallet entry if not "You" and not an example and items are not empty
        if !items.isEmpty && participant.name != "You" && !isExampleReceipt {
            walletManager.recordReceivedPayment(
                from: participant.name,
                amount: paidAmount,
                storeName: receipt.storeName,
                receiptId: receipt.id
            )
        }
    }

    // MARK: - Notification Management

    /// Schedules payment reminder notifications for unpaid participants
    /// Uses due date and reminder schedule from configuration
    private func scheduleNotificationsForParticipants() {
        guard let dueDate = configuration.dueDate else { return }

        let preferences = NotificationPreferences.load()
        guard preferences.enabled else { return }

        // Use the per-split reminder schedule instead of global preference
        let reminderSchedule: ReminderSchedule
        let scheduleString = configuration.reminderSchedule ?? "multipleDays"

        switch scheduleString {
        case "oneDayBefore":
            reminderSchedule = .oneDayBefore
        case "threeDaysBefore":
            reminderSchedule = .threeDaysBefore
        case "oneWeekBefore":
            reminderSchedule = .oneWeekBefore
        case "multipleDays":
            reminderSchedule = .multipleDays
        default:
            reminderSchedule = .multipleDays
        }

        // Schedule notifications for each unpaid participant
        for summary in summaries where !summary.isPaid {
            // Use participant ID as the payment record ID for consistent cancellation
            // This ensures we can cancel the same notifications later
            notificationManager.schedulePaymentReminder(
                paymentRecordID: summary.participant.id,
                payeeName: summary.participant.name,
                amount: summary.total,
                dueDate: dueDate,
                reminderSchedule: reminderSchedule,
                restaurantName: receipt.storeName
            )
        }
    }

    /// Cancels all payment reminder notifications for this split
    /// Called when due date is cleared or split is deleted
    private func cancelNotificationsForParticipants() {
        // Cancel all notifications for this split by canceling for each participant
        for summary in summaries {
            // Use the same participant ID that was used during scheduling
            notificationManager.cancelPaymentReminders(for: summary.participant.id)
        }
    }
}

// MARK: - Sent Receipt Participant Card Component
// This is similar to ParticipantCard but without the Pay Now button

struct SentReceiptParticipantCard: View {
    let summary: SplitSummary
    let receipt: Receipt
    let configuration: SplitConfiguration
    let totalReceiptItems: Int
    let isAdmin: Bool
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    @ObservedObject private var currencyManager = CurrencyManager.shared

    /// Returns total count of items on the receipt
    /// Used for displaying "X/Y items paid" information
    private func getReceiptItemCount() -> Int {
        return totalReceiptItems
    }

    /// Calculates amount paid based on selected items for "By Item" splits
    /// Includes proportional tax and tip based on items paid
    private func calculatePaidAmount() -> Double {
        guard configuration.splitType == .individual else {
            return summary.total
        }

        let paidItems = configuration.paidItems[summary.participant.id] ?? []
        guard !paidItems.isEmpty else {
            return 0.0
        }

        // Calculate the ratio of paid items to total assigned items
        let totalAssignedItems = Set(summary.items.map { $0.id })
        let paidItemsSet = paidItems.intersection(totalAssignedItems)

        guard !totalAssignedItems.isEmpty else {
            return 0.0
        }

        // If all assigned items are paid, return the full summary total
        if paidItemsSet.count == totalAssignedItems.count {
            return summary.total
        }

        // Calculate proportional amount based on paid items
        var paidSubtotal: Double = 0.0

        for itemId in paidItemsSet {
            if let summaryItem = summary.items.first(where: { $0.id == itemId }),
               let assignment = configuration.itemAssignments.first(where: { $0.itemId == itemId }) {

                // Calculate this participant's share of the item
                if assignment.participants.contains(summary.participant.id) {
                    switch assignment.splitType {
                    case .equal:
                        paidSubtotal += summaryItem.totalPrice / Double(assignment.participants.count)
                    case .percentage:
                        let percentage = assignment.customSplits[summary.participant.id] ?? 0
                        paidSubtotal += summaryItem.totalPrice * (percentage / 100.0)
                    case .custom:
                        paidSubtotal += assignment.customSplits[summary.participant.id] ?? 0
                    }
                } else {
                    // Not assigned but can still pay - use equal share
                    paidSubtotal += summaryItem.totalPrice / Double(assignment.participants.count)
                }
            }
        }

        // Calculate proportional tax and tip based on participant's total subtotal
        if summary.subtotal > 0 && paidSubtotal > 0 {
            let proportionalFactor = paidSubtotal / summary.subtotal
            let paidTax = summary.tax * proportionalFactor
            let paidTip = summary.tip * proportionalFactor
            return paidSubtotal + paidTax + paidTip
        }

        return paidSubtotal
    }

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
                            // Show paid items for "By Item" splits
                            if configuration.splitType == .individual {
                                let paidItemsCount = configuration.paidItems[summary.participant.id]?.count ?? 0
                                let totalItems = getReceiptItemCount()

                                Text("\(paidItemsCount)/\(totalItems) item\(totalItems == 1 ? "" : "s")")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .fixedSize()
                            } else {
                                Text("\(summary.itemsCount) item\(summary.itemsCount == 1 ? "" : "s")")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .fixedSize()
                            }

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
                        let displayAmount = summary.isPaid && configuration.splitType == .individual ? calculatePaidAmount() : summary.total

                        // Ensure the amount is valid (not infinity or NaN)
                        let safeAmount = displayAmount.isFinite ? displayAmount : 0.0

                        Text(currencyManager.format(amount: safeAmount))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
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

            // Mark as Paid/Unpaid Button (Only this button, no Pay Now)
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

#Preview {
    SentReceiptView(
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
            currency: CurrencyManager.shared.currencySymbol,
            scanType: .manual,
            category: .food,
            receiptType: .sent
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
