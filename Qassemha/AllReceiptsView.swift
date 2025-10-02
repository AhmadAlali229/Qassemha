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
    @State private var receipts: [Receipt] = []
    @State private var filteredReceipts: [Receipt] = []
    @State private var searchText: String = ""
    @State private var selectedCategory: Receipt.ReceiptCategory? = nil
    @State private var showingReceiptDetail = false
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

                    // Filter and Sort Row
                    HStack(spacing: 12) {
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // All Categories Button
                                FilterCategoryButton(
                                    title: "All",
                                    icon: "list.bullet",
                                    color: .blue,
                                    isSelected: selectedCategory == nil
                                ) {
                                    selectedCategory = nil
                                }

                                ForEach(Receipt.ReceiptCategory.allCases, id: \.self) { category in
                                    FilterCategoryButton(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        color: category.color,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, -20)

                        Spacer()

                        // Sort Menu
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
                            HStack(spacing: 4) {
                                Image(systemName: sortOrder.systemImage)
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.blue, lineWidth: 1)
                            )
                        }
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

                    if !searchText.isEmpty || selectedCategory != nil {
                        Text("filtered")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if !filteredReceipts.isEmpty {
                        let totalAmount = filteredReceipts.reduce(0) { $0 + $1.total }
                        Text("Total: $\(totalAmount, specifier: "%.2f")")
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
                                hasFilters: !searchText.isEmpty || selectedCategory != nil,
                                searchText: searchText
                            )
                        } else {
                            ForEach(filteredReceipts) { receipt in
                                ReceiptListCard(receipt: receipt) {
                                    selectedReceipt = receipt
                                    showingReceiptDetail = true
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
        .sheet(isPresented: $showingReceiptDetail) {
            if let receipt = selectedReceipt {
                ReceiptReviewView(
                    receipt: .constant(receipt),
                    isPresented: $showingReceiptDetail
                )
            }
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
        .onChange(of: selectedCategory) { _ in
            applyFiltersAndSort()
        }
    }

    private func loadReceipts() {
        receipts = CoreDataManager.shared.getSavedReceipts()
        applyFiltersAndSort()
    }

    private func applyFiltersAndSort() {
        var filtered = receipts

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { receipt in
                receipt.storeName.localizedCaseInsensitiveContains(searchText) ||
                receipt.items.contains { item in
                    item.name.localizedCaseInsensitiveContains(searchText)
                }
            }
        }

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
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

struct FilterCategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(isSelected ? 0 : 0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
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