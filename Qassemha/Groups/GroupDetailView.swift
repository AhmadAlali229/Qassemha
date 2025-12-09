//
//  GroupDetailView.swift
//  Qassemha
//
//  Group detail view with member management
//

import SwiftUI
import CoreData

struct GroupDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupManager = GroupManager.shared
    @ObservedObject var group: SavedGroup

    @State private var showingEditGroup = false
    @State private var showingAddMembers = false
    @State private var showingDeleteAlert = false
    @State private var showingCloneDialog = false
    @State private var cloneGroupName = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Group Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(group.color.opacity(0.15))
                                .frame(width: 100, height: 100)

                            Image(systemName: group.icon ?? "person.3.fill")
                                .font(.system(size: 42, weight: .medium))
                                .foregroundColor(group.color)
                        }

                        VStack(spacing: 8) {
                            Text(group.displayName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("\(group.memberCount) members")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Last activity: \(group.lastActivityString)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        // Favorite Toggle
                        Button(action: {
                            groupManager.toggleFavorite(group)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: group.isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 14, weight: .medium))

                                Text(group.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(group.isFavorite ? .yellow : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(group.isFavorite ? Color.yellow.opacity(0.15) : Color.blue.opacity(0.15))
                            )
                        }
                    }
                    .padding(.top, 20)

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            cloneGroupName = "\(group.displayName) Copy"
                            showingCloneDialog = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.doc")
                                Text("Clone")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }

                        Button(action: {
                            showingEditGroup = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Members Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Members")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: {
                                showingAddMembers = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            }
                        }

                        if group.contactArray.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)

                                Text("No members in this group")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(group.contactArray, id: \.objectID) { contact in
                                    MemberRow(contact: contact, group: group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Delete Button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Delete Group")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditGroup) {
                EditGroupView(group: group, isPresented: $showingEditGroup)
            }
            .sheet(isPresented: $showingAddMembers) {
                AddMembersView(group: group, isPresented: $showingAddMembers)
            }
            .alert("Clone Group", isPresented: $showingCloneDialog) {
                TextField("New group name", text: $cloneGroupName)

                Button("Cancel", role: .cancel) { }

                Button("Clone") {
                    groupManager.cloneGroup(group, newName: cloneGroupName.isEmpty ? nil : cloneGroupName)
                }
            } message: {
                Text("Create a copy of this group with the same members and settings?")
            }
            .alert("Delete Group", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    groupManager.deleteGroup(group)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this group? This action cannot be undone.")
            }
        }
    }
}

struct MemberRow: View {
    @ObservedObject var contact: Contact
    @ObservedObject var group: SavedGroup
    @ObservedObject var groupManager = GroupManager.shared
    @State private var showingRemoveAlert = false

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let image = contact.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
            }

            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                if let email = contact.email, !email.isEmpty {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Remove Button
            Button(action: {
                showingRemoveAlert = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .alert("Remove Member", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }

            Button("Remove", role: .destructive) {
                if let members = group.members as? Set<GroupMember>,
                   let member = members.first(where: { $0.contact?.objectID == contact.objectID }) {
                    groupManager.removeMember(member, from: group)
                }
            }
        } message: {
            Text("Remove \(contact.displayName) from this group?")
        }
    }
}

struct EditGroupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupManager = GroupManager.shared
    let group: SavedGroup
    @Binding var isPresented: Bool

    @State private var groupName: String
    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @State private var selectedContacts: [Contact]

    private let icons = ["person.3.fill", "house.fill", "briefcase.fill", "film.fill", "graduationcap.fill", "heart.fill", "gamecontroller.fill", "music.note", "fork.knife", "cup.and.saucer.fill", "airplane", "car.fill"]
    private let colors: [Color] = [.blue, .purple, .orange, .green, .red, .pink, .indigo, .teal]

    /// Initializes edit view with current group data
    /// Pre-populates form fields with existing group properties
    init(group: SavedGroup, isPresented: Binding<Bool>) {
        self.group = group
        self._isPresented = isPresented
        self._groupName = State(initialValue: group.displayName)
        self._selectedIcon = State(initialValue: group.icon ?? "person.3.fill")
        self._selectedColor = State(initialValue: group.color)
        self._selectedContacts = State(initialValue: group.contactArray)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(selectedColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: selectedIcon)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(selectedColor)
                        }

                        Text(groupName.isEmpty ? "Group Name" : groupName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 20) {
                        // Group Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("Enter group name", text: $groupName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Icon Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose Icon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                                ForEach(icons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? selectedColor.opacity(0.15) : Color.gray.opacity(0.1))
                                                .frame(width: 56, height: 56)

                                            Image(systemName: icon)
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : .secondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose Color")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                ForEach(colors, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }

    /// Saves group changes to database and dismisses view
    /// Updates group properties while preserving existing members
    private func saveChanges() {
        groupManager.updateGroup(
            group,
            name: groupName,
            icon: selectedIcon,
            colorHex: selectedColor.toHex(),
            contacts: group.contactArray
        )
        isPresented = false
    }
}

struct AddMembersView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var groupManager = GroupManager.shared
    @ObservedObject var contactManager = ContactManager.shared
    @ObservedObject var group: SavedGroup
    @Binding var isPresented: Bool

    @State private var selectedContacts: [Contact] = []
    @State private var searchText = ""
    @State private var localSelection: Set<NSManagedObjectID> = []

    /// Returns contacts not already in the group
    /// Filters out existing members to prevent duplicates
    var availableContacts: [Contact] {
        let existingContactIDs = Set(group.contactArray.map { $0.objectID })
        return contactManager.contacts.filter { !existingContactIDs.contains($0.objectID) }
    }

    /// Filters available contacts based on search text
    /// Searches across name, email, and phone number fields
    var filteredContacts: [Contact] {
        let available = availableContacts
        if searchText.isEmpty {
            return available
        }
        return available.filter { contact in
            contact.name?.localizedCaseInsensitiveContains(searchText) == true ||
            contact.email?.localizedCaseInsensitiveContains(searchText) == true ||
            contact.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        NavigationView {
            ContactPickerContent(
                selectedContacts: $selectedContacts,
                searchText: $searchText,
                localSelection: $localSelection,
                filteredContacts: filteredContacts,
                toggleSelection: toggleSelection,
                applySelection: applySelection
            )
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addMembers()
                    }
                    .disabled(localSelection.isEmpty)
                }
            }
            .onAppear {
                localSelection = Set(selectedContacts.map { $0.objectID })
            }
        }
    }

    /// Toggles selection state for a contact
    /// Adds or removes contact from local selection set
    private func toggleSelection(_ contact: Contact) {
        if localSelection.contains(contact.objectID) {
            localSelection.remove(contact.objectID)
        } else {
            localSelection.insert(contact.objectID)
        }
    }

    /// Converts selected object IDs back to Contact objects
    /// Prepares contacts for addition to group
    private func applySelection() {
        selectedContacts = contactManager.contacts.filter { localSelection.contains($0.objectID) }
    }

    /// Adds selected contacts to the group and dismisses view
    /// Iterates through selected contacts to create member relationships
    private func addMembers() {
        applySelection()
        for contact in selectedContacts {
            groupManager.addMember(contact: contact, to: group)
        }
        isPresented = false
    }
}

#Preview {
    GroupDetailView(group: SavedGroup())
}
