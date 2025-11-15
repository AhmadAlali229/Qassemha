//
//  SelectItemsForMarkAsPaidView.swift
//  Qassemha
//
//  View to select items when marking a participant as paid in sent receipts
//

import SwiftUI

struct SelectItemsForMarkAsPaidView: View {
    let receipt: Receipt
    let configuration: SplitConfiguration
    let participant: Participant
    let onConfirm: (Set<UUID>) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedItems: Set<UUID> = []

    private var assignedItems: [ReceiptItem] {
        // Show all items for sent receipts
        receipt.items
    }

    private var alreadyPaidItems: Set<UUID> {
        configuration.paidItems[participant.id] ?? []
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
                            Text("Select Items \(participant.name) Paid For")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)

                            if assignedItems.isEmpty {
                                Text("No items on this receipt")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(assignedItems) { item in
                                        MarkAsPaidItemCard(
                                            item: item,
                                            configuration: configuration,
                                            participantId: participant.id,
                                            isSelected: selectedItems.contains(item.id),
                                            isAlreadyPaid: alreadyPaidItems.contains(item.id),
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
                                Text("Items Selected")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text("\(selectedItems.count) of \(assignedItems.count)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Button(action: {
                                onConfirm(selectedItems)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Mark as Paid")
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
            // Initialize with already paid items selected
            selectedItems = alreadyPaidItems
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)

            Text("Select which items \(participant.name) has paid for")
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

    private func toggleSelection(for itemId: UUID) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }

    private func selectAll() {
        selectedItems = Set(assignedItems.map { $0.id })
    }

    private func deselectAll() {
        selectedItems.removeAll()
    }
}

// MARK: - Mark As Paid Item Card

struct MarkAsPaidItemCard: View {
    let item: ReceiptItem
    let configuration: SplitConfiguration
    let participantId: UUID
    let isSelected: Bool
    let isAlreadyPaid: Bool
    let onToggle: () -> Void

    @ObservedObject private var currencyManager = CurrencyManager.shared

    private var itemAssignment: ItemAssignment? {
        configuration.itemAssignments.first(where: { $0.itemId == item.id })
    }

    private var participantAmount: Double {
        // For sent receipts, items should be automatically split among all participants
        // If there's an assignment, use it; otherwise divide by total participants

        if let assignment = itemAssignment {
            // Check if participant is assigned to this item
            if assignment.participants.contains(participantId) {
                // Participant is assigned - show their specific share
                switch assignment.splitType {
                case .equal:
                    return item.totalPrice / Double(assignment.participants.count)
                case .percentage:
                    let percentage = assignment.customSplits[participantId] ?? 0
                    return item.totalPrice * (percentage / 100.0)
                case .custom:
                    return assignment.customSplits[participantId] ?? 0
                }
            } else {
                // Participant is NOT assigned - show equal share based on assignment count
                return item.totalPrice / Double(assignment.participants.count)
            }
        } else {
            // No assignment exists - divide by all participants (default behavior for sent receipts)
            let totalParticipants = configuration.participants.count
            return totalParticipants > 0 ? item.totalPrice / Double(totalParticipants) : item.totalPrice
        }
    }

    private var otherParticipants: [Participant] {
        if let assignment = itemAssignment {
            // Show participants from the assignment (excluding current participant)
            return configuration.participants.filter { participant in
                assignment.participants.contains(participant.id) && participant.id != participantId
            }
        } else {
            // No assignment - show all other participants (default sharing)
            return configuration.participants.filter { $0.id != participantId }
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
                    HStack {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        if isAlreadyPaid {
                            Text("Already Paid")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.green.opacity(0.15))
                                )
                        }
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

                // Participant's Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(currencyManager.format(amount: participantAmount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? .green : .primary)

                    Text("their share")
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
