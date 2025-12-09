//
//  CustomSplitOptionsView.swift
//  Qassemha
//
//  Custom splitting ratios - percentage or fixed amounts
//

import SwiftUI

struct CustomSplitOptionsView: View {
    let receipt: Receipt
    @Binding var configuration: SplitConfiguration
    @Environment(\.dismiss) private var dismiss

    var totalAssigned: Double {
        if configuration.splitType == .percentage {
            return configuration.participantSplits.compactMap { $0.customPercentage }.reduce(0, +)
        } else {
            return configuration.participantSplits.compactMap { $0.customAmount }.reduce(0, +)
        }
    }

    var remainingAmount: Double {
        if configuration.splitType == .percentage {
            return 100.0 - totalAssigned
        } else {
            return receipt.total - totalAssigned
        }
    }

    var isValid: Bool {
        if configuration.splitType == .percentage {
            return abs(totalAssigned - 100.0) < 0.01
        } else {
            return abs(totalAssigned - receipt.total) < 0.01
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    instructionsSection

                    // Progress Indicator
                    progressSection

                    // Participants Configuration
                    participantsSection

                    // Quick Actions
                    quickActionsSection

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
            .navigationTitle(configuration.splitType == .percentage ? "Set Percentages" : "Set Custom Amounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
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
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.blue)

            if configuration.splitType == .percentage {
                Text("Enter the percentage each person should pay. Total must equal 100%.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Enter the exact amount each person should pay. Total must equal $\(receipt.total, specifier: "%.2f").")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(configuration.splitType == .percentage ? "Total Percentage" : "Total Amount")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                if configuration.splitType == .percentage {
                    Text("\(Int(totalAssigned))% / 100%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isValid ? .green : .orange)
                } else {
                    Text("$\(totalAssigned, specifier: "%.2f") / $\(receipt.total, specifier: "%.2f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isValid ? .green : .orange)
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    isValid ? .green : (totalAssigned > (configuration.splitType == .percentage ? 100.0 : receipt.total) ? .red : .orange),
                                    isValid ? .green.opacity(0.7) : (totalAssigned > (configuration.splitType == .percentage ? 100.0 : receipt.total) ? .red.opacity(0.7) : .orange.opacity(0.7))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: min(geometry.size.width * (totalAssigned / (configuration.splitType == .percentage ? 100.0 : receipt.total)), geometry.size.width),
                            height: 12
                        )
                }
            }
            .frame(height: 12)

            if !isValid {
                HStack(spacing: 8) {
                    Image(systemName: remainingAmount < 0 ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(remainingAmount < 0 ? .red : .orange)

                    if configuration.splitType == .percentage {
                        Text(remainingAmount > 0 ? "Remaining: \(Int(remainingAmount))%" : "Over by: \(Int(abs(remainingAmount)))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text(remainingAmount > 0 ? "Remaining: $\(remainingAmount, specifier: "%.2f")" : "Over by: $\(abs(remainingAmount), specifier: "%.2f")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            Text("Participants")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(configuration.participants.indices, id: \.self) { index in
                    let participant = configuration.participants[index]
                    CustomSplitParticipantRow(
                        participant: participant,
                        splitType: configuration.splitType,
                        receiptTotal: receipt.total,
                        value: Binding(
                            get: {
                                if let splitIndex = configuration.participantSplits.firstIndex(where: { $0.participantId == participant.id }) {
                                    if configuration.splitType == .percentage {
                                        return configuration.participantSplits[splitIndex].customPercentage ?? 0
                                    } else {
                                        return configuration.participantSplits[splitIndex].customAmount ?? 0
                                    }
                                }
                                return 0
                            },
                            set: { newValue in
                                if let splitIndex = configuration.participantSplits.firstIndex(where: { $0.participantId == participant.id }) {
                                    if configuration.splitType == .percentage {
                                        configuration.participantSplits[splitIndex].customPercentage = newValue
                                    } else {
                                        configuration.participantSplits[splitIndex].customAmount = newValue
                                    }
                                } else {
                                    var newSplit = ParticipantSplit(participantId: participant.id)
                                    if configuration.splitType == .percentage {
                                        newSplit.customPercentage = newValue
                                    } else {
                                        newSplit.customAmount = newValue
                                    }
                                    configuration.participantSplits.append(newSplit)
                                }
                            }
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

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                Button(action: distributeEqually) {
                    HStack {
                        Image(systemName: "equal.circle.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text("Distribute Equally")
                            .font(.system(size: 15, weight: .semibold))

                        Spacer()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
                }

                Button(action: clearAll) {
                    HStack {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text("Clear All")
                            .font(.system(size: 15, weight: .semibold))

                        Spacer()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.red, lineWidth: 1.5)
                    )
                }

                if configuration.splitType == .custom && remainingAmount > 0 {
                    Button(action: assignRemaining) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))

                            Text("Assign Remaining to First Person")
                                .font(.system(size: 15, weight: .semibold))

                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
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

    // MARK: - Helper Methods

    private func distributeEqually() {
        let count = Double(configuration.participants.count)
        let valuePerPerson = configuration.splitType == .percentage ? (100.0 / count) : (receipt.total / count)

        for i in configuration.participants.indices {
            let participant = configuration.participants[i]
            if let splitIndex = configuration.participantSplits.firstIndex(where: { $0.participantId == participant.id }) {
                if configuration.splitType == .percentage {
                    configuration.participantSplits[splitIndex].customPercentage = valuePerPerson
                } else {
                    configuration.participantSplits[splitIndex].customAmount = valuePerPerson
                }
            } else {
                var newSplit = ParticipantSplit(participantId: participant.id)
                if configuration.splitType == .percentage {
                    newSplit.customPercentage = valuePerPerson
                } else {
                    newSplit.customAmount = valuePerPerson
                }
                configuration.participantSplits.append(newSplit)
            }
        }
    }

    private func clearAll() {
        for i in configuration.participantSplits.indices {
            if configuration.splitType == .percentage {
                configuration.participantSplits[i].customPercentage = 0
            } else {
                configuration.participantSplits[i].customAmount = 0
            }
        }
    }

    private func assignRemaining() {
        guard !configuration.participants.isEmpty, remainingAmount > 0 else { return }

        let firstParticipant = configuration.participants[0]
        if let splitIndex = configuration.participantSplits.firstIndex(where: { $0.participantId == firstParticipant.id }) {
            let currentAmount = configuration.participantSplits[splitIndex].customAmount ?? 0
            configuration.participantSplits[splitIndex].customAmount = currentAmount + remainingAmount
        }
    }
}

// MARK: - Custom Split Participant Row

struct CustomSplitParticipantRow: View {
    let participant: Participant
    let splitType: SplitType
    let receiptTotal: Double
    @Binding var value: Double

    @FocusState private var isFocused: Bool

    var equivalentAmount: Double {
        if splitType == .percentage {
            return receiptTotal * (value / 100.0)
        }
        return value
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(hex: participant.avatarColor) ?? .blue)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if splitType == .percentage {
                    Text("≈ $\(equivalentAmount, specifier: "%.2f")")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Input Field
            HStack(spacing: 4) {
                if splitType == .custom {
                    Text("$")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                TextField(splitType == .percentage ? "0" : "0.00", value: $value, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 80)
                    .focused($isFocused)

                if splitType == .percentage {
                    Text("%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CustomSplitOptionsView(
        receipt: Receipt(
            storeName: "Olive Garden",
            date: Date(),
            items: [],
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
            splitType: .percentage,
            participants: [
                Participant(name: "John", avatarColor: "#FF6B6B"),
                Participant(name: "Sarah", avatarColor: "#4ECDC4"),
                Participant(name: "Mike", avatarColor: "#45B7D1")
            ]
        ))
    )
}
