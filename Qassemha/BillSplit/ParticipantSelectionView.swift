//
//  ParticipantSelectionView.swift
//  Qassemha
//
//  Select and manage participants for bill splitting
//

import SwiftUI

struct ParticipantSelectionView: View {
    @Binding var configuration: SplitConfiguration
    let receipt: Receipt
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddParticipant = false
    @State private var showingGroupSelection = false
    @State private var searchText = ""

    @StateObject private var contactManager = ContactManager.shared
    @StateObject private var groupManager = GroupManager.shared

    /// Filters the contact list based on the current search text
    /// Returns all contacts if search is empty, otherwise matches by name
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return Array(contactManager.contacts)
        }
        return contactManager.contacts.filter { contact in
            contact.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search contacts...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // Quick Actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Add from Groups
                        Button(action: {
                            showingGroupSelection = true
                        }) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("From Group")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue)
                            )
                        }

                        // Add Manually
                        Button(action: {
                            showingAddParticipant = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Add Manually")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 16)

                Divider()

                // Selected Participants
                if !configuration.participants.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selected (\(configuration.participants.count))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Button("Clear All") {
                                configuration.participants.removeAll()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(configuration.participants) { participant in
                                    SelectedParticipantChip(participant: participant) {
                                        removeParticipant(participant)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 12)
                    }

                    Divider()
                }

                // Contacts List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredContacts, id: \.contactID) { contact in
                            ContactSelectionRow(
                                contact: contact,
                                isSelected: isContactSelected(contact)
                            ) {
                                toggleContact(contact)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Participants")
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
                        // Initialize participant splits if needed
                        syncParticipantSplits()
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddParticipant) {
            AddParticipantView { participant in
                addParticipant(participant)
                showingAddParticipant = false
            }
        }
        .sheet(isPresented: $showingGroupSelection) {
            GroupSelectionView { group in
                addGroupMembers(group)
                showingGroupSelection = false
            }
        }
    }

    // MARK: - Helper Methods

    /// Checks if a contact is already selected as a participant
    /// Matches by both name and phone number to avoid duplicates
    private func isContactSelected(_ contact: Contact) -> Bool {
        configuration.participants.contains { participant in
            participant.name == contact.name && participant.phoneNumber == contact.phoneNumber
        }
    }

    /// Toggles a contact's selection, adding or removing them from participants
    /// Creates a new participant with random avatar color when adding
    private func toggleContact(_ contact: Contact) {
        if isContactSelected(contact) {
            // Remove
            configuration.participants.removeAll { participant in
                participant.name == contact.name && participant.phoneNumber == contact.phoneNumber
            }
        } else {
            // Add
            let participant = Participant(
                name: contact.name ?? "Unknown",
                phoneNumber: contact.phoneNumber,
                email: contact.email,
                avatarColor: generateRandomColor()
            )
            addParticipant(participant)
        }
    }

    /// Adds a participant to the configuration if not already present
    /// Prevents duplicate participants by checking ID
    private func addParticipant(_ participant: Participant) {
        if !configuration.participants.contains(where: { $0.id == participant.id }) {
            configuration.participants.append(participant)
        }
    }

    /// Removes a participant from the split configuration
    /// Also removes associated split data through syncParticipantSplits
    private func removeParticipant(_ participant: Participant) {
        configuration.participants.removeAll { $0.id == participant.id }
    }

    /// Adds all members from a selected group as participants
    /// Converts group contacts to participants with random avatar colors
    private func addGroupMembers(_ group: SavedGroup) {
        for contact in group.contactArray {
            let participant = Participant(
                name: contact.name ?? "Unknown",
                phoneNumber: contact.phoneNumber,
                email: contact.email,
                avatarColor: generateRandomColor()
            )
            addParticipant(participant)
        }
    }

    /// Synchronizes participant splits with the current participant list
    /// Removes orphaned splits and creates new ones for added participants
    private func syncParticipantSplits() {
        // Ensure participant splits match participants
        let existingSplits = Set(configuration.participantSplits.map { $0.participantId })
        let currentParticipants = Set(configuration.participants.map { $0.id })

        // Remove splits for removed participants
        configuration.participantSplits.removeAll { !currentParticipants.contains($0.participantId) }

        // Add splits for new participants
        for participant in configuration.participants {
            if !existingSplits.contains(participant.id) {
                configuration.participantSplits.append(ParticipantSplit(participantId: participant.id))
            }
        }

        // For sent receipts, set adminId if not already set and there's a "You" participant
        if receipt.receiptType == .sent && configuration.adminId == nil {
            if let youParticipant = configuration.participants.first(where: { $0.name == "You" }) {
                configuration.adminId = youParticipant.id
            }
        }

        configuration.updatedAt = Date()
    }

    /// Generates a random color hex code for participant avatars
    /// Selects from a predefined palette of visually distinct colors
    private func generateRandomColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2", "#F8B739", "#52B788"]
        return colors.randomElement() ?? "#007AFF"
    }
}

// MARK: - Contact Selection Row

struct ContactSelectionRow: View {
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(contact.name?.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )

                // Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name ?? "Unknown")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    if let phone = contact.phoneNumber {
                        Text(phone)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Participant Chip

struct SelectedParticipantChip: View {
    let participant: Participant
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: participant.avatarColor) ?? .blue)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )

            Text(participant.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Add Participant View

struct AddParticipantView: View {
    let onAdd: (Participant) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Participant Information") {
                    TextField("Name", text: $name)
                    TextField("Phone Number (Optional)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email (Optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let participant = Participant(
                            name: name,
                            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                            email: email.isEmpty ? nil : email,
                            avatarColor: generateRandomColor()
                        )
                        onAdd(participant)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    /// Generates a random color hex code for the manually added participant's avatar
    /// Selects from a predefined palette of visually distinct colors
    private func generateRandomColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2", "#F8B739", "#52B788"]
        return colors.randomElement() ?? "#007AFF"
    }
}

// MARK: - Group Selection View

struct GroupSelectionView: View {
    let onSelect: (SavedGroup) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var groupManager = GroupManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(groupManager.groups) { group in
                        Button(action: {
                            onSelect(group)
                        }) {
                            HStack(spacing: 12) {
                                // Group Icon
                                ZStack {
                                    Circle()
                                        .fill(group.color.opacity(0.2))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: group.icon ?? "person.3.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(group.color)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(group.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text("\(group.memberCount) member\(group.memberCount == 1 ? "" : "s")")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ParticipantSelectionView(
        configuration: .constant(SplitConfiguration(receiptId: UUID())),
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
        )
    )
}
