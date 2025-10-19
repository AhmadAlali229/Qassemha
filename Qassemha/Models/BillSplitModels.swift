//
//  BillSplitModels.swift
//  Qassemha
//
//  Smart Bill Splitting Data Models
//

import Foundation
import SwiftUI

// MARK: - Participant

struct Participant: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var avatarColor: String

    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String? = nil, avatarColor: String = "#007AFF") {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.avatarColor = avatarColor
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Participant, rhs: Participant) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Split Type

enum SplitType: String, CaseIterable, Codable {
    case equal = "Equal Split"
    case individual = "By Item"
    case percentage = "By Percentage"
    case custom = "Custom Amount"

    var icon: String {
        switch self {
        case .equal: return "equal.circle"
        case .individual: return "list.bullet.rectangle"
        case .percentage: return "percent"
        case .custom: return "dollarsign.circle"
        }
    }

    var description: String {
        switch self {
        case .equal: return "Split total equally among all participants"
        case .individual: return "Assign items to specific people"
        case .percentage: return "Split by custom percentages"
        case .custom: return "Enter custom amounts per person"
        }
    }
}

// MARK: - Item Assignment

struct ItemAssignment: Identifiable, Codable, Equatable {
    let id: UUID
    var itemId: UUID  // Reference to ReceiptItem
    var participants: [UUID]  // Participant IDs who share this item
    var splitType: ItemSplitType
    var customSplits: [UUID: Double]  // For percentage or custom amount splits

    init(id: UUID = UUID(), itemId: UUID, participants: [UUID] = [], splitType: ItemSplitType = .equal, customSplits: [UUID: Double] = [:]) {
        self.id = id
        self.itemId = itemId
        self.participants = participants
        self.splitType = splitType
        self.customSplits = customSplits
    }

    enum ItemSplitType: String, Codable {
        case equal = "Equal"
        case percentage = "Percentage"
        case custom = "Custom"
    }
}

// MARK: - Participant Split

struct ParticipantSplit: Identifiable, Codable, Equatable {
    let id: UUID
    var participantId: UUID
    var subtotal: Double
    var taxAmount: Double
    var tipAmount: Double
    var total: Double
    var itemsAssigned: [UUID]  // Receipt item IDs
    var customPercentage: Double?  // For percentage-based splits
    var customAmount: Double?  // For custom amount splits

    init(id: UUID = UUID(), participantId: UUID, subtotal: Double = 0, taxAmount: Double = 0, tipAmount: Double = 0, total: Double = 0, itemsAssigned: [UUID] = [], customPercentage: Double? = nil, customAmount: Double? = nil) {
        self.id = id
        self.participantId = participantId
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.tipAmount = tipAmount
        self.total = total
        self.itemsAssigned = itemsAssigned
        self.customPercentage = customPercentage
        self.customAmount = customAmount
    }
}

// MARK: - Split Configuration

struct SplitConfiguration: Identifiable, Codable, Equatable {
    let id: UUID
    var receiptId: UUID
    var splitType: SplitType
    var participants: [Participant]
    var itemAssignments: [ItemAssignment]
    var participantSplits: [ParticipantSplit]
    var includeTax: Bool
    var includeTip: Bool
    var excludedParticipants: [UUID]  // Participants excluded from specific shared items
    var paidParticipants: [UUID]  // Participants who have paid their share
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), receiptId: UUID, splitType: SplitType = .equal, participants: [Participant] = [], itemAssignments: [ItemAssignment] = [], participantSplits: [ParticipantSplit] = [], includeTax: Bool = true, includeTip: Bool = true, excludedParticipants: [UUID] = [], paidParticipants: [UUID] = [], notes: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.receiptId = receiptId
        self.splitType = splitType
        self.participants = participants
        self.itemAssignments = itemAssignments
        self.participantSplits = participantSplits
        self.includeTax = includeTax
        self.includeTip = includeTip
        self.excludedParticipants = excludedParticipants
        self.paidParticipants = paidParticipants
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Convenience computed properties
    var totalParticipants: Int {
        participants.count
    }

    var activeParticipants: [Participant] {
        participants.filter { !excludedParticipants.contains($0.id) }
    }
}

// MARK: - Tax/Tip Distribution Method

enum TaxTipDistribution: String, CaseIterable, Codable {
    case proportional = "Proportional"
    case equal = "Equal Split"
    case none = "None"

    var description: String {
        switch self {
        case .proportional: return "Based on each person's subtotal"
        case .equal: return "Split equally among all participants"
        case .none: return "Don't include in split"
        }
    }
}

// MARK: - Split Summary

struct SplitSummary: Identifiable {
    let id = UUID()
    var participant: Participant
    var itemsCount: Int
    var subtotal: Double
    var tax: Double
    var tip: Double
    var total: Double
    var items: [ReceiptItem]
    var isPaid: Bool

    init(participant: Participant, itemsCount: Int = 0, subtotal: Double = 0, tax: Double = 0, tip: Double = 0, total: Double = 0, items: [ReceiptItem] = [], isPaid: Bool = false) {
        self.participant = participant
        self.itemsCount = itemsCount
        self.subtotal = subtotal
        self.tax = tax
        self.tip = tip
        self.total = total
        self.items = items
        self.isPaid = isPaid
    }
}
