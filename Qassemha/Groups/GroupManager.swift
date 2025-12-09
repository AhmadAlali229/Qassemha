//
//  GroupManager.swift
//  Qassemha
//
//  Group management for creating and managing groups
//

import SwiftUI
import CoreData

class GroupManager: ObservableObject {
    static let shared = GroupManager()
    private let context = PersistenceController.shared.container.viewContext

    @Published var groups: [SavedGroup] = []
    @Published var favoriteGroups: [SavedGroup] = []
    @Published var recentGroups: [SavedGroup] = []

    private init() {
        fetchGroups()
    }

    // MARK: - Fetch Groups
    /// Fetches all groups from Core Data sorted by last used date
    /// Updates published arrays for favorites and recent groups
    func fetchGroups() {
        let request: NSFetchRequest<SavedGroup> = SavedGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedGroup.lastUsed, ascending: false)]

        do {
            groups = try context.fetch(request)
            updateFavoriteAndRecentGroups()
        } catch {
            print("Error fetching groups: \(error)")
        }
    }

    private func updateFavoriteAndRecentGroups() {
        favoriteGroups = groups.filter { $0.isFavorite }.sorted {
            ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast)
        }

        recentGroups = groups.filter { !$0.isFavorite }
            .sorted { ($0.lastUsed ?? Date.distantPast) > ($1.lastUsed ?? Date.distantPast) }
            .prefix(10)
            .map { $0 }
    }

    // MARK: - Create Group
    /// Creates a new group with specified properties and member contacts
    /// Automatically sets creation and last used timestamps
    func createGroup(name: String, icon: String, colorHex: String, contacts: [Contact], isFavorite: Bool = false) {
        let group = SavedGroup(context: context)
        group.groupID = UUID()
        group.name = name
        group.icon = icon
        group.colorHex = colorHex
        group.isFavorite = isFavorite
        group.createdAt = Date()
        group.lastUsed = Date()

        // Add members
        for contact in contacts {
            let member = GroupMember(context: context)
            member.memberID = UUID()
            member.contact = contact
            member.group = group
        }

        saveContext()
        fetchGroups()
    }

    // MARK: - Update Group
    /// Updates group properties and replaces all members with new contact list
    /// Removes old members and creates new member relationships
    func updateGroup(_ group: SavedGroup, name: String, icon: String, colorHex: String, contacts: [Contact]) {
        group.name = name
        group.icon = icon
        group.colorHex = colorHex

        // Remove existing members
        if let members = group.members as? Set<GroupMember> {
            for member in members {
                context.delete(member)
            }
        }

        // Add new members
        for contact in contacts {
            let member = GroupMember(context: context)
            member.memberID = UUID()
            member.contact = contact
            member.group = group
        }

        saveContext()
        fetchGroups()
    }

    // MARK: - Delete Group
    /// Permanently removes a group and its members from the database
    /// Updates UI by refetching group list after deletion
    func deleteGroup(_ group: SavedGroup) {
        context.delete(group)
        saveContext()
        fetchGroups()
    }

    // MARK: - Toggle Favorite
    /// Toggles the favorite status of a group
    /// Moves group between favorite and recent sections
    func toggleFavorite(_ group: SavedGroup) {
        group.isFavorite.toggle()
        saveContext()
        fetchGroups()
    }

    // MARK: - Update Last Used
    /// Updates the last used timestamp for a group
    /// Keeps recent groups list sorted by usage
    func updateLastUsed(_ group: SavedGroup) {
        group.lastUsed = Date()
        saveContext()
        fetchGroups()
    }

    // MARK: - Clone Group
    /// Creates a duplicate of an existing group with all its members
    /// Useful for creating similar groups or templates
    func cloneGroup(_ group: SavedGroup, newName: String? = nil) {
        let clonedGroup = SavedGroup(context: context)
        clonedGroup.groupID = UUID()
        clonedGroup.name = newName ?? "\(group.name ?? "Group") Copy"
        clonedGroup.icon = group.icon
        clonedGroup.colorHex = group.colorHex
        clonedGroup.isFavorite = false
        clonedGroup.createdAt = Date()
        clonedGroup.lastUsed = Date()

        // Clone members
        if let members = group.members as? Set<GroupMember> {
            for member in members {
                if let contact = member.contact {
                    let newMember = GroupMember(context: context)
                    newMember.memberID = UUID()
                    newMember.contact = contact
                    newMember.group = clonedGroup
                }
            }
        }

        saveContext()
        fetchGroups()
    }

    // MARK: - Add Member to Group
    /// Adds a single contact as a member to an existing group
    /// Prevents duplicate members by checking existing membership
    func addMember(contact: Contact, to group: SavedGroup) {
        // Check if contact is already a member
        if let members = group.members as? Set<GroupMember> {
            if members.contains(where: { $0.contact?.contactID == contact.contactID }) {
                return
            }
        }

        let member = GroupMember(context: context)
        member.memberID = UUID()
        member.contact = contact
        member.group = group

        saveContext()
        fetchGroups()
    }

    // MARK: - Remove Member from Group
    /// Removes a specific member from a group
    /// Updates group membership and refreshes UI
    func removeMember(_ member: GroupMember, from group: SavedGroup) {
        context.delete(member)
        saveContext()
        fetchGroups()
    }

    // MARK: - Search Groups
    /// Searches groups by name with case-insensitive matching
    /// Returns all groups if query is empty
    func searchGroups(query: String) -> [SavedGroup] {
        if query.isEmpty {
            return groups
        }

        return groups.filter { group in
            group.name?.localizedCaseInsensitiveContains(query) == true
        }
    }

    // MARK: - Helper Methods
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - SavedGroup Extension for UI
extension SavedGroup {
    /// Returns group name or fallback text
    /// Provides safe display value when name is nil
    var displayName: String {
        name ?? "Unnamed Group"
    }

    /// Converts hex color string to SwiftUI Color
    /// Returns blue if color parsing fails
    var color: Color {
        Color(hex: colorHex ?? "#007AFF") ?? .blue
    }

    /// Returns the total number of members in the group
    /// Safely handles Core Data relationship casting
    var memberCount: Int {
        (members as? Set<GroupMember>)?.count ?? 0
    }

    /// Converts member set to sorted array of contacts
    /// Sorts contacts alphabetically by name for consistent display
    var contactArray: [Contact] {
        guard let members = members as? Set<GroupMember> else { return [] }
        return members.compactMap { $0.contact }.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    /// Returns a formatted string of member names with count overflow
    /// Shows first 3 names and indicates additional members with +N format
    var memberNames: String {
        let names = contactArray.prefix(3).compactMap { $0.name }
        let remaining = memberCount - names.count

        if remaining > 0 {
            return names.joined(separator: ", ") + " +\(remaining)"
        }
        return names.joined(separator: ", ")
    }

    /// Returns a human-readable relative time string for last activity
    /// Formats time differences in minutes, hours, days, weeks, or months
    var lastActivityString: String {
        guard let lastUsed = lastUsed else { return "Never used" }

        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents([.day, .hour, .minute], from: lastUsed, to: now)

        if let days = components.day, days > 0 {
            if days == 1 {
                return "1 day ago"
            } else if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
            } else {
                let months = days / 30
                return months == 1 ? "1 month ago" : "\(months) months ago"
            }
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Color Extension
extension Color {
    /// Initializes Color from hex string (supports RGB 24-bit, ARGB 32-bit)
    /// Returns nil if hex string format is invalid
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Converts SwiftUI Color to hex string format
    /// Returns #RRGGBB format, defaults to blue if conversion fails
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#007AFF" }

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
