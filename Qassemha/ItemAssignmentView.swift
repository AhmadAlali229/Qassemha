//
//  ItemAssignmentView.swift
//  Qassemha
//
//  Interactive item assignment interface with visual indicators
//

import SwiftUI

struct ItemAssignmentView: View {
    let receipt: Receipt
    @Binding var configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = BillSplitManager.shared

    @State private var selectedItem: ReceiptItem?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Instructions
                    instructionsSection

                    // Items List with Assignment
                    itemsSection

                    // Summary Section
                    assignmentSummarySection

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
            .navigationTitle("Assign Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        configuration.updatedAt = Date()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            ItemSplitOptionsView(
                item: item,
                receipt: receipt,
                configuration: $configuration
            )
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)

            Text("Tap an item to assign it to participants. Long press for advanced split options.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Items")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(receipt.items) { item in
                    ItemAssignmentRow(
                        item: item,
                        assignment: getAssignment(for: item),
                        participants: configuration.participants,
                        onTap: {
                            selectedItem = item
                        },
                        onQuickAssign: { participant in
                            toggleParticipantForItem(item: item, participant: participant)
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

    // MARK: - Assignment Summary Section

    private var assignmentSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assignment Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(configuration.participants) { participant in
                    ParticipantAssignmentSummary(
                        participant: participant,
                        items: getAssignedItems(for: participant),
                        total: calculateParticipantSubtotal(for: participant)
                    )
                }
            }

            // Unassigned Items Warning
            let unassignedCount = configuration.itemAssignments.filter { $0.participants.isEmpty }.count
            if unassignedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)

                    Text("\(unassignedCount) item\(unassignedCount == 1 ? "" : "s") not assigned yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
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

    // MARK: - Helper Methods

    private func getAssignment(for item: ReceiptItem) -> ItemAssignment {
        if let assignment = configuration.itemAssignments.first(where: { $0.itemId == item.id }) {
            return assignment
        }
        let newAssignment = ItemAssignment(itemId: item.id)
        configuration.itemAssignments.append(newAssignment)
        return newAssignment
    }

    private func toggleParticipantForItem(item: ReceiptItem, participant: Participant) {
        if let index = configuration.itemAssignments.firstIndex(where: { $0.itemId == item.id }) {
            var assignment = configuration.itemAssignments[index]

            if assignment.participants.contains(participant.id) {
                assignment.participants.removeAll { $0 == participant.id }
                assignment.customSplits.removeValue(forKey: participant.id)
            } else {
                assignment.participants.append(participant.id)
            }

            configuration.itemAssignments[index] = assignment
            configuration.updatedAt = Date()
        }
    }

    private func getAssignedItems(for participant: Participant) -> [ReceiptItem] {
        let assignedItemIds = configuration.itemAssignments
            .filter { $0.participants.contains(participant.id) }
            .map { $0.itemId }

        return receipt.items.filter { assignedItemIds.contains($0.id) }
    }

    private func calculateParticipantSubtotal(for participant: Participant) -> Double {
        var total = 0.0

        for assignment in configuration.itemAssignments where assignment.participants.contains(participant.id) {
            guard let item = receipt.items.first(where: { $0.id == assignment.itemId }) else { continue }

            switch assignment.splitType {
            case .equal:
                total += item.totalPrice / Double(assignment.participants.count)
            case .percentage:
                if let percentage = assignment.customSplits[participant.id] {
                    total += item.totalPrice * (percentage / 100.0)
                }
            case .custom:
                if let customAmount = assignment.customSplits[participant.id] {
                    total += customAmount
                }
            }
        }

        return total
    }
}

// MARK: - Item Assignment Row

struct ItemAssignmentRow: View {
    let item: ReceiptItem
    let assignment: ItemAssignment
    let participants: [Participant]
    let onTap: () -> Void
    let onQuickAssign: (Participant) -> Void

    var assignedParticipants: [Participant] {
        participants.filter { assignment.participants.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.category.color.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if item.quantity > 1 {
                        Text("\(Int(item.quantity))x $\(item.unitPrice, specifier: "%.2f") each")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(item.totalPrice, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)

                    if assignment.splitType != .equal {
                        Text(assignment.splitType.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
            }

            // Assigned Participants
            if assignedParticipants.isEmpty {
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .medium))

                        Text("Assign to participants")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue, lineWidth: 1.5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.05))
                            )
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Assigned to:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: onTap) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Edit")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.blue)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(assignedParticipants) { participant in
                                ParticipantAssignmentChip(
                                    participant: participant,
                                    assignment: assignment,
                                    itemTotal: item.totalPrice,
                                    onRemove: {
                                        onQuickAssign(participant)
                                    }
                                )
                            }

                            // Add more button
                            Button(action: onTap) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .medium))

                                    Text("Add")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.blue, lineWidth: 1.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.blue.opacity(0.05))
                                        )
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(assignedParticipants.isEmpty ? Color.orange.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 2)
                )
        )
    }
}

// MARK: - Participant Assignment Chip

struct ParticipantAssignmentChip: View {
    let participant: Participant
    let assignment: ItemAssignment
    let itemTotal: Double
    let onRemove: () -> Void

    var amountText: String {
        switch assignment.splitType {
        case .equal:
            let amount = itemTotal / Double(assignment.participants.count)
            return "$\(String(format: "%.2f", amount))"
        case .percentage:
            if let percentage = assignment.customSplits[participant.id] {
                return "\(Int(percentage))%"
            }
            return "?"
        case .custom:
            if let amount = assignment.customSplits[participant.id] {
                return "$\(String(format: "%.2f", amount))"
            }
            return "?"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: participant.avatarColor) ?? .blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(participant.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(amountText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Participant Assignment Summary

struct ParticipantAssignmentSummary: View {
    let participant: Participant
    let items: [ReceiptItem]
    let total: Double

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

                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("$\(total, specifier: "%.2f")")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ItemAssignmentView(
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
