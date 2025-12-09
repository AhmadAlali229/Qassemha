//
//  GroupsView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct GroupsView: View {
    @State private var searchText = ""
    @State private var showingNewGroup = false

    // Sample data
    private let favoriteGroups = [
        Group(id: 1, name: "Roommates", members: ["Alex", "Sam", "Jordan"], icon: "house.fill", color: .blue, lastActivity: "2 hours ago"),
        Group(id: 2, name: "Work Squad", members: ["Mike", "Sarah", "Tom", "Lisa"], icon: "briefcase.fill", color: .purple, lastActivity: "1 day ago"),
        Group(id: 3, name: "Movie Crew", members: ["Chris", "Emma", "Ryan"], icon: "film.fill", color: .orange, lastActivity: "3 days ago")
    ]

    private let recentGroups = [
        Group(id: 4, name: "College Friends", members: ["Jake", "Maya", "Oliver"], icon: "graduationcap.fill", color: .green, lastActivity: "1 week ago"),
        Group(id: 5, name: "Family", members: ["Mom", "Dad", "Sister"], icon: "heart.fill", color: .red, lastActivity: "2 weeks ago")
    ]

    var filteredFavorites: [Group] {
        if searchText.isEmpty {
            return favoriteGroups
        }
        return favoriteGroups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredRecent: [Group] {
        if searchText.isEmpty {
            return recentGroups
        }
        return recentGroups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Groups")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Coming Soon")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Spacer()
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
        }
    }
}

struct Group: Identifiable, Hashable {
    let id: Int
    let name: String
    let members: [String]
    let icon: String
    let color: Color
    let lastActivity: String
}

struct FavoriteGroupCard: View {
    let group: Group

    var body: some View {
        Button(action: {
            // Navigate to group details
        }) {
            VStack(spacing: 12) {
                // Group Icon
                ZStack {
                    Circle()
                        .fill(group.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: group.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(group.color)
                }

                VStack(spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("\(group.members.count) members")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(group.lastActivity)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentGroupCard: View {
    let group: Group

    var body: some View {
        Button(action: {
            // Navigate to group details
        }) {
            HStack(spacing: 16) {
                // Group Icon
                ZStack {
                    Circle()
                        .fill(group.color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: group.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(group.color)
                }

                // Group Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(group.members.joined(separator: ", "))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text("Last activity: \(group.lastActivity)")
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewGroupView: View {
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var selectedIcon = "person.3.fill"
    @State private var selectedColor = Color.blue

    private let icons = ["person.3.fill", "house.fill", "briefcase.fill", "film.fill", "graduationcap.fill", "heart.fill", "gamecontroller.fill", "music.note"]
    private let colors: [Color] = [.blue, .purple, .orange, .green, .red, .pink, .indigo, .teal]

    var body: some View {
        NavigationView {
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
                }

                VStack(alignment: .leading, spacing: 16) {
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
                                            .frame(width: 48, height: 48)

                                        Image(systemName: icon)
                                            .font(.system(size: 20, weight: .medium))
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
                                        .frame(width: 32, height: 32)
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

                Spacer()
            }
            .padding(.vertical, 20)
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
                        // Create group logic
                        isPresented = false
                    }
                    .disabled(groupName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    GroupsView()
}