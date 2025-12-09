//
//  SelectItemsForPaymentView.swift
//  Qassemha
//
//  View to select items for payment in received receipts
//

import SwiftUI

struct SelectItemsForPaymentView: View {
    let receipt: Receipt
    let configuration: SplitConfiguration
    let onConfirm: (Set<UUID>, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedItems: Set<UUID> = []

    /// Finds the "You" participant in the configuration
    /// Returns nil if current user is not a participant
    private var youParticipant: Participant? {
        configuration.participants.first(where: { $0.name == "You" })
    }

    /// Returns items assigned to the current user
    /// Filters items based on item assignments
    private var assignedItems: [ReceiptItem] {
        guard let youId = youParticipant?.id else { return [] }

        return receipt.items.filter { item in
            if let assignment = configuration.itemAssignments.first(where: { $0.itemId == item.id }) {
                return assignment.participants.contains(youId)
            }
            return false
        }
    }

    /// Calculates total payment amount for selected items
    /// Includes proportional tax and tip
    private var totalAmount: Double {
        guard let youId = youParticipant?.id else { return 0.0 }

        var subtotal: Double = 0.0

        // Calculate subtotal for selected items
        for itemId in selectedItems {
            if let item = receipt.items.first(where: { $0.id == itemId }) {
                if let assignment = configuration.itemAssignments.first(where: { $0.itemId == itemId }) {
                    let itemAmount: Double

                    switch assignment.splitType {
                    case .equal:
                        itemAmount = item.totalPrice / Double(assignment.participants.count)
                    case .percentage:
                        let percentage = assignment.customSplits[youId] ?? 0
                        itemAmount = item.totalPrice * (percentage / 100.0)
                    case .custom:
                        itemAmount = assignment.customSplits[youId] ?? 0
                    }

                    subtotal += itemAmount
                }
            }
        }

        // Calculate proportional tax and tip
        let proportionalFactor = receipt.subtotal > 0 ? subtotal / receipt.subtotal : 0
        let taxAmount = configuration.includeTax ? receipt.tax * proportionalFactor : 0
        let tipAmount = configuration.includeTip ? receipt.tip * proportionalFactor : 0

        return subtotal + taxAmount + tipAmount
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

                ScrollView {
                    VStack(spacing: 20) {
                        // Info Card
                        infoCard

                        // Items List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Items to Pay For")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            if assignedItems.isEmpty {
                                Text("No items assigned to you")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(assignedItems) { item in
                                        SelectableItemCard(
                                            item: item,
                                            configuration: configuration,
                                            youId: youParticipant?.id ?? UUID(),
                                            isSelected: selectedItems.contains(item.id),
                                            onToggle: {
                                                toggleSelection(for: item.id)
                                            }
                                        )
                                    }
                                }
                            }

                            // Quick Actions
                            if !assignedItems.isEmpty {
                                HStack(spacing: 12) {
                                    Button(action: selectAll) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Select All")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.blue, lineWidth: 1.5)
                                        )
                                    }

                                    Button(action: deselectAll) {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Deselect All")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(.gray, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 120)
                    }
                    .padding(.vertical, 20)
                }

                // Fixed Bottom Bar
                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Amount")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text(currencyManager.format(amount: totalAmount))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Button(action: {
                                onConfirm(selectedItems, totalAmount)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Pay Now")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: selectedItems.isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(selectedItems.isEmpty)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // Initialize with all assigned items selected
            selectedItems = Set(assignedItems.map { $0.id })
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)

            Text("Select which items you want to pay for from your assigned items")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Helper Methods

    /// Toggles selection state for an item
    /// Adds or removes item from selected set
    private func toggleSelection(for itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }

    /// Selects all assigned items
    /// Convenience method for bulk selection
    private func selectAll() {
        selectedItems = Set(assignedItems.map { $0.id })
    }

    /// Deselects all items
    /// Clears the selection set
    private func deselectAll() {
        selectedItems.removeAll()
    }
}

// MARK: - Selectable Item Card

struct SelectableItemCard: View {
    let item: ReceiptItem
    let configuration: SplitConfiguration
    let youId: UUID
    let isSelected: Bool
    let onToggle: () -> Void

    @ObservedObject private var currencyManager = CurrencyManager.shared

    /// Finds assignment configuration for this item
    /// Returns nil if item has no custom split
    private var itemAssignment: ItemAssignment? {
        configuration.itemAssignments.first(where: { $0.itemId == item.id })
    }

    /// Calculates your share of the item cost
    /// Based on split type (equal, percentage, or custom)
    private var yourAmount: Double {
        guard let assignment = itemAssignment else { return 0 }

        switch assignment.splitType {
        case .equal:
            return item.totalPrice / Double(assignment.participants.count)
        case .percentage:
            let percentage = assignment.customSplits[youId] ?? 0
            return item.totalPrice * (percentage / 100.0)
        case .custom:
            return assignment.customSplits[youId] ?? 0
        }
    }

    /// Returns list of other participants sharing this item
    /// Excludes current user from list
    private var otherParticipants: [Participant] {
        guard let assignment = itemAssignment else { return [] }
        return configuration.participants.filter { participant in
            assignment.participants.contains(participant.id) && participant.id != youId
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.green : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Item Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.category.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(item.category.color)
                }

                // Item Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if item.quantity > 1 {
                        Text("\(Int(item.quantity))x \(currencyManager.format(amount: item.unitPrice))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Shared with
                    if !otherParticipants.isEmpty {
                        HStack(spacing: 4) {
                            Text("Shared with:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(spacing: -6) {
                                ForEach(otherParticipants.prefix(3), id: \.id) { participant in
                                    Circle()
                                        .fill(Color(hex: participant.avatarColor) ?? .blue)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Text(participant.name.prefix(1).uppercased())
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1.5)
                                        )
                                }

                                if otherParticipants.count > 3 {
                                    Text("+\(otherParticipants.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Spacer()

                // Your Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyManager.format(amount: yourAmount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? .green : .primary)

                    Text("your share")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.green.opacity(0.05) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SelectItemsForPaymentView(
        receipt: Receipt(
            storeName: "Coffee Corner",
            date: Date(),
            items: [
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Caramel Latte", quantity: 1, unitPrice: 5.50, totalPrice: 5.50, category: .beverage, tags: []),
                ReceiptItem(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, name: "Chocolate Muffin", quantity: 2, unitPrice: 3.25, totalPrice: 6.50, category: .food, tags: [])
            ],
            subtotal: 12.00,
            tax: 1.00,
            tip: 2.00,
            total: 15.00,
            currency: "$",
            scanType: .qrCode,
            category: .food,
            receiptType: .received
        ),
        configuration: SplitConfiguration(
            receiptId: UUID(),
            splitType: .individual,
            participants: [
                Participant(id: UUID(), name: "Emma", phoneNumber: "+1234567890", avatarColor: "#FF6B6B"),
                Participant(id: UUID(), name: "You", phoneNumber: "+1234567891", avatarColor: "#4ECDC4")
            ],
            itemAssignments: [
                ItemAssignment(
                    itemId: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
                    participants: [UUID()],
                    splitType: .equal
                )
            ]
        ),
        onConfirm: { _, _ in }
    )
}
