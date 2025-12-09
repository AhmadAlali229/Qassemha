//
//  BillSplitManager.swift
//  Qassemha
//
//  Core calculation logic for smart bill splitting
//

import Foundation
import SwiftUI

class BillSplitManager: ObservableObject {
    static let shared = BillSplitManager()

    @Published var splitConfigurations: [UUID: SplitConfiguration] = [:]

    private init() {
        loadConfigurations()
    }

    // MARK: - Configuration Management

    func createConfiguration(for receipt: Receipt, participants: [Participant]) -> SplitConfiguration {
        var config = SplitConfiguration(
            receiptId: receipt.id,
            participants: participants
        )

        // Initialize participant splits
        config.participantSplits = participants.map { participant in
            ParticipantSplit(participantId: participant.id)
        }

        // Initialize item assignments
        config.itemAssignments = receipt.items.map { item in
            ItemAssignment(itemId: item.id)
        }

        splitConfigurations[receipt.id] = config
        saveConfigurations()
        notifyUpdate()
        return config
    }

    func getConfiguration(for receiptId: UUID) -> SplitConfiguration? {
        return splitConfigurations[receiptId]
    }

    func updateConfiguration(_ config: SplitConfiguration) {
        splitConfigurations[config.receiptId] = config
        saveConfigurations()
        notifyUpdate()
    }

    func deleteConfiguration(for receiptId: UUID) {
        splitConfigurations.removeValue(forKey: receiptId)
        saveConfigurations()
        notifyUpdate()
    }

    // MARK: - Equal Split Calculation

    func calculateEqualSplit(receipt: Receipt, config: SplitConfiguration) -> [ParticipantSplit] {
        let activeParticipantIds = config.activeParticipants.map { $0.id }
        let participantCount = Double(activeParticipantIds.count)

        guard participantCount > 0 else { return [] }

        let subtotalPerPerson = receipt.subtotal / participantCount
        let taxPerPerson = config.includeTax ? receipt.tax / participantCount : 0
        let tipPerPerson = config.includeTip ? receipt.tip / participantCount : 0
        let totalPerPerson = subtotalPerPerson + taxPerPerson + tipPerPerson

        return activeParticipantIds.map { participantId in
            ParticipantSplit(
                participantId: participantId,
                subtotal: subtotalPerPerson,
                taxAmount: taxPerPerson,
                tipAmount: tipPerPerson,
                total: totalPerPerson,
                itemsAssigned: receipt.items.map { $0.id }
            )
        }
    }

    // MARK: - Individual Item Split Calculation

    func calculateIndividualItemSplit(receipt: Receipt, config: SplitConfiguration) -> [ParticipantSplit] {
        var participantTotals: [UUID: (subtotal: Double, items: [UUID])] = [:]

        // Initialize all participants
        for participant in config.participants {
            participantTotals[participant.id] = (subtotal: 0, items: [])
        }

        // Calculate subtotal per participant based on item assignments
        for assignment in config.itemAssignments {
            guard let item = receipt.items.first(where: { $0.id == assignment.itemId }),
                  !assignment.participants.isEmpty else { continue }

            switch assignment.splitType {
            case .equal:
                // Split item equally among assigned participants
                let amountPerPerson = item.totalPrice / Double(assignment.participants.count)
                for participantId in assignment.participants {
                    if var current = participantTotals[participantId] {
                        current.subtotal += amountPerPerson
                        current.items.append(item.id)
                        participantTotals[participantId] = current
                    }
                }

            case .percentage:
                // Split by custom percentages
                for participantId in assignment.participants {
                    if let percentage = assignment.customSplits[participantId] {
                        let amount = item.totalPrice * (percentage / 100.0)
                        if var current = participantTotals[participantId] {
                            current.subtotal += amount
                            current.items.append(item.id)
                            participantTotals[participantId] = current
                        }
                    }
                }

            case .custom:
                // Split by custom amounts
                for participantId in assignment.participants {
                    if let customAmount = assignment.customSplits[participantId] {
                        if var current = participantTotals[participantId] {
                            current.subtotal += customAmount
                            current.items.append(item.id)
                            participantTotals[participantId] = current
                        }
                    }
                }
            }
        }

        // Calculate tax and tip distribution
        return participantTotals.map { participantId, data in
            let proportionalFactor = data.subtotal / receipt.subtotal

            let taxAmount = config.includeTax ? receipt.tax * proportionalFactor : 0
            let tipAmount = config.includeTip ? receipt.tip * proportionalFactor : 0
            let total = data.subtotal + taxAmount + tipAmount

            return ParticipantSplit(
                participantId: participantId,
                subtotal: data.subtotal,
                taxAmount: taxAmount,
                tipAmount: tipAmount,
                total: total,
                itemsAssigned: data.items
            )
        }
    }

    // MARK: - Percentage-Based Split Calculation

    func calculatePercentageSplit(receipt: Receipt, config: SplitConfiguration) -> [ParticipantSplit] {
        return config.participantSplits.map { split in
            guard let percentage = split.customPercentage else {
                return ParticipantSplit(participantId: split.participantId)
            }

            let factor = percentage / 100.0
            let subtotal = receipt.subtotal * factor
            let taxAmount = config.includeTax ? receipt.tax * factor : 0
            let tipAmount = config.includeTip ? receipt.tip * factor : 0
            let total = subtotal + taxAmount + tipAmount

            return ParticipantSplit(
                participantId: split.participantId,
                subtotal: subtotal,
                taxAmount: taxAmount,
                tipAmount: tipAmount,
                total: total,
                itemsAssigned: receipt.items.map { $0.id },
                customPercentage: percentage
            )
        }
    }

    // MARK: - Custom Amount Split Calculation

    func calculateCustomSplit(receipt: Receipt, config: SplitConfiguration) -> [ParticipantSplit] {
        return config.participantSplits.map { split in
            guard let customAmount = split.customAmount else {
                return ParticipantSplit(participantId: split.participantId)
            }

            return ParticipantSplit(
                participantId: split.participantId,
                subtotal: customAmount,
                taxAmount: 0,
                tipAmount: 0,
                total: customAmount,
                itemsAssigned: [],
                customAmount: customAmount
            )
        }
    }

    // MARK: - Main Split Calculation

    func calculateSplit(receipt: Receipt, config: SplitConfiguration) -> [ParticipantSplit] {
        switch config.splitType {
        case .equal:
            return calculateEqualSplit(receipt: receipt, config: config)
        case .individual:
            return calculateIndividualItemSplit(receipt: receipt, config: config)
        case .percentage:
            return calculatePercentageSplit(receipt: receipt, config: config)
        case .custom:
            return calculateCustomSplit(receipt: receipt, config: config)
        }
    }

    // MARK: - Item Assignment Helpers

    func assignItemToParticipants(itemId: UUID, participantIds: [UUID], config: inout SplitConfiguration) {
        if let index = config.itemAssignments.firstIndex(where: { $0.itemId == itemId }) {
            config.itemAssignments[index].participants = participantIds
        }
        config.updatedAt = Date()
    }

    func setItemSplitType(itemId: UUID, splitType: ItemAssignment.ItemSplitType, config: inout SplitConfiguration) {
        if let index = config.itemAssignments.firstIndex(where: { $0.itemId == itemId }) {
            config.itemAssignments[index].splitType = splitType
        }
        config.updatedAt = Date()
    }

    func setItemCustomSplit(itemId: UUID, participantId: UUID, value: Double, config: inout SplitConfiguration) {
        if let index = config.itemAssignments.firstIndex(where: { $0.itemId == itemId }) {
            config.itemAssignments[index].customSplits[participantId] = value
        }
        config.updatedAt = Date()
    }

    // MARK: - Split Summary Generation

    func generateSplitSummaries(receipt: Receipt, config: SplitConfiguration) -> [SplitSummary] {
        let splits = calculateSplit(receipt: receipt, config: config)

        return splits.map { split in
            guard let participant = config.participants.first(where: { $0.id == split.participantId }) else {
                return SplitSummary(participant: Participant(name: "Unknown"))
            }

            let assignedItems = receipt.items.filter { split.itemsAssigned.contains($0.id) }
            let isPaid = config.paidParticipants.contains(participant.id)

            return SplitSummary(
                participant: participant,
                itemsCount: assignedItems.count,
                subtotal: split.subtotal,
                tax: split.taxAmount,
                tip: split.tipAmount,
                total: split.total,
                items: assignedItems,
                isPaid: isPaid
            )
        }
    }

    // MARK: - Payment Tracking

    func togglePaymentStatus(participantId: UUID, config: inout SplitConfiguration) {
        if config.paidParticipants.contains(participantId) {
            config.paidParticipants.removeAll { $0 == participantId }
        } else {
            config.paidParticipants.append(participantId)
        }
        config.updatedAt = Date()
    }

    func markAsPaid(participantId: UUID, config: inout SplitConfiguration) {
        if !config.paidParticipants.contains(participantId) {
            config.paidParticipants.append(participantId)
            config.updatedAt = Date()
        }
    }

    func markAsUnpaid(participantId: UUID, config: inout SplitConfiguration) {
        config.paidParticipants.removeAll { $0 == participantId }
        config.updatedAt = Date()
    }

    // MARK: - Validation

    func validateSplit(receipt: Receipt, config: SplitConfiguration) -> [String] {
        var warnings: [String] = []

        // Check if all items are assigned
        let unassignedItems = config.itemAssignments.filter { $0.participants.isEmpty }
        if !unassignedItems.isEmpty {
            warnings.append("\(unassignedItems.count) item(s) not assigned to anyone")
        }

        // Check if percentages add up to 100%
        if config.splitType == .percentage {
            let totalPercentage = config.participantSplits.compactMap { $0.customPercentage }.reduce(0, +)
            if abs(totalPercentage - 100.0) > 0.01 {
                warnings.append("Percentages don't add up to 100% (current: \(String(format: "%.1f", totalPercentage))%)")
            }
        }

        // Check if custom amounts match receipt total
        if config.splitType == .custom {
            let totalCustom = config.participantSplits.compactMap { $0.customAmount }.reduce(0, +)
            if abs(totalCustom - receipt.total) > 0.01 {
                warnings.append("Custom amounts don't match receipt total")
            }
        }

        // Check if item percentages add up correctly
        if config.splitType == .individual {
            for assignment in config.itemAssignments where assignment.splitType == .percentage {
                let totalPercentage = assignment.customSplits.values.reduce(0, +)
                if abs(totalPercentage - 100.0) > 0.01 {
                    warnings.append("Item split percentages don't add up to 100%")
                    break
                }
            }
        }

        return warnings
    }

    // MARK: - Persistence

    private func saveConfigurations() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(splitConfigurations) {
            UserDefaults.standard.set(encoded, forKey: "BillSplitConfigurations")
        }
    }

    private func loadConfigurations() {
        guard let data = UserDefaults.standard.data(forKey: "BillSplitConfigurations"),
              let configs = try? JSONDecoder().decode([UUID: SplitConfiguration].self, from: data) else {
            return
        }
        splitConfigurations = configs
    }

    private func notifyUpdate() {
        NotificationCenter.default.post(name: NSNotification.Name("BillSplitUpdated"), object: nil)
    }
}
