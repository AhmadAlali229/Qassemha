//
//  HistoryView.swift
//  Qassemha
//
//  Created by Harjot Singh on 21/09/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedFilter = "All"
    @State private var searchText = ""
    @State private var showingFilters = false

    private let filterOptions = ["All", "Completed", "Pending", "This Week", "This Month"]

    // Sample transaction data
    private let transactions = [
        HistoryTransaction(
            id: 1,
            title: "Dinner at Olive Garden",
            date: Date(),
            total: 67.25,
            yourShare: 16.81,
            participants: ["You", "Alex", "Sarah", "Mike"],
            status: "pending",
            items: ["Pasta", "Salad", "Drinks"],
            type: "receipt"
        ),
        HistoryTransaction(
            id: 2,
            title: "Coffee & Brunch",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            total: 45.80,
            yourShare: 22.90,
            participants: ["You", "Emma"],
            status: "completed",
            items: ["Latte", "Croissant", "Avocado Toast"],
            type: "receipt"
        ),
        HistoryTransaction(
            id: 3,
            title: "Movie Night Tickets",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            total: 56.00,
            yourShare: 14.00,
            participants: ["You", "Chris", "Jordan", "Taylor"],
            status: "completed",
            items: ["Movie Tickets"],
            type: "manual"
        ),
        HistoryTransaction(
            id: 4,
            title: "Uber to Airport",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date(),
            total: 32.50,
            yourShare: 16.25,
            participants: ["You", "Sam"],
            status: "completed",
            items: ["Uber Ride"],
            type: "manual"
        ),
        HistoryTransaction(
            id: 5,
            title: "Grocery Shopping",
            date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date(),
            total: 89.45,
            yourShare: 44.73,
            participants: ["You", "Roommate"],
            status: "completed",
            items: ["Groceries", "Household Items"],
            type: "receipt"
        )
    ]

    var filteredTransactions: [HistoryTransaction] {
        var filtered = transactions

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.participants.joined().localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply status/time filter
        switch selectedFilter {
        case "Completed":
            filtered = filtered.filter { $0.status == "completed" }
        case "Pending":
            filtered = filtered.filter { $0.status == "pending" }
        case "This Week":
            let oneWeekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneWeekAgo }
        case "This Month":
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= oneMonthAgo }
        default:
            break
        }

        return filtered.sorted { $0.date > $1.date }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "clock")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("History")
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HistoryTransaction: Identifiable {
    let id: Int
    let title: String
    let date: Date
    let total: Double
    let yourShare: Double
    let participants: [String]
    let status: String
    let items: [String]
    let type: String
}

struct HistoryTransactionCard: View {
    let transaction: HistoryTransaction
    @ObservedObject private var currencyManager = CurrencyManager.shared

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) == true {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private var statusColor: Color {
        switch transaction.status {
        case "pending":
            return .orange
        case "completed":
            return .green
        default:
            return .secondary
        }
    }

    private var typeIcon: String {
        switch transaction.type {
        case "receipt":
            return "receipt"
        case "manual":
            return "plus.circle"
        default:
            return "doc"
        }
    }

    var body: some View {
        Button(action: {
            // Navigate to transaction details
        }) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Type Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                            .frame(width: 48, height: 48)

                        Image(systemName: typeIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.blue)
                    }

                    // Transaction Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(transaction.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currencyManager.format(amount: transaction.yourShare))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 6, height: 6)

                                    Text(transaction.status.capitalized)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(statusColor)
                                }
                            }
                        }

                        Text("\(transaction.participants.count) people • \(formatDate(transaction.date))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Total: $\(transaction.total, specifier: "%.2f")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                // Items Preview
                if !transaction.items.isEmpty {
                    HStack {
                        Text(transaction.items.prefix(3).joined(separator: " • "))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        if transaction.items.count > 3 {
                            Text("and \(transaction.items.count - 3) more")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
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

struct FilterView: View {
    @Binding var selectedFilter: String
    @Binding var isPresented: Bool

    private let filterOptions = [
        ("All", "All transactions"),
        ("Completed", "Fully settled transactions"),
        ("Pending", "Outstanding payments"),
        ("This Week", "Last 7 days"),
        ("This Month", "Last 30 days")
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Filter transactions by:")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    ForEach(filterOptions, id: \.0) { filter in
                        Button(action: {
                            selectedFilter = filter.0
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(filter.0)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)

                                    Text(filter.1)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedFilter == filter.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedFilter == filter.0 ? .blue : Color.gray.opacity(0.3), lineWidth: selectedFilter == filter.0 ? 2 : 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
}