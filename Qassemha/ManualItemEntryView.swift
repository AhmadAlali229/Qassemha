//
//  ManualItemEntryView.swift
//  Qassemha
//
//  Created by Harjot Singh on 27/09/25.
//

import SwiftUI

struct ManualItemEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ManualEntryViewModel()
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.blue)
                        }

                        VStack(spacing: 8) {
                            Text("Add Items Manually")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Create a receipt by adding items one by one")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)

                    // Receipt Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Receipt Information")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Store Name",
                                text: $viewModel.storeName,
                                placeholder: "e.g., Olive Garden",
                                icon: "storefront"
                            )
                            .onChange(of: viewModel.storeName) { _ in
                                viewModel.updateCategorySuggestion()
                            }

                            CustomTextField(
                                title: "Location (Optional)",
                                text: $viewModel.storeLocation,
                                placeholder: "e.g., 123 Main St",
                                icon: "location"
                            )

                            // Receipt Category Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Receipt.ReceiptCategory.allCases, id: \.self) { category in
                                            ReceiptCategoryButton(
                                                category: category,
                                                isSelected: viewModel.selectedCategory == category
                                            ) {
                                                viewModel.selectedCategory = category
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.horizontal, -20)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                    // Items Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Items")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Spacer()

                            Text("\(viewModel.items.count) item\(viewModel.items.count == 1 ? "" : "s")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        // Add Item Button
                        Button(action: {
                            viewModel.showingAddItem = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16, weight: .medium))

                                Text("Add Item")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.blue, lineWidth: 2)
                            )
                        }

                        // Items List
                        if viewModel.items.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)

                                Text("No items added yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)

                                Text("Tap 'Add Item' to get started")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                    ManualItemRow(
                                        item: item,
                                        onEdit: {
                                            viewModel.editingIndex = index
                                            viewModel.showingAddItem = true
                                        },
                                        onDelete: {
                                            viewModel.removeItem(at: index)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                    // Summary Card
                    if !viewModel.items.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Summary")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Subtotal")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("$\(viewModel.subtotal, specifier: "%.2f")")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }

                                HStack {
                                    Text("Tax")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    TextField("0.00", value: $viewModel.tax, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                }

                                HStack {
                                    Text("Tip (Optional)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    TextField("0.00", value: $viewModel.tip, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                }

                                Divider()

                                HStack {
                                    Text("Total")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("$\(viewModel.total, specifier: "%.2f")")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.regularMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
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
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveReceipt()
                        showingSuccess = true
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(viewModel.items.isEmpty || viewModel.storeName.isEmpty)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            AddItemView(
                item: viewModel.editingIndex != nil ? viewModel.items[viewModel.editingIndex!] : nil,
                onSave: { item in
                    if let editingIndex = viewModel.editingIndex {
                        viewModel.updateItem(at: editingIndex, with: item)
                        viewModel.editingIndex = nil
                    } else {
                        viewModel.addItem(item)
                    }
                    viewModel.showingAddItem = false
                },
                onCancel: {
                    viewModel.editingIndex = nil
                    viewModel.showingAddItem = false
                }
            )
        }
        .alert("Receipt Saved", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your receipt has been saved and will appear in Recent Scans!")
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)

                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
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
}

struct ManualItemRow: View {
    let item: ManualReceiptItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Item Category Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.category.color.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: item.category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.category.color)
            }

            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack {
                    if item.quantity > 1 {
                        Text("\(Int(item.quantity))x")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }

                    Text("$\(item.unitPrice, specifier: "%.2f")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    if item.quantity > 1 {
                        Text("each")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Total Price and Actions
            HStack(spacing: 8) {
                Text("$\(item.totalPrice, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct AddItemView: View {
    let item: ManualReceiptItem?
    let onSave: (ManualReceiptItem) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var quantity: Double = 1.0
    @State private var unitPrice: Double = 0.0
    @State private var selectedCategory: ReceiptItem.ItemCategory = .food
    @State private var notes: String = ""

    var totalPrice: Double {
        quantity * unitPrice
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Item Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Item Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(spacing: 12) {
                            CustomTextField(
                                title: "Item Name",
                                text: $name,
                                placeholder: "e.g., Fettuccine Alfredo",
                                icon: "fork.knife"
                            )

                            // Category Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(ReceiptItem.ItemCategory.allCases, id: \.self) { category in
                                            CategoryButton(
                                                category: category,
                                                isSelected: selectedCategory == category
                                            ) {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.horizontal, -20)
                            }

                            HStack(spacing: 12) {
                                // Quantity
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Quantity")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Image(systemName: "number")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                            .frame(width: 20)

                                        TextField("1", value: $quantity, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(PlainTextFieldStyle())
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

                                // Unit Price
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Unit Price")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)

                                    HStack {
                                        Image(systemName: "dollarsign.circle")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                            .frame(width: 20)

                                        TextField("0.00", value: $unitPrice, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(PlainTextFieldStyle())
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
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                    // Notes (Optional)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes (Optional)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "note.text")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(width: 20)

                                TextField("Add notes about this item...", text: $notes, axis: .vertical)
                                    .lineLimit(3)
                                    .textFieldStyle(PlainTextFieldStyle())
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
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )

                    // Total Preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Total")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack {
                            if quantity > 1 {
                                Text("\(Int(quantity)) × $\(unitPrice, specifier: "%.2f")")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("$\(unitPrice, specifier: "%.2f")")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text("$\(totalPrice, specifier: "%.2f")")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.green.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
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
            .navigationTitle(item != nil ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newItem = ManualReceiptItem(
                            name: name,
                            quantity: quantity,
                            unitPrice: unitPrice,
                            category: selectedCategory,
                            notes: notes.isEmpty ? nil : notes
                        )
                        onSave(newItem)
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || unitPrice <= 0)
                }
            }
        }
        .onAppear {
            if let item = item {
                name = item.name
                quantity = item.quantity
                unitPrice = item.unitPrice
                selectedCategory = item.category
                notes = item.notes ?? ""
            }
        }
    }
}

struct CategoryButton: View {
    let category: ReceiptItem.ItemCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : category.color)
                }

                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? category.color : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Models and Data

struct ManualReceiptItem: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unitPrice: Double
    var category: ReceiptItem.ItemCategory
    var notes: String?

    var totalPrice: Double {
        quantity * unitPrice
    }
}

class ManualEntryViewModel: ObservableObject {
    @Published var storeName: String = ""
    @Published var storeLocation: String = ""
    @Published var selectedCategory: Receipt.ReceiptCategory = .other
    @Published var items: [ManualReceiptItem] = []
    @Published var tax: Double = 0.0
    @Published var tip: Double = 0.0
    @Published var showingAddItem = false
    @Published var editingIndex: Int?

    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var total: Double {
        subtotal + tax + tip
    }

    func addItem(_ item: ManualReceiptItem) {
        items.append(item)
        updateCategorySuggestion()
    }

    func updateItem(at index: Int, with item: ManualReceiptItem) {
        guard index < items.count else { return }
        items[index] = item
        updateCategorySuggestion()
    }

    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
        updateCategorySuggestion()
    }

    func updateCategorySuggestion() {
        // Only auto-suggest if category is still "other" (default)
        guard selectedCategory == .other else { return }

        // First, try to categorize by store name
        if !storeName.isEmpty {
            if let storeCategory = categorizeByStoreName(storeName) {
                selectedCategory = storeCategory
                return
            }
        }

        // If no items yet, keep as other
        guard !items.isEmpty else { return }

        // Count categories of items
        var categoryCounts: [Receipt.ReceiptCategory: Int] = [:]

        for item in items {
            let receiptCategory = mapItemCategoryToReceiptCategory(item.category)
            categoryCounts[receiptCategory, default: 0] += 1
        }

        // Find the most common category
        if let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
            selectedCategory = mostCommonCategory
        }
    }

    private func categorizeByStoreName(_ name: String) -> Receipt.ReceiptCategory? {
        let lowercaseName = name.lowercased()

        // Food & Dining
        let foodKeywords = ["restaurant", "cafe", "coffee", "pizza", "burger", "taco", "sushi",
                           "diner", "grill", "kitchen", "bar", "pub", "bistro", "mcdonald",
                           "subway", "starbucks", "domino", "kfc", "olive garden"]
        if foodKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .food
        }

        // Groceries
        let groceryKeywords = ["market", "grocery", "supermarket", "walmart", "target", "costco",
                              "kroger", "safeway", "whole foods", "trader joe", "aldi", "publix"]
        if groceryKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .groceries
        }

        // Shopping
        let shoppingKeywords = ["mall", "store", "shop", "boutique", "outlet", "department",
                               "amazon", "ebay", "best buy", "apple store", "nike", "gap"]
        if shoppingKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .shopping
        }

        // Entertainment
        let entertainmentKeywords = ["cinema", "theater", "movie", "concert", "club", "arcade",
                                   "bowling", "mini golf", "amusement", "zoo", "museum", "netflix"]
        if entertainmentKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .entertainment
        }

        // Transportation
        let transportKeywords = ["gas", "fuel", "uber", "lyft", "taxi", "parking", "metro",
                                "airline", "airport", "car rental", "shell", "exxon", "bp"]
        if transportKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .transportation
        }

        // Utilities
        let utilityKeywords = ["electric", "water", "phone", "internet", "cable", "insurance",
                              "bank", "credit", "loan", "utility", "bill"]
        if utilityKeywords.contains(where: { lowercaseName.contains($0) }) {
            return .utilities
        }

        return nil
    }

    private func mapItemCategoryToReceiptCategory(_ itemCategory: ReceiptItem.ItemCategory) -> Receipt.ReceiptCategory {
        switch itemCategory {
        case .food, .main, .appetizer, .side, .dessert:
            return .food
        case .beverage:
            return .food
        case .alcohol:
            return .entertainment
        case .other:
            return .other
        }
    }

    func saveReceipt() {
        // Convert to Receipt model and save to CoreData
        let receiptItems = items.map { manualItem in
            ReceiptItem(
                name: manualItem.name,
                quantity: manualItem.quantity,
                unitPrice: manualItem.unitPrice,
                totalPrice: manualItem.totalPrice,
                category: manualItem.category,
                tags: [],
                notes: manualItem.notes
            )
        }

        let receipt = Receipt(
            storeName: storeName,
            storeAddress: storeLocation.isEmpty ? nil : storeLocation,
            date: Date(),
            items: receiptItems,
            subtotal: subtotal,
            tax: tax,
            tip: tip,
            total: total,
            currency: "USD",
            receiptNumber: nil,
            scanType: .manual,
            category: selectedCategory
        )

        CoreDataManager.shared.saveReceipt(receipt)
    }
}

struct ReceiptCategoryButton: View {
    let category: Receipt.ReceiptCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : category.color)
                }

                Text(category.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? category.color : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ManualItemEntryView()
}