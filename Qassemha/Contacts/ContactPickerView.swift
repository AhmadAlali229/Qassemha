//
//  ContactPickerView.swift
//  Qassemha
//
//  Contact picker with search, filtering, and profile pictures
//

import SwiftUI
import CoreData

struct ContactPickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var contactManager = ContactManager.shared
    @Binding var selectedContacts: [Contact]

    @State private var searchText = ""
    @State private var localSelection: Set<NSManagedObjectID> = []

    /// Returns contacts filtered by current search query
    /// Delegates to ContactManager for consistent search logic
    var filteredContacts: [Contact] {
        contactManager.searchContacts(query: searchText)
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
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applySelection()
                        dismiss()
                    }
                    .disabled(localSelection.isEmpty)
                }
            }
            .onAppear {
                // Initialize local selection from passed contacts
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

    /// Applies local selection to bound selectedContacts array
    /// Converts object IDs back to Contact objects for parent view
    private func applySelection() {
        selectedContacts = contactManager.contacts.filter { localSelection.contains($0.objectID) }
    }
}

struct ContactPickerContent: View {
    @ObservedObject var contactManager = ContactManager.shared
    @Binding var selectedContacts: [Contact]
    @Binding var searchText: String
    @Binding var localSelection: Set<NSManagedObjectID>

    let filteredContacts: [Contact]
    let toggleSelection: (Contact) -> Void
    let applySelection: () -> Void

    var body: some View {
        VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search contacts", text: $searchText)
                        .textFieldStyle(.plain)

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
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Selected Count
                if !localSelection.isEmpty {
                    HStack {
                        Text("\(localSelection.count) selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Clear All") {
                            localSelection.removeAll()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                // Contact List
                if filteredContacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text(searchText.isEmpty ? "No contacts available" : "No contacts found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredContacts, id: \.objectID) { contact in
                                ContactRow(
                                    contact: contact,
                                    isSelected: localSelection.contains(contact.objectID)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(contact)
                                }

                                if contact != filteredContacts.last {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }

struct ContactRow: View {
    let contact: Contact
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let image = contact.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
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
                } else if let phone = contact.phoneNumber, !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Selection Indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)

                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }
}

#Preview {
    ContactPickerView(selectedContacts: .constant([]))
}
