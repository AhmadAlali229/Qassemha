//
//  AllReceiptsView.swift
//  Qassemha
//
//  Created by Harjot Singh on 27/09/25.
//

import SwiftUI
import Combine

struct AllReceiptsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var billSplitManager = BillSplitManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var receipts: [Receipt] = []
    @State private var filteredReceipts: [Receipt] = []
    @State private var searchText: String = ""
    @State private var selectedReceipt: Receipt?
    @State private var sortOrder: SortOrder = .dateDescending

    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case amountDescending = "Highest Amount"
        case amountAscending = "Lowest Amount"
        case storeName = "Store Name"

        var systemImage: String {
            switch self {
            case .dateDescending: return "calendar.badge.minus"
            case .dateAscending: return "calendar.badge.plus"
            case .amountDescending: return "arrow.down.circle"
            case .amountAscending: return "arrow.up.circle"
            case .storeName: return "textformat.abc"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Header
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("Search receipts...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())

                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.blue.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Sort Menu - Expanded
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(action: {
                                sortOrder = order
                                applyFiltersAndSort()
                            }) {
                                HStack {
                                    Image(systemName: order.systemImage)
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sort By")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text(sortOrder.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)

                // Results Summary
                HStack {
                    Text("\(filteredReceipts.count) receipt\(filteredReceipts.count == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    if !searchText.isEmpty {
                        Text("filtered")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if !filteredReceipts.isEmpty {
                        let totalAmount = filteredReceipts.reduce(0) { $0 + $1.total }
                        Text("Total: \(currencyManager.format(amount: totalAmount))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Receipts List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredReceipts.isEmpty {
                            EmptyStateView(
                                hasFilters: !searchText.isEmpty,
                                searchText: searchText
                            )
                        } else {
                            ForEach(filteredReceipts) { receipt in
                                ReceiptListCard(receipt: receipt) {
                                    selectedReceipt = receipt
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.02),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .navigationTitle("All Receipts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(item: $selectedReceipt) { receipt in
            ReceiptReviewView(
                receipt: .constant(receipt),
                isPresented: Binding(
                    get: { selectedReceipt != nil },
                    set: { if !$0 { selectedReceipt = nil } }
                )
            )
        }
        .onAppear {
            loadReceipts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .receiptSaved)) { _ in
            loadReceipts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .receiptDeleted)) { _ in
            loadReceipts()
        }
        .onChange(of: searchText) { _ in
            applyFiltersAndSort()
        }
    }

    private func loadReceipts() {
        receipts = CoreDataManager.shared.getSavedReceipts()
        applyFiltersAndSort()
    }

    private func applyFiltersAndSort() {
        var filtered = receipts

        // Filter by user - only show receipts created by current user (or examples)
        let currentUserPhone = authManager.currentUserPhoneNumber
        filtered = filtered.filter { receipt in
            // Always show example receipts
            let isExample = receipt.id.uuidString.hasPrefix("00000000-0000-0000-0000")
            if isExample {
                return true
            }

            // Check if receipt has a configuration
            if let config = billSplitManager.getConfiguration(for: receipt.id) {
                // If config has adminId, only show if current user is the admin
                if let adminId = config.adminId {
                    let isCurrentUserAdmin = config.participants.contains { participant in
                        participant.id == adminId && participant.phoneNumber == currentUserPhone
                    }
                    return isCurrentUserAdmin
                }
                // If config exists but no adminId, show it (legacy receipts)
                return true
            }

            // If no config exists, show it (newly added manual receipts)
            return true
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { receipt in
                receipt.storeName.localizedCaseInsensitiveContains(searchText) ||
                receipt.items.contains { item in
                    item.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        // Apply sorting
        switch sortOrder {
        case .dateDescending:
            filtered.sort { $0.date > $1.date }
        case .dateAscending:
            filtered.sort { $0.date < $1.date }
        case .amountDescending:
            filtered.sort { $0.total > $1.total }
        case .amountAscending:
            filtered.sort { $0.total < $1.total }
        case .storeName:
            filtered.sort { $0.storeName.localizedCaseInsensitiveCompare($1.storeName) == .orderedAscending }
        }

        filteredReceipts = filtered
    }
}

struct ReceiptListCard: View {
    let receipt: Receipt
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Receipt Category Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(receipt.category.color.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: receipt.category.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(receipt.category.color)
                }

                // Receipt Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(receipt.storeName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(receipt.formattedTotal)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .environment(\.layoutDirection, .leftToRight)
                    }

                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: receipt.scanType.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text(receipt.scanType.description)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(receipt.items.count) item\(receipt.items.count == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(receipt.formattedDate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Items Preview
                    if receipt.items.count > 0 {
                        Text(receipt.items.prefix(2).map { $0.name }.joined(separator: ", ") +
                             (receipt.items.count > 2 ? "..." : ""))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let hasFilters: Bool
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasFilters ? "magnifyingglass" : "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(hasFilters ? "No matching receipts" : "No receipts saved")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)

                if hasFilters {
                    if !searchText.isEmpty {
                        Text("No receipts match '\(searchText)'")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Try adjusting your filters")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Start by scanning a receipt or adding items manually")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    AllReceiptsView()
}