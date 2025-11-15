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
    @StateObject private var walletManager = WalletManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared

    @State private var selectedSummary: SplitSummary?
    @State private var showingResetConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingEditSplit = false
    @State private var participantToPay: SplitSummary?
    @State private var showingDueDatePicker = false
    @State private var showingItemSelectionForPaid = false
    @State private var participantForItemSelection: Participant?
    @StateObject private var notificationManager = NotificationManager.shared

    var summaries: [SplitSummary] {
        manager.generateSplitSummaries(receipt: receipt, config: configuration)
    }

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
        .sheet(item: $participantToPay) { participant in
            PaymentMethodSelectionView(
                isPresented: Binding(
                    get: { participantToPay != nil },
                    set: { if !$0 { participantToPay = nil } }
                ),
                amount: participant.total,
                payeeName: participant.participant.name,
                billSplitID: receipt.id.uuidString,
                onPaymentComplete: { result in
                    handlePaymentCompletion(for: participant, result: result)
                }
            )
        }
        .fullScreenCover(isPresented: $showingEditSplit) {
            BillSplitView(receipt: receipt)
        }
        .sheet(isPresented: $showingItemSelectionForPaid) {
            if let participant = participantForItemSelection {
                SelectItemsForMarkAsPaidView(
                    receipt: receipt,
                    configuration: configuration,
                    participant: participant,
                    onConfirm: { selectedItems in
                        handleItemSelectionForPaid(participantId: participant.id, selectedItems: selectedItems)
                    }
                )
            }
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

        // Special calculation for sent receipts with "By Item" split
        let (paidAmount, totalAmount) = calculatePaymentAmounts()

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

                Text(currencyManager.format(amount: totalAmount - paidAmount))
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
            // Header - Only show for sent receipts
            if receipt.receiptType == .sent {
                HStack {
                    Text("Who Owes What")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            // Participant Cards
            VStack(spacing: 12) {
                ForEach(summaries) { summary in
                    if receipt.receiptType == .received {
                        // For received receipts, only show Pay Now (no Mark as Paid toggle)
                        ReceivedReceiptParticipantCard(
                            summary: summary,
                            isAdmin: configuration.adminId == summary.participant.id,
                            onTap: {
                                selectedSummary = summary
                            },
                            onPayNow: {
                                participantToPay = summary
                            }
                        )
                    } else {
                        // For sent receipts, show both Pay Now and Mark as Paid toggle
                        ParticipantCard(
                            summary: summary,
                            currency: receipt.currency,
                            isAdmin: configuration.adminId == summary.participant.id,
                            onTap: {
                                selectedSummary = summary
                            },
                            onTogglePaid: {
                                // For "By Item" splits, show item selection before marking as paid
                                if configuration.splitType == .individual {
                                    participantForItemSelection = summary.participant
                                    showingItemSelectionForPaid = true
                                } else {
                                    // For other split types, toggle payment status directly
                                    togglePaymentStatus(for: summary.participant.id)
                                }
                            },
                            onPayNow: {
                                participantToPay = summary
                            }
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

    private func calculatePaymentAmounts() -> (paidAmount: Double, totalAmount: Double) {
        // Sum what participants have actually paid (from their summaries)
        let paidAmount = summaries.filter { $0.isPaid }.reduce(0.0) { $0 + $1.total }

        // Always use full receipt total (even for "By Item" - pending shows remaining balance including tax)
        return (paidAmount, receipt.total)
    }

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

    private func handleItemSelectionForPaid(participantId: UUID, selectedItems: Set<UUID>) {
        // Update paidItems with selected items
        if selectedItems.isEmpty {
            // If no items selected, mark as unpaid and remove from paidItems
            configuration.paidItems.removeValue(forKey: participantId)
            configuration.paidParticipants.removeAll { $0 == participantId }
        } else {
            // Update paid items for this participant
            configuration.paidItems[participantId] = selectedItems
            // Mark participant as paid
            if !configuration.paidParticipants.contains(participantId) {
                configuration.paidParticipants.append(participantId)
            }
        }
        configuration.updatedAt = Date()
        manager.updateConfiguration(configuration)
    }

    private func handlePaymentCompletion(for participant: SplitSummary, result: PaymentCompletionResult) {
        guard result.success else { return }

        // Mark participant as paid in bill split configuration
        togglePaymentStatus(for: participant.participant.id)

        // Refresh wallet data to update balances
        walletManager.refresh()
    }

    // MARK: - Notification Management

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

    private func cancelNotificationsForParticipants() {
        // Cancel all notifications for this split by canceling for each participant
        for summary in summaries {
            // Use the same participant ID that was used during scheduling
            notificationManager.cancelPaymentReminders(for: summary.participant.id)
        }
    }
}

// MARK: - Due Date Picker View

struct DueDatePickerView: View {
    @Binding var dueDate: Date
    @Binding var reminderSchedule: String
    @Binding var isPresented: Bool
    var onSet: () -> Void
    var onClear: () -> Void

    private let scheduleOptions = [
        ("oneDayBefore", "1 Day Before", "Reminder 1 day before due date"),
        ("threeDaysBefore", "3 Days Before", "Reminder 3 days before due date"),
        ("oneWeekBefore", "1 Week Before", "Reminder 7 days before due date"),
        ("multipleDays", "Multiple Reminders", "Reminders 7, 3, 1 days before + on due date")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Info Card
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.purple)

                        Text("Set the due date and time for payment reminders")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )

                    // Date Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Due Date")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }

                    // Time Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification Time")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        DatePicker(
                            "Time",
                            selection: $dueDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )

                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)

                            Text("Reminders will be sent at \(dueDate.formatted(date: .omitted, time: .shortened)) on scheduled days")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }

                    // Reminder Schedule Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Schedule")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 8) {
                            ForEach(scheduleOptions, id: \.0) { option in
                                Button(action: {
                                    reminderSchedule = option.0
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(option.1)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text(option.2)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if reminderSchedule == option.0 {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(.purple)
                                        } else {
                                            Image(systemName: "circle")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(.gray.opacity(0.3))
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(reminderSchedule == option.0 ? Color.purple.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(reminderSchedule == option.0 ? Color.purple : Color.gray.opacity(0.2), lineWidth: reminderSchedule == option.0 ? 2 : 1)
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            onSet()
                            isPresented = false
                        }) {
                            Text("Set Reminder")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: {
                            onClear()
                            isPresented = false
                        }) {
                            Text("Clear Due Date")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 2)
                                        .background(Color.red.opacity(0.05))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Set Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Participant Card Component

struct ParticipantCard: View {
    let summary: SplitSummary
    let currency: String
    let isAdmin: Bool
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    let onPayNow: () -> Void
    @ObservedObject private var currencyManager = CurrencyManager.shared

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
                        Text(currencyManager.format(amount: summary.total))
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

            // Pay Now Button (only show when not paid)
            if !summary.isPaid {
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

                Divider()
            }

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
    @ObservedObject private var currencyManager = CurrencyManager.shared

    var body: some View {
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

                            Text(currencyManager.format(amount: summary.total))
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

                                        Text(currencyManager.format(amount: item.totalPrice))
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
                                    Text(currencyManager.format(amount: summary.subtotal))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                HStack {
                                    Text("Tax")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(currencyManager.format(amount: summary.tax))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Tip")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(currencyManager.format(amount: summary.tip))
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
                                    Text(currencyManager.format(amount: summary.total))
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
            currency: CurrencyManager.shared.currencySymbol,
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