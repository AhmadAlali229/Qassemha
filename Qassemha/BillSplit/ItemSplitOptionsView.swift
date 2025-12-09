//
//  ItemSplitOptionsView.swift
//  Qassemha
//
//  Detailed options for splitting individual items
//

import SwiftUI

struct ItemSplitOptionsView: View {
    let item: ReceiptItem
    let receipt: Receipt
    @Binding var configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared

    @State private var selectedParticipants: Set<UUID> = []
    @State private var itemSplitType: ItemAssignment.ItemSplitType = .equal
    @State private var customValues: [UUID: Double] = [:]

    /// Retrieves the existing assignment for this item or returns a new one
    /// Provides default assignment if item hasn't been configured yet
    var assignment: ItemAssignment {
        configuration.itemAssignments.first(where: { $0.itemId == item.id }) ?? ItemAssignment(itemId: item.id)
    }

    /// Calculates the total percentage or amount currently assigned across all selected participants
    /// Returns 100 for equal splits or sum of custom values for percentage/custom splits
    var totalAssigned: Double {
        switch itemSplitType {
        case .equal:
            return Double(selectedParticipants.count) > 0 ? 100.0 : 0
        case .percentage:
            return customValues.values.reduce(0, +)
        case .custom:
            return customValues.values.reduce(0, +)
        }
    }

    /// Validates if the current split configuration is complete and correct
    /// Checks if percentages total 100% or amounts equal item price
    var isValid: Bool {
        if selectedParticipants.isEmpty { return false }

        switch itemSplitType {
        case .equal:
            return true
        case .percentage:
            return abs(totalAssigned - 100.0) < 0.01
        case .custom:
            return abs(totalAssigned - item.totalPrice) < 0.01
        }
    }

    /// Filters participants to show only the current user
    /// Restricts item-level splits to the user's own items
    var availableParticipants: [Participant] {
        configuration.participants.filter { $0.name == "You" }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Item Header
                    itemHeaderSection

                    // Split Type Selection
                    splitTypeSection

                    // Participant Selection
                    participantSelectionSection

                    // Custom Values (if needed)
                    if itemSplitType != .equal && !selectedParticipants.isEmpty {
                        customValuesSection
                    }

                    // Summary
                    summarySection

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
            .navigationTitle("Split Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAssignment()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            loadCurrentAssignment()
        }
    }

    // MARK: - Item Header Section

    private var itemHeaderSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.category.color.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: item.category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(item.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if item.quantity > 1 {
                    Text("\(Int(item.quantity))x $\(item.unitPrice, specifier: "%.2f") each")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(currencyManager.format(amount: item.totalPrice))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
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
            Text("How to Split")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach([ItemAssignment.ItemSplitType.equal, .percentage, .custom], id: \.self) { type in
                    Button(action: {
                        itemSplitType = type
                        if type == .equal {
                            customValues.removeAll()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: type == itemSplitType ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(type == itemSplitType ? .blue : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text(type.description)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(type == itemSplitType ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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

    // MARK: - Participant Selection Section

    private var participantSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Who's Sharing")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(selectedParticipants.count)/\(availableParticipants.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(availableParticipants) { participant in
                    Button(action: {
                        toggleParticipant(participant.id)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: participant.avatarColor) ?? .blue)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(participant.name.prefix(1).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            Text(participant.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: selectedParticipants.contains(participant.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedParticipants.contains(participant.id) ? .blue : .gray)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedParticipants.contains(participant.id) ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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

    // MARK: - Custom Values Section

    private var customValuesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(itemSplitType == .percentage ? "Set Percentages" : "Set Amounts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            // Progress indicator
            VStack(spacing: 8) {
                HStack {
                    Text("Total")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    if itemSplitType == .percentage {
                        Text("\(Int(totalAssigned))% / 100%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isValid ? .green : .orange)
                    } else {
                        Text("\(currencyManager.format(amount: totalAssigned)) / \(currencyManager.format(amount: item.totalPrice))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isValid ? .green : .orange)
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(isValid ? Color.green : Color.orange)
                            .frame(
                                width: min(geometry.size.width * (totalAssigned / (itemSplitType == .percentage ? 100.0 : item.totalPrice)), geometry.size.width),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
            .padding(.bottom, 8)

            // Participant value inputs
            VStack(spacing: 12) {
                ForEach(Array(selectedParticipants), id: \.self) { participantId in
                    if let participant = configuration.participants.first(where: { $0.id == participantId }) {
                        ItemSplitValueRow(
                            participant: participant,
                            splitType: itemSplitType,
                            itemTotal: item.totalPrice,
                            currency: receipt.currency,
                            value: Binding(
                                get: { customValues[participantId] ?? 0 },
                                set: { customValues[participantId] = $0 }
                            )
                        )
                    }
                }
            }

            // Quick actions
            Button(action: distributeEqually) {
                HStack {
                    Image(systemName: "equal.circle")
                        .font(.system(size: 14, weight: .medium))
                    Text("Distribute Equally")
                        .font(.system(size: 14, weight: .semibold))
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Split Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            if selectedParticipants.isEmpty {
                Text("No participants selected")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(selectedParticipants), id: \.self) { participantId in
                        if let participant = configuration.participants.first(where: { $0.id == participantId }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: participant.avatarColor) ?? .blue)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(participant.name.prefix(1).uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )

                                Text(participant.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(currencyManager.format(amount: calculateAmount(for: participantId)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
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

    // MARK: - Helper Methods

    /// Loads the existing assignment data into the view's state
    /// Populates selected participants, split type, and custom values from saved configuration
    private func loadCurrentAssignment() {
        selectedParticipants = Set(assignment.participants)
        itemSplitType = assignment.splitType
        customValues = assignment.customSplits
    }

    /// Toggles a participant's selection for this item
    /// Adds or removes participant and clears their custom values if removed
    private func toggleParticipant(_ id: UUID) {
        if selectedParticipants.contains(id) {
            selectedParticipants.remove(id)
            customValues.removeValue(forKey: id)
        } else {
            selectedParticipants.insert(id)
        }
    }

    /// Calculates the monetary amount a participant owes for this item
    /// Applies equal, percentage, or custom split calculation based on split type
    private func calculateAmount(for participantId: UUID) -> Double {
        switch itemSplitType {
        case .equal:
            return item.totalPrice / Double(selectedParticipants.count)
        case .percentage:
            let percentage = customValues[participantId] ?? 0
            return item.totalPrice * (percentage / 100.0)
        case .custom:
            return customValues[participantId] ?? 0
        }
    }

    /// Distributes the item cost equally among all selected participants
    /// Sets equal percentages or amounts for each participant
    private func distributeEqually() {
        let count = Double(selectedParticipants.count)
        let value = itemSplitType == .percentage ? (100.0 / count) : (item.totalPrice / count)

        for participantId in selectedParticipants {
            customValues[participantId] = value
        }
    }

    /// Saves the current split configuration for this item
    /// Updates existing assignment or creates new one with current settings
    private func saveAssignment() {
        if let index = configuration.itemAssignments.firstIndex(where: { $0.itemId == item.id }) {
            configuration.itemAssignments[index].participants = Array(selectedParticipants)
            configuration.itemAssignments[index].splitType = itemSplitType
            configuration.itemAssignments[index].customSplits = customValues
        } else {
            let newAssignment = ItemAssignment(
                itemId: item.id,
                participants: Array(selectedParticipants),
                splitType: itemSplitType,
                customSplits: customValues
            )
            configuration.itemAssignments.append(newAssignment)
        }
        configuration.updatedAt = Date()
    }
}

// MARK: - Item Split Value Row

struct ItemSplitValueRow: View {
    let participant: Participant
    let splitType: ItemAssignment.ItemSplitType
    let itemTotal: Double
    let currency: String
    @Binding var value: Double

    @FocusState private var isFocused: Bool

    /// Calculates the dollar equivalent of the percentage value
    /// Converts percentage to actual amount or returns amount directly
    var equivalentAmount: Double {
        if splitType == .percentage {
            return itemTotal * (value / 100.0)
        }
        return value
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: participant.avatarColor) ?? .blue)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                if splitType == .percentage {
                    Text("≈ \(currency)\(equivalentAmount, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                if splitType == .custom {
                    Text(currency)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                TextField(splitType == .percentage ? "0" : "0.00", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 70)
                    .focused($isFocused)

                if splitType == .percentage {
                    Text("%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - ItemAssignment.ItemSplitType Extension

/// Provides human-readable descriptions for item split types
/// Used in the UI to explain each split method to users
extension ItemAssignment.ItemSplitType {
    var description: String {
        switch self {
        case .equal:
            return "Split equally among selected people"
        case .percentage:
            return "Split by custom percentages"
        case .custom:
            return "Enter exact amounts per person"
        }
    }
}

#Preview {
    ItemSplitOptionsView(
        item: ReceiptItem(
            name: "Fettuccine Alfredo",
            quantity: 1,
            unitPrice: 16.99,
            totalPrice: 16.99,
            category: .main,
            tags: []
        ),
        receipt: Receipt(
            storeName: "Olive Garden",
            date: Date(),
            items: [],
            subtotal: 28.58,
            tax: 2.86,
            tip: 2.14,
            total: 33.58,
            currency: "USD",
            scanType: .manual,
            category: .food
        ),
        configuration: .constant(SplitConfiguration(
            receiptId: UUID(),
            participants: [
                Participant(name: "John", avatarColor: "#FF6B6B"),
                Participant(name: "Sarah", avatarColor: "#4ECDC4")
            ]
        ))
    )
}
