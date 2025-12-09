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

    /// Initializes a new participant with contact information and visual representation
    /// Creates a unique participant for bill splitting with default blue avatar color
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, email: String? = nil, avatarColor: String = "#007AFF") {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.avatarColor = avatarColor
    }

    /// Combines the participant's ID into the hasher for efficient set/dictionary operations
    /// Ensures participants can be uniquely identified in collections
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Compares two participants based solely on their unique ID
    /// Ensures participants are considered equal only when they have the same ID
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

    /// Returns the SF Symbol icon name for each split type
    /// Provides visual representation for UI display
    var icon: String {
        switch self {
        case .equal: return "equal.circle"
        case .individual: return "list.bullet.rectangle"
        case .percentage: return "percent"
        case .custom: return "dollarsign.circle"
        }
    }

    /// Returns a user-friendly description of how the split type works
    /// Helps users understand the splitting method before selecting it
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

    /// Initializes an item assignment for a specific receipt item
    /// Links receipt items to participants for granular bill splitting
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

    /// Initializes a split calculation for a specific participant
    /// Tracks the participant's share of subtotal, tax, tip, and total amounts
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
    var paidItems: [UUID: Set<UUID>]  // Maps participant ID to set of item IDs they've paid for
    var adminId: UUID?  // The participant who created/owns this bill split
    var dueDate: Date?  // Payment due date for notifications
    var reminderSchedule: String?  // Reminder schedule for this specific split
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    /// Initializes a complete split configuration for a receipt
    /// Creates a comprehensive bill splitting setup with payment tracking and reminders
    init(id: UUID = UUID(), receiptId: UUID, splitType: SplitType = .equal, participants: [Participant] = [], itemAssignments: [ItemAssignment] = [], participantSplits: [ParticipantSplit] = [], includeTax: Bool = true, includeTip: Bool = true, excludedParticipants: [UUID] = [], paidParticipants: [UUID] = [], paidItems: [UUID: Set<UUID>] = [:], adminId: UUID? = nil, dueDate: Date? = nil, reminderSchedule: String? = nil, notes: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
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
        self.paidItems = paidItems
        self.adminId = adminId
        self.dueDate = dueDate
        self.reminderSchedule = reminderSchedule
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Returns the total number of participants in the split
    /// Provides a quick count for UI display
    var totalParticipants: Int {
        participants.count
    }

    /// Returns only participants who are actively included in the split
    /// Filters out participants who have been excluded from specific calculations
    var activeParticipants: [Participant] {
        participants.filter { !excludedParticipants.contains($0.id) }
    }
}

// MARK: - Tax/Tip Distribution Method

enum TaxTipDistribution: String, CaseIterable, Codable {
    case proportional = "Proportional"
    case equal = "Equal Split"
    case none = "None"

    /// Returns a description of how tax/tip will be distributed
    /// Explains the distribution method to users for informed decision-making
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

    /// Initializes a split summary for a participant
    /// Aggregates all financial data and items for a single participant's share
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
