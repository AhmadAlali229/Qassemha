//
//  GroupsView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct GroupsView: View {
    @ObservedObject var groupManager = GroupManager.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var searchText = ""
    @State private var showingNewGroup = false
    @State private var selectedGroup: SavedGroup?

    var filteredFavorites: [SavedGroup] {
        if searchText.isEmpty {
            return groupManager.favoriteGroups
        }
        return groupManager.favoriteGroups.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredRecent: [SavedGroup] {
        if searchText.isEmpty {
            return groupManager.recentGroups
        }
        return groupManager.recentGroups.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                if groupManager.groups.isEmpty {
                    // Empty State
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)

                            Text("No Groups Yet")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Create your first group to split bills with friends and family")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Button(action: {
                            showingNewGroup = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Group")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Search Bar
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)

                                TextField("Search groups", text: $searchText)
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

                            // Favorite Groups
                            if !filteredFavorites.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.yellow)

                                        Text("Favorite Groups")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primary)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(filteredFavorites, id: \.objectID) { group in
                                                SavedGroupFavoriteCard(group: group)
                                                    .onTapGesture {
                                                        selectedGroup = group
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }
                            }

                            // Recent Groups
                            if !filteredRecent.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)

                                        Text("Recent Groups")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primary)

                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)

                                    VStack(spacing: 12) {
                                        ForEach(filteredRecent, id: \.objectID) { group in
                                            SavedGroupRecentCard(group: group)
                                                .onTapGesture {
                                                    selectedGroup = group
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            if filteredFavorites.isEmpty && filteredRecent.isEmpty && !searchText.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)

                                    Text("No groups found")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity)
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
            .navigationTitle("Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewGroup = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingNewGroup) {
                NewGroupView(isPresented: $showingNewGroup)
            }
            .sheet(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
            .onAppear {
                groupManager.fetchGroups()
            }
            .onChange(of: navigationCoordinator.shouldShowNewGroup) { shouldShow in
                if shouldShow {
                    // Auto-trigger new group from home screen
                    showingNewGroup = true
                    navigationCoordinator.resetGroupTrigger()
                }
            }
        }
    }
}

struct SavedGroupFavoriteCard: View {
    @ObservedObject var group: SavedGroup

    var body: some View {
        VStack(spacing: 12) {
            // Group Icon
            ZStack {
                Circle()
                    .fill(group.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: group.icon ?? "person.3.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(group.color)
            }

            VStack(spacing: 4) {
                Text(group.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(group.memberCount) members")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Text(group.lastActivityString)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct SavedGroupRecentCard: View {
    @ObservedObject var group: SavedGroup

    var body: some View {
        HStack(spacing: 16) {
            // Group Icon
            ZStack {
                Circle()
                    .fill(group.color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: group.icon ?? "person.3.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(group.color)
            }

            // Group Info
            VStack(alignment: .leading, spacing: 4) {
                Text(group.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(group.memberNames)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("Last activity: \(group.lastActivityString)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct NewGroupView: View {
    @Binding var isPresented: Bool
    @ObservedObject var groupManager = GroupManager.shared
    @State private var groupName = ""
    @State private var selectedIcon = "person.3.fill"
    @State private var selectedColor = Color.blue
    @State private var selectedContacts: [Contact] = []
    @State private var showingContactPicker = false
    @State private var isFavorite = false

    private let icons = ["person.3.fill", "house.fill", "briefcase.fill", "film.fill", "graduationcap.fill", "heart.fill", "gamecontroller.fill", "music.note", "fork.knife", "cup.and.saucer.fill", "airplane", "car.fill"]
    private let colors: [Color] = [.blue, .purple, .orange, .green, .red, .pink, .indigo, .teal]

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

                        Text(groupName.isEmpty ? "New Group" : groupName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)

                        Text("\(selectedContacts.count) members")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
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

                        // Members Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Members")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button(action: {
                                    showingContactPicker = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                }
                            }

                            if selectedContacts.isEmpty {
                                Button(action: {
                                    showingContactPicker = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)

                                        Text("Add members to this group")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)

                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(selectedContacts, id: \.objectID) { contact in
                                        HStack(spacing: 12) {
                                            if let image = contact.profileImage {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 36, height: 36)
                                                    .clipShape(Circle())
                                            } else {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 36, height: 36)
                                                    .overlay(
                                                        Image(systemName: "person.fill")
                                                            .font(.system(size: 16))
                                                            .foregroundColor(.white)
                                                    )
                                            }

                                            Text(contact.displayName)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)

                                            Spacer()

                                            Button(action: {
                                                selectedContacts.removeAll { $0.objectID == contact.objectID }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.systemGray6))
                                        )
                                    }
                                }
                            }
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

                        // Favorite Toggle
                        Toggle(isOn: $isFavorite) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add to Favorites")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)

                                Text("Quick access to frequently used groups")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(.blue)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || selectedContacts.isEmpty)
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerView(selectedContacts: $selectedContacts)
            }
        }
    }

    private func createGroup() {
        groupManager.createGroup(
            name: groupName,
            icon: selectedIcon,
            colorHex: selectedColor.toHex(),
            contacts: selectedContacts,
            isFavorite: isFavorite
        )
        isPresented = false
    }
}

#Preview {
    GroupsView()
}